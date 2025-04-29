module script.helper;

import global;
import api.ammo;
import api.schema;

import std.stdio;
import core.thread;
import core.time;
import core.runtime;
import std.net.curl;
import std.json;
import std.math;
import std.algorithm;


public bool doMithril(Character* c,int limit, bool adhereToLimit){
	//todo dynamically find this one, im pretty sure it moves.
	return doGather(c,limit,adhereToLimit,-2,13,"mithril_ore");
}

public bool doMaple(Character* c,int limit, bool adhereToLimit){
	//todo dynamically find this one, im pretty sure it moves.
	return doGather(c,limit,adhereToLimit,1,12,"maple_wood");
}

public bool doGather(Character* c,int limit, bool adhereToLimit, Location loc,string code){
    return doGather(c,limit,adhereToLimit,loc.x,loc.y,code);
}

public bool doGather(Character* c,int limit, bool adhereToLimit, int x, int y,string code){
    if(c.getBoolean("bankAll")){
        bankAll(c);
        return false;
    }
	if(bank.count(code) > limit && adhereToLimit){
		if(countItem(c,code) > 0){
            if(c.x != 4 || c.y != 1){
				int result = c.move(4,1);
				writeln(c.color,"BankMoveResult = ",result);
				return false;
			}
			bankAll(c);
			return false;
		}
		return true;
	}
	else{
		if(countInventory(c) < c.inventory_max_items){
			if(c.x != x || c.y != y){
				writeln(c.color,"GatherMove");
				int result = c.move(x,y);
				return false;
			}
			else{
				writeln(c.color,"Gather ", code ," Result = ",c.gathering());
				return false;
			}
		}
		else{
            bankAll(c);
            return false;
		}
	}
}

public bool bankAll(Character* c){
    if(c.x != 4 || c.y != 1){
        int result = c.move(4,1);
        writeln(c.color,"BankAllMoveResult = ",result);
        return false;
    }
	if(c.gold > 0){
		c.depositGold(c.gold);
		writeln(c.color,"BankAllGoldResult = ",c.gold);
		return false;
	}
    if(countInventory(c) > 0){
        foreach (item; c.inventory)
        {
            if(item.quantity > 0){
                c.setBoolean("bankAll",true);
                writeln(c.color,"BankAllResult = ",c.depositItem(item.code,item.quantity));
                return false;
            }
        }
        return false;
    }
    else{
        c.setBoolean("bankAll",false);
        return true;
    }
}

public SimpleItemSchema[] getBankItemsT(string item_code, int page, int size){
    SimpleItemSchema[] sis;
    foreach(item; bank.items){
        if(item.code == item_code){
            sis ~= item;
        }
    }
    return sis;
}

public int countItem(Character* c,string code){
	foreach(i; c.inventory){
		if(i.code == code){
			return i.quantity;
		}
	}
	return 0;
}

public int countInventory(Character* c){
	int count = 0;
	foreach(i; c.inventory){
		count += i.quantity; 
	}
	return count;
}

public int smartCraft(Character* character,string code,int quantity){
	ItemSchema ci = getItem(code);
	MapSchema requiredMap = findMapFor(ci.craft.get().skillString,"workshop");
//writeln(character.color,"Move to ",ci.craft.get().skillString," ",requiredMap.x," ",requiredMap.y);
	if(character.x != requiredMap.x || character.y != requiredMap.y){
		character.move(requiredMap.x,requiredMap.y);
		return 598;
	}
	if(character.onCooldown()){
		return 486;
	}
	//TODO: grab from bank if we need to.
	foreach(ac;ci.craft.get().items){
		if(!character.inventoryContains(ac.code,ac.quantity*quantity))return 478;
	}
	return character.crafting(code,quantity);
}

private MapSchema findMapFor(string code,string type) {
	foreach(map; maps){
		if(map.content.isNull)continue;
	//	writeln(map.content.get().code,map.content.get().type);
		if(map.content.get().code == code && map.content.get().type == type)return map;
	}
	return MapSchema();
}

public void smartEquip(Character* m, string code, string slot, int amount) {
	if(!m.inventoryContains(code,amount)){
		int mR = smartMove(m, "bank","bank");
		if(mR == 200) {
			m.withdrawItem(code, amount);
		}
		return;
	}
	else{
		writeln(m.color,slot);
		if(m.getSlot(slot) != ""){
			writeln(m.color,"Unequip ",m.getSlot(slot)," Result = ",m.unequip(slot));
			return;
		}
		writeln(m.color,"Equip ",code," Result = ",m.equip(code,slot,amount), ", ",amount);
		return;
	}
}

public void smartEquip(Character* m, string code, string slot) {
	smartEquip(m,code,slot,1);
}

public int smartMove(Character* character, string code, string type){
	MapSchema requiredMap = findMapFor(code,type);
	if(character.x != requiredMap.x || character.y != requiredMap.y){
		character.move(requiredMap.x,requiredMap.y);
		return 598;
	}
	return 200;
}

public void smartEat(Character* m, string code) {
	if(!m.inventoryContains(code,1)){
		int mR = smartMove(m, "bank","bank");
		if(mR == 200) {
			m.withdrawItem(code, min(10,bank.count(code)));
		}
		return;
	}
	else{
		m.useItem(code,1);
		return;
	}
}