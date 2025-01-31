#using scripts\codescripts\struct;

#using scripts\shared\callbacks_shared;
#using scripts\shared\array_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\_util;
#using scripts\zm\_zm;
#using scripts\zm\_zm_unitrigger;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_utility;

#insert scripts\zm\_zm_utility.gsh;
#insert scripts\zm\_war_perk_return.gsh;

//All0utWar's Perk Return | Version: 1.0 | Released: 7.21.24
#namespace war_perk_return;

REGISTER_SYSTEM_EX( "war_perk_return", &__init__, undefined, undefined )
//-----------------------------------------------------------------------------------
// Setup
//-----------------------------------------------------------------------------------
function __init__()
{
	wait 0.01; //Any other wait seems to prevent the game from starting

	//Properly initialize any player variables
	callback::on_spawned( &war_perk_return_player_setup );

	vending_triggers = GetEntArray( "zombie_vending", "targetname" );
	array::thread_all( vending_triggers, &war_perk_return_spawn );
}

function war_perk_return_spawn()
{
	level waittill("initial_blackscreen_passed");

	self war_perk_return_unitrigger_think( self.script_noteworthy );
}

function war_perk_return_unitrigger_think( str_perk )
{
	self endon("kill_trigger");

	self create_unitrigger(undefined, 80, &war_perk_return_visibility_and_update_prompt, str_perk);

	while( isdefined(self) )
	{
		self waittill("trigger_activated", player);

		removed_perk = player war_remove_perk( str_perk );

		if ( B_RETURN_GIVE_POINTS >= 1 )
		{
			if ( INT_RETURN_PERCENT > 0 || INT_RETURN_PERCENT < 0 )
			{
				return_amount = level._custom_perks[ str_perk ].cost;

				//Fix for solo QR providing zero points for some reason
				if ( (zm_perks::use_solo_revive() && str_perk == "specialty_quickrevive") || return_amount <= 0 )
				{
					return_amount = 500;
				}

				player zm_score::add_to_player_score( return_amount * INT_RETURN_PERCENT );
			}
		}
	}
}

function war_perk_return_visibility_and_update_prompt( player )
{
	can_use = self war_perk_return_visibility_unitrigger( player );

	if ( isdefined( self.hint_string ) )
	{
		self SetHintString( self.hint_string );
	}

	return can_use;
}

function war_perk_return_visibility_unitrigger( player )
{
	if ( array::contains(player.perks_active, self.stub.str_perk) )
	{
		if ( !IS_TRUE( self.stub.related_parent.power_on ) )
		{
			//Disable vending_trigger if power is off
			self.stub.related_parent SetInvisibleToPlayer(player, true);
		}

		if ( B_RETURN_GIVE_POINTS >= 1 )
		{
			self.hint_string = "Hold ^3[{+activate}]^7 to refund perk";
		}
		else
		{
			self.hint_string = "Hold ^3[{+activate}]^7 to remove perk";
		}

		self SetInvisibleToPlayer(player, false);
		return true;
	}
	else
	{
		//Re-enable vending_trigger after return is done
		self.stub.related_parent SetInvisibleToPlayer(player, false);
		self SetInvisibleToPlayer(player, true);
		self.hint_string = "";
		return false;
	}
}

//self is player
function war_remove_perk( perk )
{
	if ( !isdefined( perk ) || !self HasPerk( perk ) )
	{
		//IPrintLnBold("!!!Perk not available!!!");
		return;
	}

	perk_str = perk + "_stop";
	self notify( perk_str );

	if ( zm_perks::use_solo_revive() && perk == "specialty_quickrevive" )
	{
		self.lives--;
	}

	//IPrintLnBold("!!!Stopped " + perk + "!!!");

	return perk;
}

function war_perk_return_player_setup()
{
	//Defines the array that zm_perks() uses for perk tracking
	self.perks_active = [];
}

function create_unitrigger(str_hint, n_radius = 32, func_prompt_and_visibility = &zm_unitrigger::unitrigger_prompt_and_visibility, str_perk = undefined, func_unitrigger_logic =  &zm_unitrigger::unitrigger_logic, s_trigger_type = "unitrigger_radius_use")
{
	self.s_unitrigger = SpawnStruct();
	self.s_unitrigger.origin = self.origin;
	self.s_unitrigger.angles = self.angles;
	self.s_unitrigger.script_unitrigger_type = s_trigger_type;
	self.s_unitrigger.cursor_hint = "HINT_NOICON";
	self.s_unitrigger.hint_string = str_hint;
	self.s_unitrigger.require_look_at = 1;
	self.s_unitrigger.related_parent = self;
	self.s_unitrigger.radius = n_radius;
	self.s_unitrigger.script_width = n_radius;
	self.s_unitrigger.script_height = n_radius;
	self.s_unitrigger.script_length = n_radius;

	//Set up str_perk variable for war_perk_return_visibility_unitrigger() 
	self.s_unitrigger.str_perk = str_perk;

	zm_unitrigger::unitrigger_force_per_player_triggers( self.s_unitrigger, 1 );
	self.s_unitrigger.prompt_and_visibility_func = func_prompt_and_visibility;
	zm_unitrigger::register_static_unitrigger( self.s_unitrigger, func_unitrigger_logic );
}