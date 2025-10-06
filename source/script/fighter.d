module script.fighter;

import std.stdio;

import std.math;

import global;
import api.ammo;
import api.schema;
import script.helper;
import script.bettergear;

EquipList[][string] equipLists;

void fighter(Character* c)
{
	if(countInventory(c) >= c.inventory_max_items/2){
		bankAll(c);
		writeln(c.color,"Banking");
		return;
	}
	bool needAntidote = false;
	Location thingToFight = Location(0,0);
	string tCode = "chicken";
	auto monsterTask = getMonster(c.task);
	int charLevel = c.level;
    if(c.hp < c.max_hp){
		if(c.hp == 1 && c.x == 0 && c.y == 0){//we died
			bankAll(c);
			writeln(c.color,"Died");
			return;
		}
		if(c.max_hp - c.hp < 50){
			c.rest();
			return;
		}
		else if(foodCheck(c)){
			writeln(c.color,"We Ate");
			return;
		}
		else{
			c.rest();
			writeln(c.color,"Resting");
			return;
		}
		return;
	}
	else if(getActiveEvent("bandit_camp") is null && monsterTask.name.length > 0 && monsterTask.level < c.level - 7 && (!canPoisen(getMonster(monsterTask.code)) || !needAntidote)){
 		thingToFight = findMonsterLocation(monsterTask.code);
		tCode = monsterTask.code;
	}
	else{
		if(fightCheck(c,"chicken", ["feather"], [25]) || charLevel < 4){
			tCode = "chicken";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 5 && fightCheck(c,"yellow_slime", ["yellow_slimeball"], [5])){
			tCode = "yellow_slime";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 6 && fightCheck(c,"green_slime", ["green_slimeball"], [5])){
			tCode = "green_slime";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 8 && fightCheck(c,"blue_slime", ["blue_slimeball"], [5])){
			tCode = "blue_slime";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 10 && fightCheck(c,"red_slime", ["red_slimeball"], [5])){
			tCode = "red_slime";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 10 && fightCheck(c,"sheep", ["wool"], [25])){
			tCode = "sheep";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 5 && fightCheck(c,"yellow_slime", ["yellow_slimeball"], [15])){
			tCode = "yellow_slime";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 6 && fightCheck(c,"green_slime", ["green_slimeball"], [15])){
			tCode = "green_slime";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 8 && fightCheck(c,"blue_slime", ["blue_slimeball"], [15])){
			tCode = "blue_slime";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 10 && fightCheck(c,"red_slime", ["red_slimeball"], [15])){
			tCode = "red_slime";
			thingToFight = findMonsterLocation(tCode);
		}


		else if(charLevel >= 16 && fightCheck(c,"cow", ["cowhide","milk_bucket"], [25,50])){
			tCode = "cow";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 17 && fightCheck(c,"mushmush", ["mushroom"], [25])){
			tCode = "mushmush";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 18 && fightCheck(c,"flying_snake", ["flying_wing", "snake_hide"], [10,10])){
			tCode = "flying_snake";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 20 && fightCheck(c,"wolf", ["wolf_bone", "wolf_hair", "wolf_ears"], [10,10,1])){
			tCode = "wolf";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 21 && fightCheck(c,"highwayman", ["highwayman_dagger", "green_cloth"], [2,10])){
			tCode = "highwayman";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 22 && fightCheck(c,"skeleton", ["skeleton_bone", "skeleton_skull"], [10,10])){
			tCode = "skeleton";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 24 && fightCheck(c,"pig", ["pig_skin"], [25])){
			tCode = "pig";
			thingToFight = findMonsterLocation(tCode);;
		}
		else if(charLevel >= 26 && !needAntidote && fightCheck(c,"spider", ["spider_leg"], [25])){
			tCode = "spider";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 26 && fightCheck(c,"ogre", ["ogre_eye","ogre_skin"], [10,10])){
			tCode = "ogre";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 28 && fightCheck(c,"vampire", ["vampire_blood","vampire_tooth"], [10,10])){
			tCode = "vampire";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 28 && !needAntidote && getActiveEvent("bandit_camp") !is null && fightCheck(c,"bandit_lizard", ["lizard_eye","lizard_skin","bandit_armor","dreadful_book"], [10,10,1,1])){
			auto ee = getActiveEvent("bandit_camp");
			thingToFight = Location(ee.map.x,ee.map.y);
			tCode = "bandit_lizard";
		}
		else if(charLevel >= 30 && fightCheck(c,"cyclops", ["cyclops_eye"], [10])){
			tCode = "cyclops";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 31 && fightCheck(c,"imp", ["demoniac_dust","piece_of_obsidian"], [10,10])){
			tCode = "imp";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 31 && fightCheck(c,"death_knight", ["red_cloth","death_knight_sword"], [10,2])){
			tCode = "death_knight";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 32 && fightCheck(c,"owlbear", ["owlbear_hair","owlbear_claw"], [10,10])){
			tCode = "owlbear";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 33 && getActiveEvent("portal_demon") !is null && fightCheck(c,"demon", ["demon_horn"], [10])){
			auto ee = getActiveEvent("portal_demon");
			thingToFight = Location(ee.map.x,ee.map.y);
			tCode = "demon";
		}
		else if(charLevel >= 34 && fightCheck(c,"cultist_acolyte", ["magic_stone","cursed_book"], [10,5])){
			tCode = "cultist_acolyte";
			thingToFight = findMonsterLocation(tCode);
		}
		else if(charLevel >= 36 && fightCheck(c,"cultist_emperor", ["malefic_cloth","malefic_shard"], [10,5])){
			thingToFight = findMonsterLocation("cultist_emperor");
			tCode = "cultist_emperor";
		}
		else if(charLevel >= 36 && fightCheck(c,"goblin", ["goblin_tooth","goblin_eye"], [10,10])){
			thingToFight = findMonsterLocation("goblin");
			tCode = "goblin";
		}

		else if(charLevel >= 39 && fightCheck(c,"orc", ["orc_skin"], [10])){
			thingToFight = findMonsterLocation("orc");
			tCode = "orc";
		}

		else if(charLevel >= 41 && fightCheck(c,"hellhound", ["hellhound_hair","hellhound_bone"], [10,5])){
			tCode = "hellhound";
			thingToFight = findMonsterLocation(tCode);
		}


		else{
			tCode = "chicken";
			//find the highest level monster we can fight
			//and set it to the thingToFight
			foreach(monster;monsters){
				if(monster.level <= charLevel-7 && monster.level > getMonster(tCode).level && !canPoisen(getMonster(tCode))){
					if(monster.code == "bandit_lizard" && getActiveEvent("bandit_camp") is null)continue;
					if(monster.code == "demon" && getActiveEvent("demon_portal") is null)continue;
					if(monster.code == "demon"){
						auto ee = getActiveEvent("demon_portal");
						thingToFight = Location(ee.map.x,ee.map.y);
					}
					else if(monster.code == "bandit_lizard"){
						auto ee = getActiveEvent("bandit_camp");
						thingToFight = Location(ee.map.x,ee.map.y);
					}
					else{
						thingToFight = findMonsterLocation(monster.code);
					}
					tCode = monster.code;
				}
			}
		}
	}

	auto el = equipLists.get(c.name, []);

	if(c.getString("lastTask") != tCode){
		el = findBestEquipmentToFight(c, getMonster(tCode));
		equipLists[c.name] = el; // Store back to global AA
		writeln(c.color,"Task Change");
		c.setString("lastTask",tCode);
		bankAll(c);
		return;
	}

	if(potionCheck(c,needAntidote,getMonster(tCode))){
		writeln(c.color,"Potion Needed.");
		return;
	}

	foreach(e; el){
		if(e.itemCode == "") continue;
		writeln(c.color, "Equipping ", e.itemCode, " to ", e.slotName);
		if(checkEquip(c, e.itemCode, e.slotName)){
			writeln(c.color, "Equipping ", e.itemCode, " to ", e.slotName);
			return;
		}
	}

	if(c.x != thingToFight.x || c.y != thingToFight.y){
		writeln(c.color,"Move");
		int result = c.move(thingToFight.x,thingToFight.y);
		writeln(c.color,"moveResult = ",result);
		return;
	}
	else{
		writeln(c.color,"fightResult = ",c.fight());
		return;
	}
}

