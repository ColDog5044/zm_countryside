#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\util_shared;
#using scripts\shared\fx_shared;
#using scripts\shared\trigger_shared;
#using scripts\shared\animation_shared;
#using scripts\shared\aat_shared;

#using scripts\zm\_util;
#using scripts\zm\_zm;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_unitrigger;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_perks;

#using scripts\zm\aats\_zm_aat_blast_furnace;

#insert scripts\shared\aat_zm.gsh;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

// Pre-carga de recursos y modelos
#precache("xmodel", "p9_fxanim_zm_gp_pap_xmodel_off"); // Modelo cuando la energía está apagada
#precache("xmodel", "p9_fxanim_zm_gp_pap_xmodel"); // Modelo cuando la energía está encendida
#precache( "xanim", "xanim_c5969f9b9bb4e89_idle");
#precache( "xanim", "xanim_a79285d6b6f48f4_in_use");
#precache("string", "ZOMBIE_PERK_PACKAPUNCH");
#precache("string", "ZOMBIE_PERK_PACKAPUNCH_AAT");
#precache("string", "ZOMBIE_NEED_POWER");
#using_animtree("cwpapanimtree");

#define SND_UNSUP_PAPPING          true      // true = sound when trying to pap an unpappable weapon || false = no sound
#define USE_HAND_KNUCKLE           false     // true = knuckle anim enabled || false = knuckle anim disabled
#define AAT_FX_COLORS              2       // 1 = all AAT red fx || 2 = each AAT gets its own fx color
#define TRIGGER_COOLDOWN_TIME      2      // The time it takes for the trigger to cool down (seconds)
#define UPGRADE_FXANIM_TIME        2     // The time the upgrading fx and anim lasts after upgrading (seconds), anim will start repeating at 5 seconds #RECOMMENDED TO BE THE SAME OR LOWER THAN TRIGGER COOLDOWN TIME#, IF YOU CHANGE THIS ALSO CHANGE THE FXS ITERATIONS

REGISTER_SYSTEM_EX( "zm_cwpap", &__init__, undefined, undefined )

// Inicialización de variables y efectos
function __init__()
{
    clientfield::register( "scriptmover", "t9_pap_FX_idle", VERSION_SHIP, 1, "int" );
    clientfield::register( "scriptmover", "t9_pap_FX_inuse", VERSION_SHIP, 2, "int" );
    clientfield::register( "scriptmover", "t9_pap_FX_inuse_aat", VERSION_SHIP, 3, "int" );
    clientfield::register( "scriptmover", "t9_pap_FX_aat_bf", VERSION_SHIP, 3, "int" );
    clientfield::register( "scriptmover", "t9_pap_FX_aat_dw", VERSION_SHIP, 3, "int" );
    clientfield::register( "scriptmover", "t9_pap_FX_aat_fw", VERSION_SHIP, 3, "int" );
    clientfield::register( "scriptmover", "t9_pap_FX_aat_tw", VERSION_SHIP, 3, "int" );
    clientfield::register( "scriptmover", "t9_pap_FX_aat_t", VERSION_SHIP, 3, "int" );
    level.snd_unsup_pap = SND_UNSUP_PAPPING;
    level.use_papknuckles = USE_HAND_KNUCKLE;
    level.paptrigstruct = struct::get("pap_trigger_struct", "targetname");
    level.packAPunchModel = GetEnt("pack_a_punch_model", "targetname");
    level.packAPunchModel thread setup_unitrigger();
    level.packAPunchModel thread papIdleSound();
    level thread monitorPower(); // Monitorear el estado de la energía
}

// Monitorear el estado de la energía
function monitorPower()
{
    level flag::wait_till("all_players_spawned");

    level flag::wait_till("power_on");
    level.packAPunchModel thread powerOnAnimation();
	level.packAPunchModel thread monitorPackAPunch();
}

