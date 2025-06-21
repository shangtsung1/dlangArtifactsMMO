module api.schema;

import std.json;
import std.stdio;
import std.regex;
import std.datetime; // For SysTime, Clock
import std.typecons;
import std.conv;
import std.variant; 
import std.algorithm: map;
import std.array;

import global;
import api.ammo;

struct InventorySlot {
    int slot;
    string code;
    int quantity;
}

struct Location{
    int x;
    int y;
}

class BooleanObject : Object {
    bool value;
    this(bool v) { value = v; }
}

class IntegerObject : Object {
    int value;
    this(int v) { value = v; }
}

class DoubleObject : Object {
    double value;
    this(double v) { value = v; }
}

class StringObject : Object {
    string value;
    this(string v) { value = v; }
}

struct Character {
    string name;
    string account;
    string skin;
    int level;
    int xp;
    int max_xp;
    int gold;
    int speed;
    int mining_level;
    int mining_xp;
    int mining_max_xp;
    int woodcutting_level;
    int woodcutting_xp;
    int woodcutting_max_xp;
    int fishing_level;
    int fishing_xp;
    int fishing_max_xp;
    int weaponcrafting_level;
    int weaponcrafting_xp;
    int weaponcrafting_max_xp;
    int gearcrafting_level;
    int gearcrafting_xp;
    int gearcrafting_max_xp;
    int jewelrycrafting_level;
    int jewelrycrafting_xp;
    int jewelrycrafting_max_xp;
    int cooking_level;
    int cooking_xp;
    int cooking_max_xp;
    int alchemy_level;
    int alchemy_xp;
    int alchemy_max_xp;
    int hp;
    int max_hp;
    int haste;
    int critical_strike;
    int wisdom;
    int prospecting;
    int attack_fire;
    int attack_earth;
    int attack_water;
    int attack_air;
    int dmg;
    int dmg_fire;
    int dmg_earth;
    int dmg_water;
    int dmg_air;
    int res_fire;
    int res_earth;
    int res_water;
    int res_air;
    int x;
    int y;
    int cooldown;
    long cooldown_expiration;
    string weapon_slot;
    string rune_slot;
    string shield_slot;
    string helmet_slot;
    string body_armor_slot;
    string leg_armor_slot;
    string boots_slot;
    string ring1_slot;
    string ring2_slot;
    string amulet_slot;
    string artifact1_slot;
    string artifact2_slot;
    string artifact3_slot;
    string utility1_slot;
    int utility1_slot_quantity;
    string utility2_slot;
    int utility2_slot_quantity;
    string bag_slot;
    string task;
    string task_type;
    int task_progress;
    int task_total;
    int inventory_max_items;
    InventorySlot[] inventory;
    Nullable!CooldownSchema cooldown_schema;

    string color = "\x1b[37m";
    Object*[string] attachments;

