import std.stdio;
import core.thread;
import core.time;
import core.runtime;
import std.net.curl;
import std.json;
import std.math;
import std.conv;
import std.getopt;
import std.string;
import std.datetime : MonoTime, Duration;

import bindbc.raylib;

import global;
import api.ammo;
import api.schema;
import assetloader;

__gshared bool gui = false;
__gshared bool singleRun = false;
__gshared AssetLoader assetLoader;

void main(string[] args)
{
    assetLoader = new AssetLoader();
    string token;
    bool help = false;
    string user;
    bool printitems;
    auto opts = getopt(
        args,
        "token", &token,
        "user",&user,
        "singlerun|sr", &singleRun,
        "gui|g", &gui,
        "help|h", &help,
        "printitems|pi",&printitems
    );
    writeln(token);
    if (help || token.length == 0)
    {
        writeln("Usage: ammo --token=TOKEN [--singlerun|-sr] [--gui|-g] [--help|-h] [--printitems|-pi]");
        return;
    }
    if(printitems){
        global_init(token);
        print_items("items.json");
        return;
    }
    if(gui){
        RaylibSupport retVal = loadRaylib();
        if (retVal != raylibSupport) {
            writeln("ERROR: ", retVal);
            return;
        }

        // Window configuration
        int SCREEN_WIDTH = 1280;
        if(user.length > 0){
            SCREEN_WIDTH = 256;
        }
        int SCREEN_HEIGHT = 920;
        InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Artifact MMO Client");
        SetTargetFPS(5);
    }
    global_init(token);
    if(gui){
        //lets prefatch all the assets
        foreach(c;characters){
            auto tex = assetLoader.loadTexture("Characters", c.skin);
        }
        foreach(m;monsters){
            auto tex = assetLoader.loadTexture("Monsters", m.code);
        }
        foreach(m;npcs){
            auto tex = assetLoader.loadTexture("NPCs", m.code);
        }
        foreach(m;maps){
            auto tex = assetLoader.loadTexture("Maps", m.skin);
        }
        foreach(m;itemList){
            auto tex = assetLoader.loadTexture("Items", m.code);
        }
    }
    ulong count = 0;
    Duration logicInterval = 500.msecs;
    MonoTime lastLogicTime = MonoTime.currTime;

    Duration softUpdateInterval = 1.minutes;
    MonoTime lastSoftUpdateTime = MonoTime.currTime;
    while (!gui || !WindowShouldClose()) {
        MonoTime now = MonoTime.currTime;
        bool runLogic = (now - lastLogicTime) >= logicInterval;
        bool runSoftUpdate = (now - lastSoftUpdateTime) >= softUpdateInterval;
        if(runSoftUpdate){
            writeln("\033[37m", " SoftUpdate");
            soft_refresh();
            lastSoftUpdateTime = now;
        }
        if (runLogic) {
            writeln("\033[37m", "--------------", count++, "-----------------");
            foreach (i; 0 .. charOrder.length) {
                if(user.length > 0){
                    if(user != charOrder[i]){
                        continue;
                    }
                }
                processCharacter(characters[charOrder[i]], i);
                characters[charOrder[i]].saveAttachments(CACHE_DIR ~ "character_" ~ characters[charOrder[i]].name ~ ".json");
            }
            lastLogicTime = now;

            if (singleRun) {
                break;
            }
        }
        if (gui) {
            SetWindowTitle(("Artifact MMO Client: " ~ count.to!string).toStringz);
            BeginDrawing();
            ClearBackground(Color(30, 30, 30, 255));
            // Horizontal background rectangle (width based on character count)
            DrawRectangle(0, 0, (256 * cast(uint)charOrder.length), 128, Color(40, 40, 40, 255));
            foreach (i; 0 .. charOrder.length) {
                if(user.length > 0){
                    if(user != charOrder[i]){
                        continue;
                    }
                }
                Character* p = characters[charOrder[i]];
                int sx = cast(int)(i * 256);  // Horizontal position based on index
                int sy = 0;         // Vertical position remains constant
                
                DrawRectangle(sx + 10, sy + 10, 236, 108, Color(0, 0, 0, 255));
                DrawTexture(assetLoader.loadTexture("Characters", p.skin), sx + 20, sy + 20, WHITE);
                
                int tx = sx + 76;
                int ty = sy + 30;
                DrawText(p.name.toStringz, tx, ty, 20, LIGHTGRAY);
                
                ty += 25;
                if (p.x == 0 && p.y == 0 && p.hp <= 1) {
                    DrawText("---DEAD---".toStringz, tx, ty, 12, RED);
                } else {
                    DrawText(("HP:" ~ p.hp.to!string ~ "/" ~ p.max_hp.to!string).toStringz, 
                            tx, ty, 12, p.hp == p.max_hp ? GREEN : LIGHTGRAY);
                }
                
                ty += 16;
                DrawText(("XP:" ~ p.xp.to!string ~ "/" ~ p.max_xp.to!string).toStringz, tx, ty, 12, LIGHTGRAY);
                
                ty += 16;
                DrawText(("Lvl:" ~ p.level.to!string).toStringz, tx - 50, ty, 12, LIGHTGRAY);
                DrawText(("Inv:" ~ p.countInventory().to!string ~ "/" ~ p.inventory_max_items.to!string).toStringz, 
                        tx, ty, 12, LIGHTGRAY);
                ty += 16;        
                DrawText(("Cooldown: " ~ p.cooldownLeft().to!string).toStringz, 
                        tx, ty, 12, LIGHTGRAY);
                ty += 20;
                MapSchema ms = getMap(p.x,p.y);
                DrawTexture(assetLoader.loadTexture("Maps", ms.skin), sx + 15, ty, WHITE);
                DrawText(("(" ~ p.x.to!string ~ "," ~ p.y.to!string ~ ")").toStringz, sx + 15, ty, 12, LIGHTGRAY);
                ty += 224-68;
                DrawTexture(assetLoader.loadTexture("Characters", p.skin), sx + 100, ty, WHITE);
                ty +=16+68;
                int counta = 0;
                foreach(slot; p.inventory){
                    if(slot.quantity > 0){
                        counta+=1;
                        DrawTexture(assetLoader.loadTexture("Items", slot.code), sx + 15, ty, WHITE);
                        DrawText((""~slot.quantity.to!string).toStringz, sx + 65, ty,12, LIGHTGRAY);
                        if(counta == 9){
                            sx+=60;
                            ty-=(60*9);
                        }
                        if(counta == 18){
                            sx+=60;
                            ty-=(60*9);
                        }
                        ty +=60;
                    }
                }
            }
            EndDrawing();
        } else {
            Thread.sleep(10.msecs);
        }
    }
    if(gui){
        CloseWindow();
    }
}

