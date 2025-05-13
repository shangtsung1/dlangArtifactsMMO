module script.crafter;

import std.stdio;
import std.conv;
import std.algorithm : min, max;
import std.json;
import std.file;
import std.array;
import std.range;
import std.algorithm;

import global;
import api.ammo;
import api.schema;
import script.helper;

void crafter(Character* c) {
    if(bank.maxSlots < 200 && bank.gold + c.gold > bank.nextExpansionCost){
        if(c.x != LOC_BANK.x || c.y != LOC_BANK.y){
            c.move(LOC_BANK.x, LOC_BANK.y);
            return;
        }
        if(c.gold < bank.nextExpansionCost){
            c.withdrawGold(bank.nextExpansionCost - c.gold);
            return;
        }
        if(c.gold >= bank.nextExpansionCost){
            c.buyExpansion();
            c.setBoolean("bankAll", true);
            return;
        }
    }


    if (c.alchemy_level < 5) {
        doGather(c, 500_000, c.alchemy_level >= 5, LOC_SUNFLOWER, "sunflower");
        return;
    }
    foreach (ref const rule; simpleCraftables) {
        if (craftCheck(c, rule.itemName, rule.param1, rule.param2)) {
            return;
        }
    }
    foreach (ref const rule; recipeCraftables) {
        int currentSkill = rule.getSkillLevel(c);
        if (craftCheck(c, rule.ingredients, rule.outputItem, rule.quantities, currentSkill, rule.minLevel, rule.maxLevel, rule.maxCraft)) {
            return;
        }
    }
    if (!doGather(c,  500, c.alchemy_level >= 10, LOC_SUNFLOWER, "sunflower")) {
        return;
    }
    else if (!doGather(c,  500, c.alchemy_level >= 30, LOC_NETTLE, "nettle_leaf")) {
        return;
    }
    else if (!doGather(c,  500, c.alchemy_level >= 40, LOC_GLOWSTEM, "glowstem_leaf")) {
        return;
    }
    import script.fetcher;
    fetcher(c);
}

struct SimpleCraftRule {
    string itemName;
    int param1;
    int param2;
}

alias SkillGetter = int function(const Character* c);

struct RecipeCraftRule {
    string[] ingredients;
    string outputItem;
    int[] quantities;
    SkillGetter getSkillLevel;
    int minLevel;
    int maxLevel;
    int maxCraft;
}

SimpleCraftRule[] simpleCraftables;
RecipeCraftRule[] recipeCraftables;

static this() {
    loadCraftables();
}

void loadCraftables() {
    loadSimpleCraftables();
    loadRecipeCraftables();
}

void loadSimpleCraftables() {
    auto path = "data/simple_craftables.json";
    if (!exists(path)) {
        writeln("[ERROR] Missing simple_craftables.json");
        return;
    }
    string jsonText = readText(path);
    JSONValue json = parseJSON(jsonText);
    foreach (item; json.array()) {
        simpleCraftables ~= SimpleCraftRule(
            item["itemName"].str,
            item["lvl"].get!int,
            item["minAmount"].get!int
        );
    }
}

void loadRecipeCraftables() {
    auto path = "data/recipe_craftables.json";
    if (!exists(path)) {
        writeln("[ERROR] Missing recipe_craftables.json");
        return;
    }
    string jsonText = readText(path);
    JSONValue json = parseJSON(jsonText);
    foreach (item; json.array()) {
        string[] ingredients = item["ingredients"].array.map!(x => x.str).array;
        string outputItem = item["outputItem"].str;
        int[] quantities = item["quantities"].array.map!(x => x.get!int).array;
        string skill = item["skill"].str;
        int minLevel = item["minLevel"].get!int;
        int maxLevel = item["maxLevel"].get!int;
        int maxCraft = item["maxCraft"].get!int;

        SkillGetter getter = getSkillFunction(skill);
        recipeCraftables ~= RecipeCraftRule(ingredients, outputItem, quantities, getter, minLevel, maxLevel, maxCraft);
    }
}

