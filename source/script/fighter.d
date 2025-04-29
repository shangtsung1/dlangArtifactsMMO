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
	if(equipmentCheck(c,true)){
		return;
	}
	Location thingToFight = LOC_YELLOWSLIME;
    if(c.hp < c.max_hp){
		if(foodCheck(c)){
			writeln(c.color,"We Ate");
			return;
		}
		else{
			c.rest();
			writeln(c.color,"Resting");
			return;
		}
	}
	else{
		if(fightCheck(c,"chicken", ["feather"], [25])){
			thingToFight = LOC_CHICKEN;
		}
		else if(fightCheck(c,"yellow_slime", ["yellow_slimeball"], [25])){
			thingToFight = LOC_YELLOWSLIME;
		}
		else if(fightCheck(c,"green_slime", ["green_slimeball"], [25])){
			thingToFight = LOC_GREENSLIME;
		}
		else if(fightCheck(c,"blue_slime", ["blue_slimeball"], [25])){
			thingToFight = LOC_BLUESLIME;
		}
		else if(fightCheck(c,"red_slime", ["red_slimeball"], [25])){
			thingToFight = LOC_REDSLIME;
		}
		else if(fightCheck(c,"cow", ["cowhide"], [25])){
			thingToFight = LOC_COW;
		}
		else if(fightCheck(c,"mushmush", ["mushroom"], [25])){
			thingToFight = LOC_MUSHMUSH;
		}
		else if(fightCheck(c,"flying_serpent", ["flying_wing", "serpent_skin"], [25,25])){
			thingToFight = LOC_FLYINGSERPENT;
		}
		else if(fightCheck(c,"wolf", ["wolf_bone", "wolf_hair", "wolf_ears"], [25,25,1])){
			thingToFight = LOC_WOLF;
		}
		else if(fightCheck(c,"highwayman", ["highwayman_dagger", "green_cloth"], [25,25])){
			thingToFight = LOC_HIGHWAYMAN;
		}

		else if(fightCheck(c,"skeleton", ["skeleton_bone", "skeleton_skull"], [25,25])){
			thingToFight = LOC_SKELETON;
		}
		else if(fightCheck(c,"pig", ["pig_skin"], [25])){
			thingToFight = LOC_SKELETON;
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

bool fightCheck(Character* c,string monsterCode, string[] items, int[] amounts){
	if(getMonster(monsterCode).level > c.level-5){
		return false;
	}
	for(int i = 0; i < items.length; i++){
		if(bank.count(items[i]) < amounts[i]){
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