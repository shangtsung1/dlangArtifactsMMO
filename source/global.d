module global;

import std.stdio;
import std.file;
import std.json;
import std.range;
import std.typecons : Nullable;
import std.algorithm.mutation : reverse;

static import api.schema;
static import api.ammo;

__gshared const string CACHE_DIR = "./cache/";

alias ArtifactMMOClient = api.ammo.ArtifactMMOClient;
alias Location = api.schema.Location;
alias SimpleItemSchema = api.schema.SimpleItemSchema;
alias Character = api.schema.Character;
alias ItemSchema = api.schema.ItemSchema;
alias MapSchema = api.schema.MapSchema;
alias MonsterSchema = api.schema.MonsterSchema;
alias NpcSchema = api.schema.NpcSchema;
alias EventSchema = api.schema.EventSchema;
alias ActiveEventSchema = api.schema.ActiveEventSchema;

__gshared Bank bank;
__gshared api.schema.Character*[string] characters;
__gshared string[] charOrder;
__gshared ItemSchema[] itemList;
__gshared ArtifactMMOClient client;
__gshared MapSchema[] maps;
__gshared MonsterSchema[] monsters;
__gshared NpcSchema[] npcs;
__gshared EventSchema[] events;
__gshared ActiveEventSchema[] activeEvents;



void global_init(string token,bool sandbox)
{
    client = new ArtifactMMOClient(token,sandbox);
    client.initClient();
	bank = new Bank();
	refreshBank();
    loadCharacters();
    loadItems();
    loadMaps();
    loadMonsters();
    loadNpcs();
    loadEvents();
    soft_refresh();
}

void soft_refresh(){
    loadActiveEvents();
}

int countAllItems(string code,bool countWorn=true){
    int count = bank.count(code);
    foreach(c;charOrder){
        Character* player = characters[c];
        count+=player.countItem(code);
        if(countWorn){
            if (player.weapon_slot == code)      count++;
            if (player.rune_slot == code)        count++;
            if (player.shield_slot == code)      count++;
            if (player.helmet_slot == code)      count++;
            if (player.body_armor_slot == code)  count++;
            if (player.leg_armor_slot == code)   count++;
            if (player.boots_slot == code)       count++;
            if (player.ring1_slot == code)       count++;
            if (player.ring2_slot == code)       count++;
            if (player.amulet_slot == code)      count++;
            if (player.artifact1_slot == code)   count++;
            if (player.artifact2_slot == code)   count++;
            if (player.artifact3_slot == code)   count++;
            if (player.bag_slot == code)         count++;
        }
    }
    return count;
}

void print_items(string filepath){
    ItemSchema[] toPrint;
    foreach(item;itemList){
        if(isEquipment(item)){
            toPrint~=item;
        }
    }
    toPrint.reverse();
    JSONValue[] arr;
    foreach (item; toPrint){
        auto jva = JSONValue();
        jva["itemName"] = item.code;
        jva["lvl"] = item.level;
        jva["minAmount"] = 2;
        if(!item.craft.isNull())
            arr ~= jva;
    }

    auto jsonArray = JSONValue(arr);
    auto f = File(filepath, "w");
    f.writeln(jsonArray.toPrettyString());
    f.close();
}

bool isEquipment(ItemSchema iSchema){
  return iSchema.type == "body_armor"||
    iSchema.type == "weapon"||
    iSchema.type == "leg_armor"||
    iSchema.type == "helmet"||
    iSchema.type == "boots"||
    iSchema.type == "shield"||
    iSchema.type == "amulet"||
    iSchema.type == "ring";
}

