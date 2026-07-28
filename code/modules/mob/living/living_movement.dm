/mob/living/Moved(atom/OldLoc, Dir)
	. = ..()
	update_turf_movespeed(loc)
	update_pixel_shifting(TRUE)

/mob/living/setDir(newdir, ismousemovement)
	. = ..()
	if(ismousemovement)
		update_pixel_shifting()

/mob/living/proc/update_pixel_shifting(moved = FALSE)
	if(combat_flags & COMBAT_FLAG_ACTIVE_BLOCKING)
		animate(src, pixel_x = get_standard_pixel_x_offset(), pixel_y = get_standard_pixel_y_offset(), time = 2.5, flags = ANIMATION_END_NOW)
	else if(moved)
		if(is_shifted)
			is_shifted = FALSE
			pixel_x = get_standard_pixel_x_offset(lying)
			pixel_y = get_standard_pixel_y_offset(lying)
		if(is_tilted)
			transform = transform.Turn(-is_tilted)
			is_tilted = 0

/mob/living/proc/update_minecraft_movement(dir_moved)
	// walking? bypass and use walk speed
	if(m_intent == MOVE_INTENT_WALK || !ckey) // non-player mobs do a differnet thing
		remove_movespeed_modifier(/datum/movespeed_modifier/minecraft)
		return
	// check 2 reset tiles moved, based on tiiiime
	var/facing = dir_moved
	var/client/C = client
	var/last_move_dir = mc_last_move_dir
	var/current_move_dir
	var/its_okay = FALSE
	if(C)
		current_move_dir = C.last_move_direction
	else
		if(moving_diagonally)
			its_okay = TRUE // ugh. UGH
		else
			current_move_dir = get_dir(locate(last_x, last_y, last_z), get_turf(src))
	var/tiles_to_reach_full_speed = CONFIG_GET(number/tiles_to_reach_min_run_delay)
	var/ds = world.time - mc_last_move_time
	var/tiled_decayed = 0
	if(ds > mc_decay_one_tile)
		// how manyuu intervals of decay have passed?
		var/intervals = floor(ds / mc_decay_one_tile)
		tiled_decayed = intervals
		mc_distance_moved = max(mc_distance_moved - intervals, 0)
	// the & allows for diagonals!
	// no it doesnt
	// okay diagonal movement is actually two steps of cardinals, and... it gets complicated here
	if(!its_okay)
		if(current_move_dir == last_move_dir) // if we're moving in the same direction as last time, or a diagonal that includes the last direction, keep building up distance. otherwise reset.
			its_okay = TRUE
		if(!its_okay)
			switch(current_move_dir)
				if(NORTH)
					if(last_move_dir == NORTHEAST || last_move_dir == NORTHWEST)
						its_okay = TRUE
				if(SOUTH)
					if(last_move_dir == SOUTHEAST || last_move_dir == SOUTHWEST)
						its_okay = TRUE
				if(EAST)
					if(last_move_dir == NORTHEAST || last_move_dir == SOUTHEAST)
						its_okay = TRUE
				if(WEST)
					if(last_move_dir == NORTHWEST || last_move_dir == SOUTHWEST)
						its_okay = TRUE
				if(NORTHWEST)
					if(last_move_dir == NORTH || last_move_dir == WEST)
						its_okay = TRUE
				if(NORTHEAST)
					if(last_move_dir == NORTH || last_move_dir == EAST)
						its_okay = TRUE
				if(SOUTHWEST)
					if(last_move_dir == SOUTH || last_move_dir == WEST)
						its_okay = TRUE
				if(SOUTHEAST)
					if(last_move_dir == SOUTH || last_move_dir == EAST)
						its_okay = TRUE
	if(its_okay && C)
		its_okay = FALSE // its NOT okay!!!
		if(facing == current_move_dir || facing == last_move_dir) // if we're facing the direction we're moving, or a diagonal that includes the direction we're facing, keep building up speed. otherwise reset.
			its_okay = TRUE
		else
			switch(facing)
				if(NORTH)
					if(last_move_dir == NORTHWEST || last_move_dir == NORTHEAST)
						its_okay = TRUE
				if(SOUTH)
					if(last_move_dir == SOUTHWEST || last_move_dir == SOUTHEAST)
						its_okay = TRUE
				if(WEST)
					if(last_move_dir == NORTHWEST || last_move_dir == SOUTHWEST)
						its_okay = TRUE
				if(EAST)
					if(last_move_dir == NORTHEAST || last_move_dir == SOUTHEAST)
						its_okay = TRUE
				else
					its_okay = FALSE // if we're moving in a different direction than we're facing,
	if(its_okay)
		mc_distance_moved = min(mc_distance_moved + 1, tiles_to_reach_full_speed)
	else
		mc_distance_moved = 0
	mc_last_move_dir = current_move_dir
	mc_last_move_time = world.time
	// we go from min speed (highest delay) to config-set run speed (lowest delay)
	var/startup_slowdown = CONFIG_GET(number/movedelay/run_initial_slowdown)
	var/delay_to_use
	// interpolate!
	if(mc_distance_moved >= tiles_to_reach_full_speed)
		remove_movespeed_modifier(/datum/movespeed_modifier/minecraft)
	else
		delay_to_use = startup_slowdown - ((startup_slowdown - 1) * (mc_distance_moved / tiles_to_reach_full_speed))
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/minecraft, multiplicative_slowdown = delay_to_use)
	if(mc_debug)
		//convirt the direction numbers into binary!
		to_chat(src, "MC_DEBUG: Time since last move: [ds], distance moved in same direction: [mc_distance_moved], delay to use: [delay_to_use]")
		to_chat(src, "MC_DEBUG: Moved this dir: [dir2text(current_move_dir)], Last move dir: [dir2text(last_move_dir)], Tiles decayed: [tiled_decayed]")
		to_chat(src, "MC_DEBUG: Fenny is a dork")


