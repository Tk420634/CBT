/* 
 * NPC POOL SUBSYSTEM
 * Handles NPC mob AI heartbeats
 * Want to make mobs tick more often? adjust the wait time!
 * Does NOT handle stuff like Life or anything other than AI movement, speech, and actions
 * That stuff is handled by SSmobs!
 * Also handles the wander attractor system
 * */
SUBSYSTEM_DEF(npcpool)
	name = "NPC Pool"
	flags = SS_POST_FIRE_TIMING|SS_NO_INIT|SS_BACKGROUND
	priority = FIRE_PRIORITY_NPC
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = (0.2 SECONDS) // ZOOOOOOOM *cpu dies x.x

	var/list/currentrun = list()

	var/debug_attraction = TRUE

/datum/controller/subsystem/npcpool/stat_entry(msg)
	var/list/activelist = GLOB.simple_animals[AI_ON]
	msg = "NPCS:[length(activelist)]"
	return ..()

/datum/controller/subsystem/npcpool/fire(resumed = FALSE)

	if (!resumed)
		var/list/activelist = GLOB.simple_animals[AI_ON]
		src.currentrun = activelist.Copy()

	//cache for sanic speed (lists are references anyways) // this line appears 24 times in 19 files!
	var/list/currentrun = src.currentrun

	while(currentrun.len)
		var/mob/living/danimal/SA = currentrun[currentrun.len]
		--currentrun.len

		if (QDELETED(SA)) // Some issue causes nulls to get into this list some times. This keeps it running, but the bug is still there.
			GLOB.simple_animals[AI_ON] -= SA
			stack_trace("Found a null in simple_animals active list [SA.type]!")
			continue
		if(SA.MobReadyToTick())
			if(!SA.ckey && !SA.mob_transforming)
				var/abort = FALSE
				if(SA.stat != DEAD)
					abort = SA.handle_automated_action() == "bad"
					if(abort)
						SA.Failed()
				if(SA.stat != DEAD && !abort)
					SA.handle_automated_movement()
				if(SA.stat != DEAD && !abort)
					SA.handle_automated_speech()
			SA.PostTick()
		if (MC_TICK_CHECK)
			return
	// for(var/ID in wander_attractors)
	// 	var/datum/wander_attractor/att = wander_attractors[ID]
	// 	if(att.IsExpired())
	// 		wander_attractors.Remove(ID)
	// 		free_ids |= ID

/* WANDER ATTRACTOR!! */
/* 
 * When something in the game world makes a sound or some sort of allurance to mobs,
 * it does a ranged check for mobs in the area! It then compares the allurance to the
 * intensity of the attractor they subscribe to (if any), and if the allurance is higher,
 * they will wander towards the attractor for a bit! This is used for things like ferals
 * hearing a gunshot, or grenade, or something. maybe even some gecko musk to get them to
 * be all horny for you! =^w^=
 */
/datum/controller/subsystem/npcpool/proc/make_attraction(atom/doer, intensity, max_range, duration = (30 SECONDS))
	if(!doer)
		return
	if(intensity <= 0)
		return
	if(max_range <= 0)
		return
	for(var/mob/living/danimal/M in GLOB.simple_animals[AI_ON])
		if(!M.attractable)
			continue
		if(GET_DIST_EUCLIDEAN(M, doer) > max_range)
			continue
		M.AttractionAct(doer, intensity, max_range, duration)

/datum/wander_attractor
	var/datum/weakref/owner
	var/die_time
	var/intensity
	var/target_x = 0
	var/target_y = 0
	var/target_z = 0

/datum/wander_attractor/New()
	. = ..()

/datum/wander_attractor/Destroy()
	var/mob/living/danimal/SA = GET_WEAKREF(owner)
	if(SA)
		SA.InterruptAttractionMovement()
		SA.current_attraction = null
	owner = null
	. = ..()

/datum/wander_attractor/proc/SetTarget(atom/orig)
	var/turf/T = get_turf(orig)
	if(T)
		target_x = T.x
		target_y = T.y
		target_z = T.z

/datum/wander_attractor/proc/SetOwner(mob/living/danimal/SA)
	owner = GET_WEAKREF(SA)

/datum/wander_attractor/proc/SetupIntensity(atom/listener, intensity, max_distance)
	intensity = ModulateIntensityByDistance(listener, intensity, max_distance)

/datum/wander_attractor/proc/ModulateIntensityByDistance(atom/listener, intensity, max_distance)
	var/turf/mymob = get_turf(listener)
	if(!mymob)
		return 0
	var/atom/target = locate(target_x, target_y, target_z)
	if(!target)
		return 0
	var/distance = GET_DIST_EUCLIDEAN(mymob, target)
	var/modulated_intensity = intensity * (1 - (distance / max_distance))
	return modulated_intensity


/datum/wander_attractor/proc/GetTarget()
	var/atom/target = locate(target_x, target_y, target_z)
	return target

