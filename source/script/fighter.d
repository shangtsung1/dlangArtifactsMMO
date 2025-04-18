module script.fighter;

import std.stdio;

import global;
import api.ammo;
import api.schema;
import script.helper;
import script.bettergear;

void fighter(Character* c)
{
	if(equipmentCheck(c)){
		return;
	}
	if(countInventory(c) >= c.inventory_max_items){
		bankAll(c);
		return;
	}
	Location thingToFight = LOC_YELLOWSLIME;
    if(c.hp < c.max_hp){
		c.rest();
		return;
	}
	else{
		if(bank.count("feather") < 25 /*|| bank.count("raw_chicken") < 25 || bank.count("egg") < 25*/){
			thingToFight = LOC_CHICKEN;
		}
		else if(bank.count("yellow_slimeball") < 25 /*|| bank.count("apple") < 20*/){
			thingToFight = LOC_YELLOWSLIME;
		}
		else if(bank.count("green_slimeball") < 25 /*|| bank.count("apple") < 20*/){
			thingToFight = LOC_GREENSLIME;
		}
		else if(bank.count("blue_slimeball") < 25 /*|| bank.count("apple") < 20*/){
			thingToFight = LOC_BLUESLIME;
		}
		else if(bank.count("red_slimeball") < 25 /*|| bank.count("apple") < 20*/){
			thingToFight = LOC_REDSLIME;
		}
		else if(bank.count("cowhide") < 25 /*|| bank.count("milk_bucket") < 20 || bank.count("raw_beef") < 25*/){
			thingToFight = LOC_COW;
		}
		else if(bank.count("mushroom") < 25){
			thingToFight = LOC_MUSHMUSH;
		}
		else if(bank.count("flying_wing") < 25 || bank.count("serpent_skin") < 25){
			thingToFight = LOC_FLYINGSERPENT;
		}
		else if(/*bank.count("raw_wolf_meat") < 25 ||*/ bank.count("wolf_bone") < 25||
		 		bank.count("wolf_hair") < 25|| bank.count("wolf_ears") < 1){
			thingToFight = LOC_WOLF;
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