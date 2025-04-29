import std.stdio;
import core.thread;
import core.time;
import core.runtime;
import std.net.curl;
import std.json;
import std.math;
import std.conv;

import bindbc.raylib;

import global;
import api.ammo;
import api.schema;

void main(string[] args)
{
    string token = args[1];
    global_init(token);
    (new Thread({
        GUIThread();
    })).start();
    ulong count = 0;
    while (true) {
        writeln("\033[37m", "--------------", count++, "-----------------");
        foreach (i; 0 .. charOrder.length) {
            processCharacter(characters[charOrder[i]], i);
            characters[charOrder[i]].saveAttachments(CACHE_DIR~"character_"~characters[charOrder[i]].name~".json");
        }
        Thread.sleep(1.seconds);
    }
}

void processCharacter(Character* c, ulong i)
{
	import script.fetcher;
	import script.crafter;
	import script.fighter;
    import script.helper;
    if (c.onCooldown()) {
        //writeln(c.color, c.name ~ " is on cooldown");
        return;
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
        //writeln(c.color, c.name ~ " is doing nothing");
        return;
    }
}

void GUIThread() {
    if(true){
        writeln("GUIThread: GUI is disabled");
        return;
    }
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

    // Main loop
    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(Color(30, 30, 30, 255));
        DrawRectangle(0, 0, 250, SCREEN_HEIGHT, Color(40, 40, 40, 255));
        EndDrawing();
    }

    CloseWindow();
}