SUBSYSTEM_DEF(mobs)
	name = "Mobs"
	priority = FIRE_PRIORITY_MOBS
	flags = SS_KEEP_TIMING | SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = (2 SECONDS)

	var/list/currentrun = list()
	var/static/list/clients_by_zlevel[][]
	var/static/list/dead_players_by_zlevel[][] = list(list()) // Needs to support zlevel 1 here, MaxZChanged only happens when z2 is created and new_players can login before that.
	var/static/list/cubemonkeys = list()
	var/static/list/cheeserats = list()
	var/buggy_mob_running_away = FALSE

	var/there_is_no_escape = FALSE // there is escape
	var/debug_no_icon_2_html = FALSE
	var/debug_everyone_has_robuster_searching = FALSE

	var/distance_where_a_player_needs_to_be_in_for_npcs_to_fight_other_npcs = 12

	var/mobs_only_attack_players = TRUE // this feature sucks

/datum/controller/subsystem/mobs/stat_entry(msg)
	msg = "P:[length(GLOB.mob_living_list)]"
	return ..()

/datum/controller/subsystem/mobs/proc/MaxZChanged()
	if (!islist(clients_by_zlevel))
		clients_by_zlevel = new /list(world.maxz,0)
		dead_players_by_zlevel = new /list(world.maxz,0)
	while (clients_by_zlevel.len < world.maxz)
		clients_by_zlevel.len++
		clients_by_zlevel[clients_by_zlevel.len] = list()
		dead_players_by_zlevel.len++
		dead_players_by_zlevel[dead_players_by_zlevel.len] = list()

/datum/controller/subsystem/mobs/fire(resumed = 0)
	var/seconds = wait * 0.1
	if (!resumed)
		src.currentrun = GLOB.mob_living_list.Copy()

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	var/times_fired = src.times_fired
	while(currentrun.len)
		var/mob/living/L = currentrun[currentrun.len]
		currentrun.len--
		if(L)
			L.Life(seconds, times_fired)
		else
			GLOB.mob_living_list.Remove(L)
		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/mobs/proc/can_attack_npc(mob/living/attacker, mob/living/target)
	if(!istype(target) || !istype(attacker))
		return FALSE
	if(!target.client)
		if(SSmobs.mobs_only_attack_players)
			return FALSE
	var/client_in_range = FALSE
	for(var/mob/living/L in SSmobs.clients_by_zlevel[attacker.z])
		if(get_dist(attacker, L) < SSmobs.distance_where_a_player_needs_to_be_in_for_npcs_to_fight_other_npcs)
			return TRUE
	return FALSE

/* deprecatad */
/datum/controller/subsystem/mobs/proc/mob_spawned(mob/living/mob)

/datum/controller/subsystem/mobs/proc/mob_despawned(mob/living/mob)

/datum/controller/subsystem/mobs/proc/get_mob_tally(mob/living/mob)

/datum/controller/subsystem/mobs/proc/is_extinct(mobpath)

/datum/controller/subsystem/mobs/proc/get_existing_mob_paths(mob/mobpath)
	return typesof(mobpath)
/* end deprocatid */

//todo: move these vars to the actual file for hostile
/mob/living/simple_animal/hostile
	var/current_target_is_from_previous_tick = FALSE
	var/should_perform_dodge = FALSE
	var/should_attack_melee = FALSE
	var/should_attack_ranged = FALSE
	var/should_smash = FALSE
	var/should_windup_attack = FALSE











// /// Mob AI thinkholder
// /// kind of a blackboard, but... its just a blackboard
// /datum/mob_ai_thinkholder
// 	var/has_target_from_last_tick = FALSE
// 	var/
// 	// cooldowns
// 	/// next time mob can smash stuff, if they can
// 	var/melee_smash_cooldown = 0
// 	/// next time mob can do a melee attack, if they have one
// 	var/melee_attack_cooldown = 0
// 	/// set to current time + sight_shoot_delay_duration when a mob sees a target, to delay it shooting for a moment
// 	var/sight_shoot_delay = 0
// 	/// next time mob can throw something, if they can
// 	var/throw_cooldown = 0
// 	/// next time mob can do a ranged attack, if they have one
// 	var/ranged_cooldown = 0
// 	/// frustration timer stuff
// 	var/frustration_start_time = 0
// 	var/frustration_duration = 0
// 	var/last_move_randomization = 0
// 	var/vision_mult_active_until = 0 //if vision_mult_active_until is greater than world.time, we use the multiplied vision range, for things like attraction that temporarily boost vision
// 	var/movement_mode = MOB_MOVE_IDLE
// 	/// destination coords for retreating, considered "there" if the mob is "there"
// 	var/retreat_dest = null

// /datum/mob_ai_thinkholder/New(mob/living/simple_animal/hostile/mob)
// 	melee_smash_cooldown = world.time
// 	melee_attack_cooldown = world.time
// 	sight_shoot_delay = world.time
// 	throw_cooldown = world.time
// 	ranged_cooldown = world.time