bool potionCheck(Character* c, ref bool needAntidote,MonsterSchema ms){
	if(c.level < 20 && c.level >= 5){
		if(ms.level < 5){
			return false;
		}
		string pot = "small_health_potion";
		if(c.utility1_slot != pot){
			if(bank.count(pot) > 10 || c.countItem(pot) >= 10){
				smartEquip(c, pot, "utility1", 10);
				return true;
			}
		}
	}
	else if(c.level < 30 && c.level >= 20){
		if(ms.level < 10){
			return false;
		}
		string pot = "minor_health_potion";
		if(c.utility1_slot != pot){
			if(bank.count(pot) > 10 || c.countItem(pot) >= 10){
				smartEquip(c, pot, "utility1", 10);
				return true;
			}
			return true;
		}
	}
	else if(c.level < 40 && c.level >= 30){
		if(ms.level < 20){
			return false;
		}
		string pot = "health_potion";
		if(c.utility1_slot != pot){
			if(bank.count(pot) > 10 || c.countItem(pot) >= 10){
				smartEquip(c, pot, "utility1", 10);
				return true;
			}
			return true;
		}
	}
	return determineSecondPotion(c,needAntidote,ms);
}

bool determineSecondPotion(Character* c, ref bool needAntidote,MonsterSchema ms){
	if(canPoisen(ms)&& c.level >= 15){
		if(c.countItem("small_antidote") < 10 && c.utility2_slot != "small_antidote" && c.level >= 15){
			if(bank.count("small_antidote") == 0){
				needAntidote = true;
				writeln(c.color,"need antidote");
				return false;
			}
			if(countInventory(c) >= c.inventory_max_items-10){
				bankAll(c);
				writeln(c.color,"Banking");
				return true;
			}
			//grab potion from bank
			int mR = smartMove(c, "bank","bank");
			if(mR == 200){
				c.withdrawItem("small_antidote",10);
				writeln(c.color,"withdraw antidote");	
			}
			return true;
		}
		else if(c.countItem("small_antidote") >= 10 && c.utility2_slot != "small_antidote"){
			smartEquip(c, "small_antidote", "utility2", 10);
			writeln(c.color,"equip antidote");
			return true;
		}
		return false;
	}
	else {
		if (c.weapon_slot == "") {
			return false;
		}

		double attack_fire = 0;
		double attack_water = 0;
		double attack_earth = 0;
		double attack_air = 0;
		ItemSchema wep = getItem(c.weapon_slot);
		foreach (effect; wep.effects) {
			if (effect.code == "attack_fire") {
				attack_fire = effect.value;
			} else if (effect.code == "attack_water") {
				attack_water = effect.value;
			} else if (effect.code == "attack_earth") {
				attack_earth = effect.value;
			} else if (effect.code == "attack_air") {
				attack_air = effect.value;
			}
		}
		string bestPotion;
		double maxAttack = 0;
		if (attack_fire > maxAttack) {
			maxAttack = attack_fire;
			bestPotion = "fire_boost_potion";
		}
		if (attack_water > maxAttack) {
			maxAttack = attack_water;
			bestPotion = "water_boost_potion";
		}
		if (attack_earth > maxAttack) {
			maxAttack = attack_earth;
			bestPotion = "earth_boost_potion";
		}
		if (attack_air > maxAttack) {
			maxAttack = attack_air;
			bestPotion = "air_boost_potion";
		}
		if (bestPotion != "" && c.utility2_slot != bestPotion && c.level >= 10) {
			if (c.countItem(bestPotion) >= 10) {
				smartEquip(c, bestPotion, "utility2", 10);
				writeln(c.color, "equip "~bestPotion);
				return true;
			} else if (bank.count(bestPotion) > 0) {
				if (countInventory(c) >= c.inventory_max_items - 10) {
					bankAll(c);
					writeln(c.color, "Banking for "~bestPotion);
					return true;
				}
				int mR = smartMove(c, "bank", "bank");
				if (mR == 200) {
					c.withdrawItem(bestPotion, 10);
					writeln(c.color, "withdraw "~bestPotion);
				}
				return true;
			}
		}
	}
	return false;
}


