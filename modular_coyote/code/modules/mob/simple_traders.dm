// Helper to assign a value if the value exists
#define ASSIGN_IF_EXISTS(VARIABLE, VALUE) VARIABLE = VALUE ? VALUE : VARIABLE

// Behaviour states
#define NPC_IDLE	(1<<0)	// Stay still
#define NPC_ROAM	(1<<1)	// Walking around
#define NPC_RETURN	(1<<2)	// Return to reference marker

#define COMSIG_NPC_UPDATE "npc_update"
#define COMSIG_NPC_RETURN "npc_return"
#define COMSIG_NPC_RETURN_FINISHED "npc_return_finished"
#define COMSIG_NPC_WANDER "npc_wander"
#define COMSIG_NPC_SEEN_PERSON "npc_seen_person"
#define COMSIG_NPC_ALERT_SOUND "npc_alert_sound"

/obj/effect/spawner/trader_npc
	name = "trader spawner"
	icon = 'modular_coyote/icons/objects/misc.dmi'
	
	// Mob vars
	var/npc_name = "Grem Doe"
	var/npc_desc
	var/npc_icon_state
	var/npc_icon
	var/icon_living
	var/icon_dead
	
	// Component behaviour vars
	var/roam_area = FALSE // if true, will only wander in the area it's spawned in.
	var/roam_range = 5 // range from where it's reference tile is located, will only wander in those bounds
	var/npc_move_speed = 0.4 SECONDS
	var/wander_move_multiplier = 3 // 3x slower than walking back.
	var/idle_time = 2 MINUTES
	var/list/alert_tags = list("all")// Only listen to specific tags (used for a bell)

	var/list/locale = list(
		"welcome" = list("Welcome, Customer!", "Hi!", "What can I do for you?"),
		"busy" = list("Give me a second!", "One moment...", "Gimme a few!", "Sec!", "Hang on please!"),
		"back2work" = list("Right..", "Back to work..!", "Ugh, no more customers?", "No more?"),
		"purchase" = list("Pleasure doing business!", "Remember, no refunds!", "Wise choice!"),
		"idle_chatter" = list("I am unused!", "Can't think of how to apply this!"),
	)

	// some flufferoni
	var/busy_chance = 20
	var/wait_delay_min = 1 SECONDS
	var/wait_delay_max = 8 SECONDS

	// location refs, safe to modify in mapping if you want to change their starting point, otherwise, the place spawned is it's starting position
	var/start_pos_x
	var/start_pos_y
	
	// try to avoid changing this, might mess up in future.
	var/area_ref
	var/turf_ref


	var/mob_type = /mob/living/simple_animal/trader_npc

/obj/effect/spawner/trader_npc/Initialize()
	. = ..()

	if(isnull(start_pos_x) || isnull(start_pos_y))
		start_pos_x = loc.x
		start_pos_y = loc.y
		turf_ref = get_turf(loc)
	
	area_ref = get_area(get_turf(loc))
	if(!turf_ref)
		var/turf/T = locate(start_pos_x, start_pos_y, loc.z)

		if(isnull(T))
			WARNING("Cannot find turf located at [start_pos_x], [start_pos_y] for NPC: [npc_name], deleting them..") // check appropriate error warning, might be using wrong one
			return INITIALIZE_HINT_QDEL
		
		turf_ref = T
	
	var/mob/M = new mob_type(get_turf(loc))

	if(!M)
		WARNING("Failed to spawn NPC at [start_pos_x], [start_pos_y] for NPC: [npc_name], deleting them..") 
		return INITIALIZE_HINT_QDEL

	SetMobValues(M)
	
	var/datum/component/trader_npc/C = M.AddComponent(/datum/component/trader_npc, turf_ref, roam_area ? area_ref : null, roam_area)
	M.AddComponent(/datum/component/npc_ui/trader)

	SetComponentValues(C)

	return INITIALIZE_HINT_QDEL