function monitorPackAPunch()
{
    level.packAPunchModel thread pap_jingle_logic();

    // your trigger init logic...
    cooldown_end = .0;
    for(;;)
    {
        self waittill( "trigger_activated", player ); // Make sure to change the trigger variable with whatever var your trig is stored in

        if( GetTime() > cooldown_end ) // First time this trigger is activated, this will always be true
        {
            weapon = player GetCurrentWeapon(); // Obtener el arma actual
            if (zm_weapons::is_weapon_upgraded(weapon))
            {
                if (zm_weapons::weapon_supports_aat(weapon) && ( isdefined( level.aat_in_use ) && level.aat_in_use ) )
                {
                    if(player hasEnoughMoney(2500) && zm_utility::is_player_valid( player ) ) // Si tiene suficiente dinero
                    {
                        player thread giveWeaponAAT();
                        level.packAPunchModel thread papFXIdle(0);
                        level.packAPunchModel UseAnimTree(#animtree);
                        level.packAPunchModel AnimScripted( "optionalNotify", level.packAPunchModel.origin , level.packAPunchModel.angles, %xanim_a79285d6b6f48f4_in_use);
                        level.packAPunchModel thread stopUpgradeAnimationAfterTime(UPGRADE_FXANIM_TIME); // Detener la animación después de 5 segundos
                        level.packAPunchModel thread papInUseAATSound();
                        level.packAPunchModel thread papLeverSound();
                        level.packAPunchModel StopSound( "cw_mus_perks_packa_sting" );
                        level.packAPunchModel StopSound( "cw_mus_perks_packa_jingle" );
                        wait 0.05;
                        level.packAPunchModel PlaySound( "cw_mus_perks_packa_sting" );
                        player zm_audio::create_and_play_dialog( "weapon_pickup", "upgrade" );
                    }
                }
                else
                {
                    //player IPrintLn("WEAPON DOES NOT SUPPORT AAT");
                    if(level.snd_unsup_pap)
                    {
                        level.packAPunchModel PlaySoundToPlayer("zmb_perks_packa_deny", player);
                    }
                    player zm_audio::create_and_play_dialog( "general", "oh_shit" );
                }
            }
            else
            {
                if (zm_weapons::can_upgrade_weapon(weapon))
                {
                    if(player hasEnoughMoney(5000) && zm_utility::is_player_valid( player ) ) // Si tiene suficiente dinero
                    {
                        player thread giveWeaponUpgraded();
                        level.packAPunchModel thread papFXIdle(0);
                        level.packAPunchModel thread papFXInUse(1);
                        level.packAPunchModel UseAnimTree(#animtree);
                        level.packAPunchModel AnimScripted( "optionalNotify", level.packAPunchModel.origin , level.packAPunchModel.angles, %xanim_a79285d6b6f48f4_in_use);
                        level.packAPunchModel thread stopUpgradeAnimationAfterTime(UPGRADE_FXANIM_TIME); // Detener la animación después de 5 segundos
                        level.packAPunchModel thread papInUseSound();
                        level.packAPunchModel thread papLeverSound();
                        level.packAPunchModel StopSound( "cw_mus_perks_packa_sting" );
                        level.packAPunchModel StopSound( "cw_mus_perks_packa_jingle" );
                        wait 0.05;
                        level.packAPunchModel PlaySound( "cw_mus_perks_packa_sting" );
                        if(level.use_papknuckles)
                        {
                            wait 2.2;
                            player zm_audio::create_and_play_dialog( "weapon_pickup", "upgrade" );
                        }
                        else 
                        {
                            player zm_audio::create_and_play_dialog( "weapon_pickup", "upgrade" );
                        }
                    }
                }
                else
                {
                    //player IPrintLn("WEAPON DOES NOT SUPPORT PAPING");
                    if(level.snd_unsup_pap)
                    {
                        level.packAPunchModel PlaySoundToPlayer("zmb_perks_packa_deny", player);
                    }
                    player zm_audio::create_and_play_dialog( "general", "oh_shit" );
                }
            }
            
            cooldown_end = GetTime() + ( TRIGGER_COOLDOWN_TIME * 1000 ); // Multiplying macro by 1000 here to convert from seconds to ms
        }
    }
}

function papFXIdle(reproduce)
{
    level.packAPunchModel clientfield::set( "t9_pap_FX_idle", reproduce );
}

function papFXInUse(reproduce)
{
    level.packAPunchModel clientfield::set( "t9_pap_FX_inuse", reproduce );
}

function papFXInUseAAT(reproduce)
{
    level.packAPunchModel clientfield::set( "t9_pap_FX_inuse_aat", reproduce );
}

function powerOnAnimation()
{
    level.packAPunchModel SetModel("p9_fxanim_zm_gp_pap_xmodel");
    level.packAPunchModel thread playIdleAnimation();
}

// Animación de espera del Pack-a-Punch
function playIdleAnimation()
{
    self UseAnimTree(#animtree);
    self AnimScripted( "", self.origin , self.angles, %xanim_c5969f9b9bb4e89_idle);
    self thread papFXIdle(1);
}

// Detener animación de mejora después de un tiempo
function stopUpgradeAnimationAfterTime(duration)
{
    wait(duration);
    //level.packAPunchModel StopAnimScripted(%xanim_a79285d6b6f48f4_in_use);
    level.packAPunchModel thread papFXInUse(0);
    level.packAPunchModel thread papFXInUseAAT(0);
    level.packAPunchModel thread playIdleAnimation();
}

// Verificar si el jugador tiene suficiente dinero
function hasEnoughMoney(amount)
{
    weapon = self GetCurrentWeapon();
    player = self;
    if(player zm_score::can_player_purchase(amount))
    {
        if (zm_weapons::is_weapon_upgraded(weapon))
        {
            if (zm_weapons::weapon_supports_aat(weapon) && ( isdefined( level.aat_in_use ) && level.aat_in_use ) )
            {
                if (amount >= 2500)
                {
                    player zm_score::minus_to_player_score(amount); // Restar la cantidad necesaria
                    level.packAPunchModel PlaySoundToPlayer("zmb_cha_ching", self);
                }
            }
        }
        else
        {
            if (zm_weapons::can_upgrade_weapon(weapon))
            {
                if (amount >= 5000)
                {
                    player zm_score::minus_to_player_score(amount); // Restar la cantidad necesaria
                    level.packAPunchModel PlaySoundToPlayer("zmb_cha_ching", self);
                }
            }
        }
        return true;
    }
    else
    {
        level.packAPunchModel PlaySoundToPlayer("zmb_perks_packa_deny", self);
        //iprintln("No tienes suficiente dinero.");
        player zm_audio::create_and_play_dialog( "general", "outofmoney");
        return false;
    }
}

function giveWeaponUpgraded()
{
    weapon = self GetCurrentWeapon(); // Obtener el arma actual
    self takeWeapon(weapon); // Quitar el arma actual
    upgrade_weapon = zm_weapons::get_upgrade_weapon(weapon, false);
    if(level.use_papknuckles)
    {
        self DisableWeaponCycling();
        hands = GetWeapon("zombie_knuckle_crack");
        self GiveWeapon(hands);
        self SwitchToWeapon(hands);
        wait(2.2);
        self takeWeapon(hands);
        self EnableWeaponCycling();
    }
    self zm_weapons::weapon_give(upgrade_weapon, true, false, true, true);
    self switchToWeapon(upgrade_Weapon); // Cambiar al arma mejorada
    //self iprintln("¡Arma mejorada instantáneamente!"); // Mensaje de confirmación
}

function giveWeaponAAT() //self = who is upgrading
{
    weapon = self GetCurrentWeapon(); // Obtener el arma actual
    self thread aat::acquire( weapon );
    //self iprintln("¡Arma mejorada instantáneamente con AAT!"); // Mensaje de confirmación
    if(AAT_FX_COLORS == 1)
    {
        level.packAPunchModel thread papFXInUseAAT(1);
    }
    if(AAT_FX_COLORS == 2)
    {
        self thread watchAAT(weapon);
    }
}

function PapPromptAndVisibility(player)
{
    weapon = player GetCurrentWeapon();

    if (level flag::get("power_on"))
    {
        if ( zm_weapons::is_weapon_upgraded( weapon ))
        {
            if (zm_weapons::weapon_supports_aat(weapon))
            {    
                self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH_AAT", 2500 );
            }
            else
            { 
                self SetHintString("");
            }
        }
        // If not, display string to pack non-upgraded weapon
        else 
        {
            if (zm_weapons::can_upgrade_weapon(weapon))
            {
                self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH", 5000 );
            }
            else
            {
                self SetHintString("");
            }
        }
    }
    else
    {
        self SetHintString( &"ZOMBIE_NEED_POWER");
    }

    return true;
}

function papInUseSound()
{
    level.packAPunchModel PlaySound("alxs_cwpap_inuse");
}

function papInUseAATSound()
{
    level.packAPunchModel PlaySound("alxs_cwpap_inuse_aat");
}

function papIdleSound()
{
    level waittill("power_on");
    level.packAPunchModel PlaySound("alxs_cwpap_appear");
    wait 1;
    level.packAPunchModel PlayLoopSound("alxs_cwpap_idle_lp");
}

function papLeverSound()
{
    level.packAPunchModel PlaySound("alxs_cwpap_lever_down");
    wait 1.82;
    level.packAPunchModel PlaySound("alxs_cwpap_lever_up");
}

function watchAAT(weapon)
{
    keys = getarraykeys(level.aat);
    if(self.aat[weapon] == "zm_aat_blast_furnace")
    {
        //self IPrintLn("blastfurnace has been acquired lol");
        level.packAPunchModel thread papFXInUseAAT(2);
    }
    if(self.aat[weapon] == "zm_aat_dead_wire")
    {
        //self IPrintLn("deadwire has been acquired lol");
        level.packAPunchModel thread papFXInUseAAT(3);
    }
    if(self.aat[weapon] == "zm_aat_fire_works")
    {
        //self IPrintLn("fireworks has been acquired lol");
        level.packAPunchModel thread papFXInUseAAT(4);
    }
    if(self.aat[weapon] == "zm_aat_thunder_wall")
    {
        //self IPrintLn("thunderwall has been acquired lol");
        level.packAPunchModel thread papFXInUseAAT(5);
    }
    if(self.aat[weapon] == "zm_aat_turned")
    {
        //self IPrintLn("turned has been acquired lol");
        level.packAPunchModel thread papFXInUseAAT(6);
    }
}

function pap_jingle_logic()
{
    wait RandomIntRange( 10, 60 );
    for( ;; )
    {
        level.packAPunchModel StopSound( "cw_mus_perks_packa_sting" );
        wait 0.05;
        level.packAPunchModel PlaySound( "cw_mus_perks_packa_jingle" );
        wait ( SoundGetPlaybackTime( "cw_mus_perks_packa_jingle" ) * .001 ) + RandomIntRange( 30, 120 );
    }
}

function setup_unitrigger()
{
    unitrigger_pap = SpawnStruct();
    unitrigger_pap.origin = level.paptrigstruct.origin;
    unitrigger_pap.angles = level.paptrigstruct.angles;
    unitrigger_pap.script_unitrigger_type = "unitrigger_box_use";
    unitrigger_pap.cursor_hint = "HINT_NOICON";
    unitrigger_pap.script_width = 40;
    unitrigger_pap.script_height = 50;
    unitrigger_pap.script_length = 40;
    unitrigger_pap.related_parent = level.packAPunchModel;
    unitrigger_pap.inactive_reassess_time = 1;
    zm_unitrigger::unitrigger_force_per_player_triggers(unitrigger_pap, true);
    unitrigger_pap.prompt_and_visibility_func = &PapPromptAndVisibility;
    zm_unitrigger::register_static_unitrigger( unitrigger_pap, &zm_unitrigger::unitrigger_logic );
}