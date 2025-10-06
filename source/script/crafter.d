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
import script.bettergear;
import script.helper;

void crafter(Character* c) {
    if(bank.maxSlots < 200 && bank.gold + c.gold > bank.nextExpansionCost){
        int res = smartMove(c, "bank","bank");
        if(res!=200){
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
    if(c.countItem("bag_of_gold") > 0){
        c.useItem("bag_of_gold",1);
        return;
    }
    if(c.countItem("small_bag_of_gold") > 0){
        c.useItem("small_bag_of_gold",1);
        return;
    }
    if(c.countItem("tasks_coin")+bank.count("tasks_coin") >= 6){
        if(c.countItem("tasks_coin") < 6 && c.countInventory() > 50){
            c.setBoolean("bankAll", true);
            return;
        }
        if(c.countItem("tasks_coin") < 6){
            smartWithdraw(c,"tasks_coin",6,c.inventory_max_items);
            return;
        }
        if(c.x != 4 || c.y != 13){
            c.move(4,13);
            return;
        }
        c.taskExchange();
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

    if(merchantCheck(c)){
        return;
    }

   // if(dismantleCheck(c)){
    //    return;
   // }
    if (c.alchemy_level < 5) {
        doGather(c, 500_000, c.alchemy_level >= 5, findLocation("resource","sunflower_field"), "sunflower");
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
    if (c.alchemy_level < 20 && !doGather(c,  500, c.alchemy_level >= 10, findLocation("resource","sunflower_field"), "sunflower")) {
        return;
    }
    else if (c.alchemy_level >= 20 && !doGather(c,  500, c.alchemy_level >= 30, Location(7,14), "nettle_leaf")) {
        return;
    }
    else if (c.alchemy_level >= 40 && !doGather(c,  500, c.alchemy_level >= 40, findLocation("resource","glowstem_field"), "glowstem_leaf")) {
        return;
    }
    import script.fetcher;
    fetcher(c);
}


bool merchantCheck(Character* c){
    if(toSellFunc(c,"gemstone_merchant",5,["diamond","emerald","ruby","sapphire","topaz"])){
       return true;
    }
    else if(toSellFunc(c,"fish_merchant",0,["shell","golden_shrimp"])){
        return true;
    }
    else if(toSellFunc(c,"timber_merchant",500,["sap","maple_sap","magic_sap"])){
        return true;
    }
    else if(toSellFunc(c,"nomadic_merchant",0,["golden_egg"])){
        return true;
    }
    else if(toSellFunc(c,"nomadic_merchant",5,["highwayman_dagger","death_knight_sword","lich_crown","old_boots","wolf_ears","wooden_club"])){
        return true;
    }
    else if(toSellFunc(c,"nomadic_merchant",10,["forest_ring"])){
        return true;
    }
    return false;
}

bool toSellFunc(Character* c,string merc,int toKeep,string[] toSell){
    if(getActiveEvent(merc) !is null){
        foreach(ts; toSell){
            int amt = countAllItems(ts);
            if(amt > toKeep){
                sell(c,merc,amt-toKeep,ts);
                return true;
            }
        }
    }
    return false;
}

void sell(Character* c,string eventCode, int amnt, string itemCode){
    auto event = getActiveEvent(eventCode);
    if(event is null) return;
    int x = event.map.x;
    int y = event.map.y;
    if(c.countItem(itemCode) < 1){
        smartWithdraw(c,itemCode,1,amnt);
        return;
    }
    else{
        if(c.x != x || c.y != y){
            c.move(x,y);
            return;
        }
        c.npcSell(itemCode,min(amnt,c.countItem(itemCode)));
    }
}


struct BasicItem{
    string code;
    int quantity;
}
bool dismantleCheck(Character* c){
    int[string] itemQuantities;

    foreach (i; c.inventory) {
        itemQuantities[i.code] += i.quantity;
    }
    foreach (i; bank.items) {
        itemQuantities[i.code] += i.quantity;
    }
    
    BasicItem[] allItems;
    foreach (kv; itemQuantities.byKeyValue) {
        allItems ~= BasicItem(kv.key, countAllItems(kv.key));
    }


    foreach(item;allItems){
        if(countAllItems(item.code) < 6){
            continue;
        }
        ItemSchema ischema = getItem(item.code);
        if((ischema.type != "weapon" && ischema.type != "boots"
            && ischema.type != "shield"&& ischema.type != "leg_armor"&& ischema.type != "helmet"
            && ischema.type != "body_armor"&& ischema.type != "ring"&& ischema.type != "amulet") || ischema.subtype == "tool"){
            continue;
        }
        if(!ischema.craft.isNull()){//its craftable therefor dismantable?
            recycle(c,item,ischema.type);
            return true;
        }
    }
    return false;
}

void recycle(Character* c,BasicItem item,string type){
    int amountToRecycle = min(30,item.quantity-5);
    int amountToWithdraw = amountToRecycle - c.countItem(item.code);
    if(c.freeInventorySpaces() < 60){
        bankAll(c);
        return;
    }
    if(amountToWithdraw > 0){
        writeln(c.color,"grab ",item.code, " from bank");
        smartWithdraw(c,item.code,amountToWithdraw,amountToWithdraw);
        return;
    }
    else{
        if(type == "weapon" ){
            if(c.x != 2 || c.y != 1){
                c.move(2,1);
                return;
            }
        }
        else if(type == "amulet" || type == "ring"){
            if(c.x != 1 || c.y != 3){
                c.move(1,3);
                return;
            }
        }
        else{
            if(c.x != 3 || c.y != 1){
                c.move(3,1);
                return;
            }
        }
    }
    c.recycling(item.code,amountToRecycle);
    writeln(c.color,"Recycle ",item.code," ",amountToRecycle);
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

    if (countAllItems(prod,false) < produceWanted || level < levelComp) {
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