/obj/effect/spawner/trader_npc/proc/SetMobValues(mob/M)
	// FUCK YOUR COMPILER TIMES I DONT GIVE A FUCK
	// It hurt my brain doing it without the macro
	// If only inline constexpr exists in BYOND :(

	ASSIGN_IF_EXISTS(M.name, npc_name)
	ASSIGN_IF_EXISTS(M.desc, npc_desc)
	ASSIGN_IF_EXISTS(M.icon, npc_icon)
	ASSIGN_IF_EXISTS(M.icon_state, npc_icon_state)
	var/mob/living/simple_animal/SA = M
	if(SA)
		ASSIGN_IF_EXISTS(SA.icon_living, icon_living)
		ASSIGN_IF_EXISTS(SA.icon_dead, icon_dead)

/obj/effect/spawner/trader_npc/proc/SetComponentValues(datum/component/trader_npc/C)
	C.roam_area = roam_area
	C.roam_range = roam_range
	C.npc_move_speed = npc_move_speed
	C.wander_move_multiplier = wander_move_multiplier
	C.idle_time = idle_time

	if(LAZYLEN(alert_tags))
		C.alert_tags = alert_tags

	if(LAZYLEN(locale))
		C.locale = locale


/mob/living/simple_animal/trader_npc
	name = "npc"
	desc = "placeholder!"
	icon_state = "axolotl"
	icon_living = "axolotl"
	icon_dead = "axolotl_dead"
	maxHealth = 10
	health = 10
	attack_verb_continuous = "gremibbles" //their teeth are just for gripping food, not used for self defense nor even chewing
	attack_verb_simple = "gremibble"
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 1)
	// response_help_continuous = "pets"
	// response_help_simple = "pet"
	// response_disarm_continuous = "gently pushes aside"
	// response_disarm_simple = "gently push aside"
	// response_harm_continuous = "splats"
	// response_harm_simple = "splat"
	// pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_size = MOB_SIZE_HUMAN
	//move_resist = MOVE_FORCE_VERY_STRONG
	can_be_z_moved = FALSE


/mob/living/simple_animal/trader_npc/Initialize()
	. = ..()
	
/mob/living/simple_animal/trader_npc/ComponentInitialize()
	. = ..()

/mob/living/simple_animal/trader_npc/handle_automated_action()
	SEND_SIGNAL(src, COMSIG_NPC_UPDATE)
	. = ..()

/mob/living/simple_animal/trader_npc/handle_automated_movement() // Who asked you to WALK? >:(
	return

/mob/living/simple_animal/trader_npc/handle_automated_speech(override) // Silence, vermin.
	return

// This is NOT clean
// I just wanted to get it done, reminding myself on BYOND and whatnot, it's been a few years!
// Made specifically for trading with NPCs, we can probs modularise this into components, but the lack of AI controllers makes me CRIII

/datum/component/trader_npc
	// configuration vars
	var/roam_area = TRUE // if true, will only wander in the area it's spawned in.
	var/roam_range = -1 // range from where it's reference tile is located, will only wander in those bounds
	var/npc_move_speed = 0.4 SECONDS
	var/wander_move_multiplier = 3 // 3x slower than walking back.
	var/idle_time = 2 MINUTES
	var/list/alert_tags = list("all")// Only listen to specific tags (used for a bell)

	var/list/locale = list(
		"welcome" = list("Welcome, Customer!", "Hi!", "What can I do for you?"),
		"busy" = list("Give me a second!", "One moment...", "Gimme a few!", "Sec!", "Hang on please!"),
		"back2work" = list("Right..", "Back to work..!", "Ugh, no more customers?", "No more?"),
		"purchase" = list("Pleasure doing business!", "Remember, no refunds!", "Wise choice!"),
		"idle_chatter" = list("I am unused!", "Can't think of how to apply this!"),
	)

	// some flufferoni
	var/busy_chance = 20
	var/wait_delay_min = 1 SECONDS
	var/wait_delay_max = 8 SECONDS
	
	// stuff you shouldn't configure..
	var/npc_status = NPC_IDLE
	var/seen_people = FALSE
	var/greeted = FALSE

	var/datum/move_loop/move/return_loop
	var/datum/move_loop/move/wander_loop

	var/turf_ref
	var/area_ref

	var/mob/living/parent_ref