/mob/living/CanAllowThrough(atom/movable/mover, border_dir)
	..()
	if((mover.pass_flags & PASSMOB))
		return TRUE
	if(istype(mover, /obj/item/projectile))
		var/obj/item/projectile/P = mover
		return !P.can_hit_target(src, P.permutated, src == P.original, TRUE)
	if(mover.throwing)
		return (!density || lying)
	if(buckled == mover)
		return TRUE
	if(!ismob(mover))
		if(mover.throwing?.thrower == src)
			return TRUE
	if(ismob(mover))
		if(mover in buckled_mobs)
			return TRUE
	var/mob/living/L = mover		//typecast first, check isliving and only check this if living using short circuit
	return (!density || (isliving(mover)? L.can_move_under_living(src) : !mover.density))

/mob/living/toggle_move_intent()
	. = ..()
	update_move_intent_slowdown()

/mob/living/update_config_movespeed()
	update_move_intent_slowdown()
	sprint_buffer_max = CONFIG_GET(number/movedelay/sprint_buffer_max)
	sprint_buffer_regen_ds = CONFIG_GET(number/movedelay/sprint_buffer_regen_per_ds)
	sprint_stamina_cost = CONFIG_GET(number/movedelay/sprint_stamina_cost)
	return ..()

/// whether or not we can slide under another living mob. defaults to if we're not dense. CanPass should check "overriding circumstances" like buckled mobs/having PASSMOB flag, etc.
/mob/living/proc/can_move_under_living(mob/living/other)
	return !density

/mob/living/proc/update_move_intent_slowdown()
	add_movespeed_modifier((m_intent == MOVE_INTENT_WALK)? /datum/movespeed_modifier/config_walk_run/walk : /datum/movespeed_modifier/config_walk_run/run)

/mob/living/proc/update_turf_movespeed(turf/open/T)
	if(isopenturf(T))
		if(T.hard_yardsable)
			if(HAS_TRAIT(src, TRAIT_HARD_YARDS))
				add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/turf_slowdown, multiplicative_slowdown = (T.slowdown * 0.8))
				return
			if(HAS_TRAIT(src, TRAIT_SOFT_YARDS))
				add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/turf_slowdown, multiplicative_slowdown = (T.slowdown * 0.9))
				return
		if(HAS_TRAIT(src, TRAIT_SLUG))
			add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/turf_slowdown, multiplicative_slowdown = (T.slowdown * 1.5))
			return
		if(HAS_TRAIT(src, TRAIT_SLOWAF))
			add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/turf_slowdown, multiplicative_slowdown = (T.slowdown * 2.5))
			return
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/turf_slowdown, multiplicative_slowdown = T.slowdown)
		return
	remove_movespeed_modifier(/datum/movespeed_modifier/turf_slowdown)

/mob/living/proc/update_special_speed(speed)//SPECIAL Integration
	add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/special_speed, multiplicative_slowdown = speed)

/mob/living/proc/update_pull_movespeed()
	if(pulling)
		var/should_slow = FALSE
		if(isliving(pulling))
			var/mob/living/L = pulling
			should_slow = (drag_slowdown && L.lying && !L.buckled && grab_state < GRAB_AGGRESSIVE) ? PULL_PRONE_SLOWDOWN : FALSE
			//var/slow_difference = L.total_multiplicative_slowdown() - total_multiplicative_slowdown()
			//if(slow_difference >= 3)
			//	add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/shared_slowdown, multiplicative_slowdown = slow_difference)
		else
			should_slow = pulling.drag_delay
		if(should_slow)
			add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/bulky_drag, multiplicative_slowdown = should_slow)
			return
	remove_movespeed_modifier(/datum/movespeed_modifier/bulky_drag)
	//remove_movespeed_modifier(/datum/movespeed_modifier/shared_slowdown)

