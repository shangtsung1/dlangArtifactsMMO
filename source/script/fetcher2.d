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

    int levelOfFighter = getCharacter(0).level;

   /* if(bank.count("small_antidote") >= 10 && extraCheck(c)){
        return;
    }*/
    if (!doGather(c,  200, c.woodcutting_level >= 10, LOC_ASH, "ash_wood")) {
        return;
    }
    else if (!doGather(c,  200, c.mining_level >= 10, LOC_COPPER, "copper_ore")) {
        return;
    }
    else if (!doGather(c,  200, c.alchemy_level >= 10, LOC_SUNFLOWER, "sunflower")) {
        return;
    }
    else if (!doGather(c,  200, c.woodcutting_level >= 20, LOC_SPRUCE, "spruce_wood")) {
        return;
    }
    else if ((levelOfFighter < 10|| c.fishing_level < 10) && ((bank.count("cooked_gudgeon") < 200 || bank.count("algae") < 50) || c.fishing_level < 10) && !doGather(c,  200, c.fishing_level >= 10, LOC_GUDGEON, "gudgeon")) {
        return;
    }
    else if (!doGather(c,  200, c.mining_level >= 20, LOC_IRON, "iron_ore")) {
        return;
    }
    else if (!doGather(c,  200, c.woodcutting_level >= 30, LOC_BIRCH, "birch_wood")) {
        return;
    }
    else if ((levelOfFighter < 20|| c.fishing_level < 20) &&(bank.count("cooked_shrimp") < 200 || c.fishing_level < 20) && !doGather(c,  200, c.fishing_level >= 20, LOC_SHRIMP, "shrimp")) {
        return;
    }
    else if (!doGather(c,  200, c.mining_level >= 30, LOC_COAL, "coal")) {
        return;
    }
    else if (c.alchemy_level >= 20 && !doGather(c,  200, c.alchemy_level >= 25, LOC_NETTLE, "nettle_leaf")) {
        return;
    }
    else if (!doGather(c,  200, c.woodcutting_level >= 40, LOC_DEADTREE, "dead_wood")) {
        return;
    }
    else if ((levelOfFighter < 30|| c.fishing_level < 30)&& (bank.count("cooked_trout") < 200 || c.fishing_level < 30) &&!doGather(c,  200, c.fishing_level >= 30, LOC_TROUT, "trout")) {
        return;
    }
    else if (!doGather(c,  200, c.mining_level >= 40, LOC_GOLD, "gold_ore")) {
        return;
    }
    //TODO: fille the gap of 25->30 alch
    else if (c.alchemy_level >= 40 && !doGather(c,  200, c.alchemy_level >= 35, LOC_GLOWSTEM, "glowstem_leaf")) {
        return;
    }
    else if (!doMaple(c,  200, c.woodcutting_level >= 50)) {
        return;
    }
    else if ((levelOfFighter < 40|| c.fishing_level < 40)&&(bank.count("cooked_bass") < 200 || c.fishing_level < 40) &&!doGather(c,  200, c.fishing_level >= 40, LOC_BASS, "bass")) {
        return;
    }
    else if (!doMithril(c,  200, c.mining_level >= 50)) {
        return;
    }
    else if ((bank.count("cooked_salmon") < 200 || c.fishing_level < 50) && !doGather(c,  200, c.fishing_level >= 50, LOC_SALMON, "salmon")) {
        return;
    } 
    writeln(c.color, "Done metal melord!");
}

 bool extraCheck(Character* c, bool overide = false){
    if(c.mining_level >= 30 && c.woodcutting_level >= 30 && c.fishing_level>=30 && c.alchemy_level >= 25 && (overide ||c.level < 40 || c.alchemy_level < 50)){
        if (!doGather(c,  100, c.alchemy_level >= 20, LOC_NETTLE, "nettle_leaf")) {
            return true;//get some potions
        }
        if(overide || c.level < 30){
            import script.fighter;
            fighter(c);
            return true;
        }
    }
    else if(c.mining_level >= 20 && c.woodcutting_level >= 20 && c.fishing_level>=20 && c.alchemy_level >= 20 && (overide ||c.level < 30 || c.alchemy_level < 40)){
        if (!doGather(c,  100, c.alchemy_level >= 10, LOC_SUNFLOWER, "sunflower")) {
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