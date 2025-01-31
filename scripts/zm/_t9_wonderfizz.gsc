//----------------------------------------------//
//                                              //
//              Dobby's Wonderfizz              //
//                                              //
//----------------------------------------------//

// major credit to lilrifa for providing base code to work off of

#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\compass;
#using scripts\shared\exploder_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\math_shared;
#using scripts\shared\scene_shared;
#using scripts\shared\util_shared;
#using scripts\shared\spawner_shared;

#insert scripts\shared\version.gsh;
#insert scripts\zm\_zm_utility.gsh;
#insert scripts\shared\ai\utility.gsh;
#insert scripts\shared\ai\systems\behavior.gsh;
#insert scripts\shared\archetype_shared\archetype_shared.gsh;
#insert scripts\shared\shared.gsh;

#using scripts\zm\_zm_score;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_equipment;
#using scripts\zm\_zm_unitrigger;

#define WUNDERFIZZ_LIGHT_FX				"madgaz/wunderfizz_2/fx_perk_madgaz_wunderfizz_light"
#define WUNDERFIZZ_CONDENSATION_FX	    "zombie/fx_perk_mule_kick_zmb"

#precache("menu", "WonderfizzMenuBase");
#precache("lui_menu_data", "cw_perk_buyables.owned_perks");
#precache("string", "ZOMBIE_NEED_POWER");
#precache("model", "p9_sur_machine_perk");
#precache("model", "p9_sur_machine_perk_off");

#precache("fx", WUNDERFIZZ_LIGHT_FX);
#precache("fx", WUNDERFIZZ_CONDENSATION_FX);

function autoexec init()
{
    callback::on_connect(&on_player_connected);

    // Register each perk for our menu
    level.cw_perk_buyables = [];

    // Stock 9 perks
    RegisterBuyable("quickrevive");
    RegisterBuyable("deadshot");
    RegisterBuyable("doubletap2");
    RegisterBuyable("staminup");
    RegisterBuyable("armorvest");
    RegisterBuyable("fastreload");
    RegisterBuyable("widowswine");
    RegisterBuyable("additionalprimaryweapon");

    // HarryBo21's Perks
    RegisterBuyable("electriccherry");
    RegisterBuyable("vultureaid");
    RegisterBuyable("tombstone");
    RegisterBuyable("phdflopper");
    RegisterBuyable("combat_efficiency");

    // Sphynx's Perks
    RegisterBuyable("tracker");

    // Logical's Perks
    //RegisterBuyable("jetquiet"); // ffyl
    //RegisterBuyable("immunecounteruav"); // icu

    level thread wonderfizz_location();
}

// registers a new buyable perk
function RegisterBuyable(speciality)
{
    perk = SpawnStruct();
    perk.name = speciality;

    level.cw_perk_buyables[speciality] = perk;
}

// handle use logic
function wonderfizz_location()
{
    level endon("end_game");
    level util::waittill_multiple("all_players_connected", "initial_blackscreen_passed");

    // grab our struct and model
    perk = struct::get("t9_wonderfizz", "targetname");
    model = GetEnt(perk.target, "targetname");

    // set model back and forth to load models
    model SetModel("p9_sur_machine_perk");
    WAIT_SERVER_FRAME;
    model SetModel("p9_sur_machine_perk_off");

    // wait for power to boot things up
    level flag::wait_till("power_on");

    // cool sounds and fx and shaking and shit
    model SetModel("p9_sur_machine_perk");
    light_fx = Spawn( "script_model", model.origin );
	light_fx SetModel( "tag_origin" );
	light_fx.angles = model.angles - ( 0, 0, 0 );

    model Vibrate((0,-100,0), 0.3, 0.4, 3);
    model PlaySound("zmb_perks_power_on");
    model thread zm_perks::play_loop_on_machine();

	PlayFXOnTag(WUNDERFIZZ_LIGHT_FX, light_fx, "tag_origin");
	PlayFXOnTag(WUNDERFIZZ_CONDENSATION_FX, light_fx, "tag_origin");

    // setup trigger
    perk zm_unitrigger::create_unitrigger("Hold ^3[{+activate}]^7 to purchase a variety of Perks", 48, &visibility_and_update_prompt);
	perk.s_unitrigger.inactive_reassess_time = 0.05;
    while(1)
    {
        perk waittill("trigger_activated", player);
        player OpenBuyablesMenu();
        wait 0.05;
    }
}

// return usability
function visibility_and_update_prompt(player)
{
    can_use = self visibility_unitrigger(player);
    if(isdefined(self.hint_string))
    {
        self SetHintString(self.hint_string);
    }
    return can_use;
}

// set hints
function visibility_unitrigger(player)
{
	if(level flag::get("power_on"))
	{
        self.hint_string = "Hold ^3[{+activate}]^7 to purchase a variety of Perks";
		return true;
	}
    else
	{
    	self.hint_string = &"ZOMBIE_NEED_POWER";
    	return false;
    }
}

// updates which perks you own
function UpdateOwnedPerks()
{
    ownedPerks = [];
    foreach(perk in level.cw_perk_buyables)
    {
        name = perk.name;
        isOwned = self playerHasPerk(name);

        if(isOwned)
        {
            ownedPerks[ownedPerks.size] = name;
        }
    }

    ownedPerksStr = "";
    foreach(ownedBuyable in ownedPerks)
    {
        ownedPerksStr += (ownedBuyable + "|");
    }
    
    self SetControllerUIModelValue("cw_perk_buyables.owned_perks", ownedPerksStr);
}

// open the menu
function OpenBuyablesMenu()
{
    self CloseMenu("WonderfizzMenuBase");
    self OpenMenu("WonderfizzMenuBase");

    wait 0.05;

    self UpdateOwnedPerks();
}

// returns if the player has the given perk
function playerHasPerk(name)
{
    if(self HasPerk("specialty_" + name))
    {
        return true;
    }
    return false;
}

// on spawned
function on_player_connected()
{
    self thread WatchForMenuResponse();
}

// responds to data from doing something in menu
function WatchForMenuResponse()
{
    self endon("disconnect");

    for(;;)
    {
        self waittill("menuresponse", menu, response);

        // if the menu response isn't from wonderfizz then we dont care
        if(menu != "WonderfizzMenuBase")
        {
            continue;
        }

        // get the perk name, buy perk and update buyables
        responseData = StrTok(response, ".");
        self perkPurchased(responseData);
        self UpdateOwnedPerks();
    }
}

// purchases the given perk
function perkPurchased(responseData)
{
    buyableName = responseData[1];
    buyableCost = Int(responseData[2]);

    if(self zm_score::can_player_purchase(buyableCost) && !self HasPerk("specialty_" + buyableName))
    {
        self zm_score::minus_to_player_score(buyableCost);
        self zm_utility::play_sound_on_ent("purchase");

        self zm_perks::give_perk("specialty_" + buyableName, false);
    }
}