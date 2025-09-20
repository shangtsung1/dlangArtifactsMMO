module script.fetcher2;

import std.stdio;

import global;
import api.ammo;
import api.schema;
import script.helper;
import script.bettergear;


void fetcher2(Character* c)
{
    if(bank.items.length >= bank.maxSlots-5){
        extraCheck(c,true);
        return;
    }

    EquipList[] el = findBestWisdomEquipmentToFight(c);

	foreach(e;el){
		if(e.itemCode == "")continue;
		writeln(c.color,"Equipping ",e.itemCode," to ",e.slotName);
		if(checkEquip(c,e.itemCode,e.slotName)){
			writeln(c.color,"Equipping ",e.itemCode," to ",e.slotName);
			return;
		}
	}

    int levelOfFighter = getCharacter(0).level;

   /* if(bank.count("small_antidote") >= 10 && extraCheck(c)){
        return;
    }*/
    if (!doGather(c,  200, c.woodcutting_level >= 10, findLocation("resource","ash_tree"), "ash_wood")) {
        return;
    }
    //else if (!doGather(c,  200, c.alchemy_level >= 10, findLocation("resource","sunflower_field"), "sunflower")) {
    //    return;
    //}
    else if (!doGather(c,  200, c.woodcutting_level >= 20, findLocation("resource","spruce_tree"), "spruce_wood")) {
        return;
    }
    else if (!doGather(c,  200, c.woodcutting_level >= 30, findLocation("resource","birch_tree"), "birch_wood")) {
        return;
    }
    //else if (c.alchemy_level >= 20 && !doGather(c,  200, c.alchemy_level >= 25, findLocation("resource","nettle_field"), "nettle_leaf")) {
    //    return;
    ///}
    else if (!doGather(c,  200, c.woodcutting_level >= 40, findLocation("resource","dead_tree"), "dead_wood")) {
        return;
    }
    //TODO: fille the gap of 25->30 alch
    //else if (c.alchemy_level >= 40 && !doGather(c,  200, c.alchemy_level >= 35, findLocation("resource","glowstem_field"), "glowstem_leaf")) {
    //    return;
    //}
    else if (!doMaple(c,  200, c.woodcutting_level >= 50)) {
        return;
    } 
    writeln(c.color, "Done metal melord!");
}

 bool extraCheck(Character* c, bool overide = false){
    if(c.mining_level >= 30 && c.woodcutting_level >= 30 && c.fishing_level>=30 && c.alchemy_level >= 25 && (overide ||c.level < 40 || c.alchemy_level < 50)){
        if (!doGather(c,  100, c.alchemy_level >= 20, findLocation("resource","nettle_field"), "nettle_leaf")) {
            return true;//get some potions
        }
        if(overide || c.level < 30){
            import script.fighter;
            fighter(c);
            return true;
        }
    }
    else if(c.mining_level >= 20 && c.woodcutting_level >= 20 && c.fishing_level>=20 && c.alchemy_level >= 20 && (overide ||c.level < 30 || c.alchemy_level < 40)){
        if (!doGather(c,  100, c.alchemy_level >= 10, findLocation("resource","sunflower_field"), "sunflower")) {
            return true;//get some potions
        }
        if(overide || c.level < 20){
            import script.fighter;
            fighter(c);
            return true;
        }
    }
    else if(c.mining_level >= 10 && c.woodcutting_level >= 10 && c.fishing_level>=10 && c.alchemy_level >= 10 && (overide ||c.level < 10 || c.alchemy_level < 20)){
        import script.crafter;
        if(c.alchemy_level < 16){
            if(craftCheck(c, "small_health_potion", 18, 9999)){
                return true;
            }
        }
        else if(c.alchemy_level < 20){
            if(craftCheck(c, "earth_boost_potion", 20, 9999)){
                return true;
            }
            else if(craftCheck(c, "water_boost_potion", 20, 9999)){
                return true;
            }
            else if(craftCheck(c, "fire_boost_potion", 20, 9999)){
                return true;
            }
            else if(craftCheck(c, "air_boost_potion", 20, 9999)){
                return true;
            }
        }
        if(overide || c.level < 10){
            import script.fighter;
            fighter(c);
            return true;
        }
    }
    return false;
 }