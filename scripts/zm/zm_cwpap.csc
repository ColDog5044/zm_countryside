#using scripts\codescripts\struct;
#using scripts\shared\callbacks_shared;
#using scripts\shared\exploder_shared;
#using scripts\shared\array_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\util_shared;
#using scripts\shared\fx_shared;
#using scripts\zm\_util;
#using scripts\zm\_zm;
#using scripts\zm\_zm_utility;
#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

// Pre-carga de efectos visuales para energía encendida y mejora del Pack-a-Punch
#precache("client_fx", "ALXS/t9_pap_idk_hoe"); // FX para la energía encendida
#precache("client_fx", "ALXS/t9_pap_idk_hoe_inuse_green"); // FX cuando se usa el Pack-a-Punch
#precache("client_fx", "ALXS/t9_pap_idk_hoe_inuse_red");
#precache("client_fx", "ALXS/t9_pap_idk_hoe_inuse_blastfurnace");
#precache("client_fx", "ALXS/t9_pap_idk_hoe_inuse_deadwire");
#precache("client_fx", "ALXS/t9_pap_idk_hoe_inuse_fireworks");
#precache("client_fx", "ALXS/t9_pap_idk_hoe_inuse_thunderwall");
#precache("client_fx", "ALXS/t9_pap_idk_hoe_inuse_turned");

REGISTER_SYSTEM_EX("zm_cwpap", &__init__, undefined, undefined)

// Función de inicialización, se ejecuta al cargar el sistema
function __init__( localClientNum )
{
    //CSC FX - in CSC File
    clientfield::register( "scriptmover", "t9_pap_FX_idle", VERSION_SHIP, 1, "int", &t9_pap_FX_idle, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
    clientfield::register( "scriptmover", "t9_pap_FX_inuse", VERSION_SHIP, 2, "int", &t9_pap_FX_inuse, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
    clientfield::register( "scriptmover", "t9_pap_FX_inuse_aat", VERSION_SHIP, 3, "int", &t9_pap_FX_inuse_aat, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
    clientfield::register( "scriptmover", "t9_pap_FX_aat_bf", VERSION_SHIP, 3, "int", &t9_pap_FX_inuse_aat, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
    clientfield::register( "scriptmover", "t9_pap_FX_aat_dw", VERSION_SHIP, 3, "int", &t9_pap_FX_inuse_aat, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
    clientfield::register( "scriptmover", "t9_pap_FX_aat_fw", VERSION_SHIP, 3, "int", &t9_pap_FX_inuse_aat, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
    clientfield::register( "scriptmover", "t9_pap_FX_aat_tw", VERSION_SHIP, 3, "int", &t9_pap_FX_inuse_aat, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
    clientfield::register( "scriptmover", "t9_pap_FX_aat_t", VERSION_SHIP, 3, "int", &t9_pap_FX_inuse_aat, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
    level._effect["t9_pap_FX_idle"] = "ALXS/t9_pap_idk_hoe";
    level._effect["t9_pap_FX_inuse"] = "ALXS/t9_pap_idk_hoe_inuse_green";
    level._effect["t9_pap_FX_inuse_aat"] = "ALXS/t9_pap_idk_hoe_inuse_red";
    level._effect["t9_pap_FX_aat_bf"] = "ALXS/t9_pap_idk_hoe_inuse_blastfurnace";
    level._effect["t9_pap_FX_aat_dw"] = "ALXS/t9_pap_idk_hoe_inuse_deadwire";
    level._effect["t9_pap_FX_aat_fw"] = "ALXS/t9_pap_idk_hoe_inuse_fireworks";
    level._effect["t9_pap_FX_aat_tw"] = "ALXS/t9_pap_idk_hoe_inuse_thunderwall";
    level._effect["t9_pap_FX_aat_t"] = "ALXS/t9_pap_idk_hoe_inuse_turned";
    // Solo obtener la referencia al Pack-a-Punch una vez
    level.papstruct = struct::get("pack_a_punch_struct", "targetname");
}

function t9_pap_FX_idle( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
    fx_org = level.papstruct.origin;
    fx_player = util::spawn_model(localClientNum, "tag_origin", fx_org, level.papstruct.angles + (0, 90, 0));
    if(isdefined(self.fx))
    {
        DeleteFX(localClientNum, self.fx);
            self.fx = undefined;
    }

    if(newVal == 1)
    {
            self.fx = PlayFXOnTag(localClientNum, level._effect["t9_pap_FX_idle"], fx_player, "tag_origin");
    }
}

function t9_pap_FX_inuse( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
    fx_org = level.papstruct.origin;
    fx_player = util::spawn_model(localClientNum, "tag_origin", fx_org, level.papstruct.angles + (0, 90, 0));
    if(isdefined(self.fxtwo))
    {
        DeleteFX(localClientNum, self.fxtwo);
            self.fxtwo = undefined;
    }

    if(newVal == 1)
    {
            self.fxtwo = PlayFXOnTag(localClientNum, level._effect["t9_pap_FX_inuse"], fx_player, "tag_origin");
    }
}

function t9_pap_FX_inuse_aat( localClientNum, oldVal, newVal, weapon, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
    keys = getarraykeys(level.aat);
    fx_org = level.papstruct.origin;
    fx_player = util::spawn_model(localClientNum, "tag_origin", fx_org, level.papstruct.angles + (0, 90, 0));
    if(isdefined(self.fxthree))
    {
        DeleteFX(localClientNum, self.fxthree);
            self.fxthree = undefined;
    }

    if(newVal == 1)
    {
            self.fxthree = PlayFXOnTag(localClientNum, level._effect["t9_pap_FX_inuse_aat"], fx_player, "tag_origin");
    }
    if(newVal == 2)
    {
            self.fxthree = PlayFXOnTag(localClientNum, level._effect["t9_pap_FX_aat_bf"], fx_player, "tag_origin");
    }
    if(newVal == 3)
    {
            self.fxthree = PlayFXOnTag(localClientNum, level._effect["t9_pap_FX_aat_dw"], fx_player, "tag_origin");
    }
    if(newVal == 4)
    {
            self.fxthree = PlayFXOnTag(localClientNum, level._effect["t9_pap_FX_aat_fw"], fx_player, "tag_origin");
    }
    if(newVal == 5)
    {
            self.fxthree = PlayFXOnTag(localClientNum, level._effect["t9_pap_FX_aat_tw"], fx_player, "tag_origin");
    }
    if(newVal == 6)
    {
            self.fxthree = PlayFXOnTag(localClientNum, level._effect["t9_pap_FX_aat_t"], fx_player, "tag_origin");
    }
}