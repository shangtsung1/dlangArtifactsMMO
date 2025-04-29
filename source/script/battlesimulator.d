module script.battlesimulator;

import std.stdio;
import std.string;
import std.conv;
import std.random;
import std.math;

import global;
import api.ammo;
import api.schema;
import script.helper;
import script.bettergear;

bool simulateBattle(Character* character, MonsterSchema monster) {
    Random random = Random();
    int charHp = character.hp;
    int monsterHp = monster.hp;
    int turn = 0;

    while (charHp > 0 && monsterHp > 0 && turn < 100) {
        turn++;

        // Character's Turn
        if (monsterHp > 0) {
            int baseAttack = 1;
            int damageBuff = character.dmg_fire;
            int attackDamage = baseAttack + cast(int)std.math.round(baseAttack * (damageBuff * 0.01));
            if (uniform(0, 100, random) < character.critical_strike) { // Fixed uniform call
                attackDamage = cast(int)std.math.round(attackDamage * 1.5);
            }
            int resistance = monster.res_fire;
            int blockedDamage = cast(int)std.math.round(attackDamage * (resistance * 0.01));
            int finalDamage = attackDamage - blockedDamage;
            monsterHp -= finalDamage;
            if (monsterHp < 0) monsterHp = 0;
        }

        // Monster's Turn
        if (monsterHp > 0 && charHp > 0) {
            int baseAttack = 1;
            int resistance = character.res_fire;
            int blockedDamage = cast(int)std.math.round(baseAttack * (resistance * 0.01));
            int finalDamage = baseAttack - blockedDamage;
            charHp -= finalDamage;
            if (charHp < 0) charHp = 0;

            // Apply Monster Effects
            foreach (effect; monster.effects) {
                if (effect.code == "Burn" && turn == 1) {
                    charHp -= cast(int)std.math.round(baseAttack * (effect.value * 0.01));
                } else if (effect.code == "Healing" && turn % 3 == 0) {
                    monsterHp += cast(int)std.math.round(monster.hp * (effect.value * 0.01));
                    if (monsterHp > monster.hp) monsterHp = monster.hp;
                } else if (effect.code == "Poison" && turn == 1) {
                    charHp -= effect.value;
                } else if (effect.code == "Lifesteal" && uniform(0, 100, random) < monster.critical_strike) { // Fixed uniform
                    int lifestealAmount = cast(int)std.math.round(baseAttack * (effect.value * 0.01));
                    monsterHp += lifestealAmount;
                    if (monsterHp > monster.hp) monsterHp = monster.hp;
                } else if (effect.code == "Reconstitution" && turn == effect.value) {
                    monsterHp = monster.hp;
                }
            }
        }
    }

    return charHp > 0;
}

float simulateBattles(Character* character, MonsterSchema monster, int numSimulations = 100) {
    int victories = 0;
    for (int i = 0; i < numSimulations; ++i) {
        if (simulateBattle(character, monster)) {
            victories++;
        }
    }
    return cast(float)victories / numSimulations * 100;
}