/mob/living/Move(atom/newloc, direct, glide_size_override)
	if (buckled && buckled.loc != newloc) //not updating position
		if (!buckled.anchored)
			return buckled.Move(newloc, direct, glide_size)
		else
			return FALSE

	var/old_direction = dir
	var/turf/T = loc

	if(pulling)
		update_pull_movespeed()

	. = ..()

	update_minecraft_movement(old_direction)

	if(pulledby && moving_diagonally != FIRST_DIAG_STEP && get_dist(src, pulledby) > 1 && (pulledby != moving_from_pull))//separated from our puller and not in the middle of a diagonal move.
		pulledby.stop_pulling()
	else
		if(isliving(pulledby))
			var/mob/living/L = pulledby
			L.set_pull_offsets(src, pulledby.grab_state)

	if(active_storage && !(can_reach(active_storage.parent, STORAGE_VIEW_DEPTH)))
		active_storage.close(src)

	if(lying && !buckled && prob(getBruteLoss()*200/maxHealth))
		makeTrail(newloc, T, old_direction)

/mob/living/forceMove(atom/destination)
	if(!currently_z_moving)
		stop_pulling()
		if(buckled)
			buckled.unbuckle_mob(src, force = TRUE)
		if(has_buckled_mobs())
			unbuckle_all_mobs(force = TRUE)
	. = ..()
	if(. && client)
		reset_perspective()

/mob/living/update_z(new_z) // 1+ to register, null to unregister
	if(isnull(new_z) && audiovisual_redirect)
		return
	if (registered_z != new_z)
		if (registered_z)
			SSmobs.clients_by_zlevel[registered_z] -= src
		if (client || audiovisual_redirect)
			if (new_z)
				SSmobs.clients_by_zlevel[new_z] += src
				for (var/I in length(SSidlenpcpool.idle_mobs_by_zlevel[new_z]) to 1 step -1) //Backwards loop because we're removing (guarantees optimal rather than worst-case performance), it's fine to use .len here but doesn't compile on 511
					var/mob/living/danimal/SA = SSidlenpcpool.idle_mobs_by_zlevel[new_z][I]
					if (SA)
						SA.toggle_ai(AI_ON) // Guarantees responsiveness for when appearing right next to mobs
					else
						SSidlenpcpool.idle_mobs_by_zlevel[new_z] -= SA

			registered_z = new_z
		else
			registered_z = null

/mob/living/onTransitZ(old_z,new_z)
	..()
	update_z(new_z)

/mob/living/canface()
	if(!CHECK_MOBILITY(src, MOBILITY_MOVE))
		return FALSE
	return ..()


/**
 * We want to relay the zmovement to the buckled atom when possible
 * and only run what we can't have on buckled.zMove() or buckled.can_z_move() here.
 * This way we can avoid esoteric bugs, copypasta and inconsistencies.
 */
/mob/living/zMove(dir, turf/target, z_move_flags = ZMOVE_FLIGHT_FLAGS)
	if(buckled)
		if(buckled.currently_z_moving)
			return FALSE
		if(!(z_move_flags & ZMOVE_ALLOW_BUCKLED))
			buckled.unbuckle_mob(src, force = TRUE)
		else
			if(!target)
				target = canZMove(dir, get_turf(src), null, z_move_flags, src)
				if(!target)
					return FALSE
			return buckled.zMove(dir, target, z_move_flags) // Return value is a loc.
	return ..()

/mob/living/canZMove(direction, turf/start, turf/destination, z_move_flags = ZMOVE_FLIGHT_FLAGS, mob/living/rider)
	if(z_move_flags & ZMOVE_INCAPACITATED_CHECKS && incapacitated())
		if(z_move_flags & ZMOVE_FEEDBACK)
			to_chat(rider || src, span_warning("[rider ? src : "You"] can't do that right now!"))
		return FALSE
	if(!buckled || !(z_move_flags & ZMOVE_ALLOW_BUCKLED))
		if(!(z_move_flags & ZMOVE_FALL_CHECKS) && incorporeal_move && (!rider || rider.incorporeal_move))
			//An incorporeal mob will ignore obstacles unless it's a potential fall (it'd suck hard) or is carrying corporeal mobs.
			//Coupled with flying/floating, this allows the mob to move up and down freely.
			//By itself, it only allows the mob to move down.
			z_move_flags |= ZMOVE_IGNORE_OBSTACLES
		return ..()
	switch(SEND_SIGNAL(buckled, COMSIG_BUCKLED_CAN_Z_MOVE, direction, start, destination, z_move_flags, src))
		if(COMPONENT_RIDDEN_ALLOW_Z_MOVE) // Can be ridden.
			return buckled.canZMove(direction, start, destination, z_move_flags, src)
		if(COMPONENT_RIDDEN_STOP_Z_MOVE) // Is a ridable but can't be ridden right now. Feedback messages already done.
			return FALSE
		else
			if(!(z_move_flags & ZMOVE_CAN_FLY_CHECKS) && !buckled.anchored)
				return buckled.canZMove(direction, start, destination, z_move_flags, src)
			if(z_move_flags & ZMOVE_FEEDBACK)
				to_chat(src, span_warning("Unbuckle from [buckled] first."))
			return FALSE