SkillGetter getSkillFunction(string skill) {
    switch (skill) {
        case "mining":
            return (const Character* c) => c.mining_level;
        case "woodcutting":
            return (const Character* c) => c.woodcutting_level;
        case "cooking":
            return (const Character* c) => c.cooking_level;
        case "weaponcrafting":
            return (const Character* c) => c.weaponcrafting_level;
        case "gearcrafting":
            return (const Character* c) => c.gearcrafting_level;
        case "alchemy":
            return (const Character* c) => c.alchemy_level;
        case "fishing":
            return (const Character* c) => c.fishing_level;
        case "jewelrycrafting":
            return (const Character* c) => c.jewelrycrafting_level;
        default:
            assert(false, "Unknown skill: " ~ skill);
    }
    return null;
}

bool craftCheck(Character* m, string prod, int levelComp, int produceWanted) {
    ItemSchema ai = getItem(prod);
    int level = getLevelForSkill(m, ai.craft.get().skillString);
    int levelRequired = ai.level;
    if (level < levelRequired) {
        return false;
    }

    string[] reagents;
    int[] amntNeeded;

    foreach (item; ai.craft.get().items) {
        reagents ~= item.code;
        amntNeeded ~= item.quantity;
    }

    return craftCheck(m, reagents, prod, amntNeeded, level, levelRequired, levelComp, produceWanted);
}

bool craftCheck(Character* m, const string[] reagents, const string prod, const int[] amntNeeded, int level, const int levelRequired, const int levelComp, const int produceWanted) {
    if (level < levelRequired) {
        return false;
    }
    int totalReagents = reagents.length.to!int;
    int minReagentsInInventory = int.max;

    foreach (i; 0 .. totalReagents) {
        string reagent = reagents[i];
        int amountNeeded = amntNeeded[i];
        int total = bank.count(reagent) + countItem(m, reagent);
        if (total < amountNeeded) {
            return false;
        }
        minReagentsInInventory = min(minReagentsInInventory, countItem(m, reagent) / amountNeeded);
    }

    if (bank.count(prod) < produceWanted || level < levelComp) {
        if (minReagentsInInventory >= 1) {
            writeln(m.color, "[Crafter] make ", prod, " ", minReagentsInInventory);
            int res = smartCraft(m, prod, minReagentsInInventory);
            if (res == 200) {
                m.setBoolean("bankAll", true);
            } else {
                writeln(m.color, "[Crafter] Crafting failed with code ", res);
            }
            return true;
        } else {
            if (m.freeInventorySpaces() < totalReagents + 2) {
                m.setBoolean("bankAll", true);
                return true;
            }

            foreach (i; 0 .. totalReagents) {
                string reagent = reagents[i];
                int amountNeeded = amntNeeded[i];
                if (countItem(m, reagent) < amountNeeded) {
                    if (m.x != 4 || m.y != 1) {
                        m.move(4, 1);
                        return false;
                    }
                    int amnt = max(1, min((m.freeInventorySpaces() - 1) / totalReagents, bank.count(reagent)));
                    writeln(m.color, "[Crafter] withdraw ", reagent, " ", amnt);
                    m.withdrawItem(reagent, amnt);
                    break;
                }
            }
            return true;
        }
    }
    return false;
}

int getLevelForSkill(Character* m, string skill) {
    final switch (skill) {
        case "weaponcrafting":
            return m.weaponcrafting_level;
        case "gearcrafting":
            return m.gearcrafting_level;
        case "alchemy":
            return m.alchemy_level;
        case "cooking":
            return m.cooking_level;
        case "fishing":
            return m.fishing_level;
        case "woodcutting":
            return m.woodcutting_level;
        case "mining":
            return m.mining_level;
        case "jewelrycrafting":
            return m.jewelrycrafting_level;
    }
    writeln("UNKNOWN SKILL ", skill);
    return 0;
}