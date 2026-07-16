/mob/living/simple_animal/hostile
	faction = list("hostile")
	stop_wandering_when_pulled = 0
	obj_damage = 40
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES //Bitflags. Set to ENVIRONMENT_SMASH_STRUCTURES to break closets,tables,racks, etc; ENVIRONMENT_SMASH_WALLS for walls; ENVIRONMENT_SMASH_RWALLS for rwalls
	mob_size = MOB_SIZE_LARGE
	gold_core_spawnable = NO_SPAWN
	a_intent = INTENT_HARM // I LOVE PLAYING THE SCOOTER DANCE WITH PROTECTRONS
	var/datum/weakref/target
	var/ranged = FALSE
	var/rapid = 0 //How many shots per volley.
	var/rapid_fire_delay = 2 //Time between rapid fire shots

	var/dodging = FALSE
	var/approaching_target = FALSE //We should dodge now
	var/in_melee = FALSE	//We should sidestep now
	var/dodge_prob = 0
	var/sidestep_per_cycle = 0 //How many sidesteps per npcpool cycle when in melee

	var/extra_projectiles = 0 //how many projectiles above 1?
	/// How long to wait between shots?
	var/auto_fire_delay = GUN_AUTOFIRE_DELAY_NORMAL
	var/projectiletype	//set ONLY it and NULLIFY casingtype var, if we have ONLY projectile
	var/projectilesound
	/// Makes the mob throw a thing
	var/obj/item/throw_thing
	var/throw_thing_speed = 1
	var/throw_thing_sound = 'sound/weapons/punchmiss.ogg'
	/// Time between throwing things
	var/throw_delay = 10 SECONDS
	COOLDOWN_DECLARE(throw_cooldown)
	/// Play a sound after they shoot?
	var/sound_after_shooting
	/// How long after shooting should it play?
	var/sound_after_shooting_delay = 1 SECONDS
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

	var/casingtype		//set ONLY it and NULLIFY projectiletype, if we have projectile IN CASING
	/// Deciseconds between moves for automated movement. m2d 3 = standard, less is fast, more is slower.
	var/list/friends = list()
	var/list/foes = list()
	var/list/emote_taunt
	var/emote_taunt_sound = FALSE // Does it have a sound associated with the emote? Defaults to false.
	var/taunt_chance = 0

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

	var/lose_patience_timer_id //id for a timer to call LoseTarget(), used to stop mobs fixating on a target they can't reach
	var/lose_patience_timeout = 300 //30 seconds by default, so there's no major changes to AI behaviour, beyond actually bailing if stuck forever

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
	/// Is set by the update thingy to determine if the mob should do a melee attack this tick
	var/melee_attack_allowed = FALSE
	/// Number of rapid melee attacks left for this tick
	var/melee_rapid_attacks_left = 0
	/// currently rapid attacking
	var/melee_rapid_attacking = FALSE

	var/list/blackboard_tick = list() // a list of things to store for this tick, so i dont pass around a milluion argz

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
	var/assemlies_are_priority = TRUE // if assemlies are priority targets, set to FALSE to make them not be pruiority them

	/// The... slowdown? of a mob while a player is inside it? does nothing while ai controlled
	speed = 3

/mob/living/simple_animal/hostile/Initialize(mapload, nest_spawned)
	. = ..()
	set_origin(src)
	wanted_objects = typecacheof(wanted_objects)
	if(nest_spawned != "TOPHEAVY-KOBOLD")
		SSmobs.mob_spawned(src)
	if(MOB_EMP_DAMAGE in emp_flags)
		smoke = new /datum/effect_system/smoke_spread/bad
		smoke.attach(src)
	if(mapload && despawns_when_lonely)
		unbirth_self(TRUE)

/mob/living/simple_animal/hostile/Destroy()
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
	return ..()

/mob/living/simple_animal/hostile/BiologicalLife(seconds, times_fired)
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

/mob/living/simple_animal/hostile/proc/check_health()
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
/mob/living/simple_animal/hostile/proc/make_high_health()
	return

/// Override this with what should happen when going from high health to low health
/mob/living/simple_animal/hostile/proc/make_low_health()
	return

/// oh no it failed a tick, by runtiming or something, shut down the mob and highlight it or something
/mob/living/simple_animal/hostile/proc/Failed()
	ShutDownEverything()
	color = "#FF00FF"

/* *********************************
 * Main AI loop for hostile mobs. This is where the mob decides what to do each tick.
 * Kinda important
 * Notes:
 * order of ops:
 * if off, shut down if needed, clear everything and such, and cease
 * check if the last tick was in the middle of something, and if so, continue it if possible
 * plan this tick's actions
 * - find target if none
 * setup movement vars
 * perform movement
 * setup combat vars if in combat
 * perform combat if in combat
 */
/mob/living/simple_animal/hostile/handle_automated_action()
	. = "bad"
	if(AIStatus == AI_OFF)
		ShutDownEverything() // PresidentMadagascar, a man in brazil is coughing
		return FALSE
	
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
	UpdateAttraction(has_target)
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



/mob/living/simple_animal/hostile/proc/UpdateRTS()
	// todo: this

