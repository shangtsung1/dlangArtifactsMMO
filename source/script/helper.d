module script.helper;

import global;
import api.ammo;
import api.schema;
import api.config;

import std.stdio;
import core.thread;
import core.time;
import core.runtime;
import std.net.curl;
import std.json;


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

