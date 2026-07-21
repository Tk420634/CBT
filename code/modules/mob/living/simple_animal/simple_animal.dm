GLOBAL_LIST_EMPTY(playmob_cooldowns)
GLOBAL_VAR_INIT(attraction_cooldown, 0.1 SECONDS)
GLOBAL_VAR_INIT(last_attraction_time, 0)

/mob/living/danimal
	name = "animal"
	icon = 'icons/mob/animal.dmi'
	health = 20
	maxHealth = 20
	desc = "Whos a cute little /mob/living/danimal? You are! Yes you are!"
	///Short desc of the mob
	var/desc_short = "Some kind of horrible monster."
	///Important info of the mob
	var/desc_important = ""

	/// The toggle for whether or not this mob is "simple"
	/// Simple mobs process AI much more simply
	var/simple = TRUE
	/// When the mob has this much stamina damage, put them in stamcrit. set to SIMPLEMOB_NO_STAMCRIT
	var/stamcrit_threshold
	/// They are stamcritted for this long when stamcrit
	var/stamcrit_duration = 5 SECONDS
	COOLDOWN_DECLARE(stamcrit_timer)
	gender = PLURAL //placeholder
	///How much blud it has for bloodsucking
	blood_volume = 425 //blood will smeared only a little bit from body dragging
	var/bossmob = FALSE
	status_flags = CANPUSH
	rotate_on_lying = TRUE

	/* **************** *
	 * Appearance stuff *
	 * **************** */
	/* Visuals */
	var/advanced = FALSE
	var/icon_living = ""
	///icon when the animal is dead. Don't use animated icons for this.
	var/icon_dead = ""
	///We only try to show a gibbing animation if this exists.
	var/icon_gib = null
	/// color to colorize the dead sprite, if it should be different from the living sprite
	var/color_dead = null
	//Mob may be offset randomly on both axes by this much
	var/randpixel = 0

	/* Speech, emotes */
	var/list/speak = list()
	///Emotes while speaking IE: Ian [emote], [text] -- Ian barks, "WOOF!". Spoken text is generated from the speak variable.
	var/list/speak_emote = list()
	var/speak_chance = 0
	///Hearable emotes
	var/list/emote_hear = list()
	///Unlike speak_emote, the list of things in this variable only show by themselves with no spoken text. IE: Ian barks, Ian yaps.
	var/list/emote_see = list()

	/* Interacted With Messages */
	///Help-intent verb in present continuous tense.
	var/response_help_continuous = "pokes"
	///Help-intent verb in present simple tense.
	var/response_help_simple = "poke"
	///Disarm-intent verb in present continuous tense.
	var/response_disarm_continuous = "shoves"
	///Disarm-intent verb in present simple tense.
	var/response_disarm_simple = "shove"
	///Harm-intent verb in present continuous tense.
	var/response_harm_continuous = "hits"
	///Harm-intent verb in present simple tense.
	var/response_harm_simple = "hit"

	/* Attack Other Messages */
	///Attacking verb in present continuous tense.
	var/attack_verb_continuous = "attacks"
	///Attacking verb in present simple tense.
	var/attack_verb_simple = "attack"
	///Attacking, but without damage, verb in present continuous tense.
	var/friendly_verb_continuous = "nuzzles"
	///Attacking, but without damage, verb in present simple tense.
	var/friendly_verb_simple = "nuzzle"

	/* Taunt Emotes */
	/// list of *emotes played when the mob gets angy at the target, I think
	var/list/emote_taunt
	/// Play an extra sound?
	var/emote_taunt_sound = FALSE // Does it have a sound associated with the emote? Defaults to false.
	/// chance to do a taunt emote, 0-100, defaults to 0
	var/taunt_chance = 0

	/* Sounds */
	/// Sound to play when the mob is idle, occasionally
	var/idlesound = null
	/// Sound to play when the mob attacks something
	var/attack_sound = null
	///Played when someone punches the creature.
	var/attacked_sound = "punch"
	/// The sound played on death.
	var/death_sound = null
	///What kind of footstep this mob should have. Null if it shouldn't have any.
	var/footstep_type
	/// The sound played when the mob shoots?
	var/projectilesound
	/// Play a sound after they shoot?
	var/sound_after_shooting
	/// How long after shooting should it play?
	var/sound_after_shooting_delay = 1 SECONDS
	/// How much will the pitch vary? first is how much lower it can go, second is how high it can go. from -100 to 100. please make the first number smaller than the second
	var/list/vary_pitches = list(-100, 100)
	/// set to a value between -100 and 100 to change the mob's pitch. Set to 0 for default pitch
	var/sound_pitch = 0
	var/list/projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(PLASMA_VOLUME),
		SP_VOLUME_SILENCED(PLASMA_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(PLASMA_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(null),
		SP_DISTANT_RANGE(null)
	)


	/* ************ *
	 * COMBAT STUFF *
	 * ************ */

	/* Armor */
	/// The armor datum being used, dont touch this!
	var/datum/armor/mob_armor
	/// The armor values to be fed into the armor datum, TOUCH THIS!
	var/list/armor_list = ARMOR_VALUE_ZERO
	/// Additional armor modifiers that are applied to the actual armor value
	var/mob_armor_tokens = list()
	/// Description line for their armor, cached nice and sweet
	var/mob_armor_description = span_phobia("Oh deary me all my armor fell off uwu") // dear god dont let this show up
	/// Damage multipliers per source
	/// 1 for full damage , 0 for none , -1 for 1:1 heal from that source.
	///todo: make this not a damn list
	var/list/damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, CLONE = 1, STAMINA = 1, OXY = 1)

	/* Damage */
	///LETTING SIMPLE ANIMALS ATTACK? WHAT COULD GO WRONG. Defaults to zero so Ian can still be cuddly.
	/// Lower bound of the damage range for a simple animal's melee attack, should it do damage.
	var/melee_damage_lower = 0
	/// Upper bound of the damage range for a simple animal's melee attack, should it do damage.
	var/melee_damage_upper = 0
	///Damage type of a simple mob's melee attack, should it do damage.
	var/melee_damage_type = BRUTE
	///How much damage this simple animal does to /obj, if any.
	var/obj_damage = 0
	///How much armour they ignore, as a flat reduction from the targets armour value.
	/// //todo: armor overhaul for the fourth damn time
	var/armour_penetration = 0
	/// If bombs can gib this mob
	var/bombs_can_gib_me = TRUE
	/// The max kind of environment this mob can smash through, is a bitfield for some reason
	/// //todo: make this not awful
	var/environment_smash = ENVIRONMENT_SMASH_NONE
	//How much wounding power it has
	var/wound_bonus = 0
	//How much bare wounding power it has
	var/bare_wound_bonus = 0
	//If the attacks from this are sharp
	var/sharpness = SHARP_NONE

	/* Death Stuff */
	///list of things spawned at mob's loc when it dies.
	var/list/loot = list()
	///How do we handle the loot list? Should be either MOB_LOOT_ALL or a number. If its a number, use an associated weighted list for `loot`!
	var/loot_drop_amount = MOB_LOOT_ALL
	///Drop a random number, 1 through loot_drop_amount? only applicable if loot_drop_amount is a number
	var/loot_amount_random = TRUE
	///causes mob to be deleted on death, useful for mobs that spawn lootable corpses.
	var/del_on_death = FALSE
	/// "X dies with a bottomnal moan~"
	var/deathmessage = ""

	/* Attraction stuff */
	var/datum/wander_attractor/current_attraction
	var/attracted_move_to_delay
	var/wander_attractor_arrival_distance = 3
	var/attractable = FALSE
	// so this checks if the mob has moved more than 2 tiles in the past 5 seconds, and if it hasnt, kills the attraction movement
	var/attraction_stuck_check_time = 5 SECONDS
	var/attraction_stuck_check_distance = 2
	var/last_attraction_check_coords
	var/last_attraction_check_time
	// a cooldown on being attracted, cus spamming pathfinding is kinda bad
	var/attraction_cooldown = 10 SECONDS
	var/last_attraction_time




	var/ignore_other_mobs = TRUE // If TRUE, the mob will fight other mobs, if FALSE, it will only fight players
	var/override_ignore_other_mobs = FALSE // If TRUE, it'll ignore the idnore other mobs flag, for mobs that are supposed to be hostile to everything


/*  */

	///Healable by medical stacks? Defaults to yes.
	var/healable = 1

	var/seconds_per_wander = 1
	var/last_wander_time = 0
	///Use this to temporarely stop random movement or to if you write special movement code for animals.
	var/stop_wandering = 0
	///Does the mob wander around when idle?
	var/wander = 1
	///When set to 1 this stops the animal from moving when someone is pulling it.
	var/stop_wandering_when_pulled = 1

	/* UNUSED VARS */
	///Temperature effect.
	var/minbodytemp = 250
	var/maxbodytemp = 350
	///Atmos effect - Yes, you can make creatures that require plasma or co2 to survive. N2O is a trace gas and handled separately, hence why it isn't here. It'd be hard to add it. Hard and me don't mix (Yes, yes make all the dick jokes you want with that.) - Errorage
	// var/list/atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0) //Leaving something at 0 means it's off - has no maximum
	///This damage is taken when atmos doesn't fit all the requirements above.
	var/unsuitable_atmos_damage = 2

	///Hot simple_animal baby making vars.
	var/list/offspring_type = null
	var/next_scan_time = 0
	///Sorry, no spider+corgi buttbabies.
	var/animal_species

	///Innate access uses an internal ID card.
	var/obj/item/card/id/access_card = null
	/// Wumbonian fugu stuff, dont touch, it touches it
	var/buffed = FALSE
	///If the mob can be spawned with a gold slime core. HOSTILE_SPAWN are spawned with plasma, FRIENDLY_SPAWN are spawned with blood.
	var/gold_core_spawnable = NO_SPAWN

	var/datum/weakref/nest
	var/nest_coords

	///Sentience type, for slime potions.
	var/sentience_type = SENTIENCE_ORGANIC

	///LETS SEE IF I CAN SET SPEEDS FOR SIMPLE MOBS WITHOUT DESTROYING EVERYTHING. Higher speed is slower, negative speed is faster.
	/// Breaks everything, makes player controlled mobs wayyyyy tooo slow - didn't ask teehee
	/// dont use this, it doesnt change the mob's speed, it only works when a player is inside, and even then, its awful
	var/speed = 1
	/// The deciseconds between each step of movement. Lower is faster
	var/move_to_delay = 4
	var/minimum_distance = 0

	/* ******************* *
	 * RTS COMMANDER STUFF *
	 * ******************* */
	var/allow_movement_on_non_turfs = FALSE
	var/target_coords
	var/RTS_move_target_range = 2
	var/RTS_aggro_lockout = 0
	var/RTS_max_RTS_frustration_seconds = 10
	var/RTS_frustration_seconds = 0
	var/RTS_last_frustration = 0
	var/RTS_frustration_coords
	var/no_ghost_gta

	/* Ghost role stuff */
	///Can ghosts just hop into one of these guys?
	var/can_ghost_into = FALSE
	///The class of mob this is, for purposes of per-mob ghost cooldowns
	var/ghost_mob_id = "generic"
	///Timeout between dying or ghosting in this mob and going back into another mob
	var/ghost_cooldown_time = 15 MINUTES
	/// has the mob been lazarused?
	var/lazarused = FALSE
	/// Who lazarused this mob?
	var/datum/weakref/lazarused_by
	/// required pop to hop into this thing
	var/pop_required_to_jump_into = 0
	/// mob abilities that probably dont work anymore
	var/obj/effect/proc_holder/mob_common/direct_mobs/send_mobs
	var/obj/effect/proc_holder/mob_common/summon_backup/call_backup
	var/obj/effect/proc_holder/mob_common/make_nest/make_a_nest
	var/obj/effect/proc_holder/mob_common/unmake_nest/unmake_a_nest
	var/datum/action/innate/ghostify/ghostme


	///If the creature has, and can use, hands.
	/// please. PLEASE dont use this
	var/dextrous = FALSE
	var/dextrous_hud_type = /datum/hud/dextrous

	///The Status of our AI, can be set to AI_ON (On, usual processing), AI_IDLE (Will not process, but will return to AI_ON if an enemy comes near), AI_OFF (Off, Not processing ever), AI_Z_OFF (Temporarily off due to nonpresence of players).
	var/AIStatus = AI_ON
	///once we have become sentient, we can never go back.
	var/can_have_ai = TRUE
	///convenience var for forcibly waking up an idling AI on next check.
	var/shouldwakeup = FALSE

	///Domestication.
	var/tame = 0

	///I don't want to confuse this with client registered_z.
	var/my_z

	COOLDOWN_DECLARE(ding_spam_cooldown)

	/// Sets up mob diversity
	var/list/variation_list = list()
	/// obey the variation requests
	var/vary = TRUE
	var/list/autoset_variations = DEFAULT_VARIATIONS


	///If this is a player's ckey then this mob was spawned as a player's character
	var/player_character = null

	///multichance projectile hit behaviour (MCPHB)
	var/mcphb_arms_hit = FALSE
	var/mcphb_legs_hit = FALSE
	
	/// makes certain mobs explode into stuff when they die
	var/am_important = FALSE // you are not important
	coolshadow = FALSE

	var/quit_stealing_my_bike = FALSE

	var/bounty = 10
	var/kill_credit


	/// used for movement, to store the coords of the next tile to move to, for tile target movement
	/// format: list(x, y, z)
	var/list/move_target_coords
	/// Used for movement, to store an entity to move towards
	/// Takes priority over move_target_coords
	var/datum/weakref/move_target_entity

	/// from hostile, now here!
	/// data relating to a mob's target, or something
	var/datum/mob_target_data/target_data
	var/ranged = FALSE
	var/rapid = 0 //How many shots per volley.
	var/rapid_fire_delay = 2 //Time between rapid fire shots

	var/can_dodge_in_melee = FALSE
	var/approaching_target = FALSE //We should dodge now
	var/in_melee = FALSE	//We should sidestep now
	var/dodge_prob = 0
	var/sidestep_per_cycle = 0 //How many sidesteps per npcpool cycle when in melee

	var/extra_projectiles = 0 //how many projectiles above 1?
	/// How long to wait between shots?
	var/auto_fire_delay = GUN_AUTOFIRE_DELAY_NORMAL
	var/projectiletype	//set ONLY it and NULLIFY casingtype var, if we have ONLY projectile

	var/casingtype		//set ONLY it and NULLIFY projectiletype, if we have projectile IN CASING
	/// Deciseconds between moves for automated movement. m2d 3 = standard, less is fast, more is slower.
	var/list/friends = list()
	var/list/foes = list()

	/// What happens when this mob is EMP'd?
	var/list/emp_flags = list()
	/// What emp effects are active?
	var/list/active_emp_flags = list()
	/// Smoke!
	var/datum/effect_system/smoke_spread/bad/smoke

	var/rapid_melee = 1			 //Number of melee attacks between each npc pool tick. Spread evenly.
	var/melee_queue_distance = 4 //If target is close enough start preparing to hit them if we have rapid_melee enabled

	var/can_melee_attack = TRUE

	var/melee_smash_cooldown_duration = 1 SECONDS
	COOLDOWN_DECLARE(melee_smash_cooldown)

	var/melee_attack_cooldown_duration = 2 SECONDS
	COOLDOWN_DECLARE(melee_attack_cooldown)

	var/sight_shoot_delay_duration = 0.7 SECONDS
	COOLDOWN_DECLARE(sight_shoot_delay)

	/// The base random spread of the mob's ranged attacks.
	var/ranged_base_spread = 7
	/// The spread added to the base spread per shot for a burst.
	var/ranged_extra_spread_per_shot = 10
	/// the max spread this mob can accumulate
	var/ranged_max_spread = 45
	var/ranged_message = "fires" //Fluff text for ranged mobs
	var/ranged_cooldown = 0 //What the current cooldown on ranged attacks is, generally world.time + ranged_cooldown_time
	var/ranged_cooldown_time = 3 SECONDS //How long, in deciseconds, the cooldown of ranged attacks is
	var/ranged_ignores_vision = FALSE //if it'll fire ranged attacks even if it lacks vision on its target, only works with environment smash
	var/check_friendly_fire = 0 // Should the ranged mob check for friendlies when shooting
	var/should_factionize_shots = TRUE


	var/decompose = TRUE //Does this mob decompose over time when dead?
	//var/decomposition_time = 5 MINUTES
	//COOLDOWN_DECLARE(decomposition_schedule)

//These vars are related to how mobs locate and target
	/// doesnt do anything important, all mobs have this as true
	/// previously made the target evaluation check more conditions, which would make it use more CPU
	/// but we arent playing on our grandpa's 386 anymore, we can have our mobs do cool things!
	var/robust_searching = TRUE //By default, mobs have a simple searching method, set this to 1 for the more scrutinous searching (stat_attack, stat_exclusive, etc), should be disabled on most mobs
	/// Allows the mob to track targets even they are out of LOS, but still within the mob's vision range
	// todo: implement a sort of last-known-location system, like turrets
	var/robuster_searching = FALSE
	var/vision_range = 9 //How big of an area to search for targets in, a vision of 9 attempts to find targets as soon as they walk into screen view
	var/aggroed_vision_range = 9 //If a mob is aggro, we search in this radius. Defaults to 9 to keep in line with original simple mob aggro radius
	var/max_tracking_range = 14 //If a mob is aggro, we search in this radius. Defaults to 9 to keep in line with original simple mob aggro radius

	var/search_objects = 0 //If we want to consider objects when searching around, set this to 1. If you want to search for objects while also ignoring mobs until hurt, set it to 2. To completely ignore mobs, even when attacked, set it to 3
	var/search_objects_timer_id //Timer for regaining our old search_objects value after being attacked
	var/search_objects_regain_time = 30 //the delay between being attacked and gaining our old search_objects value back
	var/list/wanted_objects = list() //A typecache of objects types that will be checked against to attack, should we have search_objects enabled
	var/attack_downed_players = TRUE // ignore stat attack, attack people in soft crit.... for a while
	var/attack_downed_until = HOSTILES_ATTACK_UNTIL_THIS_FAR_INTO_CRIT // Attack until they're this proportion between soft crit and hard crit
	var/stat_attack = SOFT_CRIT //Mobs with stat_attack to UNCONSCIOUS will attempt to attack things that are unconscious, Mobs with stat_attack set to DEAD will attempt to attack the dead.
	var/stat_exclusive = FALSE //Mobs with this set to TRUE will exclusively attack things defined by stat_attack, stat_attack DEAD means they will only attack corpses
	/// Basically means to ignore factions and just attack everything, unless they are a friend
	var/attack_same = 0 //Set us to 1 to allow us to attack our own faction
	var/datum/weakref/targetting_origin = null //all range/attack/etc. calculations should be done from this atom, defaults to the mob itself, useful for Vehicles and such
	var/attack_all_objects = FALSE //if true, equivalent to having a wanted_objects list containing ALL objects.

	var/peaceful = FALSE //Determines if mob is actively looking to attack something, regardless if hostile by default to the target or not

	var/frustration_total
	var/last_frustration
	var/max_frustration = 5 SECONDS

	//Tactical Retreat Code//
	//tactical retreat and heal vars.  These exist to give mobs a breakpoint to cut and run from combat. 
	//Once they have disengaged they will heal up. While they can't return to combat at least they'll be prepped for the next player push.
	var/retreat_health_percent = 0 //.25 = 25% health remaining
	var/max_heal_amount = 0 //how much the mob heals up to when its triggered its low health tactical retreat
	var/heal_per_life = 0 //how much per life tick the mob heals, %. 0.25 is 25%.
	var/tactical_retreat = 0 //Distance in tiles the mob retreats in a panic
	var/retreat_message_said = FALSE 
	var/actual_retreat_message = "The %NAME tries to flee from %TARGET!"
	var/max_healing_ability = 0 //In decimal percent, 1 = 100%
	var/healing_message = "The %NAME is trying to heal itself!"
	var/healing_sound = 'sound/items/tendingwounds.ogg' // 
	var/healing_volume = 30


