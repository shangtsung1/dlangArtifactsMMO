module script.bettergear;

import global;
import api.ammo;
import api.schema;
import script.helper;
import std.stdio;
import std.string;
import std.algorithm;
import std.math;
import std.array;


struct EquipList {
    string itemCode;
    string slotName;
}

struct ItemEffect {
    float attack_fire;
    float attack_water;
    float attack_earth;
    float attack_air;
    float critical_strike;
    float haste;
    float wisdom;
    float dmg_fire;
    float dmg_water;
    float dmg_earth;
    float dmg_air;
    int max_hp;
    int hp;
    float res_fire;
    float res_water;
    float res_earth;
    float res_air;
}

EquipList[] findBestEquipmentToFight(Character* player, MonsterSchema toBeat) {
    ItemSchema[] items;
    foreach(i;player.inventory){
        items ~= getItem(i.code);
    }
    if (player.weapon_slot.length)      items ~= getItem(player.weapon_slot);
    if (player.rune_slot.length)        items ~= getItem(player.rune_slot);
    if (player.shield_slot.length)      items ~= getItem(player.shield_slot);
    if (player.helmet_slot.length)      items ~= getItem(player.helmet_slot);
    if (player.body_armor_slot.length)  items ~= getItem(player.body_armor_slot);
    if (player.leg_armor_slot.length)   items ~= getItem(player.leg_armor_slot);
    if (player.boots_slot.length)       items ~= getItem(player.boots_slot);
    if (player.ring1_slot.length)       items ~= getItem(player.ring1_slot);
    if (player.ring2_slot.length)       items ~= getItem(player.ring2_slot);
    if (player.amulet_slot.length)      items ~= getItem(player.amulet_slot);
    if (player.artifact1_slot.length)   items ~= getItem(player.artifact1_slot);
    if (player.artifact2_slot.length)   items ~= getItem(player.artifact2_slot);
    if (player.artifact3_slot.length)   items ~= getItem(player.artifact3_slot);
    if (player.bag_slot.length)         items ~= getItem(player.bag_slot);
    foreach(i;bank.items){
        items ~= getItem(i.code);
    }
    return findBestEquipmentToFight(player, toBeat, items);
}

