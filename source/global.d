module global;

import std.stdio;
import std.file;
import std.json;
import std.range;
import std.typecons : Nullable;

static import api.schema;
static import api.ammo;

alias ArtifactMMOClient = api.ammo.ArtifactMMOClient;
alias Location = api.schema.Location;
alias SimpleItemSchema = api.schema.SimpleItemSchema;
alias Character = api.schema.Character;
alias ItemSchema = api.schema.ItemSchema;


__gshared Bank bank;
__gshared api.schema.Character*[string] characters;
__gshared string[] charOrder; // Changed to a dynamic array
__gshared ItemSchema[] itemList;
__gshared ArtifactMMOClient client;


void global_init(string token)
{
    client = new ArtifactMMOClient(token);
    client.initClient();
	bank = new Bank();
	refreshBank();
    loadCharacters();
    loadItems();
}

void loadItems()
{
    int counter = 0;
    string cacheFile = "items_cache.json";
    
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

    // Cache doesn't exist or failed to load - fetch fresh data
    JSONValue[] allData;
    int totalPages = client.getItems("", 1, 50)["pages"].get!int;
    
    for (int i = 1; i < totalPages + 1; i++) {
        auto json = client.getItems("", i, 50);
        auto dataArray = json["data"];
        
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
        writeln(p.color, "Loaded Char: ", name);
        charOrder[i] = name;
        i++;
    }
}

