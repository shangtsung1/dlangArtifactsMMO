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


bool betterWeapon(Character* m, string currentWeapon) {
    int levelCur = currentWeapon == "" || currentWeapon == ("wooden_stick") ? -1 : getItem(currentWeapon).level;
    int attCur = currentWeapon == ("") ? 1 : getAttack(getItem(currentWeapon),m);
    Nullable!ItemSchema bestItem;
    foreach (bi; bank.items) {
        ItemSchema b = getItem(bi.code);
        if (b.level >= levelCur && getAttack(b,m) > attCur) {
            if (bestItem.isNull) {
                bestItem = b.nullable;
            } else if (b.level >= bestItem.get().level && getAttack(b,m) > getAttack(bestItem.get(),m)&& b.level <= m.level) {
                bestItem = b.nullable;
            }
        }
    }
    foreach(bi; m.inventory) {
        ItemSchema b = getItem(bi.code);
        if (b.level >= levelCur && getAttack(b,m) > attCur) {
            if (bestItem.isNull) {
                bestItem = b;
            } else if (b.level >= bestItem.get().level && getAttack(b,m) > getAttack(bestItem.get(),m)&& b.level <= m.level) {
                bestItem = b;
            }
        }
    }
    if (!bestItem.isNull && bestItem.get().code != currentWeapon && bestItem.get().level <= m.level) {
        smartEquip(m, bestItem.get().code, "weapon");
        return true;
    }
    return false;
}

int getAttack(ItemSchema i, Character* m) {
    int attack = 0;
    
    foreach (effect; i.effects) {
        switch (effect.code) {
            // Direct attack stats
            case "attack_fire":
            case "attack_water":
            case "attack_air":
            case "attack_earth":
                attack += effect.value;
                break;
            
            // Damage multipliers (treated as direct additive scores)
            case "dmg":
            case "dmg_fire":
            case "dmg_water":
            case "dmg_air":
            case "dmg_earth":
                attack += effect.value;
                break;
            
            // Critical strike chance
            case "critical_strike":
                attack += effect.value; // 1% crit = 1 point
                break;
            
            // Haste
            case "haste":
                attack += effect.value / 2; // value half-weight
                break;
            case "res_fire":
            case "res_water":
            case "res_air":
            case "res_earth":
                attack  += effect.value;
                break;
            
            // Direct HP
            case "hp":
                attack  += effect.value * 2; //HP is double-weighted
                break;
            
            // Combat buffs
            case "boost_hp":
                attack  += effect.value;
                break;
            default:
                break;
        }
    }
    
    return attack;
}

int getDefence(ItemSchema i, Character* m) {
    int defense = 0;
    
    foreach (effect; i.effects) {
        switch (effect.code) {
            case "attack_fire":
            case "attack_water":
            case "attack_air":
            case "attack_earth":
                defense += effect.value;
                break;
            
            // Damage multipliers (treated as direct additive scores)
            case "dmg":
            case "dmg_fire":
            case "dmg_water":
            case "dmg_air":
            case "dmg_earth":
                defense += effect.value;
                break;
            
            // Critical strike chance
            case "critical_strike":
                defense += effect.value; // 1% crit = 1 point
                break;
            
            // Haste
            case "haste":
                defense += effect.value / 2; // value half-weight
                break;
            // Resistances
            case "res_fire":
            case "res_water":
            case "res_air":
            case "res_earth":
                defense += effect.value;
                break;
            
            // Direct HP
            case "hp":
                defense += effect.value * 2; //HP is double-weighted
                break;
            
            // Combat buffs
            case "boost_hp":
                defense += effect.value;
                break;
            
            default:
                break;
        }
    }
    
    return defense;
}

bool betterArmor(Character* m, string currentEquipped,string slot) {
    int levelCur = currentEquipped == "" ? -1 : getItem(currentEquipped).level;
    int defCur = currentEquipped == "" ? -1 : getDefence(getItem(currentEquipped),m);
    Nullable!ItemSchema bestItem;
    string type;
    if(startsWith(slot,"ring")){
        type = "ring";
    }
    else if(startsWith(slot,"artifact")){
        type = "artifact";
    }
    else if(startsWith(slot,"consumable")){
        type = "consumable";
    }else{
        type = slot;
    }
    foreach (bi; bank.items) {
        ItemSchema b = getItem(bi.code);
        if (b.type == (type)) {
            if (b.level >= levelCur && getDefence(b,m) > defCur && b.level <= m.level) {
                if (bestItem.isNull) {
                    bestItem = b.nullable;
                } else if (b.level >= bestItem.get().level && getAttack(b,m) > getDefence(bestItem.get(),m)) {
                    bestItem = b.nullable;
                }
            }
        }
    }
    foreach(bi; m.inventory) {
        ItemSchema b = getItem(bi.code);
        if (b.type == (type)) {
            if (b.level >= levelCur && getDefence(b,m) > defCur) {
                if (bestItem.isNull) {
                    bestItem = b.nullable;
                } else if (b.level >= bestItem.get().level && getDefence(b,m) > getDefence(bestItem.get(),m) && b.level <= m.level) {
                    bestItem = b.nullable;
                }
            }
        }
    }
    if (!bestItem.isNull && bestItem.get().code !=(currentEquipped) && bestItem.get().level <= m.level) {
        smartEquip(m, bestItem.get().code, slot);
        return true;
    }
    return false;
}

bool equipmentCheck(Character* m) {
    if(betterWeapon( m,m.weapon_slot)){
        return true;
    }
    else if(betterArmor( m, m.shield_slot,"shield") ){
        return true;
    }
    else if(betterArmor( m, m.ring1_slot,"ring1") ){
        return true;
    }
    else if(betterArmor( m, m.ring2_slot,"ring2") ){
        return true;
    }
    else if(betterArmor( m, m.boots_slot,"boots") ){
        return true;
    }
    else if(betterArmor( m, m.helmet_slot,"helmet") ){
        return true;
    }
    else if(betterArmor( m, m.leg_armor_slot,"leg_armor") ){
        return true;
    }
    else if(betterArmor( m, m.body_armor_slot,"body_armor") ){
        return true;
    }
    else if(betterArmor( m, m.amulet_slot,"amulet") ){
        return true;
    }
    return false;
}
