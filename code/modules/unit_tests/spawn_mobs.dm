///Unit test that spawns all mobs that can be spawned by golden slimes
/datum/unit_test/spawn_mobs

/datum/unit_test/spawn_mobs/Run()
	for(var/_animal in typesof(/mob/living/danimal))
		var/mob/living/danimal/animal = _animal
		if (initial(animal.gold_core_spawnable) == HOSTILE_SPAWN || initial(animal.gold_core_spawnable) == FRIENDLY_SPAWN)
			allocate(_animal)
