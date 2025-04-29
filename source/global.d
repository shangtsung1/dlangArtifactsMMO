module global;

import std.stdio;
import std.file;
import std.json;
import std.range;
import std.typecons : Nullable;

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


__gshared Bank bank;
__gshared api.schema.Character*[string] characters;
__gshared string[] charOrder;
__gshared ItemSchema[] itemList;
__gshared ArtifactMMOClient client;
__gshared MapSchema[] maps;
__gshared MonsterSchema[] monsters;
__gshared NpcSchema[] npcs;

Location LOC_COPPER = Location(2,0);
Location LOC_COAL = Location(1,6);
Location LOC_IRON = Location(1,7);
Location LOC_GOLD = Location(6,-3);

Location LOC_ASH = Location(-1,0);
Location LOC_SPRUCE = Location(2,6);
Location LOC_BIRCH = Location(3,5);
Location LOC_DEADTREE = Location(9,6);

Location LOC_SUNFLOWER = Location(2,2);
Location LOC_NETTLE = Location(7,14);
Location LOC_GLOWSTEM = Location(1,10);

Location LOC_GUDGEON = Location(4,2);
Location LOC_SHRIMP = Location(5,2);
Location LOC_TROUT = Location(7,12);
Location LOC_BASS = Location(6,12);
Location LOC_SALMON = Location(-2,-4);

Location LOC_CHICKEN = Location(0,1);
Location LOC_COW = Location(0,2);
Location LOC_PIG = Location(-3,-3);

Location LOC_GREENSLIME = Location(0,-1);
Location LOC_REDSLIME = Location(1,-1);
Location LOC_BLUESLIME = Location(2,-1);
Location LOC_YELLOWSLIME = Location(4,-1);

Location LOC_MUSHMUSH = Location(5,3);
Location LOC_FLYINGSERPENT = Location(5,4);
Location LOC_WOLF = Location(-2,1);

Location LOC_HIGHWAYMAN = Location(2,8);
Location LOC_SKELETON = Location(8,6);



void global_init(string token)
{
    client = new ArtifactMMOClient(token);
    client.initClient();
	bank = new Bank();
	refreshBank();
    loadCharacters();
    loadItems();
    loadMaps();
    loadMonsters();
    loadNpcs();
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

class Bank{
	SimpleItemSchema[] items;

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

public void refreshBank(){
    auto json = client.getBankItems("",1,100)["data"];
    //todo check response
    bank.items.length = 0;
    foreach(item; json.array){
        SimpleItemSchema sis = SimpleItemSchema.fromJson(item);
        if(sis.quantity > 0){
            bank.items ~= sis;
        }
    }
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