void processCharacter(Character* c, ulong i)
{
	import script.fetcher;
	import script.crafter;
	import script.fighter;
    import script.helper;
    if (c.onCooldown()) {
        writeln(c.color, c.name ~ " is on cooldown");
        return;
    }
    if(c.task.length == 0){
        if(c.x != 1 || c.y != 2){
            c.move(1,2);
            return;
        }
        else{
            c.taskNew();
            return;
        }
        return;
    }
    else if(c.task_progress == c.task_total){
        if(c.x != 1 || c.y != 2){
            c.move(1,2);
            return;
        }
        else{
            c.taskComplete();
            return;
        }
    }
    if(c.getBoolean("bankAll")){
        bankAll(c);
        return;
    }
    if(c.getString("unequipbank") != "" && c.countItem(c.getString("unequipbank")) > 0){
        int result;
        result = smartMove(c, "bank","bank");
		if(result == 200) {
			result = c.depositItem(c.getString("unequipbank"),c.countItem(c.getString("unequipbank")));
		}
        if(result == 200){
            c.setString("unequipbank","");
        }
        return;
    }
    if(c.artifact2_slot == "" && (bank.count("silver_chalice")>=1 || c.countItem("silver_chalice")>=1)){
        script.helper.smartEquip(c,"silver_chalice","artifact2");
        return;
    }
    if(c.artifact1_slot == "" && (bank.count("spotted_egg")>=1 || c.countItem("spotted_egg")>=1)){
        script.helper.smartEquip(c,"spotted_egg","artifact1");
        return;
    }
    if (i == 0) {
        if(c.artifact3_slot == "" && (bank.count("dreadful_book")>=1 || c.countItem("dreadful_book")>=1)){
            script.helper.smartEquip(c,"dreadful_book","artifact3");
            return;
        }
        fighter(c);
    }
    else if (i == 1) {
        crafter(c);
    }
    else {
        fetcher(c);
    }
    if (!c.onCooldown()) {
        //if (!doGather(c,  200, c.alchemy_level >= 10, LOC_SUNFLOWER, "sunflower")) {
        //    return;
        //}
        writeln(c.color, c.name ~ " is doing nothing");
        return;
    }
}