//These vars activate certain things on the mob depending on what it hears
	var/attack_phrase = "" //Makes the mob become hostile (if it wasn't beforehand) upon hearing
	var/peace_phrase = "" //Makes the mob become peaceful (if it wasn't beforehand) upon hearing
	var/reveal_phrase = "" //Uncamouflages the mob (if it were to become invisible via the alpha var) upon hearing
	var/hide_phrase = "" //Camouflages the mob (Sets it to a defined alpha value, regardless if already 'hiddeb') upon hearing

	/// Probability it'll do some other kind of melee attack, like a knockback hit.
	var/alternate_attack_prob = 0
	/// At what percent of their health does the mob change states? Like, get ANGY on low-health or something. set to 0 or FALSE to disable
	/// Is a decimal, 0 through 1. 0.5 means half health, 0.25 is quarter health, etc
	var/low_health_threshold = 0
	/// Has the mob done its Low Health thing?
	var/is_low_health = FALSE
	/// Does this mob un-itself if nobody's on the Z level?
	var/despawns_when_lonely = TRUE
	/// timer for despawning when lonely
	var/lonely_timer_id

	/// Makes it so the mob tally doesnt count this thing as being deleted when its just sleeping
	var/went_to_sleep = FALSE

	var/time_between_move_randomization = 3 SECONDS
	var/last_move_randomization = 0

	var/vision_mult_duration = (15 SECONDS)
	var/vision_mult_active_until = 0 //if vision_mult_active_until is greater than world.time, we use the multiplied vision range, for things like attraction that temporarily boost vision

	// ------------------------ //
	// Movement vars ---------- //
	// ------------------------ //

	var/movement_mode = MOB_MOVE_IDLE
	// set a movement mode here to have it only use that mode when not idle
	// for things like mobs that don't retreat, or mobs that only retreat
	var/movement_mode_lock
	// when going from idle to active, which mode should it go to furst?
	var/movement_mode_first = MOB_MOVE_TOWARDS_TARGET

	/// If our mob runs from players when they're too close, set in tile distance. By default, mobs do not retreat.
	var/retreat_distance = 0
	/// destination coords for retreating, considered "there" if the mob is "there"
	var/retreat_dest = null
	/// how far from the dest is considered "there" for retreating
	var/retreat_dest_radius = 1

	/// approach -> retreat triggers
	var/retreat_after_attack = TRUE
	var/retreat_after_attack_count = 1

	var/retreat_after_duration = TRUE
	var/retreat_after_duration_length = 7 SECONDS

	var/retreat_after_damaged = TRUE

	/// retreat -> approach triggers
	var/approach_after_duration = TRUE
	var/approach_after_duration_duration = 5 SECONDS

	var/approach_after_damaged = TRUE

	var/approach_after_attack = TRUE
	var/approach_after_attack_count = 1

	/// retreat behavior
	var/retreat_moves_before_switch = 3
	var/retreat_moves_left = 0 // autoset
	var/retreat_move_max_duration = 2 SECONDS

	var/retreat_to_approach_chance = 50


	/// record keeping
	var/attacks_performed_this_move = 0
	var/damaged_this_move = FALSE

	/// timer keeping
	var/retreat_timeout = 0 // timeout for each move made, so they dont get stuck
	var/retreat_timeout_to_approach = 0 // timeout for the whole mode, so they dont just retreat forever, if wanted
	var/approach_timeout = 0
	var/movement_mode_last_changed = 0
	var/movement_last_move = 0

	// windup stuff
	/// Can be: MOB_WINDUP_NONE, MOB_WINDUP_WINDING_UP, MOB_WINDUP_READY
	var/windup_state = MOB_WINDUP_NONE
	// vars relating to the winding up phase of windups
	/// Mob uses the windup system
	var/windup_enabled = TRUE
	/// Time when the mob is fully wound up and ready to check if it can hit the target
	var/windup_delay_complete = 0
	/// Time it takes for a mob to complete its windup, after which it will be allowed to attack
	var/windup_delay_duration = 0.3 SECONDS
	/// The time when the mob will stop being wound up and reset its windup state, if it hasn't attacked yet
	var/windup_ready_timeout = 0
	/// How long the mob will stay wound up before the windup is cancelled and reset
	var/windup_ready_duration = 1 SECONDS
	
	/// This plays when the mob's attack windup starts. It requires windup_delay_duration to be set.
	var/windup_sound_start = 'sound/effects/flip.ogg'
	/// Sound to play when the mob is fully wound up and ready to attack
	var/windup_sound_ready = 'sound/effects/lick.ogg'
	/// Sound to play when the mob's windup is cancelled and reset
	var/windup_sound_cancel = 'sound/effects/meow1.ogg'
	/// How much to shrink and grow this mob when it's doing a windup attack.
	var/windup_magnitude = 0.3 // in decigrundles
	/// how long to do the windup animation for, in seconds
	var/windup_animation_duration = 0.5 SECONDS

	/// TRUE while a mob is winding up a melee attack, otherwise FALSE.
	var/winding_up_melee = FALSE // unused now

	/// melee attack stuff
	/// Number of rapid melee attacks left for this tick
	var/melee_rapid_attacks_left = 0
	/// currently rapid attacking
	var/melee_rapid_attacking = FALSE

	/// data stored for intra-tick processing, so we dont have to pass around a million args
	var/list/blackboard_tick = list()

	/// if the mob should use the advanced target priority selection system
	/// Only set TRUE if you have at least one of the other two set
	var/use_advanced_target_priority_selection = FALSE
	var/use_distance_priority = FALSE
	var/use_health_priority = FALSE

	/// targetting flag handling stuff
	var/turrets_are_priority = TRUE // if turrets are priority targets, set to FALSE to make them not be pruiority them
	var/players_are_priority = TRUE // if players are priority targets, set to FALSE to make them not be pruiority them
	var/objects_are_priority = TRUE // if objects are priority targets, set to FALSE to make them not be pruiority them
	var/foes_are_priority = TRUE // if foes are priority targets, set to FALSE to make them not be pruiority them
	var/assemlies_are_priority = TRUE // if assembles are priority targets, set to FALSE to make them not be pruiority them

	/// target retention stuff
	/// Target retention is the mob's ability to maintain a target that goes out of sight or something.
	/// If this is set to FALSE, the mob will drop its target as soon as it goes out of sight.
	/// When the mob realizes it cant see its target anymore (lockers dont count, they're smart enough to know u went in)
	/// it sets a time for when it gives up on the target
	var/target_retention_allowed = TRUE
	/// It wil still consider the target visible if it goes inside something like a locker
	var/target_retention_understands_lockers = TRUE
	/// the time in seconds that the mob will retain its target for, if out of sight, and sight is required to target
	var/target_retention_duration = 5 SECONDS
	/// the cooldown thing
	var/target_retention_finish_time = 0

	/// mob saw the target go in something
	var/target_seen_go_into_something = FALSE

	/// patience stuff
	/// Patience is how long the mob is willing to wait until its target is can be attacked
	/// performing a melee or ranged attack will reset the patience timer
	/// causes smething to happen when it runs out, like the mob will scatter or something, depending on the mob
	var/patience_allowed = TRUE
	/// the patience duration in seconds that we'll be patient for
	var/patience_duration = 5 SECONDS
	/// the time when the mob will give up on its target if it cant be attacked
	var/patience_finish_time = 0

	/// frustration stuff
	/// Frustration relates to mob movement, and works to track if the mob is making progress towards its target or not
	/// periodically records its coordinates, then later compares em to see oif they moved
	/// i, i guess, //todo: implement this

	/// The... slowdown? of a mob while a player is inside it? does nothing while ai controlled




/mob/living/danimal/Initialize(mapload, nest_spawned)
	. = ..()
	GLOB.simple_animals[AIStatus] += src
	if(gender == PLURAL)
		gender = pick(MALE,FEMALE)
	if(!real_name)
		real_name = name
	if(attractable && !attracted_move_to_delay)
		attracted_move_to_delay = move_to_delay
	if(!loc)
		stack_trace("Simple animal being instantiated in nullspace")
	update_simplemob_varspeed()
	if(dextrous)
		AddComponent(/datum/component/personal_crafting)
	if(footstep_type)
		AddComponent(/datum/component/footstep, footstep_type, 1, 3)
	pixel_x = rand(-randpixel, randpixel)
	pixel_y = rand(-randpixel, randpixel)
	/// WARNING: DUPLICATED CODE, MAKE BETTER
	setup_mob_armor_values()
	//todo: make armor actually make sense and work properly, wtf was i and everyone else thinking
	if (isnull(mob_armor))
		mob_armor = getArmor(arglist(armor_list))
	else if (!istype(mob_armor, /datum/armor))
		stack_trace("Invalid type [mob_armor.type] found in .armor during /mob/living/danimal Initialize()")
	/// End duplicated code
	setup_mob_armor_description()
	if(can_ghost_into)
		make_ghostable()
	setup_variations()
	if(isnull(stamcrit_threshold))
		stamcrit_threshold = maxHealth * 2
	/// hostile
	set_origin(src)
	target_data = new /datum/mob_target_data(src)
	wanted_objects = typecacheof(wanted_objects)
	if(nest_spawned != "TOPHEAVY-KOBOLD")
		SSmobs.mob_spawned(src)
	if(MOB_EMP_DAMAGE in emp_flags)
		smoke = new /datum/effect_system/smoke_spread/bad
		smoke.attach(src)
	if(mapload && despawns_when_lonely)
		unbirth_self(TRUE)

/mob/living/danimal/ComponentInitialize()
	. = ..()
	if(can_ghost_into)
		AddElement(/datum/element/ghost_role_eligibility, free_ghosting = FALSE, penalize_on_ghost = TRUE)
	RegisterSignal(src, COMSIG_HOSTILE_CHECK_FACTION,PROC_REF(infight_check))
	RegisterSignal(src, COMSIG_ATOM_BUTCHER,PROC_REF(butcher_me))
	RegisterSignal(src, COMSIG_ATOM_CAN_BUTCHER,PROC_REF(can_butcher))
	RegisterSignal(src, COMSIG_MOB_IS_IMPORTANT,PROC_REF(am_i_important))
	RegisterSignal(src, COMSIG_ATOM_QUEST_SCANNED,PROC_REF(i_got_scanned))
	RegisterSignal(src, COMSIG_RTS_SELECTED,PROC_REF(i_got_selected))
	RegisterSignal(src, COMSIG_MOVELOOP_PREPROCESS_CHECK,PROC_REF(GetAttractionMovementFlags))

/mob/living/danimal/Destroy()
	/// hostile
	QDEL_NULL(target_data)
	unset_origin()
	unset_target()
	friends = null
	foes = null
	blackboard_tick.Cut()
	blackboard_tick = null
	GiveTarget(null)
	if(!went_to_sleep)
		SSmobs.mob_despawned(src)
	if(smoke)
		QDEL_NULL(smoke)
	/// simpleanimal
	move_target_coords = null
	move_target_entity = null
	GLOB.simple_animals[AIStatus] -= src
	SSnpcpool.currentrun -= src
	QDEL_NULL(current_attraction)
	sever_link_to_nest()
	if(make_a_nest)
		QDEL_NULL(make_a_nest)
	if(unmake_a_nest)
		QDEL_NULL(unmake_a_nest)
	LAZYREMOVE(GLOB.mob_spawners[initial(name)], src)
	if(!LAZYLEN(GLOB.mob_spawners[initial(name)]))
		GLOB.mob_spawners -= initial(name)
	if(lazarused)
		LAZYREMOVE(GLOB.mob_spawners["Tame [initial(name)]"], src)
		if(!LAZYLEN(GLOB.mob_spawners["Tame [initial(name)]"]))
			GLOB.mob_spawners -= "Tame [initial(name)]"
	lazarused_by = null

	var/turf/T = get_turf(src)
	if (T && AIStatus == AI_Z_OFF)
		SSidlenpcpool.idle_mobs_by_zlevel[T.z] -= src
	
	QDEL_NULL(access_card)

	return ..()

/mob/living/danimal/attack_ghost(mob/user, latejoinercalling)
	. = ..()
	if(!cleared_to_enter(user))
		return
	if(lazarused)
		to_chat(user, span_userdanger("[name] has been lazarus injected or tamed by beastmaster! There are special rules for playing as this creature!"))
		to_chat(user, span_alert("You will be bound to serving a certain person, and very likely will be required to be friendly to Nash and its citizens! Just something to keep in mind!"))
		var/mob/the_master
		if(isweakref(lazarused_by))
			the_master = lazarused_by.resolve()
		if(the_master)
			to_chat(user, span_alert("Your master will be [the_master.real_name]! Follow their commands at all costs! (within reason of course)"))
		else
			to_chat(user, span_alert("Your master will be Nash and its citizens, protect them at all costs!"))
	var/ghost_role = alert("Hop into [name]? (This is a ghost role, still in development!)","Play as a mob!","Yes, spawn me in!","No, I wanna be a ghost!")
	if(ghost_role == "No, I wanna be a ghost!" || !loc)
		return
	if(QDELETED(src) || QDELETED(user))
		return
	if(latejoinercalling)
		var/mob/dead/new_player/NP = user
		if(istype(NP))
			NP.close_spawn_windows()
			NP.stop_sound_channel(CHANNEL_LOBBYMUSIC)
	log_game("[key_name(user)] hopped into [name]")
	become_the_mob(user)
	return TRUE

/mob/living/danimal/proc/become_the_mob(mob/user)
	if(!user.ckey)
		return
	user.transfer_ckey(src, TRUE)
	grant_all_languages()
	if(ispath(send_mobs))
		var/obj/effect/proc_holder/mob_common/direct_mobs/DM = send_mobs
		send_mobs = new DM
		AddAbility(send_mobs)
	if(ispath(call_backup))
		var/obj/effect/proc_holder/mob_common/summon_backup/CB = call_backup
		call_backup = new CB
		AddAbility(call_backup)
	if(ispath(make_a_nest))
		var/obj/effect/proc_holder/mob_common/make_nest/MN = make_a_nest
		make_a_nest = new MN
		AddAbility(make_a_nest)
		unmake_a_nest = new
		AddAbility(unmake_a_nest)
	if(lazarused)
		to_chat(src, span_userdanger("[name] has been lazarus injected or tamed by beastmaster! There are special rules for playing as this creature!"))
		to_chat(src, span_alert("You will be bound to serving a certain person, and very likely will be required to be friendly to Nash and its citizens! Just something to keep in mind!"))
		var/mob/the_master
		if(isweakref(lazarused_by))
			the_master = lazarused_by.resolve()
		if(the_master)
			to_chat(src, span_alert("Your master is [the_master.real_name]! Follow their commands at all costs! (within reason of course)"))
			log_game("[key_name(src)] has been informed that they ([name]) are lazarus injected/tamed, and will serve [the_master.real_name].")
			if(mind)
				mind.store_memory("You have been lazarus injected or tamed by [the_master.real_name], and you're bound to follow their commands! (within reason)")
		else
			to_chat(src, span_alert("Your master is be Nash and its citizens, protect them at all costs!"))
			if(mind)
				mind.store_memory("You have been lazarus injected or tamed, and are bound to serve the town of Nash and protect its people.")
			log_game("[key_name(src)] has been informed that they ([name]) are lazarus injected/tamed, and will serve Nash.")
	if(lonely_timer_id)
		deltimer(lonely_timer_id)
		lonely_timer_id = null
	unqueue_unbirth()

/mob/living/danimal/proc/cleared_to_enter(mob/user)
	if(!can_ghost_into)
		return FALSE
	if(health <= 0 || stat == DEAD)
		return FALSE
	if(!SSticker.HasRoundStarted() || !loc)
		return FALSE
	if(QDELETED(src) || QDELETED(user))
		return FALSE
	if(jobban_isbanned(user, ROLE_SYNDICATE))
		to_chat(user, span_warning("You are jobanned from playing as mobs!"))
		return FALSE
	/*if(!(z in COMMON_Z_LEVELS))
		to_chat(user, span_warning("[name] is somewhere that blocks them from being ghosted into! Try somewhere aboveground (or not in a dungeon!)"))
		return FALSE*/ // Kekeke, zlevel restrictions are antifun anyway!!!!!!!!!!!!!!!!
	if(!lazarused_by && living_player_count() < pop_required_to_jump_into)
		to_chat(user, span_warning("There needs to be at least [pop_required_to_jump_into] living players to hop in this! This check is bypassed if the mob has had a lazarus injector used on it though. Which it hasn't (yet)."))
		return FALSE
	if(client)
		to_chat(user, span_warning("Someone's in there! Wait your turn!"))
		return FALSE
	if(player_character && player_character != user.ckey)
		to_chat(user, span_warning("This mob is someone else's character so you cannot hop into them!"))
		return FALSE
	if(!user.key)
		return FALSE
	/*if(!islist(GLOB.playmob_cooldowns[user.key]))
		GLOB.playmob_cooldowns[user.key] = list()
	if(GLOB.playmob_cooldowns[user.key][ghost_mob_id] > world.time)
		var/time_left = GLOB.playmob_cooldowns[user.key][ghost_mob_id] - world.time*/ // No, respawn times are instant
		//if(check_rights_for(user.client, R_ADMIN))
		//	to_chat(user, span_green("You shoud be unable to hop into mobs for another [DisplayTimeText(time_left)], but you're special cus you're an admin and you can ghost into mobs whenever you want, also everyone loves you and thinks you're cool."))
		//else // yeah no turns out its not a great idea
		/*to_chat(user, span_warning("You're unable to hop into mobs for another [DisplayTimeText(time_left)]."))
		return FALSE*/
	return TRUE


/mob/living/danimal/proc/i_got_scanned(datum/source, mob/scanner)
	if(!nest_coords)
		return
	var/turf/nest_turf = coords2turf(nest_coords)
	if(!nest_turf)
		return
	var/obj/structure/nest/N = locate(/obj/structure/nest) in nest_turf
	if(!N)
		return
	SEND_SIGNAL(N, COMSIG_ATOM_QUEST_SCANNED, scanner)

/mob/living/danimal/proc/am_i_important()
	return am_important

/mob/living/danimal/proc/i_got_selected(datum/source, mob/selecter)
	// if(!selecter)
	// 	return
	// var/myteam = selecter.ckey
	// if(!selecter.ckey)
	// 	myteam = "bingus"
	// myteam = "team-[myteam]" // Team discovery channel!
	// faction |= myteam

/mob/living/danimal/hostile/Move(atom/newloc, dir , step_x , step_y)
	if(!winding_up_melee && can_dodge_in_melee && approaching_target && prob(dodge_prob) && moving_diagonally == 0 && isturf(loc) && isturf(newloc))
		return dodge(newloc,dir)
	else
		return ..()

/mob/living/danimal/proc/infight_check(mob/living/danimal/H)
	if(SSmobs.can_attack_npc(src, H))
		return
	if(H.client || client || player_character || H.player_character)
		return
	if(override_ignore_other_mobs || H.override_ignore_other_mobs)
		return
	if(!istype(H))
		return
	return (H.ignore_other_mobs || ignore_other_mobs)



/mob/living/danimal/hostile/RangedAttack(atom/A, params) //Player firing
	if(ranged && ranged_cooldown <= world.time)
		GiveTarget(A)
		OpenFire(A)
		DelayNextAction()
	. = ..()
	return TRUE

//Coyote Add
/mob
	///A detailed description of this mob that can be read if you examine them.
	var/flavortext = ""
	///A detailed description of the player who's controlling this mob's out-of-character roleplaying preferences. Do not set.
	var/oocnotes = ""
	///The specific name of this mob's species or subtype. Used for examine text (ie "this is Nutty a Squirrel", where Squirrel is the verbose_species)
	var/verbose_species = null

/mob/living/danimal/proc/print_flavor_text()
	if(flavortext && flavortext != "")
		var/msg = replacetext(flavortext, "\n", " ")
		if(length(msg) <= 40)
			return span_notice("[msg]")
		else
			return "<span class='notice'>[html_encode(copytext(msg, 1, 37))]... <a href='byond://?src=\ref[src];flavor_more=1'>More...</span></a>"

/mob/living/danimal/examine(mob/user)
	if(player_character)
		var/list/dat = list()
		dat += "<span class='info'>*---------*\n This is [icon2html(src, user)] <EM>[src.name]</EM>[verbose_species ? ", a <EM>[verbose_species]</EM>" : ""]!</span>"
		if(profilePicture)
			dat += "<a href='?src=[REF(src)];enlargeImageCreature=1'><img src='[PfpHostLink(profilePicture, pfphost)]' width='125' height='auto' max-height='300'></a>"
		//Hands
		for(var/obj/item/I in held_items)
			if(!(I.item_flags & ABSTRACT))
				dat += "[p_they(TRUE)] [p_are()] holding [I.get_examine_string(user)] in [p_their()] [get_held_index_name(get_held_index_of_item(I))]."
		//Internal storage
		if(internal_storage && !(internal_storage.item_flags & ABSTRACT))
			dat += "[p_they(TRUE)] [p_are()] wearing [internal_storage.get_examine_string(user)]."
		//Cosmetic hat - provides no function other than looks
		if(head && !(head.item_flags & ABSTRACT))
			dat += "[p_they(TRUE)] [p_are()] wearing [head.get_examine_string(user)] on [p_their()] head."
		if(flavortext)
			dat += "[print_flavor_text()]"
		if(oocnotes)
			dat += "<span class = 'deptradio'>OOC Notes:</span> <a href='?src=\ref[src];oocnotes=1'>\[View\]</a>"
		if(src.getBruteLoss())
			if(src.getBruteLoss() < (maxHealth/2))
				dat += span_warning("[p_they(TRUE)] looks bruised.")
			else
				dat += span_warning("<B>[p_they(TRUE)] looks severely bruised and bloodied!</B>")
		if(src.getFireLoss())
			if(src.getFireLoss() < (maxHealth/2))
				dat += span_warning("[p_they(TRUE)] looks burned.")
			else
				dat += span_warning("<B>[p_they(TRUE)] looks severely burned.</B>")
		//Personality and RP Preferences quirk display
		dat += get_personality_traits(user)
		//SPECIAL stats display
		dat += "[print_special()]"
		if(client && ((client.inactivity / 10) / 60 > 20)) //20 Minutes
			dat += "\[Inactive for [round((client.inactivity/10)/60)] minutes\]"
		else if(disconnect_time)
			dat += "\[Disconnected/ghosted [round(((world.realtime - disconnect_time)/10)/60)] minutes ago\]"
		if(lazarused)
			dat += span_danger("[p_they(TRUE)] seems to have been revived!<br>")
		dat += "<span class='info'>*---------*</span>"
		return dat
	else
		. = ..()
		. += mob_armor_description
		if(lazarused)
			. += span_danger("[p_they(TRUE)] seems to have been revived!")

