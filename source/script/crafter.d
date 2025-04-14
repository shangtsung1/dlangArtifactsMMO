module script.crafter;

import std.stdio;

import global;
import api.ammo;
import api.schema;
import script.helper;
import api.config;

void crafter(Character* c)
{
    import script.fighter;
    fighter(c);
}