void loadActiveEvents() {
    activeEvents.length = 0;
    int counter = 0;
    string cacheFile = CACHE_DIR~"activeEvents_cache.json";

    JSONValue[] allData;
    auto initialJson = client.getActiveEvents(1, 50);
    int totalPages = initialJson["pages"].get!int;
    
    // Process first page
    auto dataArray = initialJson["data"];
    foreach (ref eventJson; dataArray.array) {
        allData ~= eventJson;
        ActiveEventSchema event = ActiveEventSchema.fromJson(eventJson);
        activeEvents ~= event;
        counter++;
        writeln("page=1/", totalPages, " nName=", event.name);
    }
    
    // Process remaining pages
    for (int i = 2; i <= totalPages; i++) {
        auto json = client.getAllEvents(i, 50,null);
        dataArray = json["data"];
        foreach (ref eventJson; dataArray.array) {
            allData ~= eventJson;
            ActiveEventSchema event = ActiveEventSchema.fromJson(eventJson);
            activeEvents ~= event;
            counter++;
            writeln("page=", i, "/", totalPages, " nName=", event.name);
        }
    }

    // Save to cache
    //if (!allData.empty) {
        JSONValue jsonToSave;
        jsonToSave.array = allData;
        try {
            auto f = File(cacheFile, "w");
            f.writeln(jsonToSave.toPrettyString());
            f.close();
            writeln("ActiveEvent cache saved successfully to ", cacheFile);
        } catch (Exception e) {
            writeln("Failed to save Activeevent cache: ", e.msg);
        }
    //}

    writeln("Total ActiveEvents loaded: ", counter);
    writeln("Total ActiveEvents in list: ", activeEvents.length);
}

public ActiveEventSchema* getActiveEvent(string code) {
    foreach (i, ref event; activeEvents) {
        if (event.code == code) {
            return &activeEvents[i];
        }
    }
    return null;
}

void loadEvents() {
    int counter = 0;
    string cacheFile = CACHE_DIR~"events_cache.json";
    
    if (exists(cacheFile)) {
        try {
            string jsonData = readText(cacheFile);
            JSONValue parsedJson = parseJSON(jsonData);
            foreach (ref eventJson; parsedJson.array) {
                EventSchema event = EventSchema.fromJson(eventJson);
                events ~= event;
                counter++;
                writeln("Loaded from cache: nName=", event.name);
            }
            writeln("Total events loaded from cache: ", counter);
            writeln("Total events in list: ", events.length);
            return;
        } catch (Exception e) {
            writeln("event cache loading failed (", e.msg, "), fetching from network");
        }
    }

    JSONValue[] allData;
    auto initialJson = client.getAllEvents(1, 50,null);
    int totalPages = initialJson["pages"].get!int;
    
    // Process first page
    auto dataArray = initialJson["data"];
    foreach (ref eventJson; dataArray.array) {
        allData ~= eventJson;
        EventSchema event = EventSchema.fromJson(eventJson);
        events ~= event;
        counter++;
        writeln("page=1/", totalPages, " nName=", event.name);
    }
    
    // Process remaining pages
    for (int i = 2; i <= totalPages; i++) {
        auto json = client.getAllEvents(i, 50,null);
        dataArray = json["data"];
        foreach (ref eventJson; dataArray.array) {
            allData ~= eventJson;
            EventSchema event = EventSchema.fromJson(eventJson);
            events ~= event;
            counter++;
            writeln("page=", i, "/", totalPages, " nName=", event.name);
        }
    }

    // Save to cache
    if (!allData.empty) {
        JSONValue jsonToSave;
        jsonToSave.array = allData;
        try {
            auto f = File(cacheFile, "w");
            f.writeln(jsonToSave.toPrettyString());
            f.close();
            writeln("event cache saved successfully to ", cacheFile);
        } catch (Exception e) {
            writeln("Failed to save event cache: ", e.msg);
        }
    }

    writeln("Total events loaded: ", counter);
    writeln("Total events in list: ", events.length);
}

// Helper function to find NPCs by code
public EventSchema getEvent(string code) {
    foreach(event; events) {
        if(event.code == code) {
            return event;
        }
    }
    return EventSchema();
}