/mob/living/simple_animal/hostile/proc/UpdateAIStatusPreTick()
	if(RTS_move_ordered())
		toggle_ai(AI_ON)
		return TRUE
	if(AIShouldBeAwake())
		toggle_ai(AI_ON)
		return TRUE

/mob/living/simple_animal/hostile/proc/UpdateAIStatusPostTick()
	if(UpdateAIStatusPreTick())
		return // being on is important, going idle less so
	//todo: has-target checks, time-since-target-lost checks, frustration, etc

/// gives target if we didnt
/mob/living/simple_animal/hostile/proc/UpdateTarget(list/bb)
	if(!islist(bb))
		bb = blackboard_tick
	var/atom/my_target = get_or_remove_target() // has a target before this proc is called
	if(my_target) // if we have a target and its still valid, keep it
		var/eval_return = EvalTarget(my_target)
		if(CHECK_BITFIELD(eval_return, MTF_CAN_TARGET))
			bb[MBB_HAS_TARGET_FROM_LAST_TICK] = TRUE
			bb[MBB_HAS_TARGET] = TRUE
			bb[MBB_TARGET_EVAL] = eval_return
			return // target retained, job's done
	// possible_targets is a reference and modifies the caller's list
	// the closest this code gets to an out parameter
	//if we don't have a target, we try to find one
	bb[MBB_HAS_TARGET] = !!FindATarget()

/mob/living/simple_animal/hostile/proc/UpdateAttraction()
	return
	// todo: full rewrite of attraction, and also merging hostile into simple_animal
	// todo: continue driving these tack nails into my nuts

/// Check if we are able to do a melee to our target
/// Updates flags if so
/// todo: init check to auto-set to not use windup if someone bungled the vars
/mob/living/simple_animal/hostile/proc/UpdateWindup()
	if(!windup_enabled)
		return
	var/atom/my_target = get_or_remove_target()
	if(!my_target)
		WindupKill()
		return
	// state mingus
	// var/atom/my_origin = get_origin()
	// var/distance = get_dist(my_origin, my_target)
	// if(distance <= melee_range)
	// 	WindupStart()
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
/mob/living/simple_animal/hostile/proc/WindupStart()
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
/mob/living/simple_animal/hostile/proc/WindupCharging()
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
/mob/living/simple_animal/hostile/proc/WindupReady()
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
	return
	if(windup_sound_cancel)
		playsound(
			src,
			windup_sound_cancel,
			150,
			FALSE,
			distant_range = 4)
	// ok took too long, no more windup, reset it

/// handles killing the windup state and resetting it to none, for when we lose our target or something
/mob/living/simple_animal/hostile/proc/WindupKill()
	if(windup_state == MOB_WINDUP_NONE)
		return
	windup_state = MOB_WINDUP_NONE
	windup_delay_complete = 0
	windup_ready_timeout = 0

/// turns off the windup state forever, in case the vars are borken or something
/mob/living/simple_animal/hostile/proc/WindupKillForever()
	windup_state = MOB_WINDUP_NONE
	windup_delay_complete = 0
	windup_ready_timeout = 0
	windup_enabled = FALSE

// melee update
/// checks if we can *initiate* a melee this tick, and sets some vars accordingly
/mob/living/simple_animal/hostile/proc/UpdateMeleeAttack(list/bb)
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
/mob/living/simple_animal/hostile/proc/IsInMeleeRange()
	var/atom/my_target = get_or_remove_target()
	if(!my_target)
		return FALSE
	var/atom/my_origin = get_origin()
	var/atom/target_origin = my_target.get_origin()
	return src.can_reach(my_origin, reach = melee_range)

/// Checks if we can *initiate* a ranged attack this tick, and sets some vars accordingly
/mob/living/simple_animal/hostile/proc/UpdateRangedAttack(list/bb)
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
	if(!CanSeeTarget(my_target))
		return
	bb[MBB_RANGED_ATTACK_ALLOWED] = TRUE