/datum/component/trader_npc/Initialize(source_turf, allowed_areas, roam_in_areas = FALSE, wander_range = -1)
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	
	. = ..()

	parent_ref = parent

	turf_ref = source_turf
	area_ref = allowed_areas
	roam_area = roam_in_areas
	roam_range = wander_range

/datum/component/trader_npc/RegisterWithParent()
	. = ..()
	RegisterSignal(parent_ref, COMSIG_NPC_UPDATE, PROC_REF(process_ai))
	RegisterSignal(parent, COMSIG_NPC_RETURN, PROC_REF(return_to_position), turf_ref)
	RegisterSignal(parent, COMSIG_NPC_SEEN_PERSON, PROC_REF(notice_people))
	RegisterSignal(parent, COMSIG_NPC_ALERT_SOUND, PROC_REF(notice_people))


/datum/component/trader_npc/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent_ref, list(COMSIG_NPC_UPDATE,COMSIG_NPC_RETURN,COMSIG_NPC_SEEN_PERSON,COMSIG_NPC_ALERT_SOUND))

/datum/component/trader_npc/proc/process_ai()
	var/atoms = oview(5, parent_ref)
	if(LAZYLEN(atoms))
		for(var/mob/living/L in atoms)
			if(isplayer(L) && L.stat == CONSCIOUS )
				notice_people(L)
	
	// IDLE
	if(npc_status == NPC_IDLE)
		var/mob/living/L = face_closest_carbon(atoms)
		
		if(!greeted && seen_people)
			INVOKE_ASYNC(parent_ref,TYPE_PROC_REF(/mob/living, emote), "me", EMOTE_VISIBLE, "waves at [L].")
			addtimer(CALLBACK(parent_ref,TYPE_PROC_REF(/atom/movable, say), "[pick(locale["welcome"])]"), rand(0.5 SECONDS, 2 SECONDS)) // Hate this, but I wanted to add a short delay after the emote.
			greeted = TRUE

		if(!seen_people)
			npc_status = NPC_ROAM
			parent_ref.say("[pick(locale["back2work"])]")
	
	// ROAMING
	if(npc_status == NPC_ROAM)
		if(!wander_loop)
			wander_loop = SSmove_manager.move_rand(parent_ref, GLOB.cardinals, list(area_ref), npc_move_speed * wander_move_multiplier)

		if(seen_people)
			if(prob(busy_chance))
				parent_ref.say("[pick(locale["busy"])]")
				addtimer(CALLBACK(src,PROC_REF(return_to_position), turf_ref), rand(wait_delay_min, wait_delay_max))
			else
				return_to_position(turf_ref)
		

	if(!return_loop || QDELETED(return_loop))
		var/returnCheck = FALSE

		if(roam_range > 0)
			if(get_dist(turf_ref, parent) > roam_range)
				returnCheck = TRUE

		if(roam_area)
			if(get_area(parent_ref.loc) != area_ref)
				returnCheck = TRUE

		if(returnCheck)
			return_to_position(turf_ref)

/datum/component/trader_npc/proc/notice_people(mob/living/user, obj/alertSource, tag)
	if(tag && LAZYLEN(alert_tags))
		if(tag in alert_tags)
			seen_people = TRUE
			return
	else
		seen_people = TRUE

/datum/component/trader_npc/proc/reset_noticed_people()
	seen_people = FALSE
	greeted = FALSE

