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

    auto opts = getopt(
        args,
        "token", &token,
        "singlerun|sr", &singleRun,
        "gui|g", &gui,
        "help|h", &help
    );
    writeln(token);
    if (help || token.length == 0)
    {
        writeln("Usage: ammo --token=TOKEN [--singlerun|-sr] [--gui|-g] [--help|-h]");
        return;
    }
    if(gui){
        RaylibSupport retVal = loadRaylib();
        if (retVal != raylibSupport) {
            writeln("ERROR: ", retVal);
            return;
        }

        // Window configuration
        enum SCREEN_WIDTH = 1280;
        enum SCREEN_HEIGHT = 720;
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
    Duration logicInterval = 250.msecs;
    MonoTime lastLogicTime = MonoTime.currTime;
    while (!gui || !WindowShouldClose()) {
        MonoTime now = MonoTime.currTime;
        bool runLogic = (now - lastLogicTime) >= logicInterval;

        if (runLogic) {
            writeln("\033[37m", "--------------", count++, "-----------------");
            foreach (i; 0 .. charOrder.length) {
                processCharacter(characters[charOrder[i]], i);
                characters[charOrder[i]].saveAttachments(CACHE_DIR ~ "character_" ~ characters[charOrder[i]].name ~ ".json");
            }
            lastLogicTime = now;

            if (singleRun) {
                break;
            }
        }
        if (gui) {
            BeginDrawing();
            ClearBackground(Color(30, 30, 30, 255));
            DrawRectangle(0, 0, 256, 128 * 5, Color(40, 40, 40, 255));
            foreach (i; 0 .. charOrder.length) {
                Character* p = characters[charOrder[i]];
                int sx = 10;
                int sy = cast(int)i*128;
                DrawRectangle(10, sy+10, 236, 108, Color(0, 0, 0, 255));
                DrawTexture(assetLoader.loadTexture("Characters", p.skin), sx+10, sy+20, WHITE);
                int tx = sx+70;
                int ty = sy+30;
                DrawText(p.name.toStringz, tx, ty, 20, LIGHTGRAY);
                ty+=25;
                if(p.x == 0 && p.y == 0 && p.hp <= 1){
                    DrawText("---DEAD---".toStringz, tx, ty, 12, RED);
                }
                else{
                    DrawText(("HP:"~(p.hp.to!string)~"/"~(p.max_hp.to!string)).toStringz, tx, ty, 12, LIGHTGRAY);
                }
                ty+=16;
                DrawText(("XP:"~(p.xp.to!string)~"/"~(p.max_xp.to!string)).toStringz, tx, ty, 12, LIGHTGRAY);
                ty+=16;
                DrawText(("Lvl:"~p.level.to!string).toStringz, tx-50, ty, 12, LIGHTGRAY);
                DrawText(("Inv:"~(p.countInventory().to!string)~"/"~(p.inventory_max_items.to!string)).toStringz, tx, ty, 12, LIGHTGRAY);
            }
            EndDrawing();
        } else {
            // In CLI mode, sleep a bit to avoid CPU hogging
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
    if (i == 0) {
        fighter(c);
    }
    else if (i == 1) {
        crafter(c);
    }
    else {
        fetcher(c);
    }
    if (!c.onCooldown()) {
        if (!doGather(c,  200, c.alchemy_level >= 10, LOC_SUNFLOWER, "sunflower")) {
            return;
        }
        writeln(c.color, c.name ~ " is doing nothing");
        return;
    }
}