/mob/living/simple_animal/hostile/handle_automated_movement()
	. = ..()
	if(!CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		return
	var/atom/my_target = get_target()
	if(dodging && my_target && in_melee && isturf(loc) && isturf(my_target.loc))
		var/datum/cb = CALLBACK(src,PROC_REF(sidestep))
		if(sidestep_per_cycle > 1) //For more than one just spread them equally - this could changed to some sensible distribution later
			var/sidestep_delay = SSnpcpool.wait / sidestep_per_cycle
			for(var/i in 1 to sidestep_per_cycle)
				addtimer(cb, (i - 1)*sidestep_delay)
		else //Otherwise randomize it to make the players guessing.
			addtimer(cb,rand(1,SSnpcpool.wait))
	if(my_target)
		InterruptAttractionMovement()

/mob/living/simple_animal/hostile/AutomateAttraction()
	if(!..())
		return
	vision_mult_active_until = world.time + vision_mult_duration

/mob/living/simple_animal/hostile/AttractionAct(atom/target_origin, intensity, max_range, duration)
	if(health <= 0)
		return
	if(get_target())
		InterruptAttractionMovement()
		return FALSE
	do_alert_animation(src)
	return ..()

/mob/living/simple_animal/hostile/toggle_ai(togglestatus)
	. = ..()
	queue_naptime()

/mob/living/simple_animal/hostile/proc/queue_naptime()
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

/mob/living/simple_animal/hostile/proc/consider_despawning()
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

/mob/living/simple_animal/hostile/become_the_mob(mob/user)
	if(lonely_timer_id)
		deltimer(lonely_timer_id)
		lonely_timer_id = null
	unqueue_unbirth()
	. = ..()


/mob/living/simple_animal/hostile/proc/sidestep()
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

/mob/living/simple_animal/hostile/attacked_by(obj/item/I, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1, damage_addition, damage_override)
	. = ..()
	WasAttackedBy(I, user)

/mob/living/simple_animal/hostile/bullet_act(obj/item/projectile/P)
	. = ..()
	WasAttackedBy(P, P.firer, TRUE)

/mob/living/simple_animal/hostile/proc/WasAttackedBy(atom/movable/implement, atom/movable/attacker, approach)
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

/mob/living/simple_animal/hostile/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
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
	return ..()

/mob/living/simple_animal/hostile/proc/get_vision_range()
	var/vrange = vision_range
	if(vision_mult_active_until > world.time)
		return vrange * 3
	return vrange

//////////////HOSTILE MOB TARGETTING AND AGGRESSION////////////

/// gets a list of all possible targets in range, regardless of if we can attack them or not
/mob/living/simple_animal/hostile/proc/ListTargets()//Step 1, find out what we can see
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

/mob/living/simple_animal/hostile/proc/GetPossibleTargets(auto_set_target = TRUE)//Step 2, filter down possible targets to things we actually care about
	. = list()
	if (peaceful)
		return

	var/targ_lockout = world.time < RTS_aggro_lockout
	var/list/targ_out = list()
	targout[MT_ALL] = ListTargets()
	targout[MT_VALID] = list()
	targout[MT_PRIORITY] = list()
	targout[MT_TOP_PRIORITY] = list()
	for(var/pos_targ in targout[MT_ALL])
		var/atom/A = pos_targ
		if(targ_lockout && !isplayer(A))
			continue
		if(Found(A))//Just in case people want to override targetting
			targout[MT_TOP_PRIORITY] = list(A)
			continue
		var/eval_return = EvalTarget(A)
		if(!CHECK_BITFIELD(eval_return, MTF_CAN_TARGET))
			continue
		if(CHECK_BITFIELD(eval_return, MTF_IS_FOE))
			targout[MT_PRIORITY] |= A
			continue
		if(players_are_priority && CHECK_BITFIELD(eval_return, MTF_IS_PLAYER))
			targout[MT_PRIORITY] |= A
			continue
		if(objects_are_priority && CHECK_BITFIELD(eval_return, MTF_IS_OBJECT))
			targout[MT_PRIORITY] |= A
			continue
		if(assemblies_are_priority && CHECK_BITFIELD(eval_return, MTF_IS_ASSEMBLY))
			targout[MT_PRIORITY] |= A
			continue
		if(turrets_are_priority && CHECK_BITFIELD(eval_return, MTF_IS_TURRET))
			targout[MT_PRIORITY] |= A
			continue
		targout[MT_VALID] |= A
	if(auto_set_target)
		var/Target = ChooseTargetFromList(targout)
		GiveTarget(Target)
		var/list/retlist = list()

		return Target //We now have a targettte
	return targout

/// not very used
/mob/living/simple_animal/hostile/proc/PossibleThreats()
	. = list()
	for(var/pos_targ in ListTargets())
		var/atom/A = pos_targ
		if(Found(A))
			. = list(A)
			break
		if(EvalTarget(A))
			. += A
			continue



/mob/living/simple_animal/hostile/proc/Found(atom/A)//This is here as a potential override to pick a specific targette if available
	return

/// goes through a few lists of possible targets, and picks the most best one to target
/mob/living/simple_animal/hostile/proc/ChooseTargetFromList(list/targlist_in)//Step 3, pick amongst the possible, attackable targets
	if(LAZYLEN(targlist_in[MT_TOP_PRIORITY]))
		return pick(targlist_in[MT_TOP_PRIORITY])
	var/atom/my_target = get_or_remove_target()
	var/list/targets = list()
	targets["priority"] = targlist_in[MT_PRIORITY]
	targets["valid"] = targlist_in[MT_VALID]

	if(!use_advanced_target_priority_selection)
		var/chosen_target
		if(my_target)//If we have a current target, pick it first
			return my_target
		if(LAZYLEN(targets["priority"]))//If we have a list of priority targets, pick from them first
			chosen_target = pick(targets["priority"])
		if(!chosen_target)//If we didnt find a priority target, pick from the rest
			chosen_target = pick(targets["valid"])
		return chosen_target

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
	var/atom/chosen_target
	if(LAZYLEN(highest_targets))
		chosen_target = pick(highest_targets)
	return chosen_target

/mob/living/simple_animal/hostile/proc/GetDistancePriority(atom/A, atom/origin)
	. = 0
	if(!use_distance_priority)
		return
	. += priority_bonus
	var/dist_pen = get_dist(origin, A) * 10
	. -= dist_pen

/mob/living/simple_animal/hostile/proc/GetHealthPriority(atom/A)
	. = 0
	if(!use_health_priority)
		return
	if(!isliving(A))
		return
	var/mob/living/L = A
	var/health_bonus = 100 - ((L.health / L.maxHealth) * 100)
	. += health_bonus

// Please do not add one-off mob AIs here, but override this function for your mob
/// Returns a bitfield of flags
/mob/living/simple_animal/hostile/EvalTarget(atom/the_target)//Can we actually attack a possible targette?
	. = NONE
	if(!the_target || the_target.type == /atom/movable/lighting_object || isturf(the_target)) // bail out on invalids
		return
	if(see_invisible < the_target.invisibility)//Target's invisible to us, forget it
		return
	var/objects_only = search_objects >= 3
	if(CanSee(the_target))
		. |= MTF_CAN_SEE

	var/am_player = isplayer(the_target)
	var/datum/weakref/target_ref = WEAKREF(the_target)
	if(target_ref in foes)
		. = MTF_CAN_TARGET | MTF_IS_LIVING | MTF_IS_FOE
		if(am_player)
			. |= MTF_IS_PLAYER
		return
	if(target_ref in friends)
		. = MTF_CAN_TARGET | MTF_IS_LIVING | MTF_IS_FRIEND
		if(am_player)
			. |= MTF_IS_PLAYER
		return

	if(isobj(the_target))
		if(attack_all_objects || is_type_in_typecache(the_target, wanted_objects))
			return MTF_CAN_TARGET | MTF_IS_OBJECT

		if(istype(the_target, /obj/item/electronic_assembly))
			var/obj/item/electronic_assembly/O = the_target
			if(O.combat_circuits)
				return MTF_CAN_TARGET | MTF_IS_OBJECT | MTF_IS_ASSEMBLY

		if(ismecha(the_target))
			var/obj/mecha/M = the_target
			return EvalTarget(M.occupant)

		if(istype(the_target, /obj/machinery/porta_turret))
			var/obj/machinery/porta_turret/P = the_target
			if(P.in_faction(src)) //Don't attack if the turret is in the same faction
				return
			if(P.stat & BROKEN) //Or turrets that are already broken
				return
			return MTF_CAN_TARGET | MTF_IS_OBJECT | MTF_IS_TURRET

	if(objects_only)
		return

	if(isliving(the_target))
		var/mob/L = the_target
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
			return
		if(L.stat > stat_attack)
			return
		if(stat_attack == CONSCIOUS && IS_STAMCRIT(L))
			return
		if(attack_downed_players && L.stat == SOFT_CRIT && iscarbon(L))
			/// so fun fact, not all players go into crit at 0 HP
			/// some go into crit at, like, 50 HP, or at -40 HP
			/// so we have to offset the crit threshold by the amount of health they have
			if(!L.attackable_in_crit())
				return
		. = MTF_CAN_TARGET | MTF_IS_LIVING
		if(am_player)
			. |= MTF_IS_PLAYER
		return

/mob/living/simple_animal/hostile/proc/MeleeActionIfPossible(patience = TRUE, atom/target_override = null)
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
/mob/living/simple_animal/hostile/proc/MeleeAction(patience = TRUE, atom/target_override = null)
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
		GainPatience()

/mob/living/simple_animal/hostile/proc/CheckAndAttack()
	var/atom/origin = get_origin()
	var/atom/my_target = get_target()
	if(my_target && origin && isturf(origin.loc) && my_target.Adjacent(origin) && !incapacitated())
		AttackingTarget()

/mob/living/simple_animal/hostile/proc/perform_automated_combat_move(list/possible_targets)//Step 5, handle movement between us and our targette
	stop_wandering = TRUE
	if (peaceful == TRUE)
		LoseTarget()
		return FALSE
	
	var/atom/my_target = get_target()
	if(!my_target || !EvalTarget(my_target))
		LoseTarget()
		return FALSE
	var/turf/T = get_turf(src)
	if(my_target.z != T.z)
		LoseTarget()
		return 0

	var/atom/origin = get_origin()
	if(!(my_target in possible_targets))
		handle_frustration()
		return FALSE
	reset_frustration()
	if(get_dist(src, my_target) > max_tracking_range)
		LoseTarget()
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

/mob/living/simple_animal/hostile/proc/handle_frustration()
	if(!last_frustration)
		last_frustration = world.time
		return
	if(world.time - last_frustration >= max_frustration)
		LoseTarget()
		reset_frustration()
		return TRUE

/mob/living/simple_animal/hostile/proc/reset_frustration()
	frustration_total = 0
	last_frustration = 0

/// *********************
/// MOVEMENT PROCS
/// *********************

/// the args are overrides
/mob/living/simple_animal/hostile/proc/perform_move_action(targette, delay, minimum_distance = 0)
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
/mob/living/simple_animal/hostile/proc/get_move_target(targette)
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

/mob/living/simple_animal/hostile/proc/get_move_delay(delay)
	if(delay)
		return delay
	else
		return variate_move_to_delay()

/mob/living/simple_animal/hostile/proc/get_target_standoff_distance(minimum_distance, atom/target)
	if(minimum_distance)
		return minimum_distance
	if(movement_mode == MOB_MOVE_AWAY_FROM_TARGET)
		return 0 // we want to move to the target, yeah
	if(movement_mode == MOB_MOVE_TOWARDS_TARGET) // now we're getting somewhere
		if(approach_distance)
			return approach_distance
		
	else
		var/dist = get_dist(src, target)
		if(dist <= melee_queue_distance)
		return variate_minimum_distance()

/// **
/// RETREAT STUFF
/// **

/mob/living/simple_animal/hostile/proc/get_retreat_target()
	var/turf/T = coords2turf(retreat_dest)
	if(isturf(T))
		return T
	else
		return get_target()

/mob/living/simple_animal/hostile/proc/is_at_retreat_dest(turf/T)
	// check timeout
	if(world.time > retreat_timeout)
		return TRUE
	if(!isturf(T))
		T = coords2turf(retreat_dest)
		if(!isturf(T))
			return FALSE
	return (get_dist(src, T) > retreat_dest_radius)

/// uses that wacky bullet casing eject code to find somewhere to run away to
/mob/living/simple_animal/hostile/proc/get_new_retreat_dest()
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

/mob/living/simple_animal/hostile/proc/set_new_retreat_dest(turf/T)
	retreat_dest = atom2coords(T)
	retreat_timeout = world.time + retreat_timeout_duration
	return retreat_dest

/// ***********************
/// MOVEMENT UPDATOR
/// ***********************
//todo: a more reliable move timer
//todo: what counts as a 'move' ? Especially for approaching
//todo: maybe moves only count for retreating? approach is a timer / action based?
/mob/living/simple_animal/hostile/proc/update_movement_mode()
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
/mob/living/simple_animal/hostile/proc/should_move_towards_target()
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

/mob/living/simple_animal/hostile/proc/should_move_away_from_target()
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

/mob/living/simple_animal/hostile/proc/set_movement_mode(new_mode)
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

/mob/living/simple_animal/hostile/proc/update_approach(mode_changed, time_in_mode)
	if(mode_changed)
		approach_timeout = world.time + get_approach_duration()

/// Handles updating which tile to run to, and the moves left to run
/mob/living/simple_animal/hostile/proc/update_retreat(mode_changed, time_in_mode)
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

/mob/living/simple_animal/hostile/proc/clear_movement_data()
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

/mob/living/simple_animal/hostile/proc/get_approach_duration()
	return variate_approach_duration()

/mob/living/simple_animal/hostile/proc/get_retreat_duration()
	return variate_retreat_duration()

/mob/living/simple_animal/hostile/proc/get_retreat_moves()
	return variate_retreat_moves()

/mob/living/simple_animal/hostile/proc/get_target_standoff_distance(minimum_distance, atom/target)
	if(minimum_distance)
		return minimum_distance
	else
		var/dist = get_dist(src, target)
		if(dist <= melee_queue_distance)
			return variate_minimum_distance()
		else
			return 1 // if we're not in melee range, we might as well try and get as close as possible


/// *********************

/mob/living/simple_animal/hostile/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	on_health_changed(.)

/mob/living/simple_animal/hostile/proc/on_health_changed(amount)
	if(ckey)
		return
	if(stat != CONSCIOUS)
		return
	if(search_objects >= 2)
		return
	if(amount <= 0)
		return




	if(!ckey && !stat && search_objects < 3 && . > 0)//Not unconscious, and we don't ignore mobs
		if(amount > 0)
			try_tactical_retreat()
		if(peaceful == TRUE)
			peaceful = FALSE
		if(search_objects)//Turn off item searching and ignore whatever item we were looking at, we're more concerned with fight or flight
			LoseTarget()
			LoseSearchObjects()
		if(AIStatus != AI_ON && AIStatus != AI_OFF)
			toggle_ai(AI_ON)
			FindATarget()
		else if(get_target() != null && prob(40))//No more pulling a mob forever and having a second player attack it, it can switch targets now if it finds a more suitable one
			FindATarget()


/mob/living/simple_animal/hostile/proc/AttackingTarget(atom/target_override)
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
/mob/living/simple_animal/hostile/proc/AlternateAttackingTarget(atom/the_target)
	return

/mob/living/simple_animal/hostile/proc/Aggro()
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


/mob/living/simple_animal/hostile/proc/LoseAggro()
	stop_wandering = 0
	vision_range = initial(vision_range)
	taunt_chance = initial(taunt_chance)

//////////////END HOSTILE MOB TARGETTING AND AGGRESSION////////////

/// Makes mobs smash stuff!
/mob/living/simple_animal/hostile/rts_smash_things()
	EscapeConfinement()
	DestroyPathToTarget()

/mob/living/simple_animal/hostile/death(gibbed)
	LoseTarget()
	..(gibbed)

/mob/living/simple_animal/hostile/proc/summon_backup(distance, exact_faction_match)
	if(COOLDOWN_FINISHED(src, ding_spam_cooldown))
		return TRUE
	COOLDOWN_START(src, ding_spam_cooldown, SIMPLE_MOB_DING_COOLDOWN)
	do_alert_animation(src)
	playsound(loc, 'sound/machines/chime.ogg', 50, 1, -1)
	for(var/mob/living/simple_animal/hostile/M in oview(distance, get_origin()))
		if(!mob_faction_is_friendly_to_target(M))
			continue
		if(M.AIStatus == AI_OFF || M.stat == DEAD || M.ckey)
			continue
		M.perform_move_action(src,M.move_to_delay,M.minimum_distance)

/mob/living/simple_animal/hostile/proc/CheckFriendlyFire(atom/A)
	if(!check_friendly_fire || ckey || should_factionize_shots)
		return FALSE
	for(var/turf/T in getline(src,A)) // Not 100% reliable but this is faster than simulating actual trajectory
		for(var/mob/living/L in T)
			if(L == src || L == A)
				continue
			if(mob_faction_is_friendly_to_target(L) && !attack_same)
				return TRUE

/mob/living/simple_animal/hostile/proc/OpenFire(atom/A, rts)
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
	ThrowSomething(A)
	ranged_cooldown = world.time + ranged_cooldown_time + rand(0,30)
	if(sound_after_shooting)
		addtimer(CALLBACK(usr, GLOBAL_PROC_REF(playsound), src, sound_after_shooting, 100, 0, 0), sound_after_shooting_delay, TIMER_STOPPABLE)
	variate_projectile_type(TRUE)
	variate_casing_type(TRUE)

/mob/living/simple_animal/hostile/proc/ThrowSomething(atom/targeted_atom)
	if(!istype(throw_thing) || !istype(targeted_atom))
		return
	if(!COOLDOWN_FINISHED(src, throw_cooldown))
		return
	COOLDOWN_START(src, throw_cooldown, throw_delay)
	var/obj/item/tosser = new throw_thing(get_turf(src))
	tosser.throw_at(targeted_atom, 25, throw_thing_speed, src, TRUE, TRUE)
	playsound(src, throw_thing_sound, 100, TRUE)
	visible_message(span_alert("[src] throws [tosser] at [targeted_atom]!"))

/mob/living/simple_animal/hostile/proc/Shoot(atom/targeted_atom, spread = 0)
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

/mob/living/simple_animal/hostile/proc/CanSmashTurfs(turf/T)
	return iswallturf(T) || ismineralturf(T)


/mob/living/simple_animal/hostile/Move(atom/newloc, dir , step_x , step_y)
	if(!winding_up_melee && dodging && approaching_target && prob(dodge_prob) && moving_diagonally == 0 && isturf(loc) && isturf(newloc))
		return dodge(newloc,dir)
	else
		return ..()

/mob/living/simple_animal/hostile/proc/dodge(moving_to,move_direction)
	var/cdir = turn(move_direction,90)
	var/ccdir = turn(move_direction,-90)
//	var/next_step_dir = pick(cdir,ccdir) sworddoggirl is way too cute ~Fenny

	dodging = FALSE
	. = Move(get_step(loc,pick(cdir,ccdir)))
	if(!.) //Can't dodge there!
		visible_message("<span class='notice'>[src] dodges!</span>")
		playsound(loc, 'sound/effects/rustle3.ogg', 50, 1, -1)
	else
		// Apply stamina damage if the mob tried to dodge into a wall
		adjustStaminaLoss(10)
		playsound(loc, 'sound/effects/hit_punch.ogg', 50, 1, -1) // Play a punch sound
	dodging = TRUE

/mob/living/simple_animal/hostile/proc/DestroyObjectsInDirection(direction, rtsd)
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


/mob/living/simple_animal/hostile/proc/DestroyPathToTarget(forceit)
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


/mob/living/simple_animal/hostile/proc/DestroySurroundings() // for use with megafauna destroying everything around them
	EscapeConfinement()
	for(var/dir in GLOB.alldirs)
		DestroyObjectsInDirection(dir)


/mob/living/simple_animal/hostile/proc/EscapeConfinement()
	if(buckled)
		buckled.attack_animal(src)
	var/atom/origin = get_origin()
	if(!origin)
		return
	if(!isturf(origin.loc) && origin.loc != null)//Did someone put us in something?
		var/atom/A = origin.loc
		A.attack_animal(src)//Bang on it till we get out


/mob/living/simple_animal/hostile/proc/FindHidden()
	var/atom/my_target = get_target()
	if(!my_target)
		return FALSE
	if(istype(my_target.loc, /obj/structure/closet) || istype(my_target.loc, /obj/machinery/disposal) || istype(my_target.loc, /obj/machinery/sleeper))
		var/atom/A = my_target.loc
		perform_move_action(A,move_to_delay,minimum_distance)
		if(A.Adjacent(get_origin()))
			A.attack_animal(src)
		return 1

/mob/living/simple_animal/hostile/RangedAttack(atom/A, params) //Player firing
	if(ranged && ranged_cooldown <= world.time)
		GiveTarget(A)
		OpenFire(A)
		DelayNextAction()
	. = ..()
	return TRUE

/mob/living/simple_animal/hostile/rts_shoot(atom/A) //RTS firing
	if((ranged || projectiletype || casingtype) && world.time >= ranged_cooldown)
		ranged_cooldown = world.time + ranged_cooldown_time
		OpenFire(A)

/mob/living/simple_animal/hostile/proc/get_origin()
	return GET_WEAKREF(targetting_origin) || src

/mob/living/simple_animal/hostile/proc/set_origin(atom/orgin)
	if(!orgin)
		orgin = src
	targetting_origin = WEAKREF(orgin)

/mob/living/simple_animal/hostile/proc/unset_origin()
	targetting_origin = null

/// *****************
/// AI STATUS PROCS
/// *****************

////// AI Status ///////
/mob/living/simple_animal/hostile/proc/AICanContinue()
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
/mob/living/simple_animal/hostile/proc/AIShouldBeAwake()
	for(var/client/C in SSmobs.clients_by_zlevel[z])
		if(get_dist(src, C) <= max_tracking_range)
			return TRUE

/mob/living/simple_animal/hostile/proc/AIShouldSleep()
	var/atom/targ = get_target()
	if(get_dist(src, targ) >= max_tracking_range)
		return FALSE
	if(RTS_move_ordered())
		return FALSE
	if(FindATarget())
		return FALSE
	return TRUE

//These two procs handle losing our targette if we've failed to attack them for
//more than lose_patience_timeout deciseconds, which probably means we're stuck
/mob/living/simple_animal/hostile/proc/GainPatience()
	if(QDELETED(src))
		return

	if(lose_patience_timeout)
		LosePatience()
		lose_patience_timer_id = addtimer(CALLBACK(src,PROC_REF(LoseTarget)), lose_patience_timeout, TIMER_STOPPABLE)


/mob/living/simple_animal/hostile/proc/LosePatience()
	deltimer(lose_patience_timer_id)


//These two procs handle losing and regaining search_objects when attacked by a mob
/mob/living/simple_animal/hostile/proc/LoseSearchObjects()
	if(QDELETED(src))
		return

	search_objects = 0
	deltimer(search_objects_timer_id)
	search_objects_timer_id = addtimer(CALLBACK(src,PROC_REF(RegainSearchObjects)), search_objects_regain_time, TIMER_STOPPABLE)


/mob/living/simple_animal/hostile/proc/RegainSearchObjects(value)
	if(!value)
		value = initial(search_objects)
	search_objects = value

/mob/living/simple_animal/hostile/consider_wakeup()
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

/mob/living/simple_animal/hostile/proc/ListTargetsLazy(_Z)//Step 1, find out what we can see
	var/static/hostile_machines = typecacheof(list(/obj/machinery/porta_turret, /obj/mecha))
	. = list()
	var/v_range = get_vision_range()
	for (var/I in SSmobs.clients_by_zlevel[_Z])
		var/mob/M = I
		if (get_dist(M, src) < v_range)
			if (isturf(M.loc))
				. += M
			else if (M.loc.type in hostile_machines)
				. += M.loc

/mob/living/simple_animal/hostile/proc/handle_target_del(datum/source)
	SIGNAL_HANDLER
	unset_target()
	LoseTarget()

/mob/living/simple_animal/hostile/proc/unset_target()
	var/atom/my_target = get_target()
	if(my_target)
		UnregisterSignal(my_target, COMSIG_PARENT_QDELETING)
	target = null

/mob/living/simple_animal/hostile/proc/get_or_remove_target()
	var/atom/target = get_target()
	if(!is_valid_atom_to_target(target))
		LoseTarget()
		return null
	return target

/mob/living/simple_animal/hostile/proc/get_target()
	return GET_WEAKREF(target)

/mob/living/simple_animal/hostile/proc/add_target(new_target)
	unset_target()
	if(!new_target)
		return
	target = WEAKREF(new_target)
	RegisterSignal(target, COMSIG_PARENT_QDELETING,PROC_REF(handle_target_del), TRUE)

/mob/living/simple_animal/hostile/proc/LoseTarget()
	GiveTarget(null)
	approaching_target = FALSE
	in_melee = FALSE
	if(!RTS_move_ordered())
		walk(src, 0)
	LoseAggro()

/mob/living/simple_animal/hostile/proc/GiveTarget(new_target, evaluate)//Step 4, give us our selected targette
	var/atom/old_target = get_target()
	if(old_target == new_target)
		return FALSE
	if(evaluate)	
		var/eval_ret = EvalTarget(new_target)
		if(!CHECK_BITFIELD(eval_ret, MTF_CAN_TARGET))
			return FALSE
	add_target(new_target)
	LosePatience()
	if(get_target() != null)
		if(RTS_move_ordered())
			clear_target_coords()
			walk(src, 0)
		GainPatience()
		Aggro()
		COOLDOWN_START(src, sight_shoot_delay, sight_shoot_delay_duration)
		return 1

/mob/living/simple_animal/hostile/proc/current_target_is_valid()
	var/atom/my_target = get_target()
	return is_valid_atom_to_target(my_target)

/mob/living/simple_animal/hostile/proc/is_valid_atom_to_target(atom/target_check)
	if(!target_check)
		return FALSE
	if(QDELETED(target_check))
		return FALSE
	if(!get_turf(target_check))
		return FALSE
	return TRUE


/// ************************
/// NEST UNBIRTH PROCS
/// ************************

/mob/living/simple_animal/hostile/proc/queue_unbirth()
	SSidlenpcpool.add_to_culling(src)

/mob/living/simple_animal/hostile/proc/unqueue_unbirth()
	SSidlenpcpool.remove_from_culling(src)

/// return to monke-- stuffs a mob into their own special nest
/mob/living/simple_animal/hostile/proc/unbirth_self(forced)
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

/mob/living/simple_animal/hostile/proc/variate_move_to_delay()
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

/mob/living/simple_animal/hostile/proc/variate_projectile_type()
	. = projectiletype
	if(!projectiletype)
		return
	if(LAZYLEN(variation_list[MOB_PROJECTILE]) < 2)
		return
	var/new_projectile = vary_from_list(variation_list[MOB_PROJECTILE])
	if(autoset_variations[MOB_PROJECTILE])
		projectiletype = new_projectile
	return new_projectile


/mob/living/simple_animal/hostile/proc/variate_casing_type()
	. = casingtype
	if(!casingtype)
		return
	if(LAZYLEN(variation_list[MOB_CASING]) < 2)
		return
	var/new_casing = vary_from_list(variation_list[MOB_CASING])
	if(autoset_variations[MOB_CASING])
		casingtype = new_casing
	return new_casing

/mob/living/simple_animal/hostile/proc/variate_minimum_distance()
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

/mob/living/simple_animal/hostile/proc/variate_retreat_distance()
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

/mob/living/simple_animal/hostile/setup_variations()
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

/// ***********************
/// EMP PROCS
/// ***********************

/mob/living/simple_animal/hostile/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	emp_effect(severity)

/// EMP intensity tends to be 20-40
/mob/living/simple_animal/hostile/proc/emp_effect(intensity)
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

/mob/living/simple_animal/hostile/proc/do_emp_stun(intensity)
	if(!intensity)
		return FALSE
	if(MOB_EMP_STUN in active_emp_flags)
		return FALSE
	active_emp_flags |= MOB_EMP_STUN
	visible_message(span_green("[src] shudders as the EMP overloads its servos!"))
	LoseTarget()
	toggle_ai(AI_OFF)
	addtimer(CALLBACK(src,PROC_REF(un_emp_stun)), min(intensity, 3 SECONDS))

/mob/living/simple_animal/hostile/proc/un_emp_stun()
	active_emp_flags -= MOB_EMP_STUN
	LoseTarget()
	toggle_ai(AI_ON)

/mob/living/simple_animal/hostile/proc/do_emp_berserk(intensity)
	if(!intensity)
		return FALSE
	if(MOB_EMP_BERSERK in active_emp_flags)
		return FALSE
	active_emp_flags |= MOB_EMP_BERSERK
	LoseTarget()
	visible_message(span_green("[src] lets out a burst of static and whips its gun around wildly!"))
	var/list/old_faction = faction
	faction = null
	addtimer(CALLBACK(src,PROC_REF(un_emp_berserk), old_faction), intensity SECONDS * 0.5)

/mob/living/simple_animal/hostile/proc/un_emp_berserk(list/unberserk)
	active_emp_flags -= MOB_EMP_BERSERK
	faction = unberserk
	LoseTarget()

/mob/living/simple_animal/hostile/proc/do_emp_damage(intensity)
	if(!intensity)
		return FALSE
	smoke.set_up(round(clamp(intensity*0.5, 1, 3), 1), src)
	smoke.start()
	visible_message(span_green("[src] shoots out a plume of acrid smoke!"))
	adjustBruteLoss(maxHealth * 0.01 * intensity)
	playsound(src.loc, 'sound/effects/smoke.ogg', 50, 1, -3)

/mob/living/simple_animal/hostile/proc/do_emp_scramble(intensity)
	if(!intensity)
		return FALSE
	move_to_delay = rand(move_to_delay * 0.5, move_to_delay * 2)
	auto_fire_delay = rand(auto_fire_delay * 0.8, auto_fire_delay * 1.5)
	extra_projectiles = rand(extra_projectiles - 1, extra_projectiles + 1)
	ranged_cooldown_time = rand(ranged_cooldown_time * 0.5, ranged_cooldown_time * 2)
	retreat_distance = rand(0, 10)
	minimum_distance = rand(0, 10)
	LoseTarget()
	visible_message(span_notice("[src] jerks around wildly and starts acting strange!"))

/// ***********************
/// TACTICAL RETREAT PROCS
/// ***********************

/mob/living/simple_animal/hostile/proc/try_tactical_retreat()
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

/mob/living/simple_animal/hostile/proc/start_tactical_retreat()
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

/mob/living/simple_animal/hostile/proc/stop_tactical_retreat()
	retreat_distance = initial(retreat_distance) //Stop retreating
	retreat_message_said = FALSE //I can say my retreat message again if I need to


/// *************************
/// PASSIVE HEALING PROCS
/// *************************

/mob/living/simple_animal/hostile/proc/passive_healing() // Every life tick, my hostile ass is going to...
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

