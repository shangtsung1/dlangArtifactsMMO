module script.bettergear;

import global;
import api.ammo;
import api.schema;
import script.helper;
import std.typecons;
import std.conv;
import std.variant; 
import std.range;
import std.algorithm;
import std.math;
import std.stdio;
import std.format;

// Combat simulation parameters
enum {
    BASE_HP = 200,
    CRIT_MULTIPLIER = 1.1,
    HASTE_FACTOR = 0.01
}

struct CombatProfile {
    ElementalStats attack;
    ElementalStats dmgMultipliers = ElementalStats(1.0, 1.0, 1.0, 1.0);
    double crit;
    double haste;
    double defense;
    double hp;
    double restore;
    double wisdom;
    double offensiveScore;
    double defensiveScore;
    double utilityScore;
}

struct ElementalStats {
    double fire;
    double water;
    double air;
    double earth;
}

CombatProfile calculateCombatStats(ItemSchema item) {
    CombatProfile stats;
    stats.offensiveScore = 0;
    stats.defensiveScore = 0;
    stats.utilityScore = 0;
    // Initialize elemental stats
    stats.attack = ElementalStats(0, 0, 0, 0);
    stats.dmgMultipliers = ElementalStats(1.0, 1.0, 1.0, 1.0);
    stats.hp = BASE_HP;
    stats.crit = 0;
    stats.haste = 0;
    stats.defense = 0;
    stats.restore = 0;
    stats.wisdom = 0;

    foreach (effect; item.effects) {
        switch (effect.code) {
            // Offensive stats
            case "attack_fire":
                stats.attack.fire += effect.value;
                break;
            case "attack_water":
                stats.attack.water += effect.value;
                break;
            case "attack_air":
                stats.attack.air += effect.value;
                break;
            case "attack_earth":
                stats.attack.earth += effect.value;
                break;
            
            case "critical_strike":
                stats.crit += effect.value;
                break;
            
            case "haste":
                stats.haste += effect.value;
                break;
            case "wisdom":
                stats.wisdom += effect.value*2;
                break;
            
            case "dmg_fire":
                stats.dmgMultipliers.fire *= 1 + (effect.value / 100.0);
                break;
            case "dmg_water":
                stats.dmgMultipliers.water *= 1 + (effect.value / 100.0);
                break;
            case "dmg_air":
                stats.dmgMultipliers.air *= 1 + (effect.value / 100.0);
                break;
            case "dmg_earth":
                stats.dmgMultipliers.earth *= 1 + (effect.value / 100.0);
                break;

            // Defensive stats
            case "hp", "boost_hp":
                stats.hp += effect.value * (effect.code == "hp" ? 1 : 0.5);
                break;
            
            case "res_fire", "res_water", "res_air", "res_earth":
                stats.defense += effect.value;
                break;
            case "restore":
                stats.restore += effect.value;
                break;
            case "":
                // No effect code, do nothing
                break;
            
            default:
               // writefln("Unknown effect code: ", effect.code);
                break;
        }
    }

    double totalEffectiveAttack = 
    (stats.attack.fire * stats.dmgMultipliers.fire) +
    (stats.attack.water * stats.dmgMultipliers.water) +
    (stats.attack.air * stats.dmgMultipliers.air) +
    (stats.attack.earth * stats.dmgMultipliers.earth);

    // Calculate effective DPS
    double critMultiplier = 1 + (stats.crit / 100.0 * (CRIT_MULTIPLIER - 1));
    double hasteMultiplier = 1 + (stats.haste * HASTE_FACTOR);
    stats.offensiveScore = totalEffectiveAttack * critMultiplier * hasteMultiplier;

    // Calculate effective survivability
    double resistanceMultiplier = 1 - (stats.defense / (stats.defense + 100));
    stats.defensiveScore = stats.hp / resistanceMultiplier;

    // Level scaling with diminishing returns
    double levelBonus = 1 + (item.level * 0.05 * sqrt(item.level.to!float));
    stats.offensiveScore *= levelBonus;
    stats.defensiveScore *= levelBonus;

    stats.utilityScore = stats.restore;

    return stats;
}

bool isBetterItem(ItemSchema current, ItemSchema candidate, string slotType, Character* m) {
    if (candidate.level > m.level) return false;
    
    auto currentStats = calculateCombatStats(current);
    auto candidateStats = calculateCombatStats(candidate);
    if(slotType == "hybrid"){
       // writeln("Current: ", current.name, " (", current.code, ") - ", 
       //     "Offensive: ", currentStats.offensiveScore, 
       //     " Defensive: ", currentStats.defensiveScore, 
        //    " Utility: ", currentStats.utilityScore);
    }
    final switch (slotType) {
        case "offensive":
            return candidateStats.offensiveScore > currentStats.offensiveScore ;
        case "defensive":
            return candidateStats.defensiveScore > currentStats.defensiveScore ;
        case "hybrid":
            double currentTotal = (currentStats.offensiveScore + currentStats.defensiveScore) /2;
            double candidateTotal = (candidateStats.offensiveScore + candidateStats.defensiveScore)/2 ;
            return candidateTotal > currentTotal ;
        case "utility":
            return candidateStats.utilityScore > currentStats.utilityScore ;
    }
    return false;
}

