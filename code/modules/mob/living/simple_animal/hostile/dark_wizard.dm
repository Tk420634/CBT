/mob/living/danimal/hostile/dark_wizard
	name = "Dark Wizard"
	desc = "Killing amateurs since the dawn of times."
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "dark_wizard"
	icon_living = "dark_wizard"
	move_to_delay = 10
	projectiletype = /obj/item/projectile/temp/earth_bolt
	projectilesound = 'sound/magic/ethereal_enter.ogg'
	can_ranged_attack = TRUE
	ranged_message = "earth bolts"
	ranged_cooldown_duration = 20
	maxHealth = 50
	health = 50
	obj_damage = 20
	melee_damage_lower = 5
	melee_damage_upper = 5
	attack_verb_continuous = "staves"
	attack_verb_simple = "stave"
	a_intent = INTENT_HARM
	speak_emote = list("chants")
	attack_sound = 'sound/weapons/bladeslice.ogg'
	aggroed_vision_range = 9
	seconds_per_wander = 5
	gold_core_spawnable = HOSTILE_SPAWN
	faction = list(ROLE_WIZARD)
	footstep_type = FOOTSTEP_MOB_SHOE
	weather_immunities = list("lava","ash")
	//minbodytemp = 0
	//maxbodytemp = INFINITY
	// atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	loot = list(/obj/effect/decal/remains/human)

/obj/item/projectile/temp/earth_bolt
	name = "earth_bolt"
	icon_state = "declone"
	damage = 4
	damage_type = BURN
	flag = "energy"
