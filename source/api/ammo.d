module api.ammo;

import std.net.curl;
import std.exception : enforce;
import std.json;
import core.time;
import std.datetime;
import std.stdio;
import std.uri : encodeComponent;
import std.conv : to;
import std.typecons : Nullable;
import std.string;
import std.range;
import std.algorithm;
import std.array;

public class ArtifactMMOClient {
    private string token;
    private string BASE_URL = "https://api.artifactsmmo.com";
    private long timeOffset;
    private string userAgent = "CERN-LineMode/2.15 libwww/2.17";

    this(string token) {
        this.token = token;
    }

    this(string token,bool sandbox){
        this.token = token;
        if(sandbox){
            this.BASE_URL = "https://sandbox-api.artifactsmmo.com";
        }
    }

    public JSONValue initClient() {
        JSONValue response = getStatus();
        
        enforce("statusCode" in response, "Response JSON missing 'statusCode' field.");
        int statusCode = response["statusCode"].get!int;
        enforce(statusCode >= 200 && statusCode < 300,
            "Failed to initialize client. Status endpoint returned: " ~ to!string(statusCode));
        enforce("data" in response, "Response JSON missing 'data' field for successful status.");
        auto dataVal = response["data"];
        enforce("server_time" in dataVal, "Response JSON missing 'data.server_time' field.");
        string serverTime = dataVal["server_time"].get!string;
        long sTime = SysTime.fromISOExtString(serverTime).toUnixTime();
        long cTime = Clock.currTime().toUTC().toUnixTime();
        timeOffset = sTime - cTime;
        version(DEBUG) {
            writeln("Time offset calculated: ", timeOffset);
        }
        return response;
    }

    public long getTimeOffset() {
        return timeOffset;
    }

    private JSONValue performCurlRequest(
        string url,
        string method,
        Nullable!JSONValue body = Nullable!JSONValue(),
        bool requiresAuth = true)
    {
        try{
            auto http = HTTP();
            http.url = url;
            switch (toUpper(method)) {
                case "GET":
                    http.method = HTTP.Method.get;
                    break;
                case "POST":
                    http.method = HTTP.Method.post;
                    if (!body.isNull) {
                        http.setPostData(body.toString(), "application/json");
                    }
                    else{
                        http.setPostData("{}", "application/json");
                    }
                    break;
                default:
                    //Fuck?
                    return JSONValue(null);
            }
            if (requiresAuth) {
                http.addRequestHeader("Authorization", "Bearer " ~ token);
            }
            http.addRequestHeader("Accept","application/json; charset=UTF-8");
            string responseBody = "";
            int count = 0;
            http.onReceive = (ubyte[] data) {
                count++;
                responseBody = responseBody ~ cast(string)(data.dup);
                return data.length;
            };
            int cstatus = http.perform();
            if(cstatus != 0){//CurlError.ok
                return JSONValue(["CurlError " ~ cstatus.to!string]);
            }
            int status = http.statusLine.code;
            JSONValue result;
            if (responseBody.length == 0) {
                result = JSONValue(["statusCode": JSONValue(status)]);
            } else {
                try {
                    result = parseJSON(responseBody);
                } catch (JSONException e) {
                    writeln(responseBody);
                    writeln(e.toString());
                    result = [
                        "error": JSONValue("JSON parse error"),
                        "statusCode": JSONValue(status)
                    ];
                }
            }
            result["statusCode"] = JSONValue(status);
            version(DEBUG) {
                //writeln(count.to!string~"[ammo.performCurlRequest] "~result.toString());
            }
            return result;
        }
        catch (Exception e) {
            writeln("Error in performCurlRequest: ", e.msg);
            return JSONValue([
                        "error": JSONValue("JSON parse error"),
                        "statusCode": JSONValue(0),
                        "msg": JSONValue(e.msg)
                    ]);
        }
    }


    // --- Helper Functions ---

    private string buildQueryParams(string[] params...) {
        if (params.empty) return "";
        return "?" ~ params
            .chunks(2)
            .filter!(pair => pair.length == 2 && pair[1] !is null && !pair[1].empty)
            .map!(pair =>
                encodeComponent(pair[0]) ~ "=" ~ encodeComponent(pair[1])
            )
            .join("&");
    }

    private string buildQueryString(string[] params) {
        if (params.empty) return "";
        string[] nonEmptyParams = params.filter!(p => !p.empty).array;
        if(nonEmptyParams.empty) return "";
        return "?" ~ nonEmptyParams.join("&");
    }