/// If user is set, the mob will be told to be loyal to that mob
/mob/living/danimal/proc/make_ghostable(mob/user)
	can_ghost_into = TRUE
	AddElement(/datum/element/ghost_role_eligibility, free_ghosting = TRUE, penalize_on_ghost = FALSE)
	LAZYADD(GLOB.mob_spawners[initial(name)], src)
	// RegisterSignal(src, COMSIG_MOB_GHOSTIZE_FINAL,PROC_REF(set_ghost_timeout))
	if(istype(user))
		lazarused = TRUE
		lazarused_by = WEAKREF(user)
		if(user.mind)
			user.mind.store_memory("You were revived by [user.real_name], and thus are compelled to follow their commands and protect them!")
		show_message(span_userdanger("You were revived by [user.real_name], and are bound to protect them and follow their commands!"))
		LAZYREMOVE(GLOB.mob_spawners[initial(name)], src)
		if(!LAZYLEN(GLOB.mob_spawners[initial(name)]))
			GLOB.mob_spawners -= initial(name)
		LAZYADD(GLOB.mob_spawners["Tame [initial(name)]"], src)

/// Player left the mob's body
/mob/living/danimal/proc/set_ghost_timeout()
	SIGNAL_HANDLER
	if(!key)
		return // cant do much without a key!
	if(!islist(GLOB.playmob_cooldowns[key]))
		GLOB.playmob_cooldowns[key] = list()
	GLOB.playmob_cooldowns[key][ghost_mob_id] = world.time + ghost_cooldown_time	

/// Health and Life and Suigh

/mob/living/danimal/BiologicalLife(seconds, times_fired)
	if(!CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		walk(src, 0)
	. = ..()
	var/am_alive = .
	if(!am_alive)
		walk(src, 0) //stops walking
		/*if(decompose && COOLDOWN_FINISHED(src, decomposition_schedule))
			visible_message(span_notice("\The dead body of the [src] decomposes!"))
			dust(TRUE)*/
		if(decompose && world.time > timeofdeath + 3 MINUTES)//give players enough time to finish their fights and butcher the real way
			visible_message(span_notice("\The dead body of the [src] decomposes!"))
			dust(TRUE, TRUE)
		return
	passive_healing() // just had to put the procs where they would be run yeh, should work now, should be it, probably ye
	queue_naptime()
	check_health()

/mob/living/danimal/updatehealth()
	..()
	health = clamp(health, 0, maxHealth)
	var/slow = 0
	if(client && !HAS_TRAIT(src, TRAIT_IGNOREDAMAGESLOWDOWN))//Player controlled animal
		var/health_percent = ((health/maxHealth)*100)//1-100 scale for health
		if(health_percent <= 50 && health_percent > 0)//Start slowdown at half health, stop slowdown when health is at or below zero to prevent divide by zero errors
			slow += ((50/health_percent)/2)//0.5 slowdown at 1/2 health, 1 slowdown at 1/4 health, etc
	add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown, TRUE, slow)

/mob/living/danimal/update_stat()
	if(status_flags & GODMODE)
		return
	if(stat != DEAD)
		if(health <= 0)
			death()
		else
			if(IsSleeping())
				set_stat(UNCONSCIOUS)
			else
				set_stat(CONSCIOUS)
	med_hud_set_status()

/mob/living/danimal/proc/check_health()
	if(low_health_threshold <= 0)
		return FALSE
	if(stat == DEAD)
		return FALSE
	if (QDELETED(src)) // diseases can qdel the mob via transformations
		return FALSE

	if(is_low_health && health > (maxHealth * low_health_threshold)) // no longer low health
		make_high_health()
		return TRUE
	if(!is_low_health && health < (maxHealth * low_health_threshold))
		make_low_health()
		return TRUE

/// Override this with what should happen when going from low health to high health
/mob/living/danimal/proc/make_high_health()
	return

/// Override this with what should happen when going from high health to low health
/mob/living/danimal/proc/make_low_health()
	return

/// oh no it failed a tick, by runtiming or something, shut down the mob and highlight it or something
/mob/living/danimal/proc/Failed()
	ShutDownEverything()
	color = "#FF00FF"

/mob/living/danimal/handle_status_effects()
	..()
	if(stuttering)
		stuttering = 0

/mob/living/danimal/attacked_by(obj/item/I, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1, damage_addition, damage_override)
	. = ..()
	WasAttackedBy(I, user)

/mob/living/danimal/bullet_act(obj/item/projectile/P)
	. = ..()
	WasAttackedBy(P, P.firer, TRUE)

/mob/living/danimal/proc/WasAttackedBy(atom/movable/implement, atom/movable/attacker, approach)
	if(QDELETED(implement) || QDELETED(attacker) || QDELETED(src))
		return
	if(!attacker)
		return
	if(AIStatus == AI_OFF)
		return
	if(client)
		return
	if(peaceful == TRUE)
		peaceful = FALSE
	if(stat != CONSCIOUS)
		return
	if(get_target() && prob(50))
		return
	GiveTarget(attacker, TRUE)
	if(approach)
		perform_move_action(attacker, move_to_delay, 3)

/* *********************************
 * Main AI loop for hostile mobs. This is where the mob decides what to do each tick.
 * Kinda important
 * Performed every mob AI tick (currently 0.5 seconds) to try and update what it should be doing
 * 
 */
/mob/living/danimal/proc/handle_automated_action()
	set waitfor = FALSE
	. = "bad"
	if(AIStatus == AI_OFF)
		ShutDownEverything() // PresidentMadagascar, a man in brazil is coughing
		return FALSE
	
	if(simple)
		return TRUE // simple animals dont do anything, they just exist and wander around
	
	//danbuttfat = TRUE // vital and always true

	// update everything needing updating, record stuff
	// sets flags for what we can and probably should do this tick
	ClearTickBB()

	UpdateRTS()
	UpdateAIStatusPreTick()
	UpdateTarget()
	UpdateWindup() // set
	UpdateMeleeAttack()
	UpdateRangedAttack()
	UpdateSmash()
	UpdateAttraction()
	UpdateMovementTarget()
	UpdateDodging()

	// perform actions
	PerformMovement()
	PerformCombat()
	PerformOtherActions() // smash stuff, etc

	// clean up
	CleanupTick()
	UpdateAIStatusPostTick() // in case our actions have made us want to change states
	consider_despawning()
	ClearTickBB() // clear the blackboard for the next tick, so we dont have stale data

	return TRUE

	////////////////////////////////////
	if(environment_smash)
		EscapeConfinement()

	// if(AICanContinue(possible_targets))
	// 	var/atom/my_origin = get_origin()
	// 	var/atom/my_target = get_target()
	// 	if(my_target && !QDELETED(target) && my_origin && !my_origin.Adjacent(target))
	// 		DestroyPathToTarget()
	// 	if(!perform_automated_combat_move(possible_targets))     //if we lose our target
	// 		if(AIShouldSleep(possible_targets))	// we try to acquire a new one
	// 			toggle_ai(AI_IDLE)			// otherwise we go idle
	// return 1

/mob/living/danimal/proc/UpdateRTS()
	// todo: this

/mob/living/danimal/proc/UpdateAIStatusPreTick()
	if(RTS_move_ordered())
		toggle_ai(AI_ON)
		return TRUE
	if(AIShouldBeAwake())
		toggle_ai(AI_ON)
		return TRUE

/mob/living/danimal/proc/UpdateAIStatusPostTick()
	if(UpdateAIStatusPreTick())
		return // being on is important, going idle less so
	//todo: has-target checks, time-since-target-lost checks, frustration, etc

/* ********************************************************** *
 * Target acquisition and retention
 * Most AI stuff needs a target to do anything
 * Targets dont have to be mobs... but they almost always are
 * ********************************************************** */
/// gives target if we didnt
/mob/living/danimal/proc/UpdateTarget(list/bb)
	bb = bb || blackboard_tick
	var/list/targ_retention_return = TryRetainTarget()
	if(targ_retention_return[MTEV_CAN_RETAIN_TARGET])
		set_target_eval(targ_retention_return)
		bb[MBB_HAS_TARGET_FROM_LAST_TICK] = TRUE
		bb[MBB_HAS_TARGET]                = TRUE
		bb[MBB_TARGET_EVAL]               = targ_retention_return
		return // target retained, job's done
	// possible_targets is a reference and modifies the caller's list
	// the closest this code gets to an out parameter
	//if we don't have a target, we try to find one
	bb[MBB_HAS_TARGET] = !!FindATarget()

/mob/living/danimal/proc/TryRetainTarget()
	. = list()
	if(!target_retention_allowed)
		return
	var/atom/my_target = get_or_remove_target()
	if(!my_target)
		return
	. |= EvalTarget(my_target)
	if(.[MTEV_CAN_BE_TARGETED] != TRUE)
		return // hard no longer valid
	if(get_dist(get_origin(), my_target) <= SSmobs.always_retain_target_range)
		.[MTEV_CAN_RETAIN_TARGET] = TRUE
		return // too far away
	if(CanSee(my_target, target_retention_understands_lockers))
		.[MTEV_CAN_RETAIN_TARGET] = TRUE
		return
	// have target, can't see it, but it's close enough to retain. timer time!
	if(target_retention_finish_time == 0)
		target_retention_finish_time = world.time + target_retention_duration
	if(world.time < target_retention_finish_time)
		.[MTEV_CAN_RETAIN_TARGET] = TRUE
		return

/mob/living/danimal/proc/UpdateAttraction()
	return
	// todo: full rewrite of attraction, and also merging hostile into simple_animal
	// todo: continue driving these tack nails into my nuts

/// Check if we are able to do a melee to our target
/// Updates flags if so
/// todo: init check to auto-set to not use windup if someone bungled the vars
/mob/living/danimal/proc/UpdateWindup()
	if(!windup_enabled)
		return
	var/atom/my_target = get_or_remove_target()
	if(!my_target)
		WindupKill()
		return
	switch(windup_state)
		if(MOB_WINDUP_NONE)
			WindupStart(my_target)
			return
		if(MOB_WINDUP_WINDING_UP)
			WindupCharging(my_target)
			return
		if(MOB_WINDUP_READY)
			WindupReady(my_target)
			return
		else
			WindupKillForever()
			return

/// Checks if we can windup and attack our target, and if so, gets everything ready for th ewwindup
/mob/living/danimal/proc/WindupStart()
	var/atom/my_target = get_or_remove_target()
	if(!my_target)
		WindupKill()
		return
	if(windup_state != MOB_WINDUP_NONE)
		return
	if(!IsInMeleeRange(my_target))
		return
	// ok we're in range, lets start this bad bingus up
	windup_state = MOB_WINDUP_WINDING_UP
	windup_ready_timeout = world.time + windup_ready_duration
	if(windup_sound_start)
		playsound(
			src,
			windup_sound_start,
			150,
			FALSE,
			distant_range = 4)
	if(windup_magnitude)
		INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/,do_windup), windup_magnitude, windup_delay_duration)
	// timer set, state set, sound played, animation started
	// next ticks will go through waiting through the charging state and such

/// handles calculating when the mob is done charging and ready to attack, and if so, sets the state to ready
/mob/living/danimal/proc/WindupCharging()
	var/atom/my_target = get_or_remove_target()
	if(!my_target)
		WindupKill()
		return
	if(windup_state != MOB_WINDUP_WINDING_UP)
		return
	if(world.time < windup_delay_complete)
		return // not yet! =3
	// ok we're done charging, lets get ready to attack
	windup_state = MOB_WINDUP_READY
	if(windup_sound_ready)
		playsound(
			src,
			windup_sound_ready,
			150,
			FALSE,
			distant_range = 4)
	// if we are ready, we will check if we can attack in the next tick

/// handles calculating when the mob has been wound up too long, and resets it if that so is to be of the case
/mob/living/danimal/proc/WindupReady()
	var/atom/my_target = get_or_remove_target()
	if(!my_target)
		WindupKill()
		return
	if(windup_state != MOB_WINDUP_READY)
		return
	if(world.time < windup_ready_timeout)
		return // not yet! =3
	// ok we're done being ready, lets reset the windup
	WindupKill()
	if(windup_sound_cancel)
		playsound(
			src,
			windup_sound_cancel,
			150,
			FALSE,
			distant_range = 4)
	// ok took too long, no more windup, reset it

/// handles killing the windup state and resetting it to none, for when we lose our target or something
/mob/living/danimal/proc/WindupKill()
	if(windup_state == MOB_WINDUP_NONE)
		return
	windup_state = MOB_WINDUP_NONE
	windup_delay_complete = 0
	windup_ready_timeout = 0

/// turns off the windup state forever, in case the vars are borken or something
/mob/living/danimal/proc/WindupKillForever()
	windup_state = MOB_WINDUP_NONE
	windup_delay_complete = 0
	windup_ready_timeout = 0
	windup_enabled = FALSE

// melee update
/// checks if we can *initiate* a melee this tick, and sets some vars accordingly
/mob/living/danimal/proc/UpdateMeleeAttack(list/bb)
	if(!islist(bb)) // choose your own boardventure
		bb = blackboard_tick // default to main tick's blackboard, or use the passed one for like, rapid attacks and such
	bb[MBB_MELEE_ATTACK_ALLOWED] = FALSE
	bb[MBB_MELEE_ATTACK_CD_READY] = FALSE
	bb[MBB_MELEE_ATTACK_WINDUP_READY] = FALSE
	var/atom/my_target = get_or_remove_target()
	if(!my_target)
		return
	if(!can_melee_attack)
		return
	if(melee_attack_cooldown > world.time)
		return
	bb[MBB_MELEE_ATTACK_CD_READY] = TRUE
	if(windup_enabled && windup_state != MOB_WINDUP_READY)
		return
	bb[MBB_MELEE_ATTACK_WINDUP_READY] = TRUE
	if(!IsInMeleeRange(my_target))
		return
	bb[MBB_MELEE_ATTACK_ALLOWED] = TRUE

/// checks if my_target is in melee range, cus stuff uses it a lot i fugess
/mob/living/danimal/proc/IsInMeleeRange()
	var/atom/my_target = get_or_remove_target()
	if(!my_target)
		return FALSE
	var/atom/my_origin = get_origin()
	var/atom/target_origin = get_turf(my_target)
	if(!my_origin || !target_origin)
		return FALSE
	return src.can_reach(my_origin, reach = melee_range)

/// Checks if we can *initiate* a ranged attack this tick, and sets some vars accordingly
/mob/living/danimal/proc/UpdateRangedAttack(list/bb)
	if(!islist(bb)) // choose your own boardventure
		bb = blackboard_tick // default to main tick's blackboard, or use the passed one for like, rapid attacks and such

	bb[MBB_RANGED_ATTACK_ALLOWED] = FALSE
	bb[MBB_RANGED_ATTACK_CD_READY] = FALSE
	var/atom/my_target = get_or_remove_target()
	if(!my_target)
		return
	if(ranged_cooldown > world.time)
		return
	bb[MBB_RANGED_ATTACK_CD_READY] = TRUE
	if(!CheckLine(my_target, MLF_OPAQUE))
		return
	bb[MBB_RANGED_ATTACK_ALLOWED] = TRUE

/mob/living/danimal/proc/MeleeActionIfPossible(patience = TRUE, atom/target_override = null)
	if(COOLDOWN_TIMELEFT(src, melee_attack_cooldown))
		return TRUE
	COOLDOWN_START(src, melee_attack_cooldown, melee_attack_cooldown_duration)
	var/atom/my_target = target_override || get_target()
	var/atom/origin = get_origin()
	if(!winding_up_melee && origin && isturf(origin.loc) && my_target.Adjacent(origin)) //If they're next to us, attack
		MeleeAction(TRUE, target_override)
	else
		if(!winding_up_melee && rapid_melee > 1 && get_dist(src, my_target) <= melee_queue_distance)
			MeleeAction(FALSE, target_override)
		in_melee = FALSE //If we're just preparing to strike do not enter sidestep mode
	return TRUE

//What we do after closing in
/mob/living/danimal/proc/MeleeAction(patience = TRUE, atom/target_override = null)
	if(ismob(target_override) && mob_faction_is_friendly_to_target(target_override))
		return
	if(rapid_melee > 1)
		var/datum/callback/cb = CALLBACK(src,PROC_REF(CheckAndAttack))
		var/delay = SSnpcpool.wait / rapid_melee
		for(var/i in 1 to rapid_melee)
			addtimer(cb, (i - 1)*delay)
	else
		AttackingTarget(target_override)
	if(patience)
		StartPatience()

/mob/living/danimal/proc/CheckAndAttack()
	var/atom/origin = get_origin()
	var/atom/my_target = get_target()
	if(my_target && origin && isturf(origin.loc) && my_target.Adjacent(origin) && !incapacitated())
		AttackingTarget()

/mob/living/danimal/proc/perform_automated_combat_move(list/possible_targets)//Step 5, handle movement between us and our targette
	stop_wandering = TRUE
	if (peaceful == TRUE)
		DropTarget()
		return FALSE
	
	var/atom/my_target = get_target()
	if(!my_target || !EvalTarget(my_target))
		DropTarget()
		return FALSE
	var/turf/T = get_turf(src)
	if(my_target.z != T.z)
		DropTarget()
		return 0

	var/atom/origin = get_origin()
	if(!(my_target in possible_targets))
		handle_frustration()
		return FALSE
	reset_frustration()
	if(get_dist(src, my_target) > max_tracking_range)
		DropTarget()
		return FALSE // someday, make them go to the last seen turf if possible
	
	perform_ranged_action(my_target) //If we can shoot at them, do that before moving
	perform_smash_action()
	perform_move_action()
	variate_retreat_distance()

	if(winding_up_melee)
		return 0
	var/target_distance = get_dist(origin,my_target)
	if(ranged && target_distance <= max_tracking_range) //We ranged? Shoot at em
		if(!my_target.Adjacent(origin) && ranged_cooldown <= world.time) //But make sure they're not in range for a melee attack and our range attack is off cooldown
			OpenFire(my_target)
	if(retreat_distance != null && !winding_up_melee) //If we have a retreat distance and aren't winding up an attack, check if we need to run from our targette
		if(target_distance <= retreat_distance && CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE)) //If targette's closer than our retreat distance, run
			set_glide_size(DELAY_TO_GLIDE_SIZE(move_to_delay))
			walk_away(src,my_target,retreat_distance,move_to_delay)
		else
			perform_move_action(my_target,move_to_delay,minimum_distance) //Otherwise, get to our minimum distance so we chase them
	else
		perform_move_action(my_target,move_to_delay,minimum_distance)
	/// roll to randomize this thing... if its an option
	variate_retreat_distance()
	if(my_target)
		if(MeleeActionIfPossible(FALSE, my_target))
			return 1
	return 0

	if((environment_smash & ENVIRONMENT_SMASH_WALLS) || (environment_smash & ENVIRONMENT_SMASH_RWALLS) || robuster_searching || SSmobs.debug_everyone_has_robuster_searching) //If we're capable of smashing through walls, forget about vision completely after finding our targette
		perform_move_action(my_target,move_to_delay,minimum_distance)
		if(my_target.loc != null && get_dist(origin, my_target.loc) <= get_vision_range()) //We can't see our targette, but he's in our vision range still
			if(ranged_ignores_vision && ranged_cooldown <= world.time) //we can't see our targette... but we can fire at them!
				OpenFire(my_target)
		else
			if(FindHidden())
				return 1
	return 0

/mob/living/danimal/proc/handle_frustration()
	if(!last_frustration)
		last_frustration = world.time
		return
	if(world.time - last_frustration >= max_frustration)
		DropTarget()
		reset_frustration()
		return TRUE

/mob/living/danimal/proc/reset_frustration()
	frustration_total = 0
	last_frustration = 0

/// *********************
/// MOVEMENT PROCS
/// *********************