    int gathering() {
        JSONValue result = client.gathering(name);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int rest() {
        auto result = client.restEntity(name);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int equip( string code, string slot, int quantity = 1) {
        slot = slot.replace("_slot", "");//allow both with _slot and without
        auto result = client.equipEntity(name, code, slot, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int unequip( string slot, int quantity = 1) {
        slot = slot.replace("_slot", "");//allow both with _slot and without
        auto result = client.unequipEntity(name, slot, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int useItem( string code, int quantity) {
        auto result = client.useItem(name, code, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int fight() {
        auto result = client.fight(name);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int crafting( string code, int quantity = 1) {
        auto result = client.crafting(name, code, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int depositGold( int quantity) {
        auto result = client.depositGold(name, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        refreshBank();
        return result["statusCode"].get!int;
    }

    int depositItem( string code, int quantity) {
        auto result = client.depositItem(name, code, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        refreshBank();
        return result["statusCode"].get!int;
    }

    int withdrawItem( string code, int quantity) {
        auto result = client.withdrawItem(name, code, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        refreshBank();
        return result["statusCode"].get!int;
    }

    int withdrawGold( int quantity) {
        auto result = client.withdrawGold(name, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        refreshBank();
        return result["statusCode"].get!int;
    }

    int buyExpansion() {
        auto result = client.buyExpansion(name);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        refreshBank();
        return result["statusCode"].get!int;
    }

    int npcBuy( string code, int quantity) {
        auto result = client.npcBuy(name, code, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int npcSell( string code, int quantity) {
        auto result = client.npcSell(name, code, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int recycling( string code, int quantity = 1) {
        auto result = client.recycling(name, code, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int geBuy( string id, int quantity) {
        auto result = client.geBuy(name, id, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int geSell( string code, int quantity, int price) {
        auto result = client.geSell(name, code, quantity, price);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int geCancel( string id) {
        auto result = client.geCancel(name, id);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int taskComplete() {
        auto result = client.taskComplete(name);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int taskExchange() {
        auto result = client.taskExchange(name);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int taskNew() {
        auto result = client.taskNew(name);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int taskCancel() {
        auto result = client.taskCancel(name);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int taskTrade( string code, int quantity) {
        auto result = client.taskTrade(name, code, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int deleteItem(string code, int quantity) {
        auto result = client.deleteItem(name, code, quantity);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    int move( Location loc){
        return move(loc.x,loc.y);
    }

    int move( int x, int y){
        JSONValue result = client.move(name,x,y);
        if(result["statusCode"].get!int != 200){
            return result["statusCode"].get!int;
        }
        parse(result);
        return result["statusCode"].get!int;
    }

    void parse(JSONValue json){
        this.update(json["data"]["character"]);
        if(json["data"].type != JSONType.NULL && json["data"]["cooldown"].type != JSONType.NULL){
            this.cooldown_schema = CooldownSchema.fromJson(json["data"]["cooldown"]);
        }
    }

    bool onCooldown() {
        long now = Clock.currTime().toUTC().toUnixTime();
        return now < this.cooldown_expiration;
    }

    long cooldownLeft() {
        long now = Clock.currTime().toUTC().toUnixTime();
        long exp = this.cooldown_expiration - now;
        return exp > 0 ? exp : 0;
    }

    int countInventory(){
        int count = 0;
        foreach(i; inventory){
            count += i.quantity; 
        }
        return count;
    }

    bool inventoryContains(string code, int quantity = 1){
        foreach(i; inventory){
            if(i.code == code && i.quantity >= quantity){
                return true;
            }
        }
        return false;
    }

    int countUnequippedItem(string code){
        int count = 0;
        foreach(i; inventory){
            if(i.code == code && i.slot > 0){
                return count+=i.quantity;
            }
        }
        return count;
    }

    int countItem(string code){
        int count = 0;
        foreach(i; inventory){
            if(i.code == code){
                return count+=i.quantity;
            }
        }
        return count;
    }

    int getEquippedItemCount(string slot){
        final switch(slot){
            case "utility1":
                return utility1_slot_quantity;
            case "utility2":
                return utility2_slot_quantity;
        }
        return 0;
    }

    string getEquippedItem(string slot){
        final switch(slot){
            case "weapon":
                return weapon_slot;
            case "shield":
                return shield_slot;
            case "helmet":  
                return helmet_slot; 
            case "body_armor":      
                return body_armor_slot;
            case "leg_armor":
                return leg_armor_slot;
            case "boots":
                return boots_slot;
            case "ring1":
                return ring1_slot;
            case "ring2":
                return ring2_slot;
            case "amulet":
                return amulet_slot;
            case "artifact1":
                return artifact1_slot;
            case "artifact2":
                return artifact2_slot;
            case "artifact3":
                return artifact3_slot;
            case "utility1":
                return utility1_slot;
            case "utility2":
                return utility2_slot;
            case "rune":
                return rune_slot;
            case "bag":
                return bag_slot;

        }
        return "none";
    }

    int freeInventorySpaces(){
        return inventory_max_items-countInventory();
    }

    string getSlot(string slot) {
        switch(slot) {
            case "weapon":
                return weapon_slot;
            case "shield":
                return shield_slot;
            case "helmet":
                return helmet_slot;
            case "body_armor":
                return body_armor_slot;
            case "leg_armor":
                return leg_armor_slot;
            case "boots":
                return boots_slot;
            case "ring1":
                return ring1_slot;
            case "ring2":
                return ring2_slot;
            case "amulet":
                return amulet_slot;
            case "artifact1":
                return artifact1_slot;
            case "artifact2":
                return artifact2_slot;
            case "artifact3":
                return artifact3_slot;
            case "utility1":
                return utility1_slot;
            case "utility2":
                return utility2_slot;
            case "weapon_slot":
                return weapon_slot;
            case "shield_slot":
                return shield_slot;
            case "helmet_slot":
                return helmet_slot;
            case "body_armor_slot":
                return body_armor_slot;
            case "leg_armor_slot":
                return leg_armor_slot;
            case "boots_slot":
                return boots_slot;
            case "ring1_slot":
                return ring1_slot;
            case "ring2_slot":
                return ring2_slot;
            case "amulet_slot":
                return amulet_slot;
            case "artifact1_slot":
                return artifact1_slot;
            case "artifact2_slot":
                return artifact2_slot;
            case "artifact3_slot":
                return artifact3_slot;
            case "utility1_slot":
                return utility1_slot;
            case "utility2_slot":
                return utility2_slot;
            default:
                return "wat?"~slot;
        }
    }

    void initStruct(JSONValue json){
        this.attachments = cast(Object*[string])new Object[string];
        update(json);
    }

    void update(JSONValue json) {
        // Basic fields
        this.name = json["name"].get!string;
        writeln("updated ",name);
        this.account = json["account"].get!string;
        this.skin = json["skin"].get!string;
        if(this.skin == "men1"){
            color = "\x1b[31m";
        }
        else if(this.skin == "men2"){
            color = "\x1b[32m";
        }
        else if(this.skin == "men3"){
            color = "\x1b[33m";
        }

        else if(this.skin == "women1"){
            color = "\x1b[34m";
        }
        else if(this.skin == "women2"){
            color = "\x1b[35m";
        }
        else if(this.skin == "women3"){
            color = "\x1b[36m";
        }
        // Level and XP
        this.level = json["level"].get!int;
        this.xp = json["xp"].get!int;
        this.max_xp = json["max_xp"].get!int;
        
        // Resources
        this.gold = json["gold"].get!int;
        this.speed = json["speed"].get!int;

        // Skills - Mining
        this.mining_level = json["mining_level"].get!int;
        this.mining_xp = json["mining_xp"].get!int;
        this.mining_max_xp = json["mining_max_xp"].get!int;

        // Woodcutting
        this.woodcutting_level = json["woodcutting_level"].get!int;
        this.woodcutting_xp = json["woodcutting_xp"].get!int;
        this.woodcutting_max_xp = json["woodcutting_max_xp"].get!int;

        // Fishing
        this.fishing_level = json["fishing_level"].get!int;
        this.fishing_xp = json["fishing_xp"].get!int;
        this.fishing_max_xp = json["fishing_max_xp"].get!int;

        // Crafting skills
        this.weaponcrafting_level = json["weaponcrafting_level"].get!int;
        this.weaponcrafting_xp = json["weaponcrafting_xp"].get!int;
        this.weaponcrafting_max_xp = json["weaponcrafting_max_xp"].get!int;

        this.gearcrafting_level = json["gearcrafting_level"].get!int;
        this.gearcrafting_xp = json["gearcrafting_xp"].get!int;
        this.gearcrafting_max_xp = json["gearcrafting_max_xp"].get!int;

        this.jewelrycrafting_level = json["jewelrycrafting_level"].get!int;
        this.jewelrycrafting_xp = json["jewelrycrafting_xp"].get!int;
        this.jewelrycrafting_max_xp = json["jewelrycrafting_max_xp"].get!int;

        // Cooking
        this.cooking_level = json["cooking_level"].get!int;
        this.cooking_xp = json["cooking_xp"].get!int;
        this.cooking_max_xp = json["cooking_max_xp"].get!int;

        // Alchemy
        this.alchemy_level = json["alchemy_level"].get!int;
        this.alchemy_xp = json["alchemy_xp"].get!int;
        this.alchemy_max_xp = json["alchemy_max_xp"].get!int;

        // Combat stats
        this.hp = json["hp"].get!int;
        this.max_hp = json["max_hp"].get!int;
        this.haste = json["haste"].get!int;
        this.critical_strike = json["critical_strike"].get!int;
        this.wisdom = json["wisdom"].get!int;
        this.prospecting = json["prospecting"].get!int;

        // Attack stats
        this.attack_fire = json["attack_fire"].get!int;
        this.attack_earth = json["attack_earth"].get!int;
        this.attack_water = json["attack_water"].get!int;
        this.attack_air = json["attack_air"].get!int;

        // Damage modifiers
        this.dmg = json["dmg"].get!int;
        this.dmg_fire = json["dmg_fire"].get!int;
        this.dmg_earth = json["dmg_earth"].get!int;
        this.dmg_water = json["dmg_water"].get!int;
        this.dmg_air = json["dmg_air"].get!int;

        // Resistances
        this.res_fire = json["res_fire"].get!int;
        this.res_earth = json["res_earth"].get!int;
        this.res_water = json["res_water"].get!int;
        this.res_air = json["res_air"].get!int;

        // Position and cooldown
        this.x = json["x"].get!int;
        this.y = json["y"].get!int;
        this.cooldown = json["cooldown"].get!int;
        this.cooldown_expiration = SysTime.fromISOExtString(json["cooldown_expiration"].get!string).toUnixTime();

        // Equipment slots
        this.weapon_slot = json["weapon_slot"].get!string;
        this.rune_slot = json["rune_slot"].get!string;
        this.shield_slot = json["shield_slot"].get!string;
        this.helmet_slot = json["helmet_slot"].get!string;
        this.body_armor_slot = json["body_armor_slot"].get!string;
        this.leg_armor_slot = json["leg_armor_slot"].get!string;
        this.boots_slot = json["boots_slot"].get!string;
        this.ring1_slot = json["ring1_slot"].get!string;
        this.ring2_slot = json["ring2_slot"].get!string;
        this.amulet_slot = json["amulet_slot"].get!string;
        this.artifact1_slot = json["artifact1_slot"].get!string;
        this.artifact2_slot = json["artifact2_slot"].get!string;
        this.artifact3_slot = json["artifact3_slot"].get!string;
        
        // Utility slots
        this.utility1_slot = json["utility1_slot"].get!string;
        this.utility1_slot_quantity = json["utility1_slot_quantity"].get!int;
        this.utility2_slot = json["utility2_slot"].get!string;
        this.utility2_slot_quantity = json["utility2_slot_quantity"].get!int;
        
        this.bag_slot = json["bag_slot"].get!string;

        // Task tracking
        this.task = json["task"].get!string;
        this.task_type = json["task_type"].get!string;
        this.task_progress = json["task_progress"].get!int;
        this.task_total = json["task_total"].get!int;

        // Inventory
        this.inventory_max_items = json["inventory_max_items"].get!int;
        this.inventory = [];
        foreach(item; json["inventory"].array) {
            this.inventory ~= InventorySlot(
                item["slot"].get!int,
                item["code"].get!string,
                item["quantity"].get!int
            );
        }
    }

    void setBoolean(string key, bool value) {
        attachments[key] = cast(Object*)(new BooleanObject(value));
    }
    
    bool getBoolean(string key) {
        auto obj = attachments.get(key, null);
        if (auto bo = cast(BooleanObject) obj) {
            return bo.value;
        }
        return false;
    }

    void setInteger(string key, int value) {
        attachments[key] = cast(Object*)new IntegerObject(value);
    }
    
    int getInteger(string key) {
        auto obj = attachments.get(key, null);
        if (auto io = cast(IntegerObject) obj) {
            return io.value;
        }
        return 0;
    }

    void setDouble(string key, double value) {
        attachments[key] = cast(Object*)new DoubleObject(value);
    }
    
    double getDouble(string key) {
        auto obj = attachments.get(key, null);
        if (auto dbl = cast(DoubleObject) obj) {
            return dbl.value;
        }
        return double.nan;
    }

    void setString(string key, string value) {
        attachments[key] = cast(Object*)new StringObject(value);
    }
    
    string getString(string key) {
        auto obj = attachments.get(key, null);
        if (auto str = cast(StringObject) obj) {
            return str.value;
        }
        return null;
    }
    void saveAttachments( string filename) {
        JSONValue[] entries;

        foreach (key, obj; attachments) {
            JSONValue entry;

            if (auto bo = cast(BooleanObject)obj) {
                entry = parseJSON(`{"key": "` ~ key ~ `", "type": "boolean", "value": ` ~ to!string(bo.value) ~ `}`);
            } else if (auto io = cast(IntegerObject)obj) {
                entry = parseJSON(`{"key": "` ~ key ~ `", "type": "integer", "value": ` ~ to!string(io.value) ~ `}`);
            } else if (auto dbl = cast(DoubleObject)obj) {
                entry = parseJSON(`{"key": "` ~ key ~ `", "type": "double", "value": ` ~ to!string(dbl.value) ~ `}`);
            } else if (auto str = cast(StringObject)obj) {
                entry = parseJSON(`{"key": "` ~ key ~ `", "type": "string", "value": "` ~ str.value ~ `"}`);
            } else {
                continue; // Skip unknown types
            }

            entries ~= entry;
        }

        auto json = JSONValue(entries);
        static import std.file;
        std.file.write(filename, json.toPrettyString());
    }
    void loadAttachments(string filename) {
        static import std.file;
        string data = std.file.readText(filename);
        JSONValue json = parseJSON(data);

        foreach (entry; json.array()) {
            string key = entry["key"].str;
            string type = entry["type"].str;
            JSONValue value = entry["value"];

            Object* obj;

            switch (type) {
                case "boolean":
                    obj = cast(Object*)new BooleanObject(value.get!bool);
                    break;
                case "integer":
                    obj = cast(Object*)new IntegerObject(value.get!int);
                    break;
                case "double":
                    obj = cast(Object*)new DoubleObject(value.floating());
                    break;
                case "string":
                    obj = cast(Object*)new StringObject(value.str());
                    break;
                default:
                    continue; // Skip unknown types
            }

            attachments[key] = obj;
        }
    }
}

enum FightResult {
    win,
    loss
}

struct BlockedHitsSchema {
    int fire;
    int earth;
    int water;
    int air;
    int total;
    
    static BlockedHitsSchema fromJson(JSONValue json) {
        return BlockedHitsSchema(
            json["fire"].get!int,
            json["earth"].get!int,
            json["water"].get!int,
            json["air"].get!int,
            json["total"].get!int
        );
    }
}

struct FightDropSchema {
    string code;
    int quantity;
    
    static FightDropSchema fromJson(JSONValue json) {
        return FightDropSchema(
            json["code"].get!string,
            json["quantity"].get!int
        );
    }
}

struct FightSchema {
    int xp;
    int gold;
    FightDropSchema[] drops;
    int turns;
    BlockedHitsSchema monster_blocked_hits;
    BlockedHitsSchema player_blocked_hits;
    string[] logs;
    FightResult result;
    
    static FightSchema fromJson(JSONValue json) {
        FightSchema fight;
        
        fight.xp = json["xp"].get!int;
        fight.gold = json["gold"].get!int;
        fight.turns = json["turns"].get!int;
        fight.result = json["result"].get!FightResult();
        
        // Parse drops
        foreach(item; json["drops"].array) {
            fight.drops ~= FightDropSchema.fromJson(item);
        }
        
        // Parse blocked hits
        fight.monster_blocked_hits = BlockedHitsSchema.fromJson(json["monster_blocked_hits"]);
        fight.player_blocked_hits = BlockedHitsSchema.fromJson(json["player_blocked_hits"]);
        
        // Parse logs
        foreach(log; json["logs"].array) {
            fight.logs ~= log.get!string;
        }
        
        return fight;
    }
}

enum CraftingSkill {
    weaponcrafting,
    gearcrafting,
    jewelrycrafting,
    cooking,
    woodcutting,
    mining,
    alchemy
}

struct SimpleEffectSchema {
    string code;
    int value;
    
    static SimpleEffectSchema fromJson(JSONValue json) {
        return SimpleEffectSchema(
            json["code"].get!string,
            json["value"].get!int
        );
    }

    JSONValue toJson() const {
        auto obj = JSONValue();
        obj["code"] = code;
        obj["value"] = value;
        return obj;
    }
}

struct SimpleItemSchema {
    string code;
    int quantity;
    
    static SimpleItemSchema fromJson(JSONValue json) {
        return SimpleItemSchema(
            json["code"].get!string,
            json["quantity"].get!int
        );
    }

    JSONValue toJson() {
        auto obj = JSONValue();
        obj["code"] = code;
        obj["quantity"] = quantity;
        return obj;
    }

    static SimpleItemSchema fromJson(string json) {
        return fromJson(parseJSON(json));
    }
}

struct CraftSchema {
    CraftingSkill skill;
    string skillString;
    int level;
    SimpleItemSchema[] items;
    int quantity;
    
    static CraftSchema fromJson(JSONValue json) {
        CraftSchema craft;
        
        craft.skill = skillForString(json["skill"].get!string);
        craft.skillString = json["skill"].get!string;
        craft.level = json["level"].get!int;
        craft.quantity = json["quantity"].get!int;
        
        foreach(item; json["items"].array) {
            craft.items ~= SimpleItemSchema.fromJson(item);
        }
        
        return craft;
    }

    JSONValue toJson() {
        auto obj = JSONValue();
        obj["skill"] = skillString; // maintain string form
        obj["level"] = level;
        obj["quantity"] = quantity;

        auto itemsArray = JSONValue(JSONType.array);
        foreach (item; items) {
            itemsArray.array ~= item.toJson();
        }
        obj["items"] = itemsArray;

        return obj;
    }
}

public CraftingSkill skillForString(string skill) {
    switch (skill) {
        case "weaponcrafting": return CraftingSkill.weaponcrafting;
        case "gearcrafting": return CraftingSkill.gearcrafting;
        case "jewelrycrafting": return CraftingSkill.jewelrycrafting;
        case "cooking": return CraftingSkill.cooking;
        case "woodcutting": return CraftingSkill.woodcutting;
        case "mining": return CraftingSkill.mining;
        case "alchemy": return CraftingSkill.alchemy;
        default: throw new Exception("Unknown crafting skill: " ~ skill);
    }
}

struct ItemSchema {
    string name;
    string code;
    int level;
    string type;
    string subtype;
    string description;
    SimpleEffectSchema[] effects;
    Nullable!CraftSchema craft;
    bool tradeable;

    JSONValue toJson(){
        auto obj = JSONValue();
        obj["name"] = name;
        obj["code"] = code;
        obj["level"] = level;
        obj["type"] = type;
        obj["subtype"] = subtype;
        obj["description"] = description;
        obj["tradeable"] = tradeable;

        return obj;
    }
    
    static ItemSchema fromJson(JSONValue json) {
        ItemSchema item;
        
        item.name = json["name"].get!string;
        item.code = json["code"].get!string;
        item.level = json["level"].get!int;
        item.type = json["type"].get!string;
        item.subtype = json["subtype"].get!string;
        item.description = json["description"].get!string;
        item.tradeable = json["tradeable"].get!bool;
        
        // Parse effects array
        foreach(effect; json["effects"].array) {
            item.effects ~= SimpleEffectSchema.fromJson(effect);
        }
        
        // Handle nullable craft
        if (json["craft"].type != JSONType.NULL) {
            item.craft = Nullable!CraftSchema(CraftSchema.fromJson(json["craft"]));
        }
        
        return item;
    }
}

struct DropSchema {
    string code;
    int rate;
    int min_quantity;
    int max_quantity;
    
    static DropSchema fromJson(JSONValue json) {
        string code = json["code"].get!string;
        int rate = ("rate" in json.object) ? json["rate"].get!int : 1;
        int min_quantity = ("min_quantity" in json.object) ? json["min_quantity"].get!int : 1;
        int max_quantity = ("max_quantity" in json.object) ? json["max_quantity"].get!int : 1;
        return DropSchema(code, rate, min_quantity, max_quantity);
    }
}

struct MonsterSchema {
    string name;
    string code;
    int level;
    int hp;
    int attack_fire;
    int attack_earth;
    int attack_water;
    int attack_air;
    int res_fire;
    int res_earth;
    int res_water;
    int res_air;
    int critical_strike;
    SimpleEffectSchema[] effects;
    int min_gold;
    int max_gold;
    DropSchema[] drops;
    
    static MonsterSchema fromJson(JSONValue json) {
        return MonsterSchema(
            json["name"].get!string,
            json["code"].get!string,
            json["level"].get!int,
            json["hp"].get!int,
            json["attack_fire"].get!int,
            json["attack_earth"].get!int,
            json["attack_water"].get!int,
            json["attack_air"].get!int,
            json["res_fire"].get!int,
            json["res_earth"].get!int,
            json["res_water"].get!int,
            json["res_air"].get!int,
            json["critical_strike"].get!int,
            json["effects"].array.map!(x => SimpleEffectSchema.fromJson(x)).array,
            json["min_gold"].get!int,
            json["max_gold"].get!int,
            json["drops"].array.map!(x => DropSchema.fromJson(x)).array
        );
    }
}

struct SkillInfoSchema {
    int xp;
    DropSchema[] items;
    
    static SkillInfoSchema fromJson(JSONValue json) {
        SkillInfoSchema info;
        info.xp = json["xp"].get!int;
        foreach(item; json["items"].array) {
            info.items ~= DropSchema.fromJson(item);
        }
        return info;
    }
}

struct GoldSchema {
    int quantity;
    
    static GoldSchema fromJson(JSONValue json) {
        return GoldSchema(json["quantity"].get!int);
    }
}

struct BankExtensionSchema {
    int price;
    
    static BankExtensionSchema fromJson(JSONValue json) {
        return BankExtensionSchema(json["price"].get!int);
    }
}

struct NpcItemTransactionSchema {
    string code;
    int quantity;
    int price;
    int total_price;
    
    static NpcItemTransactionSchema fromJson(JSONValue json) {
        return NpcItemTransactionSchema(
            json["code"].get!string,
            json["quantity"].get!int,
            json["price"].get!int,
            json["total_price"].get!int
        );
    }
}

struct RecyclingItemsSchema {
    DropSchema[] items;
    
    static RecyclingItemsSchema fromJson(JSONValue json) {
        RecyclingItemsSchema recycling;
        foreach(item; json["items"].array) {
            recycling.items ~= DropSchema.fromJson(item);
        }
        return recycling;
    }
}

struct GETransactionSchema {
    string id;
    string code;
    int quantity;
    int price;
    int total_price;
    
    static GETransactionSchema fromJson(JSONValue json) {
        return GETransactionSchema(
            json["id"].get!string,
            json["code"].get!string,
            json["quantity"].get!int,
            json["price"].get!int,
            json["total_price"].get!int
        );
    }
}

struct GEOrderCreatedSchema {
    string id;
    string created_at;
    string code;
    int quantity;
    int price;
    int total_price;
    int tax;
    
    static GEOrderCreatedSchema fromJson(JSONValue json) {
        return GEOrderCreatedSchema(
            json["id"].get!string,
            json["created_at"].get!string,
            json["code"].get!string,
            json["quantity"].get!int,
            json["price"].get!int,
            json["total_price"].get!int,
            json["tax"].get!int
        );
    }
}

struct RewardsSchema {
    SimpleItemSchema[] items;
    int gold;
    
    static RewardsSchema fromJson(JSONValue json) {
        RewardsSchema rewards;
        foreach(item; json["items"].array) {
            rewards.items ~= SimpleItemSchema.fromJson(item);
        }
        rewards.gold = json["gold"].get!int;
        return rewards;
    }
}

enum CooldownReason {
    movement,
    fight,
    crafting,
    gathering,
    buy_ge,
    sell_ge,
    buy_npc,
    sell_npc,
    cancel_ge,
    delete_item,
    deposit,
    withdraw,
    deposit_gold,
    withdraw_gold,
    equip,
    unequip,
    task,
    christmas_exchange,
    recycling,
    rest,
    use,
    buy_bank_expansion
}

static CooldownReason reasonFromString(string value) {
    switch (value) {
        case "movement": return CooldownReason.movement;
        case "fight": return CooldownReason.fight;
        case "crafting": return CooldownReason.crafting;
        case "gathering": return CooldownReason.gathering;
        case "buy_ge": return CooldownReason.buy_ge;
        case "sell_ge": return CooldownReason.sell_ge;
        case "buy_npc": return CooldownReason.buy_npc;
        case "sell_npc": return CooldownReason.sell_npc;
        case "cancel_ge": return CooldownReason.cancel_ge;
        case "delete_item": return CooldownReason.delete_item;
        case "deposit": return CooldownReason.deposit;
        case "withdraw": return CooldownReason.withdraw;
        case "deposit_gold": return CooldownReason.deposit_gold;
        case "withdraw_gold": return CooldownReason.withdraw_gold;
        case "equip": return CooldownReason.equip;
        case "unequip": return CooldownReason.unequip;
        case "task": return CooldownReason.task;
        case "christmas_exchange": return CooldownReason.christmas_exchange;
        case "recycling": return CooldownReason.recycling;
        case "rest": return CooldownReason.rest;
        case "use": return CooldownReason.use;
        case "buy_bank_expansion": return CooldownReason.buy_bank_expansion;
        default: throw new Exception("Unknown CooldownReason: " ~ value);
    }
}

struct CooldownSchema {
    int total_seconds;
    int remaining_seconds;
    string started_at;
    string expiration;
    CooldownReason reason;
    
    static CooldownSchema fromJson(JSONValue json) {
        return CooldownSchema(
            json["total_seconds"].get!int,
            json["remaining_seconds"].get!int,
            json["started_at"].get!string,
            json["expiration"].get!string,
            reasonFromString(json["reason"].get!string)
        );
    }

    SysTime getStartedAt() const {
        return SysTime.fromISOExtString(started_at);
    }

    // Get expiration as SysTime object (UTC)
    SysTime getExpiration() const {
        return SysTime.fromISOExtString(expiration);
    }

    // Check if cooldown is active
    bool isActive() const {
        return Clock.currTime().toUTC() < getExpiration();
    }

    // Calculate real-time remaining seconds
    int getRemainingSeconds() const {
        auto now = Clock.currTime().toUTC();
        auto exp = getExpiration();
        if (now >= exp) return 0;
        return cast(int)(exp - now).total!"seconds"();
    }

    // Calculate elapsed seconds
    int getElapsedSeconds() const {
        auto now = Clock.currTime().toUTC().toUTC();
        return cast(int)(now - getStartedAt()).total!"seconds"();
    }

    // Get progress percentage (0.0 to 100.0)
    double getProgressPercentage() const {
        if (total_seconds <= 0) return 100.0;
        double elapsed = getElapsedSeconds();
        double percent = (elapsed / total_seconds) * 100.0;
        return percent < 100.0 ? percent : 100.0;
    }
}

struct MapContentSchema {
    string type;
    string code;
    
    static MapContentSchema fromJson(JSONValue json) {
        return MapContentSchema(
            json["type"].get!string,
            json["code"].get!string
        );
    }
}

struct MapSchema {
    string name;
    string skin;
    int x;
    int y;
    Nullable!MapContentSchema content;
    
    static MapSchema fromJson(JSONValue json) {
        auto content = Nullable!MapContentSchema.init;
        if (json["content"].type != JSONType.NULL) {
            content = Nullable!MapContentSchema(MapContentSchema.fromJson(json["content"]));
        }
        
        return MapSchema(
            json["name"].get!string,
            json["skin"].get!string,
            json["x"].get!int,
            json["y"].get!int,
            content
        );
    } 
}

struct NpcSchema {
    string name;
    string code;
    string description;
    string type;
    
    static NpcSchema fromJson(JSONValue json) {
        return NpcSchema(
            json["name"].get!string,
            json["code"].get!string,
            json["description"].get!string,
            json["type"].get!string
        );
    }
}

struct ActiveEventSchema {
    string name;
    string code;
    MapSchema map;
    string previous_skin;
    int duration;
    string expiration;
    string created_at;
    
    static ActiveEventSchema fromJson(JSONValue json) {
        writeln(json);
        return ActiveEventSchema(
            json["name"].get!string,
            json["code"].get!string,
            MapSchema.fromJson(json["map"]),
            json["previous_skin"].get!string,
            json["duration"].get!int,
            json["expiration"].get!string,
            json["created_at"].get!string
        );
    }
}

struct EventSchema {
    string name;
    string code;
    //EventContentSchema content;
    //EventMapSchema maps;
    string skin;
    int duration;
    int rate;
    
    static EventSchema fromJson(JSONValue json) {
        return EventSchema(
            json["name"].get!string,
            json["code"].get!string,
            json["skin"].get!string,
            json["duration"].get!int,
            json["rate"].get!int
        );
    }
}