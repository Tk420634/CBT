// pain and suffering tries to strike you, but misses!
SUBSYSTEM_DEF(wounds)
	name = "Wounds"
	wait = 1 SECONDS
	runlevels = RUNLEVEL_GAME
	flags = SS_KEEP_TIMING
	/// list of templates for wounds, format: list(/datum/thewound)
	var/list/wound_templates = list()
	/// processing list of wounds to process each tick
	/// format: list(/datum/thewound)
	var/list/current_wounds = list()
	var/list/currentrun = list()
	/// saved list of injuries for each mob, to be saved, for metrics
	var/list/injury_history = list()


/datum/controller/subsystem/wounds/Initialize(start_timeofday)
	. = ..()
	to_chat(world, span_alertalien("Initialized [LAZYLEN(wound_templates)] ways for you to be hurt!"))

/datum/controller/subsystem/wounds/fire(resumed)
	if (!resumed)
		currentrun = current_wounds.Copy()
	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = currentrun
	while(currentrun.len)
		var/datum/wound/ow = currentrun[currentrun.len]
		currentrun.len--
		ow?.process()
		if(MC_TICK_CHECK)
			return











/datum/wound