/// the args are overrides
/mob/living/danimal/proc/perform_move_action(targette, delay, minimum_distance = 0)
	var/atom/my_target = get_move_target(targette)
	var/move_delay = get_move_delay(delay)
	var/distance_from_target = get_target_standoff_distance(minimum_distance, my_target)
	if(my_target == targette)
		approaching_target = TRUE
	else
		approaching_target = FALSE
	if(CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		set_glide_size(DELAY_TO_GLIDE_SIZE(move_to_delay))
		walk_to(src, my_target, minimum_distance, delay)

/// finds somewhere for the mob to try and move towards
/mob/living/danimal/proc/get_move_target(targette)
	if(targette)
		return targette
	else
		update_movement_mode()
		switch(movement_mode)
			if(MOB_MOVE_TOWARDS_TARGET)
				return get_target()
			if(MOB_MOVE_AWAY_FROM_TARGET)
				return get_retreat_target()
			else
				return get_target()

/mob/living/danimal/proc/get_move_delay(delay)
	if(delay)
		return delay
	else
		return variate_move_to_delay()

// /mob/living/danimal/proc/get_target_standoff_distance(minimum_distance, atom/move_target)
// 	if(minimum_distance)
// 		return minimum_distance
// 	if(movement_mode == MOB_MOVE_AWAY_FROM_TARGET)
// 		return 0 // we want to move to the target, yeah
// 	if(movement_mode == MOB_MOVE_TOWARDS_TARGET) // now we're getting somewhere
// 		if(approach_distance)
// 			return approach_distance
		
// 	else
// 		var/dist = get_dist(src, move_target)
// 		if(dist <= melee_queue_distance)
// 		return variate_minimum_distance()

/// **
/// RETREAT STUFF
/// **

/mob/living/danimal/proc/get_retreat_target()
	var/turf/T = coords2turf(retreat_dest)
	if(isturf(T))
		return T
	else
		return get_target()

/mob/living/danimal/proc/is_at_retreat_dest(turf/T)
	// check timeout
	if(world.time > retreat_timeout)
		return TRUE
	if(!isturf(T))
		T = coords2turf(retreat_dest)
		if(!isturf(T))
			return FALSE
	return (get_dist(src, T) > retreat_dest_radius)

/// uses that wacky bullet casing eject code to find somewhere to run away to
/mob/living/danimal/proc/get_new_retreat_dest()
	var/atom/my_target = get_target()
	if(!my_target)
		set_new_retreat_dest(pick(oview(5, src))) // shrug
		return coords2turf(retreat_dest) // pick a direction, probably wont be used, no target means we'll probably just not move
	/// dir to check in
	var/cardinal = get_dir(src, my_target)
	var/possible_dirs = list(cardinal, turn(cardinal, 90), turn(cardinal, -90))
	var/dir_to_check = pick(possible_dirs)
	var/spread = ceil(get_dist(src, my_target) / 2) // its spread is +- the number given to it
	var/retreat_range = variate_retreat_distance()
	var/turf/poss_dest = get_ranged_target_turf(src, dir_to_check, retreat_range, spread)
	if(!isturf(poss_dest))
		poss_dest = safepick(oview(5, my_target)) || get_turf(src) // just get something idk
	set_new_retreat_dest(poss_dest)
	return poss_dest

/mob/living/danimal/proc/set_new_retreat_dest(turf/T)
	retreat_dest = atom2coords(T)
	retreat_timeout = world.time + retreat_timeout_duration
	return retreat_dest

/// ***********************
/// MOVEMENT UPDATOR
/// ***********************
//todo: a more reliable move timer
//todo: what counts as a 'move' ? Especially for approaching
//todo: maybe moves only count for retreating? approach is a timer / action based?
/mob/living/danimal/proc/update_movement_mode()
	if(!get_target())
		set_movement_mode(MOB_MOVE_IDLE)
		return movement_mode
	// determine which mode we should be in based on stuff
	if(movement_mode_lock)
		set_movement_mode(movement_mode_lock)
	else
		switch(movement_mode)
			if(MOB_MOVE_IDLE) // was idle, dive in
				set_movement_mode(movement_mode_first)

			if(MOB_MOVE_TOWARDS_TARGET)
				if(retreat_distance <= 0)
					set_movement_mode(MOB_MOVE_TOWARDS_TARGET) // if we dont have a retreat distance, we might as well just stay in approach mode
					return
				if(!should_move_towards_target())
					set_movement_mode(MOB_MOVE_AWAY_FROM_TARGET)
				else
					set_movement_mode(MOB_MOVE_TOWARDS_TARGET)

			if(MOB_MOVE_AWAY_FROM_TARGET)
				if(!should_move_away_from_target())
					set_movement_mode(MOB_MOVE_TOWARDS_TARGET)
				else
					set_movement_mode(MOB_MOVE_AWAY_FROM_TARGET)
	return movement_mode

/// simple checks to see if we should keep doing what we're doing, or switch it up
/mob/living/danimal/proc/should_move_towards_target()
	if(retreat_after_attack)
		if(attacks_performed_this_move >= retreat_after_attack_count)
			return FALSE
	if(retreat_after_duration)
		if(world.time > approach_timeout)
			return FALSE
	if(retreat_after_damaged)
		if(damaged_this_move)
			return FALSE
	return TRUE

/mob/living/danimal/proc/should_move_away_from_target()
	// typical checks
	if(approach_after_attack)
		if(attacks_performed_this_move >= approach_after_attack_count)
			return FALSE
	if(approach_after_duration)
		if(world.time > retreat_timeout_to_approach)
			return FALSE
	if(approach_after_damaged)
		if(damaged_this_move)
			return FALSE
	if(retreat_moves_left <= 0)
		return FALSE
	return TRUE

/// ***********************
/// MOVEMENT MODE SETTOR
/// ***********************

/mob/living/danimal/proc/set_movement_mode(new_mode)
	var/prev_mode = movement_mode
	movement_mode = new_mode
	var/mode_changed = prev_mode != movement_mode
	if(mode_changed)
		clear_movement_data()
	var/time_in_mode = world.time - movement_mode_last_changed
	switch(movement_mode)
		if(MOB_MOVE_IDLE)
			stop_wandering = FALSE
		if(MOB_MOVE_TOWARDS_TARGET)
			stop_wandering = TRUE
			update_approach(mode_changed, time_in_mode) // mostly for overriding
		if(MOB_MOVE_AWAY_FROM_TARGET)
			if(retreat_distance <= 0)
				return set_movement_mode(MOB_MOVE_TOWARDS_TARGET) // if we dont have a retreat distance, we might as well just stay in approach mode
			stop_wandering = TRUE
			update_retreat(mode_changed, time_in_mode)
	return movement_mode

/mob/living/danimal/proc/update_approach(mode_changed, time_in_mode)
	if(mode_changed)
		approach_timeout = world.time + get_approach_duration()

/// Handles updating which tile to run to, and the moves left to run
/mob/living/danimal/proc/update_retreat(mode_changed, time_in_mode)
	var/need_new_dest = FALSE
	if(is_at_retreat_dest(get_retreat_target()))
		need_new_dest = TRUE
	if(mode_changed)
		need_new_dest = TRUE
		retreat_moves_left = get_retreat_moves()
		retreat_timeout_to_approach = world.time + get_retreat_move_max_duration() // set the timeout for how long we should retreat before switching back to approach
	if(!need_new_dest)
		return // carry on!
	retreat_dest = null // we arrived, need a new one
	retreat_timeout = world.time + get_retreat_duration() // reset the timeout for reaching the retreat dest
	retreat_moves_left-- // count will be checked by update_movement_mode, as it should
	get_new_retreat_dest()

/mob/living/danimal/proc/clear_movement_data()
	attacks_performed_this_move = 0
	damaged_this_move = FALSE
	retreat_timeout = 0
	retreat_timeout_to_approach = 0
	retreat_moves_left = 0
	approach_timeout = 0
	movement_mode_last_changed = world.time
	movement_last_move = world.time

/// *********************
/// GETTORS FOR THESE THINGS
/// *********************

/mob/living/danimal/proc/get_approach_duration()
	return variate_approach_duration()

/mob/living/danimal/proc/get_retreat_duration()
	return variate_retreat_duration()

/mob/living/danimal/proc/get_retreat_moves()
	return variate_retreat_moves()

/mob/living/danimal/proc/get_target_standoff_distance(minimum_distance, atom/move_target)
	if(minimum_distance)
		return minimum_distance
	else
		var/dist = get_dist(src, move_target)
		if(dist <= melee_queue_distance)
			return variate_minimum_distance()
		else
			return 1 // if we're not in melee range, we might as well try and get as close as possible




/// Handles the automated movement of the mob, including wandering and attraction movement
/mob/living/danimal/proc/handle_automated_movement()
	set waitfor = FALSE
	if(seconds_per_wander == -1) //stops wandering entirely
		return FALSE
	if(IsAttractionMoving())
		if(ShouldStopAttractionMovement())
			InterruptAttractionMovement()
		else
			return FALSE
	if(!CanWander())
		walk(src, 0) //stop mid walk
		return FALSE
	if(AutomateAttraction())
		return FALSE
	if(world.time < last_wander_time + (seconds_per_wander SECONDS))
		return FALSE
	last_wander_time = world.time
	spawn(rand(1, 30))
		var/anydir = pick(GLOB.cardinals)
		if(Process_Spacemove(anydir))
			Move(get_step(src, anydir), anydir)
	/// hostile
	if(!CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		return
	var/atom/my_target = get_target()
	if(can_dodge_in_melee && my_target && in_melee && isturf(loc) && isturf(my_target.loc))
		var/datum/cb = CALLBACK(src,PROC_REF(sidestep))
		if(sidestep_per_cycle > 1) //For more than one just spread them equally - this could changed to some sensible distribution later
			var/sidestep_delay = SSnpcpool.wait / sidestep_per_cycle
			for(var/i in 1 to sidestep_per_cycle)
				addtimer(cb, (i - 1)*sidestep_delay)
		else //Otherwise randomize it to make the players guessing.
			addtimer(cb,rand(1,SSnpcpool.wait))
	if(my_target)
		InterruptAttractionMovement()
	return TRUE

/mob/living/danimal/proc/sidestep()
	var/atom/my_target = get_target()
	if(!my_target || !isturf(my_target.loc) || !isturf(loc) || stat == DEAD)
		return
	var/target_dir = get_dir(src,my_target)

	var/static/list/cardinal_sidestep_directions = list(-90,-45,0,45,90)
	var/static/list/diagonal_sidestep_directions = list(-45,0,45)
	var/chosen_dir = 0
	if (target_dir & (target_dir - 1))
		chosen_dir = pick(diagonal_sidestep_directions)
	else
		chosen_dir = pick(cardinal_sidestep_directions)
	if(chosen_dir)
		chosen_dir = turn(target_dir,chosen_dir)
		Move(get_step(src,chosen_dir))
		face_atom(my_target) //Looks better if they keep looking at you when dodging

/mob/living/danimal/proc/handle_automated_speech(override)
	set waitfor = FALSE
	if(!speak_chance)
		return
	if(!prob(speak_chance) && !override)
		return
	if(speak && speak.len)
		if((emote_hear && emote_hear.len) || (emote_see && emote_see.len))
			var/length = speak.len
			if(emote_hear && emote_hear.len)
				length += emote_hear.len
			if(emote_see && emote_see.len)
				length += emote_see.len
			var/randomValue = rand(1,length)
			if(randomValue <= speak.len)
				say(pick(speak), forced = "poly", only_overhead = TRUE)
			else
				randomValue -= speak.len
				if(emote_see && randomValue <= emote_see.len)
					emote("me [pick(emote_see)]", 1)
				else
					emote("me [pick(emote_hear)]", 2)
		else
			say(pick(speak), forced = "poly", only_overhead = TRUE)
	else
		if(!(emote_hear && emote_hear.len) && (emote_see && emote_see.len))
			emote("me", EMOTE_VISIBLE, pick(emote_see))
		if((emote_hear && emote_hear.len) && !(emote_see && emote_see.len))
			emote("me", EMOTE_AUDIBLE, pick(emote_hear))
		if((emote_hear && emote_hear.len) && (emote_see && emote_see.len))
			var/length = emote_hear.len + emote_see.len
			var/pick = rand(1,length)
			if(pick <= emote_see.len)
				emote("me", EMOTE_VISIBLE, pick(emote_see))
			else
				emote("me", EMOTE_AUDIBLE, pick(emote_hear))

/mob/living/danimal/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	. = ..()
	if (raw_message == attack_phrase)
		alpha = 255
		peaceful = FALSE
	if (raw_message == peace_phrase)
		peaceful = TRUE
	if (raw_message == reveal_phrase)
		alpha = 255
	if (raw_message == hide_phrase)
		alpha = 90

/mob/living/danimal/proc/CanWander(ignore_stopped_automated_movement)
	if(stat == DEAD || stat == UNCONSCIOUS || health <= 0)
		return FALSE
	if(!ignore_stopped_automated_movement)
		if(stop_wandering || !wander)
			return FALSE
	if(!isturf(loc) && !allow_movement_on_non_turfs)
		return FALSE
	if(!CHECK_MOBILITY(src, MOBILITY_MOVE))
		return FALSE
	if(has_buckled_mobs()) //If someones on a mount then it won't wander about with them
		return FALSE
	if(RTS_move_ordered())
		// am_within_range_of_target_coords()
		return FALSE
	if(stop_wandering_when_pulled && pulledby) //Some animals don't move when pulled
		return FALSE
	return TRUE

/mob/living/danimal/proc/GetAttractionMovementFlags()
	if(!istype(current_attraction))
		return MOVELOOP_KILL_PATH_AND_GIVE_UP
	if(!CanWander(TRUE))
		return MOVELOOP_KILL_PATH_AND_GIVE_UP
	var/turf/dest = current_attraction.GetTarget()
	if(get_dist(get_turf(src), dest) <= wander_attractor_arrival_distance && prob(25))
		return MOVELOOP_KILL_PATH_AND_GIVE_UP
	return NONE

/mob/living/danimal/proc/ShouldStopAttractionMovement()
	return GetAttractionMovementFlags() == MOVELOOP_KILL_PATH_AND_GIVE_UP

/mob/living/danimal/proc/AutomateAttraction()
	if(!istype(current_attraction))
		return FALSE
	if(IsAttractionMoving())
		if(ShouldStopAttractionMovement())
			InterruptAttractionMovement()
		else
			return TRUE
	var/turf/dest = current_attraction.GetTarget()
	if(!dest)
		InterruptAttractionMovement()
		return FALSE
	. = SSmove_manager.jps_move(
		src,
		dest,
		attracted_move_to_delay,
		null,
		null,
		30,
		2,
		get_idcard(TRUE),
		FALSE,
		null,
		null,
		SSmobattraction,
		1,
		NONE,
		null
	)
	if(.)
		last_wander_time = 0
		vision_mult_active_until = world.time + vision_mult_duration

/mob/living/danimal/proc/IsAttractionMoving()
	if(!istype(current_attraction))
		return FALSE
	if(!CheckAttractorMoved())
		InterruptAttractionMovement()
		return FALSE
	var/datum/move_loop/MP = SSmove_manager.processing_on(src, SSmobattraction)
	return istype(MP)

/mob/living/danimal/proc/InterruptAttractionMovement()
	if(!istype(current_attraction))
		return
	. = TRUE
	var/datum/move_loop/MP = SSmove_manager.processing_on(src, SSmobattraction)
	if(MP)
		qdel(MP)
	QDEL_NULL(current_attraction)

/mob/living/danimal/proc/AttractionAct(atom/target_origin, intensity, max_range, duration)
	if(!attractable)
		return
	if(get_dist(src, target_origin) <= wander_attractor_arrival_distance)
		return
	/// hostile
	if(health <= 0)
		return
	if(get_target())
		InterruptAttractionMovement()
		return FALSE
	do_alert_animation(src)
	var/datum/wander_attractor/att = new /datum/wander_attractor()
	att.SetOwner(src)
	att.SetTarget(target_origin)
	att.SetupIntensity(intensity, max_range)
	if(current_attraction && current_attraction.intensity > att.intensity)
		QDEL_NULL(att)
		return
	current_attraction = att
	last_wander_time = 0
	handle_automated_movement()
	return TRUE

/mob/living/danimal/proc/CheckAttractorMoved()
	if(!istype(current_attraction))
		return FALSE
	if(!last_attraction_check_coords || !last_attraction_check_time)
		last_attraction_check_coords = atom2coords(src)
		last_attraction_check_time = world.time
		return TRUE
	if(world.time < last_attraction_check_time + (attraction_cooldown))
		return TRUE
	var/turf/here = get_turf(src)
	var/turf/last_here = coords2turf(last_attraction_check_coords)
	if(get_dist(here, last_here) < attraction_stuck_check_distance)
		return FALSE
	last_attraction_check_coords = atom2coords(src)
	last_attraction_check_time = world.time
	return TRUE

/mob/living/danimal/proc/get_vision_range()
	var/vrange = vision_range
	if(vision_mult_active_until > world.time)
		return vrange * 3
	return vrange


/*****************************************
 * MOB TARGETTING                        *
 *****************************************/

/// gets a list of all possible targets in range, regardless of if we can attack them or not
/mob/living/danimal/proc/ListTargets()//Step 1, find out what we can see
	var/atom/origin = get_origin()
	var/v_range = get_vision_range()
	if(!search_objects)
		. = hearers(v_range, origin) - src //Remove self

		var/static/hostile_machines = typecacheof(list(/obj/machinery/porta_turret, /obj/mecha, /obj/item/electronic_assembly))

		for(var/HM in typecache_filter_list(range(v_range, origin), hostile_machines))
			CHECK_TICK
			if(can_see(origin, HM, v_range))
				. += HM
	else
		. = list() // The following code is only very slightly slower than just returning oview(v_range, origin), but it saves us much more work down the line, particularly when bees are involved
		for (var/obj/A in oview(v_range, origin))
			CHECK_TICK
			. += A
		for (var/mob/living/A in oview(v_range, origin)) //mob/dead/observers arent possible targets
			CHECK_TICK
			. += A

/mob/living/danimal/proc/GetPossibleTargets(auto_set_target = TRUE)//Step 2, filter down possible targets to things we actually care about
	. = list()
	if (peaceful)
		return

	var/targ_lockout = world.time < RTS_aggro_lockout
	var/list/targout = list()
	targout[MT_ALL] = ListTargets()
	targout[MT_VALID] = list()
	targout[MT_PRIORITY] = list()
	targout[MT_TOP_PRIORITY] = list()
	for(var/pos_targ in targout[MT_ALL])
		var/atom/A = pos_targ
		if(targ_lockout && !isplayer(A))
			targout[MT_ALL] -= A
			continue
		var/list/eval_return = EvalTarget(A)
		if(Found(A))//Just in case people want to override targetting
			targout[MT_TOP_PRIORITY][A] = eval_return
			break
		if(!eval_return[MTEV_CAN_BE_TARGETED])
			targout[MT_ALL] -= A
			continue
		if(eval_return[MTEV_IS_FOE])
			targout[MT_PRIORITY][A] = eval_return
			continue
		if(players_are_priority && eval_return[MTEV_IS_PLAYER])
			targout[MT_PRIORITY][A] = eval_return
			continue
		if(objects_are_priority && eval_return[MTEV_IS_OBJECT])
			targout[MT_PRIORITY][A] = eval_return
			continue
		if(assemlies_are_priority && eval_return[MTEV_IS_ASSEMBLY])
			targout[MT_PRIORITY][A] = eval_return
			continue
		if(turrets_are_priority && eval_return[MTEV_IS_TURRET])
			targout[MT_PRIORITY][A] = eval_return
			continue
		targout[MT_VALID][A] = eval_return
	if(auto_set_target)
		var/list/chosen_target = ChooseTargetFromList(targout)
		GiveTarget(chosen_target)
		var/list/retlist = list()

		return chosen_target //We now have a targettte
	return targout

/// tries to find a target, and if it does, sets it as the mob's target
/mob/living/danimal/proc/FindATarget()
	var/atom/my_target = get_or_remove_target()
	if(my_target && !QDELETED(my_target))
		return my_target
	var/list/possible_targets = GetPossibleTargets()
	var/list/new_target = ChooseTargetFromList(possible_targets)
	if(LAZYLEN(new_target))
		GiveTarget(new_target)
	return new_target

// Please do not add one-off mob AIs here, but override this function for your mob
/// Returns a list of 'flags'
/mob/living/danimal/proc/EvalTarget(atom/the_target)
	. = list()
	if(simple)
		if(see_invisible < the_target.invisibility)
			.[MTEV_IS_INVISIBLE] = TRUE
		if(ismob(the_target))
			var/mob/M = the_target
			if(M.status_flags & GODMODE)
				return
		if (isliving(the_target))
			var/mob/living/L = the_target
			.[MTEV_IS_LIVING] = TRUE
			if(L.stat != CONSCIOUS)
				return
		if (ismecha(the_target))
			var/obj/mecha/M = the_target
			.[MTEV_IS_MECHA] = TRUE
			if (M.occupant)
				return
		.[MTEV_CAN_BE_TARGETED] = TRUE
	else
	. = list()
	if(!the_target || the_target.type == /atom/movable/lighting_object || isturf(the_target)) // bail out on invalids
		return
	if(see_invisible < the_target.invisibility)//Target's invisible to us, forget it
		.[MTEV_IS_INVISIBLE] = TRUE
		return
	var/objects_only = search_objects >= 3
	if(CanSee(the_target))
		.[MTEV_IS_VISIBLE] = TRUE

	var/am_player = isplayer(the_target)
	var/datum/weakref/target_ref = WEAKREF(the_target)
	if(target_ref in foes)
		.[MTEV_CAN_BE_TARGETED]  = TRUE
		.[MTEV_IS_FOE]      = TRUE
		.[MTEV_IS_HOSTILE]  = TRUE
		.[MTEV_IS_LIVING]   = TRUE
		if(am_player)
			.[MTEV_IS_PLAYER] = TRUE
		return
	if(target_ref in friends)
		.[MTEV_CAN_BE_TARGETED] = TRUE
		.[MTEV_IS_LIVING] = TRUE
		.[MTEV_IS_FRIEND] = TRUE
		if(am_player)
			.[MTEV_IS_PLAYER] = TRUE
		return

	if(isobj(the_target))
		if(attack_all_objects || is_type_in_typecache(the_target, wanted_objects))
			.[MTEV_CAN_BE_TARGETED] = TRUE
			.[MTEV_IS_OBJECT] = TRUE
			return

		if(istype(the_target, /obj/item/electronic_assembly))
			var/obj/item/electronic_assembly/O = the_target
			if(O.combat_circuits)
				.[MTEV_CAN_BE_TARGETED] = TRUE
				.[MTEV_IS_OBJECT] = TRUE
				.[MTEV_IS_ASSEMBLY] = TRUE
				.[MTEV_IS_HOSTILE] = TRUE
				return

		if(ismecha(the_target)) // https://en.wikipedia.org/wiki/Soviet_Union
			var/obj/mecha/M = the_target // fenny how did this get here, wtf
			.[MTEV_IS_MECHA] = TRUE
			return EvalTarget(M.occupant)

		if(istype(the_target, /obj/machinery/porta_turret))
			var/obj/machinery/porta_turret/P = the_target
			if(P.in_faction(src)) //Don't attack if the turret is in the same faction
				return
			if(P.stat & BROKEN) //Or turrets that are already broken
				return
			.[MTEV_CAN_BE_TARGETED] = TRUE
			.[MTEV_IS_OBJECT] = TRUE
			.[MTEV_IS_TURRET] = TRUE
			.[MTEV_IS_HOSTILE] = TRUE
			return

	if(objects_only)
		return

	if(isliving(the_target))
		var/mob/living/L = the_target
		if(!L.can_be_targeted_by_mob_ai)
			return
		if(L.status_flags & GODMODE)
			return
		if(!SSmobs.can_attack_npc(src, L))
			return
		if(SEND_SIGNAL(L, COMSIG_HOSTILE_CHECK_FACTION, src) == SIMPLEMOB_IGNORE)
			return
		var/is_friendly_faction = FALSE
		if(!attack_same && mob_faction_is_friendly_to_target(L))
			is_friendly_faction = TRUE
		if(is_friendly_faction)
			.[MTEV_IS_FRIENDLY_FACTION] = TRUE
			return
		.[MTEV_IS_HOSTILE] = TRUE
		if(L.stat > stat_attack)
			.[MTEV_INVALID_STAT] = TRUE
			return
		if(stat_attack == CONSCIOUS && IS_STAMCRIT(L))
			.[MTEV_IS_STAMCRIT] = TRUE
			return
		if(attack_downed_players && L.stat == SOFT_CRIT && iscarbon(L))
			/// so fun fact, not all players go into crit at 0 HP
			/// some go into crit at, like, 50 HP, or at -40 HP
			/// so we have to offset the crit threshold by the amount of health they have
			if(!L.attackable_in_crit())
				.[MTEV_IS_CRIT] = TRUE
				return
		.[MTEV_CAN_BE_TARGETED]  = TRUE
		.[MTEV_IS_HOSTILE]  = TRUE

		if(am_player)
			.[MTEV_IS_PLAYER]  = TRUE
		return
	return

/mob/living/danimal/proc/Found(atom/A)//This is here as a potential override to pick a specific targette if available
	return

/// goes through a few lists of possible targets, and picks the most best one to target
/mob/living/danimal/proc/ChooseTargetFromList(list/targlist_in)//Step 3, pick amongst the possible, attackable targets
	if(LAZYLEN(targlist_in[MT_TOP_PRIORITY]))
		return pick(targlist_in[MT_TOP_PRIORITY])
	var/atom/my_target = get_or_remove_target()
	var/list/targets = list()
	targets["priority"] = targlist_in[MT_PRIORITY]
	targets["valid"] = targlist_in[MT_VALID]

	if(!use_advanced_target_priority_selection)
		var/chosen_target
		var/chosen_eval
		if(LAZYLEN(targets["priority"]))//If we have a list of priority targets, pick from them first
			chosen_target = pick(targets["priority"])
			chosen_eval = targlist_in[MT_ALL][chosen_target]
		if(!chosen_target)//If we didnt find a priority target, pick from the rest
			chosen_target = pick(targets["valid"])
			chosen_eval = targlist_in[MT_ALL][chosen_target]
		return list(chosen_target, chosen_eval)

	if(my_target)
		targets["current"] = list(my_target)
	var/atom/origin = get_origin()

	//todo: EQ style aggro list
	var/list/highest_targets = list()
	var/highest_score = 0
	for(var/cat in targets)
		if(!LAZYLEN(targets[cat]))
			continue
		var/priority_bonus = 0
		if(cat == "current")
			priority_bonus = 150
		if(cat == "priority")
			priority_bonus = 100
		for(var/atom/A in targets[cat])
			var/priority_score = 100 + priority_bonus
			priority_score += GetDistancePriority(A, origin)
			priority_score += GetHealthPriority(A)
			if(priority_score < highest_score)
				continue
			if(priority_score == highest_score)
				highest_targets |= A
				continue
			highest_targets = list(A)
			highest_score = priority_score
	var/chosen_target
	var/chosen_eval
	if(LAZYLEN(highest_targets))
		chosen_target = pick(highest_targets)
		chosen_eval = targlist_in[MT_ALL][chosen_target]
	return chosen_target

/mob/living/danimal/proc/GetDistancePriority(atom/A, atom/origin)
	. = 0
	if(!use_distance_priority)
		return
	. += priority_bonus
	var/dist_pen = get_dist(origin, A) * 10
	. -= dist_pen

/mob/living/danimal/proc/GetHealthPriority(atom/A)
	. = 0
	if(!use_health_priority)
		return
	if(!isliving(A))
		return
	var/mob/living/L = A
	var/health_bonus = 100 - ((L.health / L.maxHealth) * 100)
	. += health_bonus



/*
/mob/living/danimal/proc/environment_is_safe(datum/gas_mixture/environment, check_temp = FALSE)
	. = TRUE

	if(pulledby && pulledby.grab_state >= GRAB_KILL && atmos_requirements["min_oxy"])
		. = FALSE //getting choked

	if(isturf(src.loc) && isopenturf(src.loc))
		var/turf/open/ST = src.loc
		if(ST.air)

			var/tox = ST.air.get_moles(GAS_PLASMA)
			var/oxy = ST.air.get_moles(GAS_O2)
			var/n2  = ST.air.get_moles(GAS_N2)
			var/co2 = ST.air.get_moles(GAS_CO2)

			if(atmos_requirements["min_oxy"] && oxy < atmos_requirements["min_oxy"])
				. = FALSE
			else if(atmos_requirements["max_oxy"] && oxy > atmos_requirements["max_oxy"])
				. = FALSE
			else if(atmos_requirements["min_tox"] && tox < atmos_requirements["min_tox"])
				. = FALSE
			else if(atmos_requirements["max_tox"] && tox > atmos_requirements["max_tox"])
				. = FALSE
			else if(atmos_requirements["min_n2"] && n2 < atmos_requirements["min_n2"])
				. = FALSE
			else if(atmos_requirements["max_n2"] && n2 > atmos_requirements["max_n2"])
				. = FALSE
			else if(atmos_requirements["min_co2"] && co2 < atmos_requirements["min_co2"])
				. = FALSE
			else if(atmos_requirements["max_co2"] && co2 > atmos_requirements["max_co2"])
				. = FALSE
		else
			if(atmos_requirements["min_oxy"] || atmos_requirements["min_tox"] || atmos_requirements["min_n2"] || atmos_requirements["min_co2"])
				. = FALSE

	if(check_temp)
		var/areatemp = get_temperature(environment)
		if((areatemp < minbodytemp) || (areatemp > maxbodytemp))
			. = FALSE


/mob/living/danimal/handle_environment(datum/gas_mixture/environment)
	var/atom/A = src.loc
	if(isturf(A))
		var/areatemp = get_temperature(environment)
		if( abs(areatemp - bodytemperature) > 5)
			var/diff = areatemp - bodytemperature
			diff = diff / 5
			adjust_bodytemperature(diff)

	if(!environment_is_safe(environment))
		adjustHealth(unsuitable_atmos_damage)

	handle_temperature_damage()

/mob/living/danimal/proc/handle_temperature_damage()
	if((bodytemperature < minbodytemp) || (bodytemperature > maxbodytemp))
		adjustHealth(unsuitable_atmos_damage)
*/

/mob/living/danimal/proc/can_butcher()
	return !already_butchered

/mob/living/danimal/proc/butcher_me(datum/source, mob/butcherer, bonus_modifier, effectiveness, gibbed, loud = TRUE)
	if(!butcherer)
		return
	if(!butcher_results && !guaranteed_butcher_results)
		return
	if(already_butchered)
		return
	already_butchered = TRUE

	if(butcherer && HAS_TRAIT(butcherer, TRAIT_TRAPPER))
		effectiveness *= 2
	var/chance_to_drop_butchered_thing = effectiveness / max(butcher_difficulty, 0.01)
	var/bonus_chance = max(0, (chance_to_drop_butchered_thing - 100) + bonus_modifier) //so 125 total effectiveness = 25% extra chance
	var/meat_quality = 50 + (chance_to_drop_butchered_thing/10) //increases through quality of butchering tool, and through if it was butchered in the kitchen or not

	var/said_fail = FALSE
	var/turf/T = drop_location()
	var/list/butchered_items = list()
	for(var/V in butcher_results)
		var/obj/rando_bits = V
		var/amount = butcher_results[rando_bits]
		for(var/_i in 1 to amount)
			if(!prob(chance_to_drop_butchered_thing))
				if(butcherer && loud && !said_fail)
					said_fail = TRUE
					to_chat(butcherer, span_warning("You fail to harvest some of the [initial(rando_bits.name)] from [src]."))
			else if(prob(bonus_chance))
				if(butcherer && loud)
					to_chat(butcherer, span_info("You harvest some extra [initial(rando_bits.name)] from [src]!"))
				for(var/i in 1 to 2)
					butchered_items += new rando_bits (T)
				if(HAS_TRAIT(butcherer, TRAIT_TRAPPER))
					if(butcherer)
						to_chat(butcherer, span_info("Your advanced trapping knowledge allows you to harvest extra [initial(rando_bits.name)] from [src]!"))
					for(var/i in 1 to 2)
						butchered_items += new rando_bits (T)
			else
				butchered_items += new rando_bits (T)
		butcher_results.Remove(rando_bits) //in case you want to, say, have it drop its results on gib

	for(var/V in guaranteed_butcher_results)
		var/obj/guaranteed_bits = V
		var/amount = guaranteed_butcher_results[guaranteed_bits]
		for(var/i in 1 to amount)
			butchered_items += new guaranteed_bits (T)
		guaranteed_butcher_results.Remove(guaranteed_bits)

	for(var/butchered_item in butchered_items)
		if(isobj(butchered_item))
			var/obj/O = butchered_item
			if(isfood(O))
				var/obj/item/reagent_containers/food/butchered_meat = butchered_item
				butchered_meat.food_quality = meat_quality
			if(!O.anchored)
				O.pixel_x = rand(-14,14)
				O.pixel_y = rand(-14,14)

	if(butcherer && loud)
		visible_message(span_notice("[butcherer] butchers [src]."))
	harvest(butcherer)
	if(!gibbed)
		gib(FALSE, FALSE, TRUE)

/mob/living/danimal/gib()
	butcher_me(null, null, 0, 25, TRUE, FALSE)
	..()

/mob/living/danimal/gib_animation()
	if(icon_gib)
		new /obj/effect/temp_visual/gib_animation/animal(loc, icon_gib)

/mob/living/danimal/say_mod(input, message_mode)
	if(speak_emote && speak_emote.len)
		verb_say = pick(speak_emote)
	. = ..()

/mob/living/danimal/emote(act, m_type=1, message = null, intentional = FALSE, only_overhead)
	if(stat)
		return
	// if(act == "scream")
	// 	message = "makes a loud and pained whimper." //ugly hack to stop animals screaming when crushed :P
	// 	act = "me"
	..(act, m_type, message)

/mob/living/danimal/proc/set_varspeed(var_value)
	speed = var_value
	update_simplemob_varspeed()

/mob/living/danimal/proc/update_simplemob_varspeed()
	if(speed == 0)
		remove_movespeed_modifier(/datum/movespeed_modifier/simplemob_varspeed)
	add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/simplemob_varspeed, multiplicative_slowdown = speed)

/mob/living/danimal/get_status_tab_items()
	. = ..()
	. += ""
	. += "Health: [round((health / maxHealth) * 100)]%"

/mob/living/danimal/proc/summon_backup(distance, exact_faction_match)
	if(COOLDOWN_FINISHED(src, ding_spam_cooldown))
		return TRUE
	COOLDOWN_START(src, ding_spam_cooldown, SIMPLE_MOB_DING_COOLDOWN)
	do_alert_animation(src)
	playsound(loc, 'sound/machines/chime.ogg', 50, 1, -1)
	for(var/mob/living/danimal/hostile/M in oview(distance, get_origin()))
		if(!mob_faction_is_friendly_to_target(M))
			continue
		if(M.AIStatus == AI_OFF || M.stat == DEAD || M.ckey)
			continue
		M.perform_move_action(src,M.move_to_delay,M.minimum_distance)

/mob/living/danimal/proc/CheckFriendlyFire(atom/A)
	if(!check_friendly_fire || ckey || should_factionize_shots || attack_same)
		return FALSE
	return CheckLine(src, A, MLF_FRIENDLIES)

/mob/living/danimal/proc/OpenFire(atom/A, rts)
	if(CheckFriendlyFire(A))
		return
	// visible_message(span_danger("<b>[src]</b> [islist(ranged_message) ? pick(ranged_message) : ranged_message] at [A]!"))
	var/spreadgun = ranged_base_spread
	if(rapid > 1)
		for(var/i in 1 to rapid)
			addtimer(CALLBACK(src,PROC_REF(Shoot), A, spreadgun), (i - 1)*rapid_fire_delay)
			spreadgun += ranged_extra_spread_per_shot
	else
		Shoot(A, spreadgun)
		for(var/i in 1 to extra_projectiles)
			addtimer(CALLBACK(src,PROC_REF(Shoot), A, spreadgun), i * auto_fire_delay)
			spreadgun += ranged_extra_spread_per_shot
	ranged_cooldown = world.time + ranged_cooldown_time + rand(0,30)
	if(sound_after_shooting)
		addtimer(CALLBACK(usr, GLOBAL_PROC_REF(playsound), src, sound_after_shooting, 100, 0, 0), sound_after_shooting_delay, TIMER_STOPPABLE)
	variate_projectile_type(TRUE)
	variate_casing_type(TRUE)

/mob/living/danimal/proc/Shoot(atom/targeted_atom, spread = 0)
	var/atom/origin = get_origin()
	if( !origin || QDELETED(targeted_atom) || targeted_atom == origin.loc || targeted_atom == origin )
		return
	var/turf/startloc = get_turf(origin)
	if(!spread)
		spread = ranged_base_spread
	var/true_spread = spread ? rand(-spread, spread) : 0
	true_spread = clamp(true_spread, -ranged_max_spread, ranged_max_spread)
	if(casingtype)
		var/obj/item/ammo_casing/casing = new casingtype(startloc)
		playsound(
			src,
			projectilesound,
			projectile_sound_properties[SOUND_PROPERTY_VOLUME],
			projectile_sound_properties[SOUND_PROPERTY_VARY],
			projectile_sound_properties[SOUND_PROPERTY_NORMAL_RANGE],
			ignore_walls = projectile_sound_properties[SOUND_PROPERTY_IGNORE_WALLS],
			distant_sound = projectile_sound_properties[SOUND_PROPERTY_DISTANT_SOUND],
			distant_range = projectile_sound_properties[SOUND_PROPERTY_DISTANT_SOUND_RANGE],
			vary = FALSE,
			frequency = SOUND_FREQ_NORMALIZED(sound_pitch, vary_pitches[1], vary_pitches[2])
			)
		casing.factionize(faction)
		casing.fire_casing(targeted_atom, src, null, null, null, ran_zone(), true_spread, null, null, null, src)
		qdel(casing)
	else if(projectiletype)
		var/obj/item/projectile/P = new projectiletype(startloc)
		P.factionize(faction)
		playsound(
			src,
			projectilesound,
			projectile_sound_properties[SOUND_PROPERTY_VOLUME],
			projectile_sound_properties[SOUND_PROPERTY_VARY],
			projectile_sound_properties[SOUND_PROPERTY_NORMAL_RANGE],
			ignore_walls = projectile_sound_properties[SOUND_PROPERTY_IGNORE_WALLS],
			distant_sound = projectile_sound_properties[SOUND_PROPERTY_DISTANT_SOUND],
			distant_range = projectile_sound_properties[SOUND_PROPERTY_DISTANT_SOUND_RANGE],
			vary = FALSE,
			frequency = SOUND_FREQ_NORMALIZED(sound_pitch, vary_pitches[1], vary_pitches[2])
			)
		P.starting = startloc
		P.firer = src
		P.fired_from = src
		P.yo = targeted_atom.y - startloc.y
		P.xo = targeted_atom.x - startloc.x
		if(AIStatus != AI_ON)//Don't want mindless mobs to have their movement screwed up firing in space
			newtonian_move(get_dir(targeted_atom, origin))
		P.original = targeted_atom
		P.preparePixelProjectile(targeted_atom, src, spread = true_spread)
		P.fire()
		return P

/mob/living/danimal/proc/CanSmashTurfs(turf/T)
	return iswallturf(T) || ismineralturf(T)

/mob/living/danimal/proc/dodge(moving_to,move_direction)
	var/cdir = turn(move_direction,90)
	var/ccdir = turn(move_direction,-90)
//	var/next_step_dir = pick(cdir,ccdir) sworddoggirl is way too cute ~Fenny

	can_dodge_in_melee = FALSE
	. = Move(get_step(loc,pick(cdir,ccdir)))
	if(!.) //Can't dodge there!
		visible_message("<span class='notice'>[src] dodges!</span>")
		playsound(loc, 'sound/effects/rustle3.ogg', 50, 1, -1)
	else
		// Apply stamina damage if the mob tried to dodge into a wall
		adjustStaminaLoss(10)
		playsound(loc, 'sound/effects/hit_punch.ogg', 50, 1, -1) // Play a punch sound
	can_dodge_in_melee = TRUE

/mob/living/danimal/proc/DestroyObjectsInDirection(direction, rtsd)
	var/atom/origin = get_origin()
	if(!origin)
		return
	var/turf/T = get_step(origin, direction)
	if(rtsd)
		if(COOLDOWN_TIMELEFT(src, melee_smash_cooldown))
			return TRUE
		COOLDOWN_START(src, melee_smash_cooldown, melee_smash_cooldown_duration)
	if(T && T.Adjacent(origin))
		if(environment_smash)
			if(CanSmashTurfs(T))
				T.attack_animal(src)
		for(var/obj/O in T)
			if(O.density && environment_smash & ENVIRONMENT_SMASH_STRUCTURES && !O.IsObscured())
				O.attack_animal(src)
				return
		if(rtsd) // forced RTS attack
			for(var/mob/living/L in T)
				if(!mob_faction_is_friendly_to_target(L))
					MeleeActionIfPossible(FALSE, L)
					break


/mob/living/danimal/proc/DestroyPathToTarget(forceit)
	if(environment_smash || forceit)
		EscapeConfinement()
		var/dir_to_target = get_dir(get_origin(), get_target())
		var/dir_list = list()
		if(dir_to_target in GLOB.diagonals) //it's diagonal, so we need two directions to hit
			for(var/direction in GLOB.cardinals)
				if(direction & dir_to_target)
					dir_list += direction
		else
			dir_list += dir_to_target
		for(var/direction in dir_list) //now we hit all of the directions we got in this fashion, since it's the only directions we should actually need
			DestroyObjectsInDirection(direction)


/mob/living/danimal/proc/DestroySurroundings() // for use with megafauna destroying everything around them
	EscapeConfinement()
	for(var/dir in GLOB.alldirs)
		DestroyObjectsInDirection(dir)


/mob/living/danimal/proc/EscapeConfinement()
	if(buckled)
		buckled.attack_animal(src)
	var/atom/origin = get_origin()
	if(!origin)
		return
	if(!isturf(origin.loc) && origin.loc != null)//Did someone put us in something?
		var/atom/A = origin.loc
		A.attack_animal(src)//Bang on it till we get out


/mob/living/danimal/proc/FindHidden()
	var/atom/my_target = get_target()
	if(!my_target)
		return FALSE
	if(istype(my_target.loc, /obj/structure/closet) || istype(my_target.loc, /obj/machinery/disposal) || istype(my_target.loc, /obj/machinery/sleeper))
		var/atom/A = my_target.loc
		perform_move_action(A,move_to_delay,minimum_distance)
		if(A.Adjacent(get_origin()))
			A.attack_animal(src)
		return 1

/mob/living/danimal/proc/get_origin()
	return GET_WEAKREF(targetting_origin) || src

/mob/living/danimal/proc/set_origin(atom/orgin)
	if(!orgin)
		orgin = src
	targetting_origin = WEAKREF(orgin)

/mob/living/danimal/proc/unset_origin()
	targetting_origin = null

/// *****************
/// AI STATUS PROCS
/// *****************

////// AI Status ///////
/mob/living/danimal/proc/AICanContinue()
	switch(AIStatus)
		if(AI_ON)
			. = 1
		if(AI_IDLE)
			if(FindATarget())
				. = 1
				toggle_ai(AI_ON) //Wake up for more than one Life() cycle.
			else
				. = 0

/// Determines if the mob should be awake or asleep based on if there are any clients in range
/mob/living/danimal/proc/AIShouldBeAwake()
	for(var/client/C in SSmobs.clients_by_zlevel[z])
		if(get_dist(src, C) <= max_tracking_range)
			return TRUE

/mob/living/danimal/proc/AIShouldSleep()
	var/atom/targ = get_target()
	if(get_dist(src, targ) >= max_tracking_range)
		return FALSE
	if(RTS_move_ordered())
		return FALSE
	if(FindATarget())
		return FALSE
	return TRUE

//todo: redo these procs into my new cool thing
/mob/living/danimal/proc/StartPatience()
	patience_finish_time = world.time + patience_duration

/mob/living/danimal/proc/ResetPatience()
	patience_finish_time = 0

//These two procs handle losing and regaining search_objects when attacked by a mob
/mob/living/danimal/proc/LoseSearchObjects()
	if(QDELETED(src))
		return

	search_objects = 0
	deltimer(search_objects_timer_id)
	search_objects_timer_id = addtimer(CALLBACK(src,PROC_REF(RegainSearchObjects)), search_objects_regain_time, TIMER_STOPPABLE)


/mob/living/danimal/proc/RegainSearchObjects(value)
	if(!value)
		value = initial(search_objects)
	search_objects = value

/mob/living/danimal/hostile/consider_wakeup()
	..()
	var/list/tlist
	var/turf/T = get_turf(src)

	if (!T)
		return

	if (!length(SSmobs.clients_by_zlevel[T.z])) // It's fine to use .len here but doesn't compile on 511
		toggle_ai(AI_Z_OFF)
		return

	tlist = ListTargetsLazy(T.z)

	if(AIStatus == AI_IDLE && tlist.len)
		toggle_ai(AI_ON)

/// *************************
/// TARGETTING PROCS
/// *************************

/// Just checks if anything is in range for the purpose of waking up the AI for some reason
/mob/living/danimal/proc/ListTargetsLazy(_Z)//Step 1, find out what we can see
	var/static/hostile_machines = typecacheof(list(/obj/machinery/porta_turret, /obj/mecha))
	. = list()
	var/v_range = get_vision_range()
	for (var/I in SSmobs.clients_by_zlevel[_Z])
		var/mob/M = I
		if (get_dist(M, src) < v_range)
			if (isturf(M.loc))
				. += M
				return
			else if (M.loc.type in hostile_machines)
				. += M.loc
				return

/mob/living/danimal/proc/handle_target_del(datum/source)
	SIGNAL_HANDLER
	DropTarget()

/// its get_target, but if the target stops being valid, it drops it and returns null instead of the targette
/mob/living/danimal/proc/get_or_remove_target()
	var/atom/ttargentgt = get_target()
	if(!is_valid_atom_to_target(ttargentgt))
		DropTarget()
		return null
	return ttargentgt

/// returns the actual instance of the targette, not the weakref, if any
/mob/living/danimal/proc/get_target()
	return target_data.get_target()

/mob/living/danimal/proc/get_target_eval()
	return target_data.get_target_eval()

/// dont call this directly, use GiveTarget() instead, it handles all the other stuff
/// does the stuff needed to set a new targette, and register the signal for when it gets deleted
/mob/living/danimal/proc/set_target(new_target, list/new_target_eval = list())
	if(!new_target)
		return
	target_data.set_target(new_target)
	set_target_eval(new_target_eval)
	RegisterSignal(new_target, COMSIG_PARENT_QDELETING,PROC_REF(handle_target_del), TRUE)
	return TRUE

/mob/living/danimal/proc/set_target_eval(new_target_eval)
	target_data.set_target_eval(new_target_eval)

/// dont call this directly, use GiveTarget() instead, it handles all the other stuff
/// does the stuff needed to unset our current targette, and unregister the signal for when it gets deleted
/mob/living/danimal/proc/unset_target()
	var/atom/my_target = get_target()
	if(my_target)
		UnregisterSignal(my_target, COMSIG_PARENT_QDELETING)
	target_data.clear_target()
	return TRUE

/// put stuff here for when our current target stops being the target we're targetting
/// target was lost, became invalid, changed to another target, target got deleted
/// does NOT handle the actual losing of the target, just the stuff that should happen when we lose it
/// happens before the target is actually lost, so you can still get the target with get_target()
/mob/living/danimal/proc/OnTargetLost(atom/old_target, list/old_target_eval = list())
	if(!RTS_move_ordered())
		walk(src, 0)
	LoseAggro()
	ResetPatience()

/// changing from one target to another, this is called before the target is actually changed
/mob/living/danimal/proc/OnChangeTarget(
	atom/old_target,               atom/new_target, 
	list/old_target_eval = list(), list/new_target_eval = list())
	OnTargetLost() // override, but call ur parents, or dont if you know what ur doing

/// called when we gain a new targette, this is called before the target is actually changed
/// note that OnChangeTarget() can be called before this, so just keep that in mind
/mob/living/danimal/proc/OnTargetGained(atom/new_target, list/new_target_eval = list())
	if(RTS_move_ordered())
		clear_target_coords()
		walk(src, 0)
	StartPatience()
	Aggro()
	COOLDOWN_START(src, sight_shoot_delay, sight_shoot_delay_duration)

/// shortcut to lose our current targette
/mob/living/danimal/proc/DropTarget()
	return GiveTarget(null)

/// use this if you want to just try and acquire a targette, it will evaluate it and either accept or reject it
/mob/living/danimal/proc/GiveTarget(atom/to_target)
	return HandleTargetChange(to_target)

/// master target handling proc, handles all the target handling proc
/// call this proc when you want to change our targette or drop it
/// evaluate will reject targets that we can't target
/// drop_if_eval_fails will drop the target if it fails evaluation, otherwise it just disregards the proc
/// currently assumes all targets passed to it are hostile, and if eval says they arent, then we dotn target it
/// oh also, new_target can be null, an atom, or a list of length 2 (atom, eval)
/mob/living/danimal/proc/HandleTargetChange(something_in, force_acquire)//Step 4, give us our selected targette
	var/atom/old_target = get_target()
	var/list/old_target_eval = get_target_eval()
	var/atom/new_target
	var/list/new_target_eval
	if(islist(something_in))
		if(LAZYLEN(something_in) != 2)
			return FALSE // bad stuff input
		new_target       = something_in[1]
		new_target_eval  = something_in[2]
	else if(isatom(something_in))
		new_target      = something_in
		new_target_eval = EvalTarget(new_target)
	else if(isnull(something_in))
		new_target      = null
		new_target_eval = null
	else
		return FALSE // bad stuff imput

	if(old_target == new_target)
		return FALSE

	if(new_target && !force_acquire && !new_target_eval[MTEV_CAN_BE_TARGETED])
		return FALSE

	// had a target, and the new target isnt that one
	if(old_target)
		if(new_target)
			OnChangeTarget(old_target, new_target, old_target_eval, new_target_eval)
		else
			OnTargetLost(old_target, old_target_eval)
		unset_target()

	if(new_target)
		OnTargetGained(new_target, new_target_eval)
		set_target(new_target, new_target_eval)

	return TRUE // retrieve the datas from the mob_target_data datum and fuzzy im kinda busy right now, take a photo

/mob/living/danimal/proc/current_target_is_valid()
	var/atom/my_target = get_target()
	return is_valid_atom_to_target(my_target)

/// Basic check to see if the target atom is still a valid atom. nothing else rly
/mob/living/danimal/proc/is_valid_atom_to_target(atom/target_check)
	if(!target_check)
		return FALSE
	if(QDELETED(target_check))
		return FALSE
	if(!get_turf(target_check))
		return FALSE
	return TRUE

/* ************************************************* *
 * Line of sight / line-based accessibility checks.  *
 * ************************************************* */
/// checks line of sight, but not range unless specifically asked
/// 
/mob/living/danimal/proc/CanSee(atom/looking_at, understands_lockers)
	if(!looking_at)
		return FALSE
	var/atom/my_origin = get_turf(get_origin())
	if(!my_origin)
		return FALSE
	var/atom/target_origin = looking_at
	if(understands_lockers)
		target_origin = get_turf(looking_at)
	else
		if(!isturf(target_origin.loc))
			return FALSE
	if(SSmobs.use_view_for_close_range_los)
		if(target_origin in view(SSmobs.max_view_range, my_origin))
			return TRUE
	return CheckLine(target_origin, MLF_OPAQUE)

/// checks direct-ish accessibility, factoring in optional stuff like opacity, density, and livingness
/// doesnt care about range //todo: widen the trace, maybe two more, one to each side, offset by a tile
/mob/living/danimal/proc/CheckLine(atom/target_origin, checkflags = MLF_DEFAULT)
	var/opaque      = CHECK_BITFIELD(checkflags, MLF_OPAQUE)
	var/dense       = CHECK_BITFIELD(checkflags, MLF_DENSE)
	var/living      = CHECK_BITFIELD(checkflags, MLF_LIVING)
	var/friendlies  = CHECK_BITFIELD(checkflags, MLF_FRIENDLIES)
	if(!opaque && !dense && !living && !friendlies)
		return TRUE // ezclap
	var/list/linesight = getline(get_origin(), target_origin)
	if(!LAZYLEN(linesight))
		return FALSE
	linesight.Cut(1,2) // remove our turf, we're something
	linesight.len-- // remove their turf, they're something
	. = TRUE
	for(var/turf/T as anything in linesight)
		for(var/atom/movable/am as anything in T.contents)
			if(opaque && am.opacity)
				return FALSE
			if(dense && am.density)
				return FALSE
			if(living || friendlies)
				if(isliving(am))
					if(living)
						return FALSE
					var/mob/living/L = am
					if(friendlies)
						if(mob_faction_is_friendly_to_target(L))
							return FALSE


/// ************************
/// NEST UNBIRTH PROCS
/// ************************

/mob/living/danimal/proc/queue_unbirth()
	SSidlenpcpool.add_to_culling(src)

/mob/living/danimal/proc/unqueue_unbirth()
	SSidlenpcpool.remove_from_culling(src)

/// return to monke-- stuffs a mob into their own special nest
/mob/living/danimal/proc/unbirth_self(forced)
	if(!forced && !consider_despawning()) // check again plz
		return
	var/obj/structure/nest/my_home
	if(isweakref(nest))
		my_home = RESOLVEWEAKREF(nest)
	if(!my_home)
		my_home = new/obj/structure/nest/special(get_turf(src))
	went_to_sleep = TRUE
	SEND_SIGNAL(my_home, COMSIG_SPAWNER_ABSORB_MOB, src)

/// ***********************
/// VARIATION PROCS
/// ***********************

/mob/living/danimal/proc/variate_move_to_delay()
	. = move_to_delay
	if(!time_between_move_randomization)
		return
	if(!LAZYLEN(variation_list[MOB_VARIED_SPEED]) || !variation_list[MOB_VARIED_SPEED_CHANCE])
		return
	if(last_move_randomization + time_between_move_randomization >= world.time)
		return
	last_move_randomization = world.time
	if(!prob(variation_list[MOB_VARIED_SPEED_CHANCE]))
		return
	var/new_speed = vary_from_list(variation_list[MOB_VARIED_SPEED])
	if(auto_set_variations[MOB_VARIED_SPEED])
		move_to_delay = new_speed
		set_glide_size(move_to_delay)
	return new_speed

/mob/living/danimal/proc/variate_projectile_type()
	. = projectiletype
	if(!projectiletype)
		return
	if(LAZYLEN(variation_list[MOB_PROJECTILE]) < 2)
		return
	var/new_projectile = vary_from_list(variation_list[MOB_PROJECTILE])
	if(autoset_variations[MOB_PROJECTILE])
		projectiletype = new_projectile
	return new_projectile


/mob/living/danimal/proc/variate_casing_type()
	. = casingtype
	if(!casingtype)
		return
	if(LAZYLEN(variation_list[MOB_CASING]) < 2)
		return
	var/new_casing = vary_from_list(variation_list[MOB_CASING])
	if(autoset_variations[MOB_CASING])
		casingtype = new_casing
	return new_casing

/mob/living/danimal/proc/variate_minimum_distance()
	. = minimum_distance
	if(!winding_up_melee)
		return
	if(!variation_list[MOB_MINIMUM_DISTANCE_CHANCE])
		return
	if(!LAZYLEN(variation_list[MOB_MINIMUM_DISTANCE]))
		return
	if(!prob(variation_list[MOB_MINIMUM_DISTANCE_CHANCE]))
		return
	var/new_minimum_distance = vary_from_list(variation_list[MOB_MINIMUM_DISTANCE])
	if(autoset_variations[MOB_MINIMUM_DISTANCE])
		minimum_distance = new_minimum_distance
	return new_minimum_distance

/mob/living/danimal/proc/variate_retreat_distance()
	. = retreat_distance
	if(winding_up_melee)
		return
	if(!variation_list[MOB_RETREAT_DISTANCE_CHANCE])
		return
	if(!LAZYLEN(variation_list[MOB_RETREAT_DISTANCE]))
		return
	if(!prob(variation_list[MOB_RETREAT_DISTANCE_CHANCE]))
		return
	var/new_retreat_distance = vary_from_list(variation_list[MOB_RETREAT_DISTANCE])
	if(autoset_variations[MOB_RETREAT_DISTANCE])
		retreat_distance = new_retreat_distance
	return new_retreat_distance

/// ***********************
/// SETUP VARIATIONS PROC
/// ***********************

/mob/living/danimal/hostile/setup_variations()
	if(!..())
		return
	if(LAZYLEN(variation_list[MOB_VARIED_VIEW_RANGE]))
		vision_range = vary_from_list(variation_list[MOB_VARIED_VIEW_RANGE])
	if(LAZYLEN(variation_list[MOB_VARIED_AGGRO_RANGE]))
		aggroed_vision_range = vary_from_list(variation_list[MOB_VARIED_AGGRO_RANGE])
	if(LAZYLEN(variation_list[MOB_VARIED_SPEED]))
		move_to_delay = vary_from_list(variation_list[MOB_VARIED_SPEED])
	if(LAZYLEN(variation_list[MOB_RETREAT_DISTANCE]))
		retreat_distance = vary_from_list(variation_list[MOB_RETREAT_DISTANCE])
	if(LAZYLEN(variation_list[MOB_MINIMUM_DISTANCE]))
		minimum_distance = vary_from_list(variation_list[MOB_MINIMUM_DISTANCE])



/mob/living/danimal/proc/drop_loot()
	if(loot_drop_amount == MOB_LOOT_ALL || !isnum(loot_drop_amount))
		if(loot_drop_amount == MOB_LOOT_ALL)
			loot_amount_random = FALSE
		loot_drop_amount = LAZYLEN(loot)
	var/list/lootlist = loot
	var/list/droppedstuff = list()
	var/list/turfs = list()
	for(var/turf/T in hearers(1, src))
		if(T.density)
			continue
		turfs |= T
	if(!LAZYLEN(turfs))
		turfs |= get_turf(src)
	for(var/i in 1 to loot_amount_random ? rand(1,loot_drop_amount) : loot_drop_amount)
		if(!LAZYLEN(lootlist))
			return
		var/dropthing = pickweight_n_take(lootlist)
		if(ispath(dropthing))
			var/turf/spawn_here = pick(turfs)
			var/atom/newthing = new dropthing(get_turf(spawn_here))
			if(istype(newthing, /obj/effect/spawner/lootdrop))
				var/obj/effect/spawner/lootdrop/lut = newthing
				if(lut.delay_spawn)
					droppedstuff |= lut.spawn_the_stuff()
				continue
			else
				droppedstuff |= newthing
	for(var/atom/thingy in droppedstuff)
		SEND_SIGNAL(thingy, COMSIG_ITEM_MOB_DROPPED, src)
	loot.Cut()

/mob/living/danimal/death(gibbed)
	unset_target() // but u can call it here i guess
	movement_type &= ~FLYING
	unstamcrit()
	payout()

	sever_link_to_nest() // killed
	LAZYREMOVE(GLOB.mob_spawners[initial(name)], src)
	if(!LAZYLEN(GLOB.mob_spawners[initial(name)]))
		GLOB.mob_spawners -= initial(name)

	if(color_dead)
		add_atom_colour(color_dead, FIXED_COLOUR_PRIORITY)
	drop_loot()
	if(dextrous)
		drop_all_held_items()
	if(!gibbed)
		if(death_sound)
			playsound(get_turf(src),death_sound, 200, ignore_walls = TRUE, vary = FALSE, frequency = SOUND_FREQ_NORMALIZED(sound_pitch, vary_pitches[1], vary_pitches[2]))
		if(deathmessage || !del_on_death)
			INVOKE_ASYNC(src,PROC_REF(emote), "deathgasp")
	if(del_on_death)
		..(gibbed)
		// if(prob(del_on_death*100))
		// 	gib()
		//Prevent infinite loops if the mob Destroy() is overridden in such
		//a manner as to cause a call to death() again
		del_on_death = FALSE
		qdel(src)
	else
		health = 0
		icon_state = icon_dead
		density = FALSE
		lying = 1
		..(gibbed)

/mob/living/danimal/drop_all_held_items(skip_worn = FALSE)
	if(internal_storage && !skip_worn)
		dropItemToGround(internal_storage)
	if(head && !skip_worn)
		dropItemToGround(head)
	. = ..()

/mob/living/danimal/update_overlays()
	. = ..()
	if(SSnpcpool.debug_attraction)
		if(IsAttractionMoving())
			if(current_attraction)
				maptext = "Attracted to [current_attraction.target_x], [current_attraction.target_y], [current_attraction.target_z]"
			else
				maptext = null
		else
			maptext = null


/mob/living/danimal/handle_fire()
	return

/mob/living/danimal/IgniteMob()
	return FALSE

/mob/living/danimal/ExtinguishMob()
	return

/mob/living/danimal/revive(full_heal = 0, admin_revive = 0)
	if(..()) //successfully ressuscitated from death
		if(color_dead)
			remove_atom_colour(color_dead, FIXED_COLOUR_PRIORITY)
		icon = initial(icon)
		icon_state = icon_living
		density = initial(density)
		lying = FALSE
		set_resting(FALSE, silent = TRUE, updating = TRUE)//get up, stand up, don't forget your rights
		. = 1
		setMovetype(initial(movement_type))

/mob/living/danimal/proc/make_babies() // <3 <3 <3
	if(gender != FEMALE || stat || next_scan_time > world.time || !offspring_type || !animal_species || !SSticker.IsRoundInProgress())
		return
	next_scan_time = world.time + 400
	var/alone = 1
	var/mob/living/danimal/partner
	var/children = 0
	for(var/mob/M in view(7, src))
		if(M.stat != CONSCIOUS) //Check if it's conscious FIRST.
			continue
		else if(istype(M, offspring_type)) //Check for children SECOND.
			children++
		else if(istype(M, animal_species))
			if(M.ckey)
				continue
			else if(!istype(M, offspring_type) && M.gender == MALE) //Better safe than sorry ;_;
				partner = M

		else if(isliving(M) && !mob_faction_is_friendly_to_target(M)) //shyness check. we're not shy in front of things that share a faction with us.
			return //we never mate when not alone, so just abort early

	if(alone && partner && children < 3)
		var/childspawn = pickweight(offspring_type)
		var/turf/target = get_turf(loc)
		if(target)
			return new childspawn(target)

/mob/living/danimal/canUseTopic(atom/movable/M, be_close=FALSE, no_dextery=FALSE, no_tk=FALSE)
	if(incapacitated(allow_crit = TRUE))
		to_chat(src, span_warning("You can't do that right now!"))
		return FALSE
	if(be_close && !in_range(M, src))
		to_chat(src, span_warning("You are too far away!"))
		return FALSE
	if(!(no_dextery || dextrous))
		to_chat(src, span_warning("You don't have the dexterity to do this!"))
		return FALSE
	return TRUE

/mob/living/danimal/stripPanelUnequip(obj/item/what, mob/who, where)
	if(!canUseTopic(who, BE_CLOSE))
		return
	else
		..()

/mob/living/danimal/stripPanelEquip(obj/item/what, mob/who, where)
	if(!canUseTopic(who, BE_CLOSE))
		return
	else
		..()

/mob/living/danimal/update_mobility()
	. = ..()
	if(IsUnconscious() || IsStun() || IsParalyzed() || stat || resting)
		mobility_flags = NONE
	else if(buckled || (pulledby && HAS_TRAIT(pulledby, TRAIT_STRONG_GRABBER)))
		mobility_flags = ~MOBILITY_MOVE
	else
		mobility_flags = MOBILITY_FLAGS_DEFAULT
//	update_transform()
	update_action_buttons_icon()
	return mobility_flags

/* /mob/living/danimal/update_transform()
	var/matrix/ntransform = matrix(transform) //aka transform.Copy()
	var/changed = 0

	if(resize != RESIZE_DEFAULT_SIZE)
		changed++
		ntransform.Scale(resize)
		resize = RESIZE_DEFAULT_SIZE

	if(changed)
		animate(src, transform = ntransform, time = 2, easing = EASE_IN|EASE_OUT) */

/mob/living/danimal/proc/sentience_act() //Called when a simple animal gains sentience via gold slime potion
	toggle_ai(AI_OFF) // To prevent any weirdness.
	can_have_ai = FALSE

/mob/living/danimal/update_sight()
	if(!client)
		return
	if(stat == DEAD)
		sight = (SEE_TURFS|SEE_MOBS|SEE_OBJS)
		see_in_dark = 8
		see_invisible = SEE_INVISIBLE_OBSERVER
		return

	see_invisible = initial(see_invisible)
	if(HAS_TRAIT(src, TRAIT_NIGHT_VISION_GREATER))
		lighting_alpha = min(LIGHTING_PLANE_ALPHA_NV_TRAIT, lighting_alpha)
		see_in_dark = max(NIGHT_VISION_DARKSIGHT_RANGE_GREATER, see_in_dark)
	else if(HAS_TRAIT(src, TRAIT_NIGHT_VISION))
		lighting_alpha = min(LIGHTING_PLANE_ALPHA_NV_TRAIT, lighting_alpha)
		see_in_dark = max(NIGHT_VISION_DARKSIGHT_RANGE, see_in_dark)
	else
		see_in_dark = initial(see_in_dark)
		lighting_alpha = initial(lighting_alpha)
	sight = initial(sight)

	if(client.eye != src)
		var/atom/A = client.eye
		if(A.update_remote_sight(src)) //returns 1 if we override all other sight updates.
			return
	if(client?.holder)
		see_invisible = client.holder.ghostsight_or(see_invisible) //can't see ghosts through cameras
	sync_lighting_plane_alpha()

/mob/living/danimal/get_idcard(hand_first = TRUE)
	return ..() || access_card

/mob/living/danimal/can_hold_items()
	return dextrous

/mob/living/danimal/IsAdvancedToolUser()
	return dextrous

/mob/living/danimal/activate_hand(selhand)
	if(!dextrous)
		return ..()
	if(!selhand)
		selhand = (active_hand_index % held_items.len)+1
	if(istext(selhand))
		selhand = lowertext(selhand)
		if(selhand == "right" || selhand == "r")
			selhand = 2
		if(selhand == "left" || selhand == "l")
			selhand = 1
	if(selhand != active_hand_index)
		swap_hand(selhand)
	else
		mode()

/mob/living/danimal/swap_hand(hand_index)
	. = ..()
	if(!.)
		return
	if(!dextrous)
		return
	if(!hand_index && held_items.len)//Divide by zero prevention
		hand_index = (active_hand_index % held_items.len)+1
	var/oindex = active_hand_index
	active_hand_index = hand_index
	if(hud_used)
		var/atom/movable/screen/inventory/hand/H
		H = hud_used.hand_slots["[hand_index]"]
		if(H)
			H.update_icon()
		H = hud_used.hand_slots["[oindex]"]
		if(H)
			H.update_icon()

/mob/living/danimal/put_in_hands(obj/item/I, del_on_fail = FALSE, merge_stacks = TRUE)
	. = ..(I, del_on_fail, merge_stacks)
	update_inv_hands()

/mob/living/danimal/update_inv_hands()
	if(client && hud_used && hud_used.hud_version != HUD_STYLE_NOHUD)
		var/obj/item/l_hand = get_item_for_held_index(1)
		var/obj/item/r_hand = get_item_for_held_index(2)
		if(r_hand)
			r_hand.layer = ABOVE_HUD_LAYER
			r_hand.plane = ABOVE_HUD_PLANE
			r_hand.screen_loc = ui_hand_position(get_held_index_of_item(r_hand))
			client.screen |= r_hand
		if(l_hand)
			l_hand.layer = ABOVE_HUD_LAYER
			l_hand.plane = ABOVE_HUD_PLANE
			l_hand.screen_loc = ui_hand_position(get_held_index_of_item(l_hand))
			client.screen |= l_hand

//ANIMAL RIDING

/mob/living/danimal/user_buckle_mob(mob/living/M, mob/user)
	var/datum/component/riding/riding_datum = GetComponent(/datum/component/riding)
	if(riding_datum)
		if(user.incapacitated(allow_crit = TRUE))
			return
		for(var/atom/movable/A in get_turf(src))
			if(A != src && A != M && A.density)
				return
		M.forceMove(get_turf(src))
		no_ghost_gta = TRUE // so commanders cant just yoink someones bike
		return ..()

/mob/living/danimal/relaymove(mob/user, direction)
	var/datum/component/riding/riding_datum = GetComponent(/datum/component/riding)
	if(tame && riding_datum)
		riding_datum.handle_ride(user, direction)

/mob/living/danimal/buckle_mob(mob/living/buckled_mob, force = 0, check_loc = 1)
	. = ..()
	LoadComponent(/datum/component/riding)

/mob/living/danimal/proc/toggle_ai(togglestatus)
	if(QDELETED(src))
		return
	if(!can_have_ai && (togglestatus != AI_OFF))
		return
	if (AIStatus != togglestatus)
		if (togglestatus > 0 && togglestatus < 5)
			if (togglestatus == AI_Z_OFF || AIStatus == AI_Z_OFF)
				var/turf/T = get_turf(src)
				if (AIStatus == AI_Z_OFF)
					SSidlenpcpool.idle_mobs_by_zlevel[T.z] -= src
				else
					SSidlenpcpool.idle_mobs_by_zlevel[T.z] += src
			GLOB.simple_animals[AIStatus] -= src
			GLOB.simple_animals[togglestatus] += src
			AIStatus = togglestatus
		else
			stack_trace("Something attempted to set simple animals AI to an invalid state: [togglestatus]")
	queue_naptime()

/mob/living/danimal/proc/consider_wakeup()
	if (pulledby || shouldwakeup)
		toggle_ai(AI_ON)

/mob/living/danimal/proc/queue_naptime()
	var/go2bed = consider_despawning()
	if(go2bed)
		if(lonely_timer_id)
			return
		lonely_timer_id = addtimer(CALLBACK(src,PROC_REF(queue_unbirth)), 30 SECONDS, TIMER_STOPPABLE)
	else
		if(!lonely_timer_id)
			return
		deltimer(lonely_timer_id)
		lonely_timer_id = null
		unqueue_unbirth()

/mob/living/danimal/proc/consider_despawning()
	if(!despawns_when_lonely)
		return FALSE
	if(ckey)
		return FALSE
	if(lazarused)
		return FALSE
	if(stat == DEAD)
		return FALSE
	if(CHECK_BITFIELD(datum_flags, DF_VAR_EDITED))
		return FALSE
	if(CHECK_BITFIELD(flags_1, ADMIN_SPAWNED_1))
		return FALSE
	if(CHECK_BITFIELD(flags_2, MOB_NO_SLEEP))
		return FALSE
	if(health <= 0)
		return FALSE
	if(AIStatus == AI_ON || AIStatus == AI_OFF)
		return FALSE
	return TRUE



/mob/living/danimal/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	var/amount_did = amount
	if(!ckey && !stat)//Not unconscious
		if(AIStatus == AI_IDLE)
			toggle_ai(AI_ON)
	update_health_hud()
	INVOKE_ASYNC(src,PROC_REF(on_health_changed), amount_did)

/mob/living/danimal/proc/on_health_changed(amount)
	if(ckey)
		return
	if(stat != CONSCIOUS)
		return
	if(search_objects >= 2)
		return
	if(amount <= 0)
		return
	//Not unconscious, and we don't ignore mobs
	try_tactical_retreat()
	if(peaceful == TRUE)
		peaceful = FALSE
	if(search_objects)//Turn off item searching and ignore whatever item we were looking at, we're more concerned with fight or flight
		DropTarget()
		LoseSearchObjects()
	if(AIStatus != AI_ON && AIStatus != AI_OFF)
		toggle_ai(AI_ON)
		FindATarget()
	else if(get_target() != null && prob(40))//No more pulling a mob forever and having a second player attack it, it can switch targets now if it finds a more suitable one
		FindATarget()

/mob/living/danimal/proc/AttackingTarget(atom/target_override)
	if(!can_melee_attack)
		return
	var/atom/my_target = target_override || get_target()
	SEND_SIGNAL(src, COMSIG_HOSTILE_ATTACKINGTARGET, my_target)
	in_melee = TRUE
	if(prob(alternate_attack_prob) && AlternateAttackingTarget(my_target))
		return FALSE
	if(windup_delay_duration)
		var/m_rd = retreat_distance
		var/m_md = minimum_distance
		winding_up_melee = TRUE //Don't increase our retreating distance while winding up
		retreat_distance = null //Stop retreating
		minimum_distance = 1 //Stop moving away
		if(windup_sound_start)
			playsound(src.loc, windup_sound_start, 150, TRUE, distant_range = 4)	//Play the windup sound effect to warn that an attack is coming.
		INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/,do_windup), windup_magnitude, windup_delay_duration)	//Bouncing bitches.
		if(do_after(user=src,delay=windup_delay_duration,needhand=FALSE,progress=FALSE,required_mobility_flags=null,allow_movement=TRUE,stay_close=FALSE,public_progbar=FALSE))
			my_target = get_target() //Switch targets if we did during our windup.
			if(my_target && Adjacent(my_target)) //If we waited, check if we died or something before finishing the attack windup. If so, don't attack.
				retreat_distance = m_rd
				minimum_distance = m_md
				winding_up_melee = FALSE
				. = my_target.attack_animal(src)
			else
				retreat_distance = m_rd
				minimum_distance = m_md
				winding_up_melee = FALSE
				return FALSE
		else
			retreat_distance = m_rd
			minimum_distance = m_md
			winding_up_melee = FALSE
			return FALSE
	else
		. = my_target.attack_animal(src)

