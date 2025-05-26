module script.fighter;

import std.stdio;
import std.math;

import global;
import api.ammo;
import api.schema;
import script.helper;
import script.bettergear;

void fighter(Character* c)
{
	if(countInventory(c) >= c.inventory_max_items - 12){
		bankAll(c);
		writeln(c.color,"Banking");
		return;
	}
	bool needAntidote = false;
	Location thingToFight = Location(0,0);
	string tCode = "chicken";
	auto monsterTask = getMonster(c.task);
    if(c.hp < c.max_hp){
		if(c.hp == 1 && c.x == 0 && c.y == 0){//we died
			bankAll(c);
			writeln(c.color,"Died");
			return;
		}
		if(foodCheck(c)){
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
	else if(monsterTask.name.length > 0 && monsterTask.level < c.level - 3 && (!canPoisen(getMonster(monsterTask.code)) || !needAntidote)){
 		thingToFight = findMonsterLocation(monsterTask.code);
		tCode = monsterTask.code;
	}
	else{
		if(fightCheck(c,"chicken", ["feather"], [25])){
			thingToFight = LOC_CHICKEN;
			tCode = "chicken";
		}
		else if(fightCheck(c,"yellow_slime", ["yellow_slimeball"], [25])){
			thingToFight = LOC_YELLOWSLIME;
			tCode = "yellow_slime";
		}
		else if(fightCheck(c,"green_slime", ["green_slimeball"], [25])){
			thingToFight = LOC_GREENSLIME;
			tCode = "green_slime";
		}
		else if(fightCheck(c,"blue_slime", ["blue_slimeball"], [25])){
			thingToFight = LOC_BLUESLIME;
			tCode = "blue_slime";
		}
		else if(fightCheck(c,"red_slime", ["red_slimeball"], [25])){
			thingToFight = LOC_REDSLIME;
			tCode = "red_slime";
		}
		else if(fightCheck(c,"cow", ["cowhide","milk_bucket"], [25,50])){
			thingToFight = LOC_COW;
			tCode = "cow";
		}
		else if(fightCheck(c,"mushmush", ["mushroom"], [25])){
			thingToFight = LOC_MUSHMUSH;
			tCode = "mushmush";
		}
		else if(fightCheck(c,"flying_serpent", ["flying_wing", "serpent_skin"], [10,10])){
			thingToFight = LOC_FLYINGSERPENT;
			tCode = "flying_serpent";
		}
		else if(fightCheck(c,"wolf", ["wolf_bone", "wolf_hair", "wolf_ears"], [10,10,1])){
			thingToFight = LOC_WOLF;
			tCode = "wolf";
		}
		else if(fightCheck(c,"highwayman", ["highwayman_dagger", "green_cloth"], [2,10])){
			thingToFight = LOC_HIGHWAYMAN;
			tCode = "highwayman";
		}
		else if(fightCheck(c,"skeleton", ["skeleton_bone", "skeleton_skull"], [10,10])){
			thingToFight = LOC_SKELETON;
			tCode = "skeleton";
		}
		else if(fightCheck(c,"pig", ["pig_skin"], [25])){
			thingToFight = LOC_PIG;
			tCode = "pig";
		}
		else if(!needAntidote && fightCheck(c,"spider", ["spider_leg"], [25])){
			thingToFight = LOC_SPIDER;
			tCode = "spider";
		}
		else if(fightCheck(c,"ogre", ["ogre_eye","ogre_skin"], [10,10])){
			thingToFight = LOC_OGRE;
			tCode = "ogre";
		}

		else if(fightCheck(c,"vampire", ["vampire_blood","vampire_tooth"], [10,10])){
			thingToFight = LOC_VAMPIRE;
			tCode = "vampire";
		}
		else if(!getActiveEvent("bandit_camp").isNull() && fightCheck(c,"bandit_lizard", ["lizard_eye","lizard_skin","bandit_armor","dreadful_book"], [10,10,1,1])){
			auto ee = getActiveEvent("bandit_camp").get();
			thingToFight = Location(ee.map.x,ee.map.y);
			tCode = "bandit_lizard";
		}
		else if(fightCheck(c,"cyclops", ["cyclops_eye"], [10])){
			thingToFight = LOC_CYCLOPS;
			tCode = "cyclops";
		}
		else if(fightCheck(c,"death_knight", ["red_cloth","death_knight_sword"], [10,2])){
			thingToFight = LOC_DKNIGHT;
			tCode = "death_knight";
		}
		else if(fightCheck(c,"imp", ["demoniac_dust","piece_of_obsidian"], [10,10])){
			thingToFight = LOC_IMP;
			tCode = "imp";
		}


		else{
			int charLevel = c.level;
			tCode = "chicken";
			//find the highest level monster we can fight
			//and set it to the thingToFight
			foreach(monster;monsters){
				if(monster.level <= charLevel-5 && monster.level > getMonster(tCode).level && !canPoisen(getMonster(tCode))){
					if(monster.code == "bandit_lizard")continue;
					thingToFight = findMonsterLocation(monster.code);
					tCode = monster.code;
				}
			}
		}
	}

	if(potionCheck(c,needAntidote,getMonster(tCode))){
		return;
	}

	EquipList[] el = findBestEquipmentToFight(c, getMonster(tCode));

	foreach(e;el){
		if(checkEquip(c,e.itemCode,e.slotName)){
			writeln(c.color,"Equipping ",e.itemCode," to ",e.slotName);
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
	if(c.countItem("small_health_potion") < 10 && c.utility1_slot != "small_health_potion"){
		if(countInventory(c) >= c.inventory_max_items-51){
			bankAll(c);
			writeln(c.color,"Banking");
			return true;
		}
		//grab potion from bank
		int mR = smartMove(c, "bank","bank");
		if(mR == 200){
			c.withdrawItem("small_health_potion",50);	
		}
		return true;
	}
	else if(c.utility1_slot != "small_health_potion"){
		smartEquip(c, "small_health_potion", "utility1", 10);
		return true;
	}
	else if(c.countItem("small_antidote") < 10 && c.utility2_slot != "small_antidote"){
		if(bank.count("small_antidote") == 0){
			needAntidote = true;
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
		}
		return true;
	}
	else if(c.utility2_slot != "small_antidote"){
		smartEquip(c, "small_antidote", "utility2", 10);
		return true;
	}

	return false;
}

bool checkEquip(Character* c, string itemCode, string slotName){
	//writeln(c.color,"Check ",c.getSlot(slotName)," ",slotName);
	if(c.getSlot(slotName) == itemCode){
		return false;
	}
	smartEquip(c,itemCode,slotName);
	return true;
}

bool fightCheck(Character* c,string monsterCode, string[] items, int[] amounts){
	if(getMonster(monsterCode).level > c.level-2){
		writeln(c.color,"Cant fight by level ",monsterCode);
		return false;
	}
	for(int i = 0; i < items.length; i++){
		if(bank.count(items[i]) < amounts[i]){
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