//Look Sir, free crabs!
/mob/living/danimal/crab
	name = "crab"
	desc = "Free crabs!"
	icon_state = "crab"
	icon_living = "crab"
	icon_dead = "crab_dead"
	speak_emote = list("clicks")
	emote_hear = list("clicks.")
	emote_see = list("clacks.")
	blood_volume = 350
	speak_chance = 1
	seconds_per_wander = 5
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/rawcrab = 4)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "stomps"
	response_harm_simple = "stomp"
	stop_wandering = 1
	friendly_verb_continuous = "pinches"
	friendly_verb_simple = "pinch"
	ventcrawler = VENTCRAWLER_ALWAYS
	mob_size = MOB_SIZE_TINY
	var/obj/item/inventory_head
	var/obj/item/inventory_mask
	gold_core_spawnable = FRIENDLY_SPAWN

/mob/living/danimal/crab/BiologicalLife(seconds, times_fired)
	if(!(. = ..()))
		return
	//CRAB movement
	regenerate_icons()

//COFFEE! SQUEEEEEEEEE!
/mob/living/danimal/crab/Coffee
	name = "Coffee"
	real_name = "Coffee"
	desc = "It's Coffee, the other pet!"
	gender = FEMALE
	gold_core_spawnable = NO_SPAWN

/mob/living/danimal/crab/evil
	name = "Evil Crab"
	real_name = "Evil Crab"
	desc = "Unnerving, isn't it? It has to be planning something nefarious..."
	icon_state = "evilcrab"
	icon_living = "evilcrab"
	icon_dead = "evilcrab_dead"
	response_help_continuous = "pokes"
	response_help_simple = "poke"
	response_disarm_continuous = "shoves"
	response_disarm_simple = "shove"
	gold_core_spawnable = HOSTILE_SPAWN

/mob/living/danimal/crab/kreb
	name = "Kreb"
	desc = "This is a real crab. The other crabs are simply gubbucks in disguise!"
	real_name = "Kreb"
	icon_state = "kreb"
	icon_living = "kreb"
	icon_dead = "kreb_dead"
	gold_core_spawnable = NO_SPAWN

/mob/living/danimal/crab/evil/kreb
	name = "Evil Kreb"
	real_name = "Evil Kreb"
	icon_state = "evilkreb"
	icon_living = "evilkreb"
	icon_dead = "evilkreb_dead"
	gold_core_spawnable = NO_SPAWN