/// Does an extra *thing* when attacking. Return TRUE to not do the standard attack
/mob/living/danimal/proc/AlternateAttackingTarget(atom/the_target)
	return

/mob/living/danimal/proc/Aggro()
	if(ckey)
		return TRUE
	vision_range = aggroed_vision_range
	var/atom/my_target = get_target()
	if(my_target && LAZYLEN(emote_taunt) && prob(taunt_chance))
		INVOKE_ASYNC(src,PROC_REF(emote), "me", EMOTE_VISIBLE, "[pick(emote_taunt)] at [my_target].")
		taunt_chance = max(taunt_chance-7,2)
	if(LAZYLEN(emote_taunt_sound))
		var/taunt_choice = pick(emote_taunt_sound)
		playsound(loc, taunt_choice, 50, 0, vary = FALSE, frequency = SOUND_FREQ_NORMALIZED(sound_pitch, vary_pitches[1], vary_pitches[2]))


/mob/living/danimal/proc/LoseAggro()
	stop_wandering = 0
	vision_range = initial(vision_range)
	taunt_chance = initial(taunt_chance)

/mob/living/danimal/onTransitZ(old_z, new_z)
	..()
	if (AIStatus == AI_Z_OFF)
		SSidlenpcpool.idle_mobs_by_zlevel[old_z] -= src
		toggle_ai(initial(AIStatus))