void loadNpcs() {
    int counter = 0;
    string cacheFile = CACHE_DIR~"npcs_cache.json";
    
    if (exists(cacheFile)) {
        try {
            string jsonData = readText(cacheFile);
            JSONValue parsedJson = parseJSON(jsonData);
            foreach (ref npcJson; parsedJson.array) {
                NpcSchema npc = NpcSchema.fromJson(npcJson);
                npcs ~= npc;
                counter++;
                writeln("Loaded from cache: nName=", npc.name);
            }
            writeln("Total NPCs loaded from cache: ", counter);
            writeln("Total NPCs in list: ", npcs.length);
            return;
        } catch (Exception e) {
            writeln("NPC cache loading failed (", e.msg, "), fetching from network");
        }
    }

    JSONValue[] allData;
    auto initialJson = client.getAllNpcs(1, 50,null);
    writeln(initialJson);
    int totalPages = initialJson["pages"].get!int;
    
    // Process first page
    auto dataArray = initialJson["data"];
    foreach (ref npcJson; dataArray.array) {
        allData ~= npcJson;
        NpcSchema npc = NpcSchema.fromJson(npcJson);
        npcs ~= npc;
        counter++;
        writeln("page=1/", totalPages, " nName=", npc.name);
    }
    
    // Process remaining pages
    for (int i = 2; i <= totalPages; i++) {
        auto json = client.getAllNpcs(i, 50,null);
        dataArray = json["data"];
        foreach (ref npcJson; dataArray.array) {
            allData ~= npcJson;
            NpcSchema npc = NpcSchema.fromJson(npcJson);
            npcs ~= npc;
            counter++;
            writeln("page=", i, "/", totalPages, " nName=", npc.name);
        }
    }

    // Save to cache
    if (!allData.empty) {
        JSONValue jsonToSave;
        jsonToSave.array = allData;
        try {
            auto f = File(cacheFile, "w");
            f.writeln(jsonToSave.toPrettyString());
            f.close();
            writeln("NPC cache saved successfully to ", cacheFile);
        } catch (Exception e) {
            writeln("Failed to save NPC cache: ", e.msg);
        }
    }

    writeln("Total NPCs loaded: ", counter);
    writeln("Total NPCs in list: ", npcs.length);
}

// Helper function to find NPCs by code
public NpcSchema getNpc(string code) {
    foreach(npc; npcs) {
        if(npc.code == code) {
            return npc;
        }
    }
    return NpcSchema();
}

void loadMonsters() {
    int counter = 0;
    string cacheFile = CACHE_DIR~"monsters_cache.json";
    
    if (exists(cacheFile)) {
        try {
            string jsonData = readText(cacheFile);
            JSONValue parsedJson = parseJSON(jsonData);
            foreach (ref monsterJson; parsedJson.array) {
                MonsterSchema monster = MonsterSchema.fromJson(monsterJson);
                monsters ~= monster;
                counter++;
                writeln("Loaded from cache: mName=", monster.name);
            }
            writeln("Total monsters loaded from cache: ", counter);
            writeln("Total monsters in list: ", monsters.length);
            return;
        } catch (Exception e) {
            writeln("Monster cache loading failed (", e.msg, "), fetching from network");
        }
    }

    JSONValue[] allData;
    auto initialJson = client.getAllMonsters(1, 50);
    int totalPages = initialJson["pages"].get!int;
    
    // Process first page
    auto dataArray = initialJson["data"];
    foreach (ref monsterJson; dataArray.array) {
        allData ~= monsterJson;
        MonsterSchema monster = MonsterSchema.fromJson(monsterJson);
        monsters ~= monster;
        counter++;
        writeln("page=1/", totalPages, " mName=", monster.name);
    }
    
    // Process remaining pages
    for (int i = 2; i <= totalPages; i++) {
        auto json = client.getAllMonsters(i, 50);
        dataArray = json["data"];
        foreach (ref monsterJson; dataArray.array) {
            allData ~= monsterJson;
            MonsterSchema monster = MonsterSchema.fromJson(monsterJson);
            monsters ~= monster;
            counter++;
            writeln("page=", i, "/", totalPages, " mName=", monster.name);
        }
    }

    // Save to cache
    if (!allData.empty) {
        JSONValue jsonToSave;
        jsonToSave.array = allData;
        try {
            auto f = File(cacheFile, "w");
            f.writeln(jsonToSave.toPrettyString());
            f.close();
            writeln("Monster cache saved successfully to ", cacheFile);
        } catch (Exception e) {
            writeln("Failed to save monster cache: ", e.msg);
        }
    }

    writeln("Total monsters loaded: ", counter);
    writeln("Total monsters in list: ", monsters.length);
}