EquipList[] findBestEquipmentToFight(Character* player, MonsterSchema toBeat, const ItemSchema[] items) {
    import std.ascii : isDigit;
    int[string] itemCodeCount;
    foreach (item; items) {
        itemCodeCount[item.code] = itemCodeCount.get(item.code, 0) + 1;
    }

    Character basePlayer = *player;

    string[] slotOrder = [
        "weapon_slot", "rune_slot", "shield_slot", "helmet_slot",
        "body_armor_slot", "leg_armor_slot", "boots_slot", "ring1_slot",
        "ring2_slot", "amulet_slot", /*"artifact1_slot", "artifact2_slot",
        "artifact3_slot",*/ "bag_slot"
    ];

    EquipList[] bestEquip;

    foreach (slot; slotOrder) {
        const(ItemSchema)*[] candidates;
        candidates ~= null;

        // Get slot base name without "_slot" suffix
        string slotBase = slot.replace("_slot", "");
        
        foreach (ref const item; items) {
            // Check if item can be equipped in this slot
            if (item.type.length > slotBase.length) continue;
            
            // Match base type and optional digits
            if (slotBase.startsWith(item.type)) {
                string remaining = slotBase[item.type.length..$];
                
                // Check if remaining characters are all digits or empty
                bool validRemaining = remaining.all!(c => c.isDigit);
                
                if (validRemaining && 
                    itemCodeCount.get(item.code, 0) > 0 && 
                    item.level <= basePlayer.level) {
                    candidates ~= &item;
                }
            }
        }

        const(ItemSchema)* bestItem = null;
        double bestScore = -1.0;

        foreach (candidate; candidates) {
            if (candidate !is null) {
                ItemEffect ee = ItemEffect(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
                foreach (effect; candidate.effects) {
                    getEffect(ee,effect);
                }
                double currentScore = computeScore(ee, toBeat);
                if(player.getEquippedItem(candidate.type) == candidate.name){
                    currentScore+=0.001;
                }
                if (currentScore > bestScore) {
                    bestScore = currentScore;
                    bestItem = candidate;
                }
            }
        }

        if (bestItem !is null) {
            bestEquip ~= EquipList(bestItem.code, slot);
            itemCodeCount[bestItem.code]--;
        }
        else{
            bestEquip ~= EquipList("", slot);
        }
    }
    return bestEquip;
}

EquipList[] findBestWisdomEquipmentToFight(Character* player) {
    ItemSchema[] items;
    foreach(i;player.inventory){
        items ~= getItem(i.code);
    }
    if (player.weapon_slot.length)      items ~= getItem(player.weapon_slot);
    if (player.rune_slot.length)        items ~= getItem(player.rune_slot);
    if (player.shield_slot.length)      items ~= getItem(player.shield_slot);
    if (player.helmet_slot.length)      items ~= getItem(player.helmet_slot);
    if (player.body_armor_slot.length)  items ~= getItem(player.body_armor_slot);
    if (player.leg_armor_slot.length)   items ~= getItem(player.leg_armor_slot);
    if (player.boots_slot.length)       items ~= getItem(player.boots_slot);
    if (player.ring1_slot.length)       items ~= getItem(player.ring1_slot);
    if (player.ring2_slot.length)       items ~= getItem(player.ring2_slot);
    if (player.amulet_slot.length)      items ~= getItem(player.amulet_slot);
    if (player.artifact1_slot.length)   items ~= getItem(player.artifact1_slot);
    if (player.artifact2_slot.length)   items ~= getItem(player.artifact2_slot);
    if (player.artifact3_slot.length)   items ~= getItem(player.artifact3_slot);
    if (player.bag_slot.length)         items ~= getItem(player.bag_slot);
    foreach(i;bank.items){
        items ~= getItem(i.code);
    }
    return findBestWisdomEquipmentToFight(player, items);
}


EquipList[] findBestWisdomEquipmentToFight(Character* player, const ItemSchema[] items) {
    import std.ascii : isDigit;
    int[string] itemCodeCount;
    foreach (item; items) {
        itemCodeCount[item.code] = itemCodeCount.get(item.code, 0) + 1;
    }

    Character basePlayer = *player;

    string[] slotOrder = [
        "rune_slot", "shield_slot", "helmet_slot",
        "body_armor_slot", "leg_armor_slot", "boots_slot", "ring1_slot",
        "ring2_slot", "amulet_slot", /*"artifact1_slot", "artifact2_slot",
        "artifact3_slot",*/ "bag_slot"
    ];

    EquipList[] bestEquip;

    foreach (slot; slotOrder) {
        const(ItemSchema)*[] candidates;
        candidates ~= null;

        // Get slot base name without "_slot" suffix
        string slotBase = slot.replace("_slot", "");
        
        foreach (ref const item; items) {
            // Check if item can be equipped in this slot
            if (item.type.length > slotBase.length) continue;
            
            // Match base type and optional digits
            if (slotBase.startsWith(item.type)) {
                string remaining = slotBase[item.type.length..$];
                
                // Check if remaining characters are all digits or empty
                bool validRemaining = remaining.all!(c => c.isDigit);
                
                if (validRemaining && 
                    itemCodeCount.get(item.code, 0) > 0 && 
                    canEquip(basePlayer,item)) {
                    candidates ~= &item;
                }
            }
        }

        const(ItemSchema)* bestItem = null;
        double bestScore = -1.0;

        foreach (candidate; candidates) {
            if (candidate !is null) {
                ItemEffect ee = ItemEffect(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
                foreach (effect; candidate.effects) {
                    getEffect(ee,effect);
                }
                double currentScore = computeWisdomScore(ee);
                if(player.getEquippedItem(candidate.type) == candidate.name){
                    currentScore+=9;
                }
                if (currentScore > bestScore) {
                    bestScore = currentScore;
                    bestItem = candidate;
                }
            }
        }

        if (bestItem !is null) {
            bestEquip ~= EquipList(bestItem.code, slot);
            itemCodeCount[bestItem.code]--;
        }
        else{
            bestEquip ~= EquipList("", slot);
        }
    }
    return bestEquip;
}

bool canEquip(Character player, const(ItemSchema) item) {
    foreach (cond; item.conditions) {
        double statValue = player.skillLevel(cond.code);

        final switch (cond.op) {
            case ConditionOperator.eq:
                if (statValue != cond.value) return false;
                break;
            case ConditionOperator.ne:
                if (statValue == cond.value) return false;
                break;
            case ConditionOperator.lt:
                if (statValue >= cond.value) return false;
                break;
            case ConditionOperator.lte:
                if (statValue > cond.value) return false;
                break;
            case ConditionOperator.gt:
                if (statValue <= cond.value) return false;
                break;
            case ConditionOperator.gte:
                if (statValue < cond.value) return false;
                break;
        }
    }

    return true;
}

double computeScore(ref ItemEffect item, MonsterSchema monster)
{
    double score = 0;

    // Offensive contribution (Attack boosts)
    score += item.attack_fire * (1.0 - monster.res_fire / 100.0) * monster.hp;
    score += item.attack_water * (1.0 - monster.res_water / 100.0) * monster.hp;
    score += item.attack_earth * (1.0 - monster.res_earth / 100.0) * monster.hp;
    score += item.attack_air * (1.0 - monster.res_air / 100.0) * monster.hp;

    // Damage boosts (apply globally to monster HP, reduced by their resistances)
    score += item.dmg_fire * (1.0 - monster.res_fire / 100.0) * monster.hp;
    score += item.dmg_water * (1.0 - monster.res_water / 100.0) * monster.hp;
    score += item.dmg_earth * (1.0 - monster.res_earth / 100.0) * monster.hp;
    score += item.dmg_air * (1.0 - monster.res_air / 100.0) * monster.hp;

    // Critical strike chance (weigh this higher for squishy monsters with low HP)
    score += item.critical_strike * (monster.hp < 500 ? 2.0 : 1.0);

    //score += item.haste * 1.5;//probs not needed, speeds up cooldown after fight iirc

    //score += item.wisdom * 1.0;//wisdom useless in the grand scheme me thinks

    score += item.max_hp * 0.2;
    score += item.hp * 0.1;

    // Resistance bonus (survivability against monster's attack types)
    score += item.res_fire * (monster.attack_fire > 0 ? 1.0 : 0.0);
    score += item.res_water * (monster.attack_water > 0 ? 1.0 : 0.0);
    score += item.res_earth * (monster.attack_earth > 0 ? 1.0 : 0.0);
    score += item.res_air * (monster.attack_air > 0 ? 1.0 : 0.0);

    return score;
}

double computeWisdomScore(ref ItemEffect item)
{
    double score = item.wisdom;
    score += item.haste * 0.1;
    return score;
}

void getEffect(ref ItemEffect delta, const ref SimpleEffectSchema effect) {
    if (effect.code == "attack_fire") {
        delta.attack_fire = effect.value;
    } else if (effect.code == "attack_water") {
        delta.attack_water = effect.value;
    } else if (effect.code == "attack_earth") {
        delta.attack_earth = effect.value;
    } else if (effect.code == "attack_air") {
        delta.attack_air = effect.value;
    } else if (effect.code == "critical_strike") {
        delta.critical_strike = effect.value;
    } else if (effect.code == "haste") {
        delta.haste = effect.value;
    } else if (effect.code == "wisdom") {
        delta.wisdom = effect.value;
    } else if (effect.code == "dmg_fire") {
        delta.dmg_fire = effect.value;
    } else if (effect.code == "dmg_water") {
        delta.dmg_water = effect.value;
    } else if (effect.code == "dmg_earth") {
        delta.dmg_earth = effect.value;
    } else if (effect.code == "dmg_air") {
        delta.dmg_air = effect.value;
    } else if (effect.code == "dmg") {
        delta.dmg_fire = effect.value;
        delta.dmg_water = effect.value;
        delta.dmg_earth = effect.value;
        delta.dmg_air = effect.value;
    } else if (effect.code == "hp") {
        delta.max_hp = cast(int)effect.value;
        delta.hp = delta.max_hp;
    } else if (effect.code == "boost_hp") {
        delta.max_hp = cast(int)effect.value;
        delta.hp = delta.max_hp;
    } else if (effect.code == "res_fire") {
        delta.res_fire = effect.value;
    } else if (effect.code == "res_water") {
        delta.res_water = effect.value;
    } else if (effect.code == "res_earth") {
        delta.res_earth = effect.value;
    } else if (effect.code == "res_air") {
        delta.res_air = effect.value;
    } else if (effect.code == "res") {
        delta.res_fire = effect.value;
        delta.res_water = effect.value;
        delta.res_earth = effect.value;
        delta.res_air = effect.value;
    }
}










struct Tool {
    string name;
    int levelRequired;
    string slot;
    string skill;
}

Tool[] allTools = [
    Tool("copper_axe", 1, "weapon", "woodcutting"),
    Tool("apprentice_gloves", 1, "weapon", "alchemy"),
    Tool("copper_pickaxe", 1, "weapon", "mining"),
    Tool("fishing_net", 1, "weapon", "fishing"),
    Tool("iron_pickaxe", 10, "weapon", "mining"),
    Tool("iron_axe", 10, "weapon", "woodcutting"),
    Tool("spruce_fishing_rod", 10, "weapon", "fishing"),
    Tool("leather_gloves", 10, "weapon", "alchemy"),
    Tool("steel_fishing_rod", 20, "weapon", "fishing"),
    Tool("steel_pickaxe", 20, "weapon", "mining"),
    Tool("steel_gloves", 20, "weapon", "alchemy"),
    Tool("steel_axe", 20, "weapon", "woodcutting"),
    Tool("gold_fishing_rod", 30, "weapon", "fishing"),
    Tool("gold_axe", 30, "weapon", "woodcutting"),
    Tool("gold_pickaxe", 30, "weapon", "mining"),
    Tool("golden_gloves", 30, "weapon", "alchemy"),
    Tool("frozen_pickaxe", 40, "weapon", "mining"),
    Tool("frozen_gloves", 40, "weapon", "alchemy"),
    Tool("frozen_fishing_rod", 40, "weapon", "fishing"),
    Tool("frozen_axe", 40, "weapon", "woodcutting")
];

bool equipBestForSkill(Character* c, string skill) {
    auto matchingTools = allTools
        .filter!(tool => tool.skill == skill) // Skill match
        .filter!(tool => tool.levelRequired <= c.skillLevel(skill)) // Level check
        .array;

    // Sort by highest level first
    matchingTools.sort!((a, b) => a.levelRequired > b.levelRequired);

    foreach (tool; matchingTools) {
        string currentlyEquipped = c.getEquippedItem(tool.slot);
        if (currentlyEquipped == tool.name) {
            // Already equipped, no need to equip again
            return true;
        }
        if (c.countItem(tool.name) > 0 || bank.count(tool.name) > 0) {
            c.smartEquip(tool.name,tool.slot);
            return false;
        }
    }

    return true; // No usable, owned tool found
}
