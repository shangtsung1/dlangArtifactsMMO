module script.fetcher3;

import std.stdio;

import global;
import api.ammo;
import api.schema;
import script.helper;
import script.bettergear;


void fetcher3(Character* c)
{
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
    import script.crafter;
   /* if(bank.count("small_antidote") >= 10 && extraCheck(c)){
        return;
    }*/
    if ((levelOfFighter < 10|| c.fishing_level < 10) && ((bank.count("cooked_gudgeon") < 200 || bank.count("algae") < 50) || c.fishing_level < 10) && !doGather(c,  200, c.fishing_level >= 10, findLocation("resource","gudgeon_fishing_spot"), "gudgeon")) {
        return;
    }
    else if(c.alchemy_level>= 10 && c.alchemy_level < 16 && craftCheck(c, "small_health_potion", 18, 9999)){
        return;
    }
    else if(c.alchemy_level>= 10 && c.alchemy_level < 20 && craftCheck(c, "earth_boost_potion", 20, 9999)){
        return;
    }
    else if(c.alchemy_level>= 10 && c.alchemy_level < 20 && craftCheck(c, "water_boost_potion", 20, 9999)){
        return;
    }
    else if(c.alchemy_level>= 10 && c.alchemy_level < 20 && craftCheck(c, "fire_boost_potion", 20, 9999)){
        return;
    }
    else if(c.alchemy_level>= 10 && c.alchemy_level < 20 && craftCheck(c, "air_boost_potion", 20, 9999)){
        return;
    }
    else if (!doGather(c,  200, c.alchemy_level >= 10, findLocation("resource","sunflower_field"), "sunflower")) {
        return;
    }
    else if ((levelOfFighter < 20|| c.fishing_level < 20) &&(bank.count("cooked_shrimp") < 200 || c.fishing_level < 20) && !doGather(c,  200, c.fishing_level >= 20, findLocation("resource","shrimp_fishing_spot"), "shrimp")) {
        return;
    }
    else if ((levelOfFighter < 30|| c.fishing_level < 30)&& (bank.count("cooked_trout") < 200 || c.fishing_level < 30) &&!doGather(c,  200, c.fishing_level >= 30, findLocation("resource","trout_fishing_spot"), "trout")) {
        return;
    }
    else if (c.alchemy_level >= 20 && !doGather(c,  200, c.alchemy_level >= 25, findLocation("resource","nettle_field"), "nettle_leaf")) {
        return;
    }
    else if ((levelOfFighter < 40|| c.fishing_level < 40)&&(bank.count("cooked_bass") < 200 || c.fishing_level < 40) &&!doGather(c,  200, c.fishing_level >= 40, findLocation("resource","bass_fishing_spot"), "bass")) {
        return;
    }
    //TODO: fille the gap of 25->30 alch
    else if (c.alchemy_level >= 40 && !doGather(c,  200, c.alchemy_level >= 35, findLocation("resource","glowstem_field"), "glowstem_leaf")) {
        return;
    }
    else if ((bank.count("cooked_salmon") < 200 || c.fishing_level < 50) && !doGather(c,  200, c.fishing_level >= 50, findLocation("resource","salmon_fishing_spot"), "salmon")) {
        return;
    } 
    writeln(c.color, "Done metal melord!");
}