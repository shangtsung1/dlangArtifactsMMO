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

import script.bettergear;


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
	ItemSchema ai = getItem(code);
	string skill = ai.subtype;
    if(c.getBoolean("bankAll")){
        bankAll(c);
        return false;
    }
	if(bank.count(code) > limit && adhereToLimit){
		if(countItem(c,code) > 0){
			int res = smartMove(c, "bank","bank");
			if(res!=200){
				return false;
			}
			bankAll(c);
			return false;
		}
		return true;
	}
	else{
		if(countInventory(c) < c.inventory_max_items){
			if(!equipBestForSkill(c,skill)){
				return false;
			}
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

bool checkEquip(Character* c, string itemCode, string slotName){

	if(itemCode == ""){
		writeln(c.color,"Check? ",c.getSlot(slotName)," ",slotName, " ",itemCode);
		return false;
	}
	if(c.getSlot(slotName) == itemCode){
		return false;
	}
	writeln(c.color,"Check ",c.getSlot(slotName)," ",slotName, " wants ", itemCode);
	if(smartEquip(c,itemCode,slotName) == 200){
		//bankAll(c);
	}
	return true;
}



public bool bankAll(Character* c) {
    int res = smartMove(c, "bank", "bank");
    if (res != 200) {
        return false;
    }
    if (c.gold > 0) {
        c.depositGold(c.gold);
        writeln(c.color, "BankAllGoldResult = ", c.gold);
        return false;
    }
    if (countInventory(c) > 0) {
        // Collect all item codes and quantities from inventory
        string[] codes;
        int[] quantities;
        foreach (item; c.inventory) {
            if (item.quantity > 0) {
                codes ~= item.code;
                quantities ~= item.quantity;
            }
        }
        if (codes.length > 0) {
            c.setBoolean("bankAll", true);
            writeln(c.color, "BankAllResult = ", c.depositItem(codes, quantities));
            return false;
        }
        return false;
    } else {
        c.setBoolean("bankAll", false);
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
		if(map.content.get().code == code && map.content.get().type == type)return map;
	}
	return MapSchema();
}

private MapSchema[] findMapsFor(string code,string type) {
	MapSchema[] arrayOfMaps;
	foreach(map; maps){
		if(map.content.isNull)continue;
		if(map.content.get().code == code && map.content.get().type == type)arrayOfMaps~=map;
	}
	return arrayOfMaps;
}

public int smartEquip(Character* m, string code, string slot, int amount) {
	int result;
	bool potionSlot = slot=="utility1" || slot=="utility2";
	if(!m.inventoryContains(code,amount)){
		writeln(m.color,"Not enough ",code," to equip ",slot);
		result = smartMove(m, "bank","bank");
		if(result == 200) {
			result = m.withdrawItem(code, min(bank.count(code),amount));
		}
		
		return result;
	}
	else{
		writeln(m.color,slot);
		/*if(m.getSlot(slot) != ""){
			if(!potionSlot){
				m.setString("unequipbank",m.getSlot(slot));
			}
			//no need to unequip anymore.
			//result = m.unequip(slot);
			//writeln(m.color,"Unequip ",m.getSlot(slot)," Result = ",result);
			//return result;
		}*/
		result = m.equip(code,slot,amount);
		writeln(m.color,"Equip ",code," Result = ",result, ", ",amount);
		return result;
	}
}

public int smartEquip(Character* m, string code, string slot) {
	return smartEquip(m,code,slot,1);
}

public int smartMove(Character* character, string code, string type) {
	MapSchema[] candidates = findMapsFor(code, type);
	if (candidates.length == 0)
		return 404; // No map found

	MapSchema closest;
	int closestDistance = int.max;
	foreach (map; candidates) {
		int dist = abs(character.x - map.x) + abs(character.y - map.y);
		if (dist < closestDistance) {
			closestDistance = dist;
			closest = map;
		}
	}

	if (character.x != closest.x || character.y != closest.y) {
		character.move(closest.x, closest.y);
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

public void smartWithdraw(Character* m, string code, int minAmount,int maxAmount) {
	if(!m.inventoryContains(code,minAmount)){
		int mR = smartMove(m, "bank","bank");
		if(mR == 200) {
			m.withdrawItem(code, min(m.inventory_max_items-m.countInventory(),min(maxAmount,bank.count(code))));
		}
		return;
	}
	return;
}