module script.crafter;

import std.stdio;
import std.conv;
import std.algorithm : min;
import std.algorithm : max;

import global;
import api.ammo;
import api.schema;
import script.helper;
import api.config;

void crafter(Character* c)
{
    if((bank.count("copper_ore") > 100 || countItem(c,"copper_ore") >= 10) && (c.mining_level < 10|| bank.count("copper") < 100)){
        craft(c,"copper_ore","copper",c.inventory_max_items,10,LOC_MINING);
    }
    else if(c.mining_level >= 10 && (bank.count("iron_ore") > 100 || countItem(c,"iron_ore") >= 10) && (c.mining_level < 20 || bank.count("iron") < 100)){
        craft(c,"iron_ore","iron",c.inventory_max_items,10,LOC_MINING);
    }
    else if (!doGather(c,  1_000, c.fishing_level >= 10, LOC_GUDGEON, "gudgeon")) {
        return;
    }
    else if (!doGather(c,  1_000, c.fishing_level >= 20, LOC_SHRIMP, "shrimp")) {
        return;
    }
    else if (!doGather(c,  1_000, c.fishing_level >= 30, LOC_TROUT, "trout")) {
        return;
    }
    else{
        import script.fighter;
        fighter(c);
    }
}

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

bool craftCheck(Character* m, string[] reagents, string prod, int[] amntNeeded, int level, int levelRequired, int levelComp, int reagentNeededInBank, int produceWanted, bool bankRes) {
        if(level < levelRequired) {
            return false;
        }
        int totalReagents = reagents.length.to!int;
        int minReagentsInInventory = 999_999;
        bool craftBank;//global?

        // Check if the bank and inventory contain enough of each reagent
        for(int i = 0; i < totalReagents; i++) {
            string reagent = reagents[i];
            int amountNeeded = amntNeeded[i];
            int totalReagentCount = bank.count(reagent) + countItem(m,reagent);

            if(totalReagentCount < reagentNeededInBank) {
                return false;
            }

            minReagentsInInventory = min(minReagentsInInventory, countItem(m,reagent) / amountNeeded);
        }

        if(bank.count(prod) < produceWanted || level < levelComp) {
            //if(bankRes && bankRes(am, m)) {
            //    writeln("[Crafter] CraftCheckBankRes ",prod);
            //    return true;
            //}

            if(minReagentsInInventory >= 1) {
                writeln("[Crafter] make " , prod);
                //if(am.smartCraft(m, prod, minReagentsInInventory) == 200){
                //    craftBank = true;
                //}
                return true;
            } else {
                if(m.freeInventorySpaces() < totalReagents + 2) {
                    craftBank = true;
                    return true;
                }

                for(int i = 0; i < totalReagents; i++) {
                    string reagent = reagents[i];
                    int amountNeeded = amntNeeded[i];

                    if(countItem(m,reagent) < amountNeeded) {
                        int amnt = max(1,min((min(m.freeInventorySpaces() - 1, bank.count(reagent)))/ totalReagents,bank.count(reagent)));
                        writeln("[Crafter] withdraw " , reagent , " ",amnt);
                        m.withdrawItem(reagent, amnt);
                        break; // Only withdraw one reagent at a time
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