bool fightCheck(Character* c,string monsterCode, string[] items, int[] amounts){
	if(getMonster(monsterCode).level > c.level-2){
		writeln(c.color,"Cant fight by level ",monsterCode);
		return false;
	}
	for(int i = 0; i < items.length; i++){
		if(bank.count(items[i])+c.countItem(items[i]) < amounts[i]){
			writeln(c.color,"Not enough ",items[i]," to fight ",monsterCode, " Have ",bank.count(items[i]), " want ", amounts[i]);
			return true;
		}
	}
	return false;
}

bool foodCheck(Character* c){
	ItemSchema[] foodItems;
	foreach(item; itemList){
		if(item.type == "consumable" && item.subtype == "food"){
			foodItems ~= item;
		}
	}
	ItemSchema bestItemWeHave = getItem("cooked_gudgeon");
	//see if any are in our inventory
	foreach(item; foodItems){
		if(item.level <= c.level && item.level > bestItemWeHave.level && getFoodHealing(item) > getFoodHealing(bestItemWeHave)){
			if(c.countItem(item.code) > 0){
				bestItemWeHave = item;
			}
		}
	}
	if(c.countItem(bestItemWeHave.code) > 0){
		writeln(c.color,"Eating ",bestItemWeHave.code);
		c.useItem(bestItemWeHave.code,1);
		return true;
	}
	foreach(item; foodItems){
		if(item.level <= c.level && item.level > bestItemWeHave.level && getFoodHealing(item) > getFoodHealing(bestItemWeHave)){
			if(bank.count(item.code) > 0){
				bestItemWeHave = item;
			}
		}
	}
	if(bank.count(bestItemWeHave.code) > 0){
		smartEat(c, bestItemWeHave.code);
		return true;
	}
	return false;
}

int getFoodHealing(ItemSchema item){
	foreach(effect;item.effects){
		if(effect.code == "heal"){
			return effect.value;
		}
	}
	return 0;
}