Nullable!ItemSchema findBestItem(Character* m, string currentItemCode, SlotConfig slotConfig) {
    auto currentItem = currentItemCode.empty ? ItemSchema.init : getItem(currentItemCode);
    Nullable!ItemSchema bestItem;
    double bestScore = -1.0;

    auto searchPool = chain(
        m.inventory.map!(bi => getItem(bi.code)), 
        bank.items.map!(bi => getItem(bi.code))
    )
    .filter!(item => 
        item.type == slotConfig.typeName &&
        item.level <= m.level
    );
    foreach (item; searchPool) {
        //writeln("SearchPool: Item: ", item.name, " (", item.code, ")");
        if (isBetterItem(currentItem, item, slotConfig.type, m)) {
            auto stats = calculateCombatStats(item);
            double score = slotConfig.type == "offensive" ? stats.offensiveScore : 
                         slotConfig.type == "defensive" ? stats.defensiveScore :
                         stats.utilityScore;
            if (score > bestScore) {
                bestItem = item.nullable;
                bestScore = score;
            }
            
        }
    }

    return bestItem;
}

Nullable!ItemSchema findBestStackableItem(Character* m, SlotConfig slot) {
    auto currentlyEquipped = m.getEquippedItem(slot.slot);
    int currentQty = m.getEquippedItemCount(slot.slot);
    int maxToEquip = slot.maxStack - currentQty;

    // return null if already have some
    if (currentQty > 0) {
        return Nullable!ItemSchema();
    }

    ItemEvaluation best = ItemEvaluation(getItem(currentlyEquipped), calculateCombatStats(getItem(currentlyEquipped)).utilityScore * 15, 10);
    foreach (bi; chain(
        m.inventory.map!(bi => getItem(bi.code)), 
        bank.items.map!(bi => getItem(bi.code))
    )) {
        ItemSchema item = getItem(bi.code);
        if (item.type != slot.type || item.level > m.level) continue;
        int totalAvailable = countItem(m,bi.code) + bank.count(item.code);
        int possibleQty = min(totalAvailable, slot.maxStack);

        if (possibleQty <= currentQty) continue;
        
        double score = calculateCombatStats(item).utilityScore * possibleQty;
        
        if (score > best.score) {
            best = ItemEvaluation(item, score, possibleQty);
        }
    }
    
    return best.item.nullable;
}

bool tryEquipStackable(Character* m, ItemSchema item, SlotConfig slot) {

    int currentlyEquipped = m.getEquippedItemCount(slot.slot);
    int needed = slot.maxStack - currentlyEquipped;
    
    if (needed <= 0) return false;
    
    // Calculate available quantity
    int inventoryQty = m.countUnequippedItem(item.code);
    int bankQty = bank.count(item.code);
    int totalAvailable = inventoryQty + bankQty;
    int toWithdraw = min(needed, totalAvailable);
    
    if (toWithdraw > 0) {
        // Equip the full stack
        smartEquip(m, item.code, slot.slot, toWithdraw);
        return true;
    }
    
    return false;
}

struct SlotConfig {
    string slot;
    string typeName;
    string type;
    string[] conflictSlots;
    int maxStack; 
    bool isConsumable; 
}

struct ItemEvaluation {
    ItemSchema item;
    double score;
    int availableQty;
}


bool equipmentCheck(Character* m,bool doConsumables) {
    static SlotConfig[] slots = [
    // Offensive slots
    SlotConfig("weapon","weapon", "offensive", [],1,false),
    SlotConfig("amulet","amulet", "hybrid", [],1,false),
    SlotConfig("ring1","ring", "hybrid", ["ring2"],1,false),
    SlotConfig("ring2","ring", "hybrid", ["ring1"],1,false),
    
    // Defensive slots
    SlotConfig("helmet","helmet", "defensive", [],1,false),
    SlotConfig("body_armor","body_armor", "defensive", [],1,false),
    SlotConfig("leg_armor","leg_armor", "defensive", [],1,false),
    SlotConfig("boots","boots", "defensive", [],1,false),
    SlotConfig("shield","shield", "defensive", [],1,false),
    
    // Utility slots
    SlotConfig("utility1","utility", "utility", ["utility2"], 10, true),
    //SlotConfig("utility2", "utility","utility", ["utility1"], 10, true),
    SlotConfig("artifact1","artifact", "utility", [], 1, false),
    ];

    foreach (slotConfig; slots) {
        if (doConsumables && slotConfig.isConsumable) {
            auto bestItem = findBestStackableItem(m, slotConfig);
           // writeln("Best item for ", slotConfig.slot, ": ", bestItem.isNull ? "None" : bestItem.get().name); 
            if (!bestItem.isNull) {
                if (tryEquipStackable(m, bestItem.get(), slotConfig)) {
                    debugLog(m, format("Stacked %s x%d in %s", 
                        bestItem.get().name, 
                        m.getEquippedItemCount(slotConfig.slot),
                        slotConfig.slot));
                    return true;
                }
            }
        } else if(!slotConfig.isConsumable) {
            string currentItem = m.getEquippedItem(slotConfig.slot);
            auto bestItem = findBestItem(m, currentItem, slotConfig);
            //writeln(currentItem," ","Best item for ", slotConfig.slot, ": ", bestItem.isNull ? "None" : bestItem.get().name); 
            if (!bestItem.isNull) {
                if (tryEquipItem(m, bestItem.get(), slotConfig.slot)) {
                    auto combatStats = calculateCombatStats(bestItem.get());
                    debugLog(m, format("Upgraded %s: %s (Score: %.1f)", 
                        slotConfig.slot, bestItem.get().name, 
                        slotConfig.type == "offensive" ? combatStats.offensiveScore :
                        (slotConfig.type == "defensive" ? combatStats.defensiveScore :
                         combatStats.offensiveScore + combatStats.defensiveScore)));
                    return true;
                }
            }
        }
    }
    return false;
}

bool tryEquipItem(Character* m, ItemSchema item, string slot) {
    smartEquip(m, item.code, slot, 1);
    return false;
}

void debugLog(Character* m, string message) {
    writeln(m.color, "[Gear] ", message);
}