/mob/living/danimal/Life()
	update_health_hud()
	. = ..()
	if(stat == DEAD)
		return
	if (idlesound && !(islist(idlesound) && LAZYLEN(idlesound) == 0))
		if (prob(5))
			var/chosen_sound = pick(idlesound)
			playsound(src, chosen_sound, 60, FALSE, ignore_walls = FALSE)
	adjustStaminaLoss(-stamcrit_threshold * 0.01)

/mob/living/danimal/update_health_hud()
	if(!client || !hud_used)
		return
	if(hud_used.healths)
		if(stat != DEAD)
			. = 1
			if(!health)
				health = health
			if(health >= maxHealth)
				hud_used.healths.icon_state = "health0"
			else if(health > maxHealth*0.95)
				hud_used.healths.icon_state = "health1"
			else if(health > maxHealth*0.9)
				hud_used.healths.icon_state = "health2"
			else if(health > maxHealth*0.85)
				hud_used.healths.icon_state = "health3"
			else if(health > maxHealth*0.80)
				hud_used.healths.icon_state = "health4"
			else if(health > maxHealth*0.75)
				hud_used.healths.icon_state = "health5"
			else if(health > maxHealth*0.70)
				hud_used.healths.icon_state = "health6"
			else if(health > maxHealth*0.65)
				hud_used.healths.icon_state = "health7"
			else if(health > maxHealth*0.60)
				hud_used.healths.icon_state = "health8"
			else if(health > maxHealth*0.55)
				hud_used.healths.icon_state = "health9"
			else if(health > maxHealth*0.50)
				hud_used.healths.icon_state = "health10"
			else if(health > maxHealth*0.45)
				hud_used.healths.icon_state = "health11"
			else if(health > maxHealth*0.40)
				hud_used.healths.icon_state = "health12"
			else if(health > maxHealth*0.35)
				hud_used.healths.icon_state = "health13"
			else if(health > maxHealth*0.30)
				hud_used.healths.icon_state = "health14"
			else if(health > maxHealth*0.25)
				hud_used.healths.icon_state = "health15"
			else if(health > maxHealth*0.20)
				hud_used.healths.icon_state = "health16"
			else if(health > maxHealth*0.15)
				hud_used.healths.icon_state = "health17"
			else if(health > maxHealth*0.10)
				hud_used.healths.icon_state = "health18"
			else if(health > maxHealth*0.05)
				hud_used.healths.icon_state = "health19"
			else if(health > 0)
				hud_used.healths.icon_state = "health19"
			else
				hud_used.healths.icon_state = "health20"
		else
			hud_used.healths.icon_state = "health21"

