module script.fetcher;

import std.stdio;

import global;
import api.ammo;
import api.schema;
import script.helper;
import script.bettergear;


void fetcher(Character* c)
{
    if(equipmentCheck(c,false)){
		return;
	}
    if(extraCheck(c)){
        return;
    }
    else if (!doGather(c,  500, c.mining_level >= 10, LOC_COPPER, "copper_ore")) {
        return;
    }
    else if (!doGather(c,  500, c.woodcutting_level >= 10, LOC_ASH, "ash_wood")) {
        return;
    }
    else if (!doGather(c,  500, c.alchemy_level >= 10, LOC_SUNFLOWER, "sunflower")) {
        return;
    }
    else if (((bank.count("cooked_gudgeon") < 500 || bank.count("algae") < 50) || c.fishing_level < 10) && !doGather(c,  500, c.fishing_level >= 10, LOC_GUDGEON, "gudgeon")) {
        return;
    }
    else if (!doGather(c,  500, c.mining_level >= 20, LOC_IRON, "iron_ore")) {
        return;
    }
    else if (!doGather(c,  500, c.woodcutting_level >= 20, LOC_SPRUCE, "spruce_wood")) {
        return;
    }
    else if ((bank.count("cooked_shrimp") < 500 || c.fishing_level < 20) && !doGather(c,  500, c.fishing_level >= 20, LOC_SHRIMP, "shrimp")) {
        return;
    }
    else if (!doGather(c,  500, c.mining_level >= 30, LOC_COAL, "coal")) {
        return;
    }
    else if (!doGather(c,  500, c.woodcutting_level >= 30, LOC_BIRCH, "birch_wood")) {
        return;
    }
    else if (!doGather(c,  500, c.alchemy_level >= 30, LOC_NETTLE, "nettle_leaf")) {
        return;
    }
    else if (!doGather(c,  500, c.fishing_level >= 30, LOC_TROUT, "trout")) {
        return;
    }
    else if (!doGather(c,  500, c.mining_level >= 40, LOC_GOLD, "gold_ore")) {
        return;
    }
    else if (!doGather(c,  500, c.woodcutting_level >= 40, LOC_DEADTREE, "dead_wood")) {
        return;
    }
    else if (!doGather(c,  500, c.alchemy_level >= 40, LOC_GLOWSTEM, "glowstem_leaf")) {
        return;
    }
    else if (!doGather(c,  500, c.fishing_level >= 40, LOC_BASS, "bass")) {
        return;
    }
    else if (!doMithril(c,  500, c.mining_level >= 50)) {
        return;
    }
    else if (!doMaple(c,  500, c.woodcutting_level >= 50)) {
        return;
    }
    else if (!doGather(c,  500, c.fishing_level >= 50, LOC_SALMON, "salmon")) {
        return;
    } 
    writeln(c.color, "Done metal melord!");
}

 bool extraCheck(Character* c){
    if(c.mining_level >= 10 && c.woodcutting_level >= 10 && c.fishing_level>=10 && c.alchemy_level >= 10){
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
        if(c.level < 10){
            import script.fighter;
            fighter(c);
            return true;
        }
    }
    return false;
 }