    // --- API Method Implementations ---
    public JSONValue getStatus() {
        string url = BASE_URL ~ "";
        return performCurlRequest(url, "GET", Nullable!JSONValue(), false);
    }

    public JSONValue getAccountDetails() {
        string url = BASE_URL ~ "/my/details";
        return performCurlRequest(url, "GET");
    }

    public JSONValue getBankDetails() {
        string url = BASE_URL ~ "/my/bank";
        return performCurlRequest(url, "GET");
    }

    public JSONValue getBankItems(string item_code, int page = 1, int size = 50) {
        string url = BASE_URL ~ "/my/bank/items";
        url ~= buildQueryParams(
            "item_code", item_code,
            "page", page.to!string,
            "size", size.to!string
        );
        return performCurlRequest(url, "GET");
    }

    public JSONValue getGESellOrders(string code = null, int page = 1, int size = 50){
        string url = BASE_URL ~ "/my/grandexchange/orders";
        url ~= buildQueryParams(
            "code", code,
            "page", page.to!string,
            "size", size.to!string
            );
        return performCurlRequest(url, "GET");
    }

    public JSONValue getGESellHistory(string code = null, string id = null, int page = 1, int size = 50){
        string url = BASE_URL ~ "/my/grandexchange/history";
         url ~= buildQueryParams(
            "code", code,
            "id", id,
            "page", page.to!string,
            "size", size.to!string
            );
        return performCurlRequest(url, "GET");
    }