// Helper function to find monsters by code
public MonsterSchema getMonster(string code) {
    foreach(monster; monsters) {
        if(monster.code == code) {
            return monster;
        }
    }
    return MonsterSchema();
}

void loadMaps() {
    int counter = 0;
    string cacheFile = CACHE_DIR~"maps_cache.json";
    
    if (exists(cacheFile)) {
        try {
            string jsonData = readText(cacheFile);
            JSONValue parsedJson = parseJSON(jsonData);
            foreach (ref mapJson; parsedJson.array) {
                MapSchema map = MapSchema.fromJson(mapJson);
                maps ~= map;
                counter++;
                writeln("Loaded from cache: mapName=", map.name);
            }
            writeln("Total maps loaded from cache: ", counter);
            writeln("Total maps in list: ", maps.length);
            return;
        } catch (Exception e) {
            writeln("Map cache loading failed (", e.msg, "), fetching from network");
        }
    }

    JSONValue[] allData;
    auto initialJson = client.getAllMaps(null, null, 1, 50);
    int totalPages = initialJson["pages"].get!int;
    
    // Process first page
    auto dataArray = initialJson["data"];
    foreach (ref mapJson; dataArray.array) {
        allData ~= mapJson;
        MapSchema map = MapSchema.fromJson(mapJson);
        maps ~= map;
        counter++;
        writeln("page=1/", totalPages, " mapName=", map.name);
    }
    
    // Process remaining pages
    for (int i = 2; i <= totalPages; i++) {
        auto json = client.getAllMaps(null, null, i, 50);
        dataArray = json["data"];
        foreach (ref mapJson; dataArray.array) {
            allData ~= mapJson;
            MapSchema map = MapSchema.fromJson(mapJson);
            maps ~= map;
            counter++;
            writeln("page=", i, "/", totalPages, " mapName=", map.name);
        }
    }

    // Save to cache
    if (!allData.empty) {
        JSONValue jsonToSave;
        jsonToSave.array = allData;
        try {
            auto f = File(cacheFile, "w");
            f.writeln(jsonToSave.toPrettyString());
            f.close();
            writeln("Map cache saved successfully to ", cacheFile);
        } catch (Exception e) {
            writeln("Failed to save map cache: ", e.msg);
        }
    }

    writeln("Total maps loaded: ", counter);
    writeln("Total maps in list: ", maps.length);
}

void loadItems() {
    int counter = 0;
    string cacheFile = CACHE_DIR~"items_cache.json";
    
    if (exists(cacheFile)) {
        try {
            string jsonData = readText(cacheFile);
            JSONValue parsedJson = parseJSON(jsonData);
            foreach (ref itemJson; parsedJson.array) {
                ItemSchema item = ItemSchema.fromJson(itemJson);
                itemList ~= item;
                counter++;
                writeln("Loaded from cache: iName=", item.name);
            }
            writeln("Total items loaded from cache: ", counter);
            writeln("Total items in list: ", itemList.length);
            return;
        } catch (Exception e) {
            writeln("Cache loading failed (", e.msg, "), fetching from network");
        }
    }

    JSONValue[] allData;
    auto initialJson = client.getItems("", 1, 50);
    int totalPages = initialJson["pages"].get!int;
    
    // Process first page
    auto dataArray = initialJson["data"];
    foreach (ref itemJson; dataArray.array) {
        allData ~= itemJson;
        ItemSchema item = ItemSchema.fromJson(itemJson);
        itemList ~= item;
        counter++;
        writeln("page=1/", totalPages, " iName=", item.name);
    }
    
    // Process remaining pages
    for (int i = 2; i <= totalPages; i++) {
        auto json = client.getItems("", i, 50);
        dataArray = json["data"];
        foreach (ref itemJson; dataArray.array) {
            allData ~= itemJson;
            ItemSchema item = ItemSchema.fromJson(itemJson);
            itemList ~= item;
            counter++;
            writeln("page=", i, "/", totalPages, " iName=", item.name);
        }
    }

    // Save to cache
    if (!allData.empty) {
        JSONValue jsonToSave;
        jsonToSave.array = allData;
        try {
            auto f = File(cacheFile, "w");
            f.writeln(jsonToSave.toPrettyString());
            f.close();
            writeln("Cache saved successfully to ", cacheFile);
        } catch (Exception e) {
            writeln("Failed to save cache: ", e.msg);
        }
    }

    writeln("Total items loaded: ", counter);
    writeln("Total items in list: ", itemList.length);
}