/mob/living/danimal/update_stamina()
	if(stamcrit_threshold == SIMPLEMOB_NO_STAMCRIT)
		return
	if((staminaloss + bruteloss) >= stamcrit_threshold)
		stamcrit()
	else
		unstamcrit()

/mob/living/danimal/proc/stamcrit()
	if(CHECK_BITFIELD(combat_flags, COMBAT_FLAG_HARD_STAMCRIT))
		return
	ENABLE_BITFIELD(combat_flags, COMBAT_FLAG_HARD_STAMCRIT)
	to_chat(src, span_notice("You're too exhausted to keep going..."))
	filters += CIT_FILTER_STAMINACRIT
	walk(src, 0)
	set_resting(TRUE, FALSE, FALSE)
	update_mobility()

/mob/living/danimal/proc/unstamcrit()
	if(!CHECK_BITFIELD(combat_flags, COMBAT_FLAG_HARD_STAMCRIT))
		return
	DISABLE_BITFIELD(combat_flags, COMBAT_FLAG_HARD_STAMCRIT)
	COOLDOWN_RESET(src, stamcrit_timer)
	to_chat(src, span_notice("You don't feel nearly as exhausted anymore."))
	filters -= CIT_FILTER_STAMINACRIT
	walk(src, 0)
	set_resting(FALSE, FALSE, FALSE)
	update_mobility()

/mob/living/danimal/fully_heal(admin_revive = FALSE)
	. = ..()
	unstamcrit()

/* *******************************
 * RTS SIMPLEMOB STUFF END
 * *******************************/

