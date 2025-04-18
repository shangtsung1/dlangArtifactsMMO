import std.stdio;
import core.thread;
import core.time;
import core.runtime;
import std.net.curl;
import std.json;

import global;
import api.ammo;
import api.schema;

void main(string[] args)
{
    string token = args[1];
    global_init(token);
    ulong count = 0;
    while (true) {
        writeln("--------------",count++,"-----------------");
        foreach (i; 0 .. charOrder.length) {
            processCharacter(characters[charOrder[i]], i);
            characters[charOrder[i]].saveAttachments("./character_"~characters[charOrder[i]].name~".json");
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