public Location findMonsterLocation(string code) {
    foreach (ref map; maps) {
        if (!map.interactions.content.isNull()) {
            if(map.interactions.content.get().code == code) {
                return Location(map.x, map.y);
            }
        }
    }
    return Location(0, 0);
}

public Location findLocation(string type, string code) {
    foreach (ref map; maps) {
        if (!map.interactions.content.isNull()) {
            if(map.interactions.content.get().code == code && map.interactions.content.get().type == type) {
                return Location(map.x, map.y);
            }
        }
    }
    return Location(0, 0);
}

public MapSchema getMap(int x, int y) {
    foreach (ref map; maps) {
        if (map.x == x && map.y == y) {
            return map;
        }
    }
    writeln("Map not found at coordinates (", x, ", ", y, ")");
    return MapSchema();
}

public ItemSchema getItem(string code)
{
    foreach(item; itemList){
        if(item.code == code){
            return item;
        }
    }
    return ItemSchema();
}

public ItemSchema getItemByName(string name)
{
    foreach(item; itemList){
        if(item.name == name){
            return item;
        }
    }
    return ItemSchema();
}
public SimpleItemSchema[] getCraftingMaterialsFor(string code)
{
    return getItem(code).craft.get().items;
}
public string getItemType(string code)
{
    return getItem(code).type;
}

public int getItemCraftLevel(string code)
{
    return getItem(code).craft.get().level;
}

bool canPoisen(MonsterSchema ms){
    if(ms.effects.length > 0){
        foreach(effect;ms.effects){
            if(effect.code == "poison"){
                return true;
            }
        }
    }
    return false;
}

class Bank{
	SimpleItemSchema[] items;
    int maxSlots;
    int expansions;
    int nextExpansionCost;
    int gold;
    int count(string code){
        int count = 0;
        foreach(item; items){
            if(item.code == code){
                count += item.quantity;
            }
        }
        return count;
    }
}

public void refreshBank() {
    import std.json : JSONValue;

    void processItemsPage(JSONValue data) {
        foreach (item; data.array) {
            auto sis = SimpleItemSchema.fromJson(item);
            if (sis.quantity > 0) {
                bank.items ~= sis;
            }
        }
    }

    void updateBankDetails() {
        auto detailsResponse = client.getBankDetails();
        auto details = detailsResponse["data"];
        bank.maxSlots = details["slots"].get!int;
        bank.expansions = details["expansions"].get!int;
        bank.nextExpansionCost = details["next_expansion_cost"].get!int;
        bank.gold = details["gold"].get!int;
    }

    enum pageSize = 100;
    enum initialPage = 1;

    auto itemsResponse = client.getBankItems("", initialPage, pageSize);
    writeln(itemsResponse);
    int totalItems = itemsResponse["total"].get!int;
    bank.items.length = 0;

    processItemsPage(itemsResponse["data"]);

    int totalPages = (totalItems + pageSize - 1) / pageSize;
    for (int currentPage = initialPage + 1; currentPage <= totalPages; currentPage++) {
        auto pageResponse = client.getBankItems("", currentPage, pageSize);
        processItemsPage(pageResponse["data"]);
    }

    updateBankDetails();
}

public void loadCharacters()
{
    auto json = client.getCharacters();

    auto dataArray = json["data"];
    charOrder.length = dataArray.array.length; // Resize charOrder to match the number of characters
    int i = 0;
    foreach (item; dataArray.array) {
        string name = item["name"].get!string;
        Character* p = new Character;
        p.initStruct(item);
        characters[name] = p;
        if(exists(CACHE_DIR~"character_"~p.name~".json")){
            p.loadAttachments(CACHE_DIR~"character_"~p.name~".json");
        }
        writeln(p.color, "Loaded Char: ", name);
        charOrder[i] = name;
        i++;
    }
}

public Character* getCharacter(int id){
    return characters[charOrder[id]];
}

public Character* getCharacter(string name){
    return characters[name];
}