// todo: rework this nightmare
/mob/living/danimal/proc/RTS_move_to_tile(targettte, delay, minimum_distance)
	end_RTS_move()
	if(!targettte)
		return
	if(!delay)
		delay = move_to_delay
	if(!minimum_distance)
		minimum_distance = 0
	set_target_coords(atom2coords(targettte))
	set_RTS_command_aggro_lockout()
	if(CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		set_glide_size(DELAY_TO_GLIDE_SIZE(move_to_delay))
		walk_to(src, targettte, minimum_distance, delay)
	if(AIStatus != AI_ON && AIStatus != AI_OFF)
		toggle_ai(AI_ON)

/// if you issue a command to a mob, and they are aggroed, they'll happily ignore you
/// this makes them unable to aggro for a short time after a command is issued
/mob/living/danimal/proc/set_RTS_command_aggro_lockout()
	RTS_aggro_lockout = world.time + SSrts.aggro_lockout_time


/// Makes mobs smash stuff!
/mob/living/danimal/proc/rts_smash_things(atom/towards)
	EscapeConfinement()
	DestroyPathToTarget()

/// Makes mobs shoot stuff!
/mob/living/danimal/proc/rts_shoot(atom/towards)
	if((ranged || projectiletype || casingtype) && world.time >= ranged_cooldown)
		ranged_cooldown = world.time + ranged_cooldown_time
		OpenFire(towards)

/// <summary>
/// This gives the mob a goal to get somewhere near, so it will evetually stop getting nearer to the target.
/// </summary>
/mob/living/danimal/proc/set_target_coords(coords)
	target_coords = coords

/mob/living/danimal/proc/clear_target_coords()
	target_coords = null

/mob/living/danimal/proc/am_within_range_of_target_coords()
	if(!RTS_move_ordered())
		return FALSE
	if(!target_coords)
		return end_RTS_move()
	var/atom/targetloc = coords2turf(target_coords)
	if(!targetloc)
		return end_RTS_move()
	var/distfrommetoit = get_dist(get_turf(src), targetloc)
	if(distfrommetoit <= RTS_move_target_range)
		return end_RTS_move()
	return FALSE

/mob/living/danimal/proc/RTS_move_ordered()
	return !isnull(target_coords)

/mob/living/danimal/proc/end_RTS_move()
	target_coords = null
	walk(src, 0)
	return TRUE

/mob/living/danimal/proc/check_frustration()
	if(!RTS_frustration_coords)
		RTS_frustration_coords = atom2coords(src)
		return
	if(world.time < RTS_last_frustration + (1 SECONDS))
		return
	RTS_last_frustration = world.time
	var/turf/whereiwas = coords2turf(RTS_frustration_coords)
	var/turf/whereiam = get_turf(src)
	if(get_dist(whereiwas, whereiam) < 2)
		frustrate()

/mob/living/danimal/proc/frustrate()
	RTS_frustration_seconds++
	if(RTS_frustration_seconds >= RTS_max_RTS_frustration_seconds)
		RTS_frustration_coords = null
		RTS_frustration_seconds = 0
		end_RTS_move()
		do_huh_animation(src)
		for(var/turf/T in orange(1,src))
			if(prob(50))
				do_huh_animation(T)

/* *******************************
 * RTS SIMPLEMOB STUFF END
 * *******************************/

/mob/living/danimal/proc/link_to_nest(atom/birthplace)
	if(nest || !isatom(birthplace))
		return
	nest = WEAKREF(birthplace)
	nest_coords = atom2coords(birthplace)

/mob/living/danimal/proc/sever_link_to_nest()
	if(!nest)
		return
	var/atom/our_nest = GET_WEAKREF(nest)
	if(istype(our_nest))
		SEND_SIGNAL(our_nest, COMSIG_SPAWNER_REMOVE_MOB_FROM_NEST, src)
	nest = null

/mob/living/danimal/proc/setup_variations()
	if(!LAZYLEN(variation_list))
		return FALSE // we're good here
	if(autoset_variations[MOB_VARIATE_ALL])
		var/list/variatables = list()
		for(var/key in variation_list)
			variatables |= key
		autoset_variations = variatables
	variate_color()
	variate_health()
	return TRUE

/mob/living/danimal/proc/vary_from_list(which_list, weighted_list = FALSE)
	if(isnum(which_list))
		return which_list
	if(islist(which_list))
		if(weighted_list)
			return(pickweight(which_list))
		return(pick(which_list))

/mob/living/danimal/proc/vary_mob_name_from_global_lists()
	var/list/our_mob_random_name_list = variation_list[MOB_VARIED_NAME_GLOBAL_LIST]
	var/our_new_name = ""
	var/number_of_name_tokens_left = LAZYLEN(variation_list[MOB_VARIED_NAME_GLOBAL_LIST])
	for(var/name_token in our_mob_random_name_list)
		for(var/num_names in 1 to our_mob_random_name_list[name_token])
			switch(name_token)
				if(MOB_NAME_RANDOM_MALE)
					our_new_name += capitalize(pick(GLOB.first_names_male)) + " " + capitalize(pick(GLOB.last_names))
				if(MOB_NAME_RANDOM_FEMALE)
					our_new_name += capitalize(pick(GLOB.first_names_female)) + " " + capitalize(pick(GLOB.last_names))
				if(MOB_NAME_RANDOM_LIZARD_MALE)
					our_new_name += capitalize(lizard_name(MALE))
				if(MOB_NAME_RANDOM_LIZARD_FEMALE)
					our_new_name += capitalize(lizard_name(FEMALE))
				if(MOB_NAME_RANDOM_PLASMAMAN)
					our_new_name += capitalize(plasmaman_name())
				if(MOB_NAME_RANDOM_ETHERIAL)
					our_new_name += capitalize(ethereal_name())
				if(MOB_NAME_RANDOM_MOTH)
					our_new_name += capitalize(pick(GLOB.moth_first)) + " " + capitalize(pick(GLOB.moth_last))
				if(MOB_NAME_RANDOM_ALL_OF_THEM)
					our_new_name += get_random_random_name()
			if(num_names != our_mob_random_name_list[name_token])
				our_new_name += " "
		if(number_of_name_tokens_left-- > 0)
			our_new_name += " "
	if(our_new_name != "")
		name = our_new_name

/mob/living/danimal/proc/vary_mob_name_from_local_list()
	name = pick(variation_list[MOB_VARIED_NAME_LIST])

/mob/living/danimal/proc/variate_color()
	. = color
	if(!LAZYLEN(variation_list[MOB_VARIED_COLOR]))
		return
	if(LAZYLEN(variation_list[MOB_VARIED_COLOR][MOB_VARIED_COLOR_MIN]) != 3)
		return
	if(LAZYLEN(variation_list[MOB_VARIED_COLOR][MOB_VARIED_COLOR_MAX]) != 3)
		return

	var/list/our_mob_random_color_list = variation_list[MOB_VARIED_COLOR]
	var/list/colors = list()

	if(our_mob_random_color_list[MOB_VARIED_COLOR_MIN][1] < 1 && our_mob_random_color_list[MOB_VARIED_COLOR_MAX][1] < 1)
		colors["red"] = 255
	else
		var/list/red_numbers = put_numbers_in_order(our_mob_random_color_list[MOB_VARIED_COLOR_MIN][1], our_mob_random_color_list[MOB_VARIED_COLOR_MAX][1])
		colors["red"] = rand(red_numbers[1], red_numbers[2])

	if(our_mob_random_color_list[MOB_VARIED_COLOR_MIN][2] < 1 && our_mob_random_color_list[MOB_VARIED_COLOR_MAX][2] < 1)
		colors["green"] = 255
	else
		var/list/green_numbers = put_numbers_in_order(our_mob_random_color_list[MOB_VARIED_COLOR_MIN][2], our_mob_random_color_list[MOB_VARIED_COLOR_MAX][2])
		colors["green"] = rand(green_numbers[1], green_numbers[2])

	if(our_mob_random_color_list[MOB_VARIED_COLOR_MIN][3] < 1 && our_mob_random_color_list[MOB_VARIED_COLOR_MAX][3] < 1)
		colors["blue"] = 255
	else
		var/list/blue_numbers = put_numbers_in_order(our_mob_random_color_list[MOB_VARIED_COLOR_MIN][3], our_mob_random_color_list[MOB_VARIED_COLOR_MAX][3])
		colors["blue"] = rand(blue_numbers[1], blue_numbers[2])
	var/new_color = rgb(clamp(colors["red"], 0, 255), clamp(colors["green"], 0, 255), clamp(colors["blue"], 0, 255))
	if(autoset_variations[MOB_VARIED_COLOR])
		color = new_color
	return new_color

/mob/living/danimal/proc/variate_health()
	. = maxHealth
	if(!LAZYLEN(variation_list[MOB_VARIED_HEALTH]))
		return
	var/new_health = vary_from_list(variation_list[MOB_VARIED_HEALTH])
	if(autoset_variations[MOB_VARIED_HEALTH])
		maxHealth = new_health
		health = new_health
	return new_health


/// ***********************
/// EMP PROCS
/// ***********************

/mob/living/danimal/hostile/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	emp_effect(severity)

/// EMP intensity tends to be 20-40
/mob/living/danimal/proc/emp_effect(intensity)
	if(!LAZYLEN(emp_flags))
		return FALSE
	if(!islist(emp_flags))
		return FALSE

	switch(pick(emp_flags))
		if(MOB_EMP_STUN)
			do_emp_stun(intensity)
		if(MOB_EMP_BERSERK)
			do_emp_berserk(intensity)
		if(MOB_EMP_DAMAGE)
			do_emp_damage(intensity)
		if(MOB_EMP_SCRAMBLE)
			do_emp_scramble(intensity)
	do_sparks(3, FALSE, src)
	return TRUE

/mob/living/danimal/proc/do_emp_stun(intensity)
	if(!intensity)
		return FALSE
	if(MOB_EMP_STUN in active_emp_flags)
		return FALSE
	active_emp_flags |= MOB_EMP_STUN
	visible_message(span_green("[src] shudders as the EMP overloads its servos!"))
	DropTarget()
	toggle_ai(AI_OFF)
	addtimer(CALLBACK(src,PROC_REF(un_emp_stun)), min(intensity, 3 SECONDS))

/mob/living/danimal/proc/un_emp_stun()
	active_emp_flags -= MOB_EMP_STUN
	DropTarget()
	toggle_ai(AI_ON)

/mob/living/danimal/proc/do_emp_berserk(intensity)
	if(!intensity)
		return FALSE
	if(MOB_EMP_BERSERK in active_emp_flags)
		return FALSE
	active_emp_flags |= MOB_EMP_BERSERK
	DropTarget()
	visible_message(span_green("[src] lets out a burst of static and whips its gun around wildly!"))
	var/list/old_faction = faction
	faction = null
	addtimer(CALLBACK(src,PROC_REF(un_emp_berserk), old_faction), intensity SECONDS * 0.5)

/mob/living/danimal/proc/un_emp_berserk(list/unberserk)
	active_emp_flags -= MOB_EMP_BERSERK
	faction = unberserk
	DropTarget()

/mob/living/danimal/proc/do_emp_damage(intensity)
	if(!intensity)
		return FALSE
	smoke.set_up(round(clamp(intensity*0.5, 1, 3), 1), src)
	smoke.start()
	visible_message(span_green("[src] shoots out a plume of acrid smoke!"))
	adjustBruteLoss(maxHealth * 0.01 * intensity)
	playsound(src.loc, 'sound/effects/smoke.ogg', 50, 1, -3)

/mob/living/danimal/proc/do_emp_scramble(intensity)
	if(!intensity)
		return FALSE
	move_to_delay = rand(move_to_delay * 0.5, move_to_delay * 2)
	auto_fire_delay = rand(auto_fire_delay * 0.8, auto_fire_delay * 1.5)
	extra_projectiles = rand(extra_projectiles - 1, extra_projectiles + 1)
	ranged_cooldown_time = rand(ranged_cooldown_time * 0.5, ranged_cooldown_time * 2)
	retreat_distance = rand(0, 10)
	minimum_distance = rand(0, 10)
	DropTarget()
	visible_message(span_notice("[src] jerks around wildly and starts acting strange!"))

/// ***********************
/// TACTICAL RETREAT PROCS
/// ***********************

/mob/living/danimal/proc/try_tactical_retreat()
	if(!SSmobs.buggy_mob_running_away)
		return
	var/should_retreat = FALSE
	if(tactical_retreat)
		if(stat == CONSCIOUS)
			if((health / maxHealth) < retreat_health_percent)
				should_retreat = TRUE
	if(should_retreat)
		start_tactical_retreat()
	else
		stop_tactical_retreat()
	
	if(tactical_retreat && stat != DEAD && (health / maxHealth) < retreat_health_percent) // If I have a tactical retreat distance, and I'm not dead, and my health is below my retreat health percent then...
		retreat_distance = initial(retreat_distance) // I look at my original mob retreat distance
	else
		retreat_distance = null //Otherwise, I don't retreat at all!

/mob/living/danimal/proc/start_tactical_retreat()
	if(!tactical_retreat)
		stop_tactical_retreat()
		return
	// say the line
	if(!retreat_message_said)
		var/atom/my_target = get_target() //Do I have a target?????
		if(my_target)
			var/msg = actual_retreat_message // Then play my retreat message
			msg = replacetext(msg, "%NAME", name) //with my name
			msg = replacetext(msg, "%TARGET", my_target.name) // and the targets name
			visible_message(span_danger(msg)) // in it.
		else
			visible_message(span_danger(replacetext(actual_retreat_message, "%NAME", name))) // If I don't have a target just say the message without the target's name in it.
		retreat_message_said = TRUE //I've officially said my retreat message
	retreat_distance = tactical_retreat // then make my retreat distance my tactical retreat distance

/mob/living/danimal/proc/stop_tactical_retreat()
	retreat_distance = initial(retreat_distance) //Stop retreating
	retreat_message_said = FALSE //I can say my retreat message again if I need to


/// *************************
/// PASSIVE HEALING PROCS
/// *************************

/mob/living/danimal/proc/passive_healing() // Every life tick, my hostile ass is going to...
	if(!heal_per_life)
		return
	if(health > max_healing_ability)
		return
	if(get_target())
		return
	adjustHealth(-heal_per_life*maxHealth) //heal this much per life tick, negative is giving me health back. I guess you could make a mob bleed out by having it do positive adjust health?
	visible_message(span_danger(replacetext(healing_message, "%NAME", name))) // almost, take a look at how the retreatcode's message is handled
	playsound(get_turf(src), healing_sound, healing_volume, 1, ignore_walls = TRUE)
	retreat_message_said = FALSE

/mob/living/danimal/proc/put_numbers_in_order(num_1, num_2)
	if(num_1 < num_2)
		return list(num_1, num_2)
	return list(num_2, num_1)

/mob/living/danimal/proc/get_random_random_name()
	switch(rand(1,26))
		if(1)
			return pick(GLOB.ai_names)
		if(2)
			return pick(GLOB.wizard_first)
		if(3)
			return pick(GLOB.wizard_second)
		if(4)
			return pick(GLOB.ninja_titles)
		if(5)
			return pick(GLOB.ninja_names)
		if(6)
			return pick(GLOB.commando_names)
		if(7)
			return pick(GLOB.first_names)
		if(8)
			return pick(GLOB.first_names_male)
		if(9)
			return pick(GLOB.first_names_female)
		if(10)
			return pick(GLOB.last_names)
		if(11)
			return pick(GLOB.lizard_names_male)
		if(12)
			return pick(GLOB.lizard_names_female)
		if(13)
			return pick(GLOB.carp_names)
		if(14)
			return pick(GLOB.golem_names)
		if(15)
			return pick(GLOB.moth_first)
		if(16)
			return pick(GLOB.moth_last)
		if(17)
			return pick(GLOB.plasmaman_names)
		if(18)
			return pick(GLOB.ethereal_names)
		if(19)
			return pick(GLOB.posibrain_names)
		if(20)
			return pick(GLOB.nightmare_names)
		if(21)
			return pick(GLOB.megacarp_first_names)
		if(22)
			return pick(GLOB.megacarp_last_names)
		if(23)
			return pick(GLOB.verbs)
		if(24)
			return pick(GLOB.ing_verbs)
		if(25)
			return pick(GLOB.adverbs)
		if(26)
			return pick(GLOB.adjectives)

/// AAA DUPLICATED CODE FROM OBJ.DM
/mob/living/danimal/proc/setup_mob_armor_values()
	if(!mob_armor)
		return
	if(!islist(mob_armor))
		return
	if(length(mob_armor_tokens) < 1)
		return // all done!
	var/list/armorlist = list(armor_list)
	
	for(var/list/token in mob_armor_tokens)
		for(var/modifier in token)
			switch(GLOB.armor_token_operation_legend[modifier])
				if("MULT")
					armorlist[modifier] = round(armorlist[modifier] * token[modifier], 1)
				if("ADD")
					armorlist[modifier] = max(armorlist[modifier] + token[modifier], 0)
				else
					continue
	armor_list = armorlist

/// compiles the mob's armor description
/mob/living/danimal/proc/setup_mob_armor_description()

	var/list/descriptors = list("\n" + span_notice("You consider [src]'s resistances...") + "\n")
	///Melee
	var/melee_armor = mob_armor?.getRating("melee")

	descriptors += span_notice("[p_they(TRUE)] look[p_s()] like [p_they()]")
	switch(melee_armor)
		if(-INFINITY to 20, null)
			descriptors += span_notice("'d bruise like a mutfruit.")
		if(20 to 40)
			descriptors += span_notice(" could take a punch, maybe two if [p_they()] had to.")
		if(40 to 60)
			descriptors += span_alert(" could take a slap from [istype(src, /mob/living/danimal/hostile/supermutant) ? "another" : "a"] supermutant and get right back up.")
		if(60 to 80)
			descriptors += span_alert(" could play chicken with a car and win.")
		if(80 to INFINITY)
			descriptors += span_warning(" could play pattycake with [istype(src, /mob/living/danimal/hostile/aethergiest) ? "another" : "a"] aethergiest and win.")
	descriptors += "\n"
	///Bullet
	var/bullet_armor = mob_armor?.getRating("bullet")
	descriptors += span_notice("You feel like")
	switch(bullet_armor)
		if(-INFINITY to 20, null)
			descriptors += span_notice(" a bullet would smash right through [p_them()].")
		if(20 to 40)
			descriptors += span_notice(" a bullet would hurt them good, with heavy enough ammo.")
		if(40 to 60)
			descriptors += span_alert(" [p_they()] would need a lot of ammo to take down.")
		if(60 to 80)
			descriptors += span_alert(" gunfire would just annoy [p_them()].")
		if(80 to INFINITY)
			descriptors += span_warning(" you'd have better luck blowing up a tank with a BB gun.")
	descriptors += "\n"
	///Laser
	var/laser_armor = mob_armor?.getRating("laser")
	descriptors += span_notice("You figure")
	switch(laser_armor)
		if(-INFINITY to 20, null)
			descriptors += span_notice(" a laser would slice through [p_them()] like brahminbutter.")
		if(20 to 40)
			descriptors += span_notice(" a laser would singe the everliving daylights out of [p_them()].")
		if(40 to 60)
			descriptors += span_alert(" [p_they()] would need a lot of juice to take down.")
		if(60 to 80)
			descriptors += span_alert(" laserfire would just make [p_them()] uncomfortably warm.")
		if(80 to INFINITY)
			descriptors += span_warning(" you may as well be waving a torch at [p_them()].")
	descriptors += "\n"
	///plasma
	var/plasma_armor = mob_armor?.getRating("energy")
	descriptors += span_notice("You imagine that")
	switch(plasma_armor)
		if(-INFINITY to 20, null)
			descriptors += span_notice(" a burst of intense heat would simply burn [p_them()] to a crisp.")
		if(20 to 40)
			descriptors += span_notice(" a burst of intense heat would sear [p_them()] medium-well.")
		if(40 to 60)
			descriptors += span_alert(" [p_they()] would need a lot of agonizing plasma to put them out of their misery.")
		if(60 to 80)
			descriptors += span_alert(", for whatever reason, [p_they()] wouldn't be too bothered by intense heat.")
		if(80 to INFINITY)
			descriptors += span_warning(" this is some kind of super creature drinks plasma for breakfast.")
	descriptors += "\n"
	// ///dt
	// var/damage_threshold = mob_armor.getRating("damage_threshold")
	// switch(damage_threshold)
	// 	if(-INFINITY to 1)
	// 		descriptors += span_greenteamradio("[p_they(TRUE)] look[p_s()] like a reasonably safe opponent.")
	// 	if(2 to 4)
	// 		descriptors += span_info("[p_they(TRUE)] look[p_s()] like an even fight.")
	// 	if(5 to 6)
	// 		descriptors += span_yellowteamradio("[p_they(TRUE)] look[p_s()] like quite a gamble!")
	// 	if(7 to 9)
	// 		descriptors += span_yellowteamradio("[p_they(TRUE)] look[p_s()] like it would wipe the floor with you!")
	// 	if(9 to INFINITY)
	// 		descriptors += span_warning("What would you like your tombstone to say?")
	descriptors += "\n"
	if(LAZYLEN(descriptors))
		mob_armor_description = jointext(descriptors, "")

//Coyote Add
/mob/living/danimal/throw_item(atom/target)
	throw_mode_off()
	if(!target || !isturf(loc))
		return
	if(istype(target, /atom/movable/screen))
		return
	if(IS_STAMCRIT(src))
		to_chat(src, span_warning("You're too exhausted."))
		return

	var/random_turn = a_intent == INTENT_HARM
	//END OF CIT CHANGES

	var/obj/item/I = get_active_held_item()

	var/atom/movable/thrown_thing
	var/mob/living/throwable_mob

	if(istype(I, /obj/item/clothing/head/mob_holder))
		var/obj/item/clothing/head/mob_holder/holder = I
		if(holder.held_mob)
			throwable_mob = holder.held_mob
			holder.release()

	if(!I || throwable_mob)
		if(!throwable_mob && pulling && isliving(pulling) && grab_state >= GRAB_AGGRESSIVE)
			throwable_mob = pulling

		if(throwable_mob && !throwable_mob.buckled)
			thrown_thing = throwable_mob
			if(pulling)
				stop_pulling()
			if(HAS_TRAIT(src, TRAIT_PACIFISM))
				to_chat(src, span_notice("You gently let go of [throwable_mob]."))
				return

			adjustStaminaLossBuffered(STAM_COST_THROW_MOB * ((throwable_mob.mob_size+1)**2))// throwing an entire person shall be very tiring
			var/turf/start_T = get_turf(loc) //Get the start and target tile for the descriptors
			var/turf/end_T = get_turf(target)
			if(start_T && end_T)
				log_combat(src, throwable_mob, "thrown", addition="grab from tile in [AREACOORD(start_T)] towards tile at [AREACOORD(end_T)]")

	else if(!CHECK_BITFIELD(I.item_flags, ABSTRACT) && !HAS_TRAIT(I, TRAIT_NODROP))
		thrown_thing = I
		dropItemToGround(I)

		if(HAS_TRAIT(src, TRAIT_PACIFISM) && I.throwforce)
			to_chat(src, span_notice("You set [I] down gently on the ground."))
			return

		adjustStaminaLossBuffered(I.getweight(src, STAM_COST_THROW_MULT, SKILL_THROW_STAM_COST))

	if(thrown_thing)
		var/power_throw = 0
		if(HAS_TRAIT(src, TRAIT_HULK))
			power_throw++
		if(pulling && grab_state >= GRAB_NECK)
			power_throw++
		visible_message(span_danger("[src] throws [thrown_thing][power_throw ? " really hard!" : "."]"), \
						span_danger("You throw [thrown_thing][power_throw ? " really hard!" : "."]"))
		log_message("has thrown [thrown_thing] [power_throw ? "really hard" : ""]", LOG_ATTACK)
		do_attack_animation(target, no_effect = 1)
		playsound(loc, 'sound/weapons/punchmiss.ogg', 50, 1, -1)
		newtonian_move(get_dir(target, src))
		thrown_thing.safe_throw_at(target, thrown_thing.throw_range, thrown_thing.throw_speed + power_throw, src, null, null, null, move_force, random_turn)

/mob/living/danimal/proc/toggle_throw_mode()
	if(stat)
		return
	if(in_throw_mode)
		throw_mode_off()
	else
		throw_mode_on()

/mob/living/danimal/proc/throw_mode_off()
	in_throw_mode = 0
	if(client && hud_used)
		hud_used.throw_icon.icon_state = "act_throw_off"

/mob/living/danimal/proc/throw_mode_on()
	in_throw_mode = 1
	if(client && hud_used)
		hud_used.throw_icon.icon_state = "act_throw_on"
//End Coyote Add

/mob/living/danimal/proc/give_credit(mob/living/attacker)
	if(!isliving(attacker))
		return
	if(!attacker.client)
		return
	if(islist(faction) && islist(attacker.faction))
		if(LAZYLEN(attacker.faction & faction))
			return
	if(lazarused) // no killing friendlies for cash!
		return
	kill_credit = SSeconomy.extract_quid(attacker)

/mob/living/danimal/proc/payout()
	if(!bounty || !kill_credit)
		return
	var/mob/living/kyller = SSeconomy.quid2mob(kill_credit)
	if(!kyller)
		return
	var/amt = COINS_TO_CREDITS(bounty)
	bounty = 0
	if(!SSeconomy.adjust_funds(kyller, amt))
		return
	var/cashdisplay = ""
	if(bounty >= 0)
		cashdisplay += "+"
	else
		cashdisplay += "-"
	cashdisplay += "$[CREDITS_TO_COINS(amt)]"
	new /obj/effect/temp_visual/floaty_thing/cash(get_turf(src), cashdisplay)

/obj/effect/temp_visual/floaty_thing
	name = "floaty"
	icon = 'icons/effects/effects.dmi'
	icon_state = "butt"
	duration = 5 SECONDS
	var/textcolor = "#FFFFFF"
	var/defer = FALSE
	var/txtshow
	var/matrix/finmat

/obj/effect/temp_visual/floaty_thing/Initialize(atom/origin, todisplay)
	. = ..()
	if(!defer)
		spawn(0)
			numberate(origin, todisplay)

/obj/effect/temp_visual/floaty_thing/proc/numberate(atom/origin, todisplay)
	// first the vertical offset
	transform = transform.Translate(0, 32) // close enough
	txtshow = todisplay
	txtshow = "<span style='color:[textcolor]'>[todisplay]</span>"
	finmat = transform
	finmat = finmat.Translate(0, 32)
	if(!defer)
		scoot_n_vanish()

/obj/effect/temp_visual/floaty_thing/proc/scoot_n_vanish()
	maptext = txtshow
	// and scoot it up and disappear
	animate(src, time = (duration-1), transform = finmat, alpha = 0)

/obj/effect/temp_visual/floaty_thing/cash
	textcolor = "#FFFF00"

