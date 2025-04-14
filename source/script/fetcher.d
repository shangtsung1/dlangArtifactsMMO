module script.fetcher;

import std.stdio;

import global;
import api.ammo;
import api.schema;
import script.helper;
import api.config;


void fetcher(Character* c)
{
    if (!doGather(c,  1_000, c.mining_level >= 10, LOC_COPPER, "copper_ore")) {
        return;
    }
    else if (!doGather(c,  1_000, c.woodcutting_level >= 10, LOC_ASH, "ash_wood")) {
        return;
    }
    else if (!doGather(c,  1_000, c.alchemy_level >= 10, LOC_SUNFLOWER, "sunflower")) {
        return;
    }
    else if (!doGather(c,  1_000, c.fishing_level >= 10, LOC_GUDGEON, "gudgeon")) {
        return;
    }

    else if (!doGather(c,  1_000, c.mining_level >= 20, LOC_IRON, "iron_ore")) {
        return;
    }
    else if (!doGather(c,  1_000, c.woodcutting_level >= 20, LOC_SPRUCE, "spruce_wood")) {
        return;
    }
    else if (!doGather(c,  1_000, c.fishing_level >= 20, LOC_SHRIMP, "shrimp")) {
        return;
    }
    else if (!doGather(c,  1_000, c.alchemy_level >= 20, LOC_SUNFLOWER, "sunflower")) {
        return;
    }

    else if (!doGather(c,  1_000, c.mining_level >= 30, LOC_COAL, "coal")) {
        return;
    }
    else if (!doGather(c,  1_000, c.woodcutting_level >= 30, LOC_BIRCH, "birch_wood")) {
        return;
    }
    else if (!doGather(c,  1_000, c.alchemy_level >= 30, LOC_NETTLE, "nettle_leaf")) {
        return;
    }
    else if (!doGather(c,  1_000, c.fishing_level >= 30, LOC_TROUT, "trout")) {
        return;
    }

    else if (!doGather(c,  1_000, c.mining_level >= 40, LOC_GOLD, "gold_ore")) {
        return;
    }
    else if (!doGather(c,  1_000, c.woodcutting_level >= 40, LOC_DEADTREE, "dead_wood")) {
        return;
    }
    else if (!doGather(c,  1_000, c.alchemy_level >= 40, LOC_GLOWSTEM, "glowstem_leaf")) {
        return;
    }
    else if (!doGather(c,  1_000, c.fishing_level >= 40, LOC_BASS, "bass")) {
        return;
    }

    else if (!doMithril(c,  1_000, c.mining_level >= 50)) {
        return;
    }
    else if (!doMaple(c,  1_000, c.woodcutting_level >= 50)) {
        return;
    }
    else if (!doGather(c,  1_000, c.fishing_level >= 50, LOC_SALMON, "salmon")) {
        return;
    } 

    writeln(c.color, "Done metal melord!");
}