/datum/component/trader_npc/proc/face_closest_carbon(list/atoms)
	var/mob/living/closest_person = get_closest_atom(/mob/living, atoms, parent_ref)

	if(closest_person)
		if(closest_person.stat == CONSCIOUS)
			addtimer(CALLBACK(src,PROC_REF(reset_noticed_people)), idle_time, TIMER_UNIQUE|TIMER_OVERRIDE)
			if(!seen_people)
				notice_people()

		parent_ref.face_atom(closest_person) // I like to seperate this, making the AI acknowledge things being tossed at them which are unconscious
		return closest_person

// Return back to spot!
/datum/component/trader_npc/proc/return_to_position()
	if(wander_loop)
		qdel(wander_loop)
		wander_loop = null

	return_loop = SSmove_manager.jps_move(moving = parent_ref, chasing = turf_ref, delay = npc_move_speed, repath_delay = 10 SECONDS, timeout = 1 MINUTES, flags = MOVEMENT_LOOP_START_FAST)

	if(!return_loop)
		return

	RegisterSignal(return_loop, COMSIG_MOVELOOP_START,PROC_REF(return_onstart))
	RegisterSignal(return_loop, COMSIG_MOVELOOP_STOP,PROC_REF(return_onstop))
	RegisterSignal(return_loop, COMSIG_PARENT_QDELETING,PROC_REF(return_ondeath))

	if(return_loop.running)
		return_onstart(return_loop) // There's a good chance it'll autostart, gotta catch that
	
	npc_status = NPC_RETURN

/datum/component/trader_npc/proc/return_onstart()
	SIGNAL_HANDLER
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED,PROC_REF(return_handle_move))

/datum/component/trader_npc/proc/return_onstop()
	SIGNAL_HANDLER
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED))

/datum/component/trader_npc/proc/return_ondeath(datum/source)
	SIGNAL_HANDLER
	return_loop = null
	npc_status = NPC_IDLE
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED))


/datum/component/trader_npc/proc/return_handle_move(datum/source, old_loc)
	SIGNAL_HANDLER

	// This can happen, because signals once sent cannot be stopped
	if(QDELETED(src))
		return
	
	if(return_loop)
		if(get_turf(parent) == turf_ref)
			qdel(return_loop)
			npc_status = NPC_IDLE
			SEND_SIGNAL(parent, COMSIG_NPC_RETURN_FINISHED)

	// to do: maybe make idle chatter?

/obj/item/deskbell
	name = "Bell"
	desc = "A desk bell, you can alert NPCs with this!"
	icon = 'modular_coyote/icons/objects/misc.dmi'
	icon_state = "bell"
	var/bell_sound = 'sound/ambience/servicebell.ogg'
	var/assigned_tag = "all"
	var/sound_range = 7

	var/cooldown_time = 2 SECONDS
	COOLDOWN_DECLARE(bell_cd)

/obj/item/deskbell/Initialize()
	. = ..()
	interaction_flags_item &= ~INTERACT_ITEM_ATTACK_HAND_PICKUP
	AddElement(/datum/element/drag_pickup)
	
/obj/item/deskbell/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/item/deskbell/attack_hand(mob/user, list/modifiers)
	. = ..()
	ring(user)

/obj/item/deskbell/proc/ring(mob/user)
	if(!COOLDOWN_FINISHED(src,bell_cd))
		return

	for(var/mob/living/L in ohearers(sound_range, get_turf(loc)))
		SEND_SIGNAL(L, COMSIG_NPC_ALERT_SOUND, user, src, assigned_tag)
	
	COOLDOWN_START(src, bell_cd, cooldown_time)

	user.playsound_local(get_turf(loc), bell_sound, 50, TRUE)
	user.visible_message(span_notice("[user] presses the [src]"), span_notice("You press the [src]"))
	do_jiggle(8, 4)
// Todo: Allow a pen to label which NPC it's for non case sensitive.
// /obj/item/deskbell/attackby(obj/item/I, mob/user, params)



#undef ASSIGN_IF_EXISTS
