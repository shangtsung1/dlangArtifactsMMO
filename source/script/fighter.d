module script.fighter;

import std.stdio;

import global;
import api.ammo;
import api.schema;
import script.helper;
import api.config;

void fighter(Character* c)
{
	if(countInventory(c) >= c.inventory_max_items){
		bankAll(c);
		return;
	}
	Location thingToFight = LOC_CHICKEN;
    if(c.hp < c.max_hp){
		c.rest();
		return;
	}
	else{
		 
		//if(){
			//thingToFight = LOC_COW;
		//}
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