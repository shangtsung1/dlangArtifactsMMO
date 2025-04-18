module script.crafter;

import std.stdio;
import std.conv;
import std.algorithm : min;
import std.algorithm : max;

import global;
import api.ammo;
import api.schema;
import script.helper;

void crafter(Character* c)
{
    if(c.alchemy_level < 5){
        doGather(c,  500_000, c.alchemy_level >= 5, LOC_SUNFLOWER, "sunflower");
        return;
    }
    foreach (ref const rule; simpleCraftables) {
        if (craftCheck(c, rule.itemName, rule.param1, rule.param2)) {
            return;
        }
    }
    foreach (ref const rule; recipeCraftables) {
        int currentSkill = rule.getSkillLevel(c);
        if (craftCheck(c, rule.ingredients, rule.outputItem, rule.quantities,currentSkill, rule.minLevel, rule.maxLevel, rule.maxCraft)) {
            return;
        }
    }
    import script.fighter;
    fighter(c);
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

SimpleCraftRule[] simpleCraftables = [
    //lvl15
    { "wisdom_amulet",         15, 2 },

    //lvl10
    { "slime_shield",         10, 2 },
    { "fire_and_earth_amulet", 10, 2 },
    { "air_and_water_amulet",  10, 2 },

    // lvl10
    { "spruce_fishing_rod",    10, 2 },
    { "iron_axe",              10, 2 },
    { "iron_pickaxe",          10, 2 },

    // lvl10
    { "air_ring",              15, 2 },
    { "earth_ring",            15, 2 },
    { "fire_ring",             15, 2 },
    { "life_ring",             15, 2 },
    { "water_ring",            15, 2 },

    // lvl10
    { "iron_helm",             10, 2 },
    { "iron_legs_armor",       10, 2 },
    { "iron_armor",            10, 2 },
    { "iron_boots",            15, 2 },
    { "iron_ring",             20, 2 },
    //lvl5
    { "life_amulet",            5, 2 },
    { "satchel",                5, 2 },
    { "fire_staff",             5, 2 },
    { "sticky_sword",           5, 2 },
    { "copper_armor",           5, 2 },
    { "copper_dagger",         10, 2 },
    { "copper_legs_armor",     10, 2 },
    //lvl1
    { "wooden_shield",          1, 2 },
    { "copper_helmet",          1, 2 },
    { "copper_boots",           5, 2 },
    { "copper_ring",           10, 2 },

    // Potions
    { "small_health_potion",10, 5 }
];

RecipeCraftRule[] recipeCraftables = [
    // Mining Recipes
    { ["copper_ore"], "copper", [10],          (const Character* c) => c.mining_level,  0, 10,  500 },
    { ["iron_ore", "coal"], "steel", [3, 7],   (const Character* c) => c.mining_level, 20, 30, 1500 },
    { ["iron_ore"], "iron", [10],              (const Character* c) => c.mining_level, 10, 20,  500 },
    { ["gold_ore"], "gold", [10],              (const Character* c) => c.mining_level, 30, 40,  500 },
    { ["piece_of_obsidian"], "obsidian", [4],  (const Character* c) => c.mining_level, 30, 40,  500 },
    { ["gold_ore", "strange_ore"], "strangold", [4, 6], (const Character* c) => c.mining_level, 35, 40,  500 },

    // Woodcutting Recipes
    { ["ash_wood", "birch_wood"], "hardwood_plank", [4, 6], (const Character* c) => c.woodcutting_level, 20, 30,  500 },
    { ["ash_wood"], "ash_plank", [10],          (const Character* c) => c.woodcutting_level,  0, 10,  500 },
    { ["spruce_wood"], "spruce_plank", [10],    (const Character* c) => c.woodcutting_level, 10, 20,  500 },
    { ["dead_wood"], "dead_wood_plank", [10],  (const Character* c) => c.woodcutting_level, 30, 40,  500 },
    { ["dead_wood", "magic_wood"], "magical_plank", [4, 6], (const Character* c) => c.woodcutting_level, 35, 40,  500 },

    // Cooking Recipes
    { ["egg"], "fried_eggs", [2],              (const Character* c) => c.cooking_level, 10, 40, 50 },
    { ["raw_chicken"], "cooked_chicken", [1],  (const Character* c) => c.cooking_level,  0, 40, 50 },
    { ["gudgeon"], "cooked_gudgeon", [1],      (const Character* c) => c.cooking_level,  0, 40, 50 },
    { ["shrimp"], "cooked_shrimp", [1],        (const Character* c) => c.cooking_level, 10, 40, 50 },
    { ["trout"], "cooked_trout", [1],          (const Character* c) => c.cooking_level, 20, 40, 50 },
    { ["bass"], "cooked_bass", [1],            (const Character* c) => c.cooking_level, 30, 40, 50 },
    { ["milk_bucket"], "cheese", [1],          (const Character* c) => c.cooking_level, 10, 40, 50 },
    { ["raw_wolf_meat"], "cooked_wolf_meat", [1], (const Character* c) => c.cooking_level, 15, 40, 50 }
];


void craft(Character* c,string reagent,string code, int amount, int divisor,Location loc){
    if(countItem(c,reagent) < countInventory(c)){
        bankAll(c);
        return;
    }
    if(countItem(c,reagent) < amount-1 / divisor){

        withdraw(c,reagent, (amount-1 / divisor)-countItem(c,reagent));
        return;
    }
    if(c.x != loc.x || c.y != loc.y){
        writeln(c.color,"CraftMove", c.move(loc.x,loc.y));
        return;
    }
    writeln(c.color,"Crafting ",countItem(c,reagent) / divisor,"",c.crafting(code,countItem(c,reagent) / divisor));
}

void withdraw(Character* c,string code, int amount){
    if(c.x != 4 || c.y != 1){
        writeln(c.color,"BankMoveResult = ",c.move(4,1));
        return;
    }
    
    writeln(c.color,"CraftingWithdraw ",code," ",amount," ",c.withdrawItem(code,amount));
}

bool craftCheck(Character* m, string prod, int levelComp, int produceWanted) {
    ItemSchema ai = getItem(prod);
    int level = getLevelForSkill(m,ai.craft.get().skillString);
    int levelRequired = ai.level;
    if(level < levelRequired) {
        return false;
    }

    int[] amntNeeded;
    string[] reagents;

    foreach(item;ai.craft.get().items){
        reagents ~= item.code;
        amntNeeded ~= item.quantity;
    }

    int totalReagents = reagents.length.to!int;
    int minReagentsInInventory = 999_999;

    // Check if the bank and inventory contain enough of each reagent
    for(int i = 0; i < totalReagents; i++) {
        string reagent = reagents[i];
        int amountNeeded = amntNeeded[i];
        int totalReagentCount = bank.count(reagent) + countItem(m,reagent);

        if(totalReagentCount < amountNeeded) {
            return false;
        }

        minReagentsInInventory = min(minReagentsInInventory, countItem(m,reagent) / amountNeeded);
    }

    return craftCheck( m, reagents, prod, amntNeeded, level, levelRequired, levelComp, produceWanted);
}

bool craftCheck(Character* m, const string[] reagents, const string prod, const int[] amntNeeded, int level, const int levelRequired, const int levelComp, const int produceWanted) {
        if(level < levelRequired) {
            return false;
        }
        int totalReagents = reagents.length.to!int;
        int minReagentsInInventory = 999_999;

        // Check if the bank and inventory contain enough of each reagent
        for(int i = 0; i < totalReagents; i++) {
            string reagent = reagents[i];
            int amountNeeded = amntNeeded[i];
            if(bank.count(reagent)+countItem(m,reagent) < amountNeeded){
                return false;
            }
            minReagentsInInventory = min(minReagentsInInventory, countItem(m,reagent) / amountNeeded);
        }

        if(bank.count(prod) < produceWanted || level < levelComp) {
            if(minReagentsInInventory >= 1) {
                writeln(m.color,"[Crafter] make " , prod, " ",minReagentsInInventory);
                int res = smartCraft(m, prod, minReagentsInInventory);
                if(res == 200){
                    m.setBoolean("bankAll",true);
                }
                else{
                    writeln(m.color,"[Crafter] Crafting failed with code ",res);
                }
                return true;
            } else {
                if(m.freeInventorySpaces() < totalReagents + 2) {
                    m.setBoolean("bankAll",true);
                    return true;
                }

                for(int i = 0; i < totalReagents; i++) {
                    string reagent = reagents[i];
                    int amountNeeded = amntNeeded[i];
                    if(m.x != 4 || m.y != 1){
                        int result = m.move(4,1);
                        return false;
                    }
                    if(countItem(m,reagent) < amountNeeded) {
                        int amnt = max(1,min((min(m.freeInventorySpaces() - 1, bank.count(reagent)))/ totalReagents,bank.count(reagent)));
                        writeln(m.color,"[Crafter] withdraw " , reagent , " ",amnt);
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
        final switch(skill){
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
        writeln("UNKNOWN SKILL ",skill);
        return 0;
    }