    public JSONValue changePassword(string current_password, string new_password) {
        JSONValue body = [
            "current_password": current_password,
            "new_password": new_password
        ];
        string url = BASE_URL ~ "/my/change_password";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue move(string name, int x, int y) {
        JSONValue body = [
            "x": x,
            "y": y
        ];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/move";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue restEntity(string name) {
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/rest";
        return performCurlRequest(url, "POST");
    }

    public JSONValue equipEntity(string name, string code, string slot, int quantity = 1) {
        JSONValue body = [
            "code": JSONValue(code),
            "slot": JSONValue(slot),
            "quantity": JSONValue(quantity)
        ];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/equip";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue unequipEntity(string name, string slot, int quantity = 1) {
        JSONValue body = [
            "slot": JSONValue(slot),
            "quantity": JSONValue(quantity)
        ];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/unequip";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue useItem(string name, string code, int quantity) {
        JSONValue body = ["code": JSONValue(code), "quantity": JSONValue(quantity)];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/use";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue fight(string name, string[] participants = []) {
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/fight";
        JSONValue body;
        if (participants.length > 0) {
             auto participantsJson = JSONValue(JSONType.array);
            foreach(p; participants) {
                participantsJson.array ~= JSONValue(p);
            }
            body = JSONValue(["participants": participantsJson]);
        } else {
            body = JSONValue(JSONType.object);
        }
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue gathering(string name) {
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/gathering";
        return performCurlRequest(url, "POST");
    }

    public JSONValue crafting(string name, string code, int quantity = 1) {
        JSONValue body = ["code": JSONValue(code), "quantity": JSONValue(quantity)];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/crafting";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue depositGold(string name, int quantity) {
        JSONValue body = ["quantity": quantity];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/bank/deposit/gold";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue depositItem(string name, string code, int quantity) {
        JSONValue[] bodyArray = [
            JSONValue([
                "code": JSONValue(code),
                "quantity": JSONValue(quantity)
            ])
        ];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/bank/deposit/item";
        return performCurlRequest(url, "POST", Nullable!JSONValue(JSONValue(bodyArray)));
    }

    public JSONValue depositItem(string name, string[] codes, int[] quantities) {
        enforce(codes.length == quantities.length, "codes and quantities must have the same length");

        JSONValue[] bodyArray;
        foreach (i; 0 .. codes.length) {
            bodyArray ~= JSONValue([
                "code": JSONValue(codes[i]),
                "quantity": JSONValue(quantities[i])
            ]);
        }

        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/bank/deposit/item";
        return performCurlRequest(url, "POST", Nullable!JSONValue(JSONValue(bodyArray)));
    }

    public JSONValue withdrawItem(string name, string code, int quantity) {
        JSONValue[] bodyArray = [
            JSONValue([
                "code": JSONValue(code),
                "quantity": JSONValue(quantity)
            ])
        ];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/bank/withdraw/item";
        return performCurlRequest(url, "POST", Nullable!JSONValue(JSONValue(bodyArray)));
    }

    public JSONValue withdrawGold(string name, int quantity) {
        JSONValue body = ["quantity": JSONValue(quantity)];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/bank/withdraw/gold";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue buyExpansion(string name) {
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/bank/buy_expansion";
        return performCurlRequest(url, "POST");
    }

    public JSONValue npcBuy(string name, string code, int quantity) {
        JSONValue body = ["code": JSONValue(code), "quantity": JSONValue(quantity)];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/npc/buy";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue npcSell(string name, string code, int quantity) {
        JSONValue body = ["code": JSONValue(code), "quantity": JSONValue(quantity)];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/npc/sell";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue recycling(string name, string code, int quantity = 1) {
        JSONValue body = ["code": JSONValue(code), "quantity": JSONValue(quantity)];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/recycling";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue geBuy(string name, string id, int quantity) {
        JSONValue body = ["id": JSONValue(id), "quantity": JSONValue(quantity)];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/grandexchange/buy";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue geSell(string name, string code, int quantity, int price) {
        JSONValue body = [
                "code": JSONValue(code),
                "quantity": JSONValue(quantity),
                "price": JSONValue(price)
            ];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/grandexchange/sell";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue geCancel(string name, string id) {
        JSONValue body = ["id": JSONValue(id)];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/grandexchange/cancel";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    private JSONValue postNoBodyTaskAction(string name, string action) {
         string url = BASE_URL~"/my/"~encodeComponent(name)~"/action/task/"~action;
         return performCurlRequest(url, "POST");
    }

    public JSONValue taskComplete(string name) {
        return postNoBodyTaskAction(name, "complete");
    }

    public JSONValue taskExchange(string name) {
        return postNoBodyTaskAction(name, "exchange");
    }

    public JSONValue taskNew(string name) {
        return postNoBodyTaskAction(name, "new");
    }

    public JSONValue taskCancel(string name) {
        return postNoBodyTaskAction(name, "cancel");
    }

    public JSONValue taskTrade(string name, string code, int quantity) {
        JSONValue body = ["code": JSONValue(code), "quantity": JSONValue(quantity)];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/task/trade";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue deleteItem(string name, string code, int quantity) {
        JSONValue body = ["code": JSONValue(code), "quantity": JSONValue(quantity)];
        string url = BASE_URL ~ "/my/" ~ encodeComponent(name) ~ "/action/delete";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue getLogs(int page = 1, int size = 50) {
        string url = BASE_URL ~ "/my/logs";
        url ~= buildQueryParams(
            "page", page.to!string,
            "size", size.to!string
        );
        return performCurlRequest(url, "GET");
    }

    public JSONValue getCharacters() {
        string url = BASE_URL ~ "/my/characters";
        return performCurlRequest(url, "GET");
    }

    public JSONValue createAccount(string username, string password, string email) {
        JSONValue body = [
            "username": username,
            "password": password,
            "email": email
        ];
        string url = BASE_URL ~ "/accounts/create";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body), false);
    }

    public JSONValue getAccountCharacters(string account) {
        string url = BASE_URL ~ "/accounts/" ~ encodeComponent(account) ~ "/characters";
        return performCurlRequest(url, "GET", Nullable!JSONValue(), false);
    }

    public JSONValue getAccount(string account) {
        string url = BASE_URL ~ "/accounts/" ~ encodeComponent(account);
        return performCurlRequest(url, "GET", Nullable!JSONValue(), false);
    }

    public JSONValue getAccountAchievements(string account, bool completed = false,
                                             int page = 1, int size = 50, string type = null) {
        string url = BASE_URL ~ "/accounts/" ~ encodeComponent(account) ~ "/achievements";
        string[] params;
        params ~= "completed=" ~ (completed ? "true" : "false");
        params ~= "page=" ~ page.to!string;
        params ~= "size=" ~ size.to!string;
        if (type !is null && !type.empty) params ~= "type=" ~ encodeComponent(type);

        url ~= buildQueryString(params);
        return performCurlRequest(url, "GET", Nullable!JSONValue(), false);
    }

     public JSONValue createCharacter(string name, string skin) {
        JSONValue body = [
            "name": name,
            "skin": skin
        ];
        string url = BASE_URL ~ "/characters/create";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    public JSONValue deleteCharacter(string name) {
        JSONValue body = ["name": name];
        string url = BASE_URL ~ "/characters/delete";
        return performCurlRequest(url, "POST", Nullable!JSONValue(body));
    }

    private JSONValue createGetRequest(string url) {
         bool requiresAuthNeeded = (token.length > 0);
         return performCurlRequest(url, "GET", Nullable!JSONValue(), requiresAuthNeeded);
    }

    public JSONValue getAchievements(int page = 1, int size = 50, string type = null) {
        string url = BASE_URL ~ "/achievements";
        url ~= buildQueryParams("page", page.to!string, "size", size.to!string);
        if (type !is null && !type.empty) url ~= "&type=" ~ encodeComponent(type);
        return createGetRequest(url);
    }

    public JSONValue getAchievement(string code) {
        return createGetRequest(BASE_URL ~ "/achievements/" ~ encodeComponent(code));
    }

    public JSONValue getBadges(int page = 1, int size = 50) {
        return createGetRequest(BASE_URL ~ "/badges" ~ buildQueryParams("page", page.to!string, "size", size.to!string));
    }

    public JSONValue getBadge(string code) {
        return createGetRequest(BASE_URL ~ "/badges/" ~ encodeComponent(code));
    }

    public JSONValue getCharacter(string name) {
        return createGetRequest(BASE_URL ~ "/characters/" ~ encodeComponent(name));
    }

    public JSONValue getEffects(int page = 1, int size = 50) {
        return createGetRequest(BASE_URL ~ "/effects" ~ buildQueryParams("page", page.to!string, "size", size.to!string));
    }

    public JSONValue getEffect(string code) {
        return createGetRequest(BASE_URL ~ "/effects/" ~ encodeComponent(code));
    }

    public JSONValue getActiveEvents(int page = 1, int size = 50) {
        return createGetRequest(BASE_URL ~ "/events/active" ~ buildQueryParams("page", page.to!string, "size", size.to!string));
    }

    public JSONValue getAllEvents(int page = 1, int size = 50, string type = null) {
        string url = BASE_URL ~ "/events";
        url ~= buildQueryParams("page", page.to!string, "size", size.to!string);
        if (type !is null && !type.empty) url ~= "&type=" ~ encodeComponent(type);
        return createGetRequest(url);
    }

    public JSONValue getGeHistory(string code, string buyer = null, int page = 1, string seller = null, int size = 50) {
        string url = BASE_URL ~ "/grandexchange/history/" ~ encodeComponent(code);
        url ~= buildQueryParams(
            "buyer", buyer,
            "page", page.to!string,
            "seller", seller,
            "size", size.to!string
            );
        return createGetRequest(url);
    }

    public JSONValue getGeOrders(string code = null, int page = 1, string seller = null, int size = 50) {
        string url = BASE_URL ~ "/grandexchange/orders";
        url ~= buildQueryParams(
            "code", code,
            "page", page.to!string,
            "seller", seller,
            "size", size.to!string
            );
        return createGetRequest(url);
    }

    public JSONValue getGeOrder(string id) {
        return createGetRequest(BASE_URL ~ "/grandexchange/orders/" ~ encodeComponent(id));
    }

    public JSONValue getItems(string craftMaterial = null, string craftSkill = null,
                               int maxLevel = 0, int minLevel = 0, string name = null,
                               int page = 1, int size = 50, string type = null) {
        string url = BASE_URL ~ "/items";
        url ~= buildQueryParams(
            "craft_material", craftMaterial,
            "craft_skill", craftSkill,
            "max_level", (maxLevel > 0) ? maxLevel.to!string : null,
            "min_level", (minLevel > 0) ? minLevel.to!string : null,
            "name", name,
            "page", page.to!string,
            "size", size.to!string,
            "type", type
        );
        return createGetRequest(url);
    }

    public JSONValue getItems(string name = null,int page = 1, int size = 100) {
        string url = BASE_URL ~ "/items";
        url ~= buildQueryParams(
            "name", name,
            "page", page.to!string,
            "size", size.to!string
        );
        return createGetRequest(url);
    }

    public JSONValue getItem(string code) {
        return createGetRequest(BASE_URL ~ "/items/" ~ encodeComponent(code));
    }

    public JSONValue getCharacterLeaderboard(string name = null, int page = 1,
                                              int size = 50, string sort = "combat") {
        string url = BASE_URL ~ "/leaderboard/characters";
        url ~= buildQueryParams(
            "name", name,
            "page", page.to!string,
            "size", size.to!string,
            "sort", sort
            );
        return createGetRequest(url);
    }

    public JSONValue getAccountLeaderboard(string name = null, int page = 1,
                                            int size = 50, string sort = "achievements_points") {
        string url = BASE_URL ~ "/leaderboard/accounts";
         url ~= buildQueryParams(
            "name", name,
            "page", page.to!string,
            "size", size.to!string,
            "sort", sort
            );
        return createGetRequest(url);
    }

    public JSONValue getMap(int x, int y) {
        return createGetRequest(BASE_URL ~ "/maps/" ~ x.to!string ~ "/" ~ y.to!string);
    }

    public JSONValue getAllMaps(string contentCode = null, string contentType = null,
                                 int page = 1, int size = 50) {
        string url = BASE_URL ~ "/maps";
        url ~= buildQueryParams(
            "content_code", contentCode,
            "content_type", contentType,
            "page", page.to!string,
            "size", size.to!string
        );
        return createGetRequest(url);
    }

    public JSONValue getAllMonsters(
                                  int page = 1, int size = 50) {
        string url = BASE_URL ~ "/monsters";
        url ~= buildQueryParams(
            "page", page.to!string,
            "size", size.to!string
        );
        return createGetRequest(url);
    }

    public JSONValue getMonster(string code) {
        return createGetRequest(BASE_URL ~ "/monsters/" ~ encodeComponent(code));
    }

    public JSONValue getAllNpcs(int page = 1, int size = 50, string type = null) {
        string url = BASE_URL ~ "/npcs/details";
        url ~= buildQueryParams("page", page.to!string, "size", size.to!string);
        if (type !is null && !type.empty) url ~= "&type=" ~ encodeComponent(type);
      //  writeln(url);
        return createGetRequest(url);
    }

    public JSONValue getNpc(string code) {
        return createGetRequest(BASE_URL ~ "/npcs/details/" ~ encodeComponent(code));
    }

    public JSONValue getNpcItems(string code, int page = 1, int size = 50) {
        string url = BASE_URL ~ "/npcs/items/"~ encodeComponent(code);
        url ~= buildQueryParams("page", page.to!string, "size", size.to!string);
        return createGetRequest(url);
    }

    public JSONValue getAllNpcItems(string code,string currency,string npc, int page = 1, int size = 50) {
        string url = BASE_URL ~ "/npcs/items";
        url ~= buildQueryParams("code",code.to!string,"page", page.to!string, "size", size.to!string,"currency", currency.to!string,"npc", npc.to!string);
        return createGetRequest(url);
    }

    public JSONValue getResources(string drop = null, int maxLevel = 0, int minLevel = 0,
                                   int page = 1, int size = 50, string skill = null) {
        string url = BASE_URL ~ "/resources";
        url ~= buildQueryParams(
            "drop", drop,
            "max_level", (maxLevel > 0) ? maxLevel.to!string : null,
            "min_level", (minLevel > 0) ? minLevel.to!string : null,
            "page", page.to!string,
            "size", size.to!string,
            "skill", skill
        );
        return createGetRequest(url);
    }

    public JSONValue getResource(string code) {
        return createGetRequest(BASE_URL ~ "/resources/" ~ encodeComponent(code));
    }

    public JSONValue getTasks(int maxLevel = 0, int minLevel = 0, int page = 1,
                               int size = 50, string skill = null, string type = null) {
        string url = BASE_URL ~ "/tasks/list";
        url ~= buildQueryParams(
            "max_level", (maxLevel > 0) ? maxLevel.to!string : null,
            "min_level", (minLevel > 0) ? minLevel.to!string : null,
            "page", page.to!string,
            "size", size.to!string,
            "skill", skill,
            "type", type
        );
        return createGetRequest(url);
    }

    public JSONValue getTask(string code) {
        return createGetRequest(BASE_URL ~ "/tasks/list/" ~ encodeComponent(code));
    }

    public JSONValue getTaskRewards(int page = 1, int size = 50) {
        return createGetRequest(BASE_URL ~ "/tasks/rewards" ~ buildQueryParams("page", page.to!string, "size", size.to!string));
    }

    public JSONValue getTaskReward(string code) {
        return createGetRequest(BASE_URL ~ "/tasks/rewards/" ~ encodeComponent(code));
    }

    public JSONValue createToken() {
        string url = BASE_URL ~ "/token";
        return performCurlRequest(url, "POST");
    }
}