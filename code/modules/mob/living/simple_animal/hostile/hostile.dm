/* *********************************************
 * WELCOME TO DANS OVERHAULED MOB CODE! (D.O.M. CODE)
 * All the procs and vars for hostile mobs have been moved to simple_animal.dm
 * guess they arent that simple anymore huh? :^)
 * Hostile mobs are just simple animals with their vars preset to something hostile
 * ********************************************* */
/mob/living/danimal/hostile
	faction = list("hostile")
	stop_wandering_when_pulled = 0
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES //Bitflags. Set to ENVIRONMENT_SMASH_STRUCTURES to break closets,tables,racks, etc; ENVIRONMENT_SMASH_WALLS for walls; ENVIRONMENT_SMASH_RWALLS for rwalls
	mob_size = MOB_SIZE_LARGE
	gold_core_spawnable = NO_SPAWN
	a_intent = INTENT_HARM // I LOVE PLAYING THE SCOOTER DANCE WITH PROTECTRONS
	simple = FALSE
	obj_damage = 40
	melee_damage_lower = 10
	melee_damage_upper = 20
	melee_damage_type = BRUTE


/mob/living/danimal/hostile/Initialize(mapload, nest_spawned)
	. = ..()

/mob/living/danimal/hostile/Destroy()
	. = ..()

