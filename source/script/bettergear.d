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

void applyEffect(ref Character player, const ref SimpleEffectSchema effect) {
    if (effect.code == "attack_fire") {
        player.attack_fire += effect.value;
    } else if (effect.code == "attack_water") {
        player.attack_water += effect.value;
    } else if (effect.code == "attack_earth") {
        player.attack_earth += effect.value;
    } else if (effect.code == "attack_air") {
        player.attack_air += effect.value;
    } else if (effect.code == "critical_strike") {
        player.critical_strike += effect.value;
    } else if (effect.code == "haste") {
        player.haste += effect.value;
    } else if (effect.code == "wisdom") {
       // player.wisdom += effect.value;//wisdom is useless ;)
    } else if (effect.code == "dmg_fire") {
        player.dmg_fire += effect.value;
    } else if (effect.code == "dmg_water") {
        player.dmg_water += effect.value;
    } else if (effect.code == "dmg_earth") {
        player.dmg_earth += effect.value;
    } else if (effect.code == "dmg_air") {
        player.dmg_air += effect.value;
    } else if (effect.code == "dmg") {
        player.dmg_fire += effect.value;
        player.dmg_water += effect.value;
        player.dmg_earth += effect.value;
        player.dmg_air += effect.value;
    } else if (effect.code == "hp") {
        player.max_hp += effect.value;
        player.hp = player.max_hp;
    } else if (effect.code == "boost_hp") {
        player.max_hp = cast(int)round(player.max_hp * (1.0 + effect.value / 100.0));
        player.hp = player.max_hp;
    } else if (effect.code == "res_fire") {
        player.res_fire += effect.value;
    } else if (effect.code == "res_water") {
        player.res_water += effect.value;
    } else if (effect.code == "res_earth") {
        player.res_earth += effect.value;
    } else if (effect.code == "res_air") {
        player.res_air += effect.value;
    } else if (effect.code == "res") {
        player.res_fire += effect.value;
        player.res_water += effect.value;
        player.res_earth += effect.value;
        player.res_air += effect.value;
    }
}
enum Element { fire, water, earth, air }

Element getWeakestElement(ref const MonsterSchema monster) {
    int[Element] res;
    res[Element.fire] = monster.res_fire;
    res[Element.water] = monster.res_water;
    res[Element.earth] = monster.res_earth;
    res[Element.air] = monster.res_air;

    Element weakest = Element.fire;
    int minRes = res[weakest];

    foreach (e; [Element.fire,Element.water,Element.earth,Element.air]) {
        if (res[e] < minRes) {
            weakest = e;
            minRes = res[e];
        }
    }
    return weakest;
}

double computeScore(ref const Character player, ref const MonsterSchema monster) {
    Element preferred = getWeakestElement(monster);

    int computeElementDamage(int attack, int dmg, int monsterRes) {
        int damageIncrease = dmg - monsterRes;
        double multiplier = 1.0 + damageIncrease / 100.0;
        return cast(int)round(attack * multiplier);
    }

    double computeMonsterElementDamage(int monsterAttack, int playerRes) {
        int damageReduction = cast(int)round(monsterAttack * (playerRes / 100.0));
        int damagePossible = max(monsterAttack - damageReduction, 0);
        double blockChance = (playerRes / 10.0) / 100.0;
        return damagePossible * (1.0 - blockChance);
    }

    int bestElementDamage;
    final switch (preferred) {
        case Element.fire:
            bestElementDamage = computeElementDamage(player.attack_fire, player.dmg_fire, monster.res_fire);
            break;
        case Element.water:
            bestElementDamage = computeElementDamage(player.attack_water, player.dmg_water, monster.res_water);
            break;
        case Element.earth:
            bestElementDamage = computeElementDamage(player.attack_earth, player.dmg_earth, monster.res_earth);
            break;
        case Element.air:
            bestElementDamage = computeElementDamage(player.attack_air, player.dmg_air, monster.res_air);
            break;
    }

    double critMultiplier = 1.0 + 0.5 * (player.critical_strike / 100.0);
    double avgDamage = bestElementDamage * critMultiplier;

    double monsterDamage = 0;
    monsterDamage += computeMonsterElementDamage(monster.attack_fire, player.res_fire);
    monsterDamage += computeMonsterElementDamage(monster.attack_water, player.res_water);
    monsterDamage += computeMonsterElementDamage(monster.attack_earth, player.res_earth);
    monsterDamage += computeMonsterElementDamage(monster.attack_air, player.res_air);

    // Calculate turns to kill each other
    double playerTurnsToKill = ceil(monster.hp / avgDamage);
    double monsterTurnsToKill = ceil(player.hp / monsterDamage);

    double survivalFactor = (playerTurnsToKill < monsterTurnsToKill) ? 1.5 : 0.8;

    if (monsterDamage <= 0) monsterDamage = 1e-9;
    double score = (avgDamage * player.hp * survivalFactor) / monsterDamage;
    return score;
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
        "weapon_slot", "rune_slot", "shield_slot", /*"helmet_slot",*/
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

        Character virtualPlayer = basePlayer; // always reset for each slot

        foreach (candidate; candidates) {
            Character tempPlayer = basePlayer;
            if (candidate !is null) {
                foreach (effect; candidate.effects) {
                    applyEffect(tempPlayer, effect);
                }
            }

            double currentScore = computeScore(tempPlayer, toBeat);
            if (currentScore > bestScore * 1.01) {
                bestScore = currentScore;
                bestItem = candidate;
            }
        }

        if (bestItem !is null) {
            bestEquip ~= EquipList(bestItem.code, slot);
            itemCodeCount[bestItem.code]--;

            foreach (effect; bestItem.effects) {
                applyEffect(virtualPlayer, effect);
            }
        }
    }

    return bestEquip;
}


