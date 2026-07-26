GLOBAL_LIST_EMPTY(gun_accepted_magazines)
GLOBAL_LIST_EMPTY(gun_accepted_casings)

/obj/item/gun/ballistic
	desc = "Now comes in flavors like GUN. Uses 10mm ammo, for some reason."
	name = "projectile gun"
	icon_state = "pistol"
	weapon_class = null
	var/spawnwithmagazine = TRUE
	var/mag_type = /obj/item/ammo_box/magazine/m10mm/adv //Removes the need for max_ammo and caliber 
	var/init_mag_type = null
	var/list/extra_mag_types = list()
	/// List of mags accepted by the gun
	/// defaults to a typecache of mag_type
	/// Dont set this, its handled by Init()
	var/list/allowed_mags = list()
	/// List of mags not accepted by the gun
	var/list/disallowed_mags = list()
	/// Loaded magazine
	var/obj/item/ammo_box/magazine/magazine
	var/casing_ejector = TRUE //whether the gun ejects the chambered casing
	var/magazine_wording = "magazine"
	var/cock_wording = "rack"
	var/en_bloc = 0
	/// Which direction do the casings fly out?
	var/ejector_side = GUN_EJECTOR_RIGHT
	var/insert_magazine_delay = 0.5 SECONDS
	var/remove_magazine_delay = 0.5 SECONDS
	var/revolver = FALSE // hack
	fire_sound = null //null tells the gun to draw from the casing instead of the gun for sound
	var/can_load_magazine_through_bolt = FALSE

	/// sound it plays when you manually put a casing into the chamber by using bullet on gun
	var/manual_chamber_sound =       'sound/weapons/biblically_accurate_guns/manual_insert_casing_into_chamber.ogg'
	/// sound for pulling bolt open manually
	var/manual_bolt_open_sound =     'sound/weapons/biblically_accurate_guns/manual_bolt_back_pistol.ogg'
	// sound for pushing bolt closed manually
	var/manual_bolt_close_sound =    'sound/weapons/biblically_accurate_guns/manual_bolt_forward_pistol.ogg'
	/// sound for when it ejects a loaded casing when you pull the bolt open manually
	var/casing_eject_sound =         'sound/weapons/biblically_accurate_guns/bolt_casing_eject.ogg'
	/// sound for when it ejects an empty casing when you pull the bolt open manually
	var/empty_casing_eject_sound =   'sound/weapons/biblically_accurate_guns/bolt_casing_eject_empty.ogg'
	/// sound for when the gun automatically cycles the bolt closed after firing
	var/auto_bolt_open_sound =       'sound/weapons/biblically_accurate_guns/auto_bolt_back.ogg'
	var/auto_bolt_close_sound =      'sound/weapons/biblically_accurate_guns/auto_bolt_forward.ogg'
	var/cock_hammer_sound =          'sound/weapons/biblically_accurate_guns/manual_hammer_back_normalgun.ogg'
	var/uncock_hammer_sound =        'sound/weapons/biblically_accurate_guns/manual_hammer_forward_normalgun.ogg'
	var/auto_cock_hammer_sound =     'sound/weapons/biblically_accurate_guns/auto_hammer_back.ogg'
	var/auto_uncock_hammer_sound =   'sound/weapons/biblically_accurate_guns/auto_hammer_forward.ogg'

	/// cutecool overlays to show what position the hammer and or bolt are in!
	var/mutable_appearance/hammer_overlay
	var/hammer_cocked_icon = 'icons/obj/guninfo.dmi'
	var/hammer_cocked_icon_state = "hammer_up"
	var/hammer_uncocked_icon = 'icons/obj/guninfo.dmi'
	var/hammer_uncocked_icon_state = "hammer_down"

	var/mutable_appearance/bolt_overlay
	var/bolt_closed_icon = 'icons/obj/guninfo.dmi'
	var/bolt_closed_icon_state = "bolt_closed"
	var/bolt_open_icon = 'icons/obj/guninfo.dmi'
	var/bolt_open_icon_state = "bolt_open"

/obj/item/gun/ballistic/Initialize()
	. = ..()
	give_magazine()
	handle_accepted_magazines()
	register_magazines()
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.bolt_shootable_state != GBOLT_OPEN)
		chamber_round()
	make_bolt_and_hammer_shootable()
	update_icon()

/obj/item/gun/ballistic/admin_fill_gun()
	if(!istype(magazine))
		return
	return SEND_SIGNAL(magazine, COMSIG_GUN_MAG_ADMIN_RELOAD) // get relayed, noob

/obj/item/gun/ballistic/proc/give_magazine()
	if(!spawnwithmagazine)
		return
	if (magazine)
		return
	if(init_mag_type)
		magazine = new init_mag_type(src)
	else
		magazine = new mag_type(src)
	if(magazine.fixed_mag)
		gun_tags |= GUN_INTERNAL_MAG

/obj/item/gun/ballistic/proc/handle_accepted_magazines()
	allowed_mags |= typesof(mag_type)
	if(extra_mag_types)
		if(islist(extra_mag_types) && LAZYLEN(extra_mag_types))
			allowed_mags |= extra_mag_types
		else if (ispath(extra_mag_types))
			allowed_mags |= typesof(extra_mag_types)
	if(LAZYLEN(disallowed_mags))
		allowed_mags -= disallowed_mags

/obj/item/gun/ballistic/proc/make_bolt_and_hammer_shootable()
	var/datum/firemode/my_mode = get_current_firemode()
	hammer_state = GHAMMER_COCKED
	bolt_state = my_mode.bolt_shootable_state

/obj/item/gun/ballistic/pickup(mob/living/user)
	. = ..()
	update_icon()

/obj/item/gun/ballistic/dropped(mob/user)
	. = ..()
	update_icon()

/obj/item/gun/ballistic/equipped(mob/living/user, slot)
	. = ..()
	update_icon()

/obj/item/gun/ballistic/update_icon_state()
	if(SEND_SIGNAL(src, COMSIG_ITEM_UPDATE_RESKIN))
		return // all done!
	icon_state = "[initial(icon_state)][sawn_off ? "-sawn" : ""]"

/obj/item/gun/ballistic/update_overlays()
	. = ..()
	if(!istype(loc, /mob))
		return
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode)
		if(!my_mode.hammer_ignore)
			var/mutable_appearance/hoverlay
			if(hammer_state == GHAMMER_COCKED)
				if(hammer_cocked_icon && hammer_cocked_icon_state)
					hoverlay = mutable_appearance(hammer_cocked_icon, hammer_cocked_icon_state)
			else if(hammer_state == GHAMMER_UNCOCKED)
				if(hammer_uncocked_icon && hammer_uncocked_icon_state)
					hoverlay = mutable_appearance(hammer_uncocked_icon, hammer_uncocked_icon_state)
			if(hoverlay)
				hoverlay.appearance_flags = RESET_COLOR|RESET_TRANSFORM
				. += hoverlay
		// bolt ignore doesnt really apply, cus you can still open and close the bolt
		if(!revolver) // revolvers dont really have bolts, do they?
			var/mutable_appearance/boltoverlay
			if(bolt_state == GBOLT_OPEN)
				if(my_mode.bolt_shootable_state == GBOLT_OPEN)
					if(bolt_closed_icon && bolt_closed_icon_state)
						boltoverlay = mutable_appearance(bolt_closed_icon, bolt_closed_icon_state)
				else
					if(bolt_open_icon && bolt_open_icon_state)
						boltoverlay = mutable_appearance(bolt_open_icon, bolt_open_icon_state)
			else if(bolt_state == GBOLT_CLOSED)
				if(my_mode.bolt_shootable_state == GBOLT_OPEN)
					if(bolt_open_icon && bolt_open_icon_state)
						boltoverlay = mutable_appearance(bolt_open_icon, bolt_open_icon_state)
				else
					if(bolt_closed_icon && bolt_closed_icon_state)
						boltoverlay = mutable_appearance(bolt_closed_icon, bolt_closed_icon_state)
			if(boltoverlay)
				boltoverlay.appearance_flags = RESET_COLOR|RESET_TRANSFORM
				. += boltoverlay

/obj/item/gun/ballistic/proc/register_magazines()
	if(LAZYACCESS(GLOB.gun_accepted_magazines, "[type]"))
		return
	GLOB.gun_accepted_magazines["[type]"] = ""
	if(magazine && magazine.fixed_mag)
		GLOB.gun_accepted_magazines["[type]"] = "This weapon has a fixed magazine that accepts [english_list(magazine.caliber)]."
		return
	var/list/names_of_mags = list()
	for(var/mag in allowed_mags)
		if(!ispath(mag))
			continue
		var/atom/movable/marge = mag
		names_of_mags += initial(marge.name)
	GLOB.gun_accepted_magazines["[type]"] = "This weapon accepts: [english_list(names_of_mags)]."

/// Ejects whatever's chambered, and attempts to load a new one from the magazine
/// chamber_round wont load another one if something's still in the chamber
/// this is how bolt-action guns require pumping
/obj/item/gun/ballistic/process_chamber(mob/living/user, soft_eject = FALSE)
	eject_chambered(user, FALSE)
	chamber_round()

/obj/item/gun/ballistic/chamber_round(obj/item/ammo_casing/load_this)
	if(chambered)
		return
	var/obj/item/ammo_casing/to_chamber = load_this
	if(!to_chamber)
		to_chamber = get_next_chamberable_round(TRUE)
	if(to_chamber)
		to_chamber.forceMove(src)
		chambered = to_chamber
	update_icon()

/obj/item/gun/ballistic/proc/get_next_chamberable_round(take_it)
	if(istype(magazine))
		return magazine.get_round(!take_it)
	return null

/obj/item/gun/ballistic/can_shoot()
	var/obj/item/ammo_casing/AC = get_chambered()
	if(!!AC?.BB)
		return TRUE
	. = ..()

/obj/item/gun/ballistic/attack_self(mob/living/user)
	operate_bolt_manually(user)
	update_icon()
	return

/obj/item/gun/ballistic/MiddleClick(mob/living/user)
	if(!operate_hammer_manually(user))
		return
	update_icon()
	return COMSIG_MOB_CANCEL_CLICKON

/obj/item/gun/ballistic/AltClick(mob/living/user)
	if(!magazine)
		return
	if(magazine.fixed_mag)
		return
	eject_magazine(user, !en_bloc, TRUE)
	update_icon()

/obj/item/gun/ballistic/attackby(obj/item/A, mob/user, params)
	..()
	if(revolver) // it uh, does things differently
		return
	if(istype(A, /obj/item/ammo_casing))
		return use_casing_on_gun(A, user)
	if(istype(A, /obj/item/ammo_box))
		return use_ammobox_on_gun(A, user)

/obj/item/gun/ballistic/proc/use_ammobox_on_gun(obj/item/ammo_box/A, mob/user)
	if(!istype(A, /obj/item/ammo_box))
		return FALSE
	if(load_internal_magazine(A, user))
		return TRUE
	if(load_external_magazine(A, user))
		return TRUE
	return FALSE

/obj/item/gun/ballistic/proc/use_casing_on_gun(obj/item/ammo_casing/A, mob/user)
	// first try stuffing it into the chamber
	if(try_load_chamber_with_casing(A, user))
		return TRUE
	// if not, can we stuff it into the mazagine?
	if(!can_insert_casings_into_gun(user))
		return FALSE
	// okay stuff it in
	if(magazine.load_from_casing(
		A,
		user,
		dosound = TRUE,
		dotext = TRUE,
		bypass_doafter = FALSE,
		))
		chamber_round()
	update_icon()
	return TRUE

/obj/item/gun/ballistic/proc/try_load_chamber_with_casing(obj/item/ammo_casing/A, mob/user)
	if(!can_insert_casing_into_chamber(user, A))
		return FALSE
	var/obj/item/ammo_casing/cbrd = get_chambered()
	if(cbrd)
		if(cbrd.BB)
			return FALSE // somethings already in there..... maybe load the mag!
		eject_chambered(user, FALSE)
		if(get_chambered()) // its still in there!
			to_chat(user, span_alert("There's still something in the chamber of \the [src]!"))
			return FALSE
	chamber_round(A)
	if(chambered)
		playsound(src, manual_chamber_sound, 70, 1)
	// addtimer(CALLBACK(usr, GLOBAL_PROC_REF(playsound), src, 'sound/weapons/gun_chamber_round.ogg', 100, 1), 3)
	update_icon()
	if(!user)
		return TRUE
	to_chat(user, span_notice("You load \the [A] into the chamber of \the [src]."))
	return TRUE

/obj/item/gun/ballistic/proc/load_internal_magazine(obj/item/ammo_box/A, mob/user)
	if(!istype(magazine))
		return FALSE
	if(!magazine.fixed_mag)
		return FALSE
	if(!can_insert_casings_into_gun(user, TRUE))
		return FALSE
	if(magazine.load_from_box(A, user, FALSE))
		chamber_round()
	update_icon()
	return TRUE

/// TG always said to make your procs and vars check for the *truth* of something, instead of a non-null meaning *no its not good*
/obj/item/gun/ballistic/proc/can_insert_casings_into_gun(mob/user, loudly = FALSE)
	if(!user)
		return TRUE
	if(!istype(magazine))
		return FALSE
	if(!magazine.fixed_mag)
		if(!can_load_magazine_through_bolt)
			return FALSE
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.bolt_ignore)
		return TRUE // load it anyway
	if(isnull(my_mode.bolt_reloadable_state))
		return TRUE // like how you can stuff shells into a shootgun
	if(bolt_state != my_mode.bolt_reloadable_state)
		if(my_mode.bolt_reloadable_state == GBOLT_CLOSED)
			if(loudly)
				to_chat(user, span_warning("The bolt of \the [src] is closed, you need to open it to load ammo!"))
		else
			if(loudly)
				to_chat(user, span_warning("The bolt of \the [src] is open, you need to close it to load ammo!"))
		return FALSE
	return TRUE

/// TG always said to make your procs and vars check for the *truth* of something, instead of a non-null meaning *no its not good*
/obj/item/gun/ballistic/proc/can_insert_casing_into_chamber(mob/user, obj/item/ammo_casing/A, loudly = FALSE)
	if(!istype(A))
		return FALSE
	if(!casing_probably_fits_in_chamber(A))
		return FALSE
	if(!user)
		return TRUE
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.bolt_ignore)
		return TRUE // load it anyway
	if(isnull(my_mode.bolt_manually_chamberable_state))
		return TRUE // like how you can stuff shells into a shootgun
	if(bolt_state != my_mode.bolt_manually_chamberable_state)
		if(my_mode.bolt_manually_chamberable_state == GBOLT_CLOSED)
			if(loudly)
				to_chat(user, span_warning("The bolt of \the [src] is closed, you need to open it to load ammo!"))
		else
			if(loudly)
				to_chat(user, span_warning("The bolt of \the [src] is open, you need to close it to load ammo!"))
		return FALSE
	return TRUE

////////////////////////////////////////////////////
/// BOLTIE AND HAMMER STUFF
////////////////////////////////////////////////////

/obj/item/gun/ballistic/check_bolt_is_in_shootable_position(mob/living/user, tell_them)
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.bolt_ignore)
		return TRUE
	var/shootable_state = my_mode.bolt_shootable_state
	if(bolt_state == shootable_state)
		return TRUE
	// not working, let them know why
	if(tell_them && user)
		if(shootable_state == GBOLT_CLOSED)
			to_chat(user, span_danger("The bolt of \the [src] isn't closed! Close it to shoot!!"))
		else if(shootable_state == GBOLT_OPEN)
			to_chat(user, span_danger("The bolt of \the [src] isn't open! Open it to shoot!!"))
		else
			to_chat(user, span_danger("The bolt of \the [src] is broken! It cant shoot"))
	return FALSE

/obj/item/gun/ballistic/check_hammer_is_in_shootable_position(mob/living/user, tell_them)
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.hammer_ignore)
		return TRUE
	// shootable position is always cocked
	if(hammer_state == GHAMMER_COCKED)
		return TRUE
	// not working, let them knof
	if(tell_them && user)
		to_chat(user, span_danger("The hammer of \the [src] isn't cocked! Cock it to shoot!!"))
	return FALSE



/// When the gun shoots, this happens automatically with the hammer
/// typically just drops the hammer (striker, etc) after triggerpull
/// FALSE means it couldnt do the thing
/obj/item/gun/ballistic/operate_hammer_on_trigger(mob/living/user)
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.hammer_ignore)
		hammer_state = GHAMMER_COCKED
		return TRUE
	if(hammer_state != GHAMMER_COCKED)
		return FALSE
	return set_hammer_state(user, GHAMMER_UNCOCKED, FALSE, FALSE)

/obj/item/gun/ballistic/operate_hammer_post_fire(mob/living/user)
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.hammer_ignore)
		hammer_state = GHAMMER_COCKED
		return TRUE
	if(my_mode.hammer_recock_on_fire)
		set_hammer_state(user, GHAMMER_COCKED, FALSE, FALSE)
	return TRUE

/obj/item/gun/ballistic/operate_hammer_manually(mob/living/user)
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.hammer_ignore)
		hammer_state = GHAMMER_COCKED
		return TRUE
	if(!my_mode.hammer_manually_operatable)
		return FALSE // probably going to be handled by the bolt or something
	return toggle_hammer(user, TRUE, TRUE)

/obj/item/gun/ballistic/toggle_hammer(mob/living/user, manually, loudly)
	if(hammer_state == GHAMMER_UNCOCKED)
		return set_hammer_state(user, GHAMMER_COCKED, manually, loudly)
	else
		return set_hammer_state(user, GHAMMER_UNCOCKED, manually, loudly)

/obj/item/gun/ballistic/set_hammer_state(mob/living/user, newstate, manually, loudly)
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.hammer_ignore)
		hammer_state = GHAMMER_COCKED
		return
	switch(newstate)
		if(GHAMMER_COCKED)
			. = hammer_cock(user, manually, loudly)
		if(GHAMMER_UNCOCKED)
			. = hammer_drop(user, manually, loudly)
	update_icon()

////
/obj/item/gun/ballistic/hammer_cock(mob/living/user, manually, loudly)
	if(hammer_state == GHAMMER_COCKED)
		return
	hammer_state = GHAMMER_COCKED
	hammer_cock_effects(user, manually, loudly)
	return TRUE

/obj/item/gun/ballistic/hammer_drop(mob/living/user, manually, loudly)
	if(hammer_state == GHAMMER_UNCOCKED)
		return
	hammer_state = GHAMMER_UNCOCKED
	hammer_drop_effects(user, manually, loudly)
	return TRUE

////
/obj/item/gun/ballistic/hammer_cock_effects(mob/living/user, manually, loudly)
	if(loudly)
		if(manually && cock_hammer_sound)
			playsound(src, cock_hammer_sound, 50, FALSE)
		else if (!manually && auto_cock_hammer_sound)
			playsound(src, auto_cock_hammer_sound, 50, FALSE)
	update_icon()
	update_firemode()
	do_squish(0.75,0.75,0.3 SECONDS)

/obj/item/gun/ballistic/hammer_drop_effects(mob/living/user, manually, loudly)
	if(loudly)
		if(manually && uncock_hammer_sound)
			playsound(src, uncock_hammer_sound, 50, FALSE)
		else if (!manually && auto_uncock_hammer_sound)
			playsound(src, auto_uncock_hammer_sound, 50, FALSE)
	update_icon()
	update_firemode()
	do_squish(0.75,0.75,0.3 SECONDS)

//////////////////////////////////////
/// BOLT STUFF

/// for when to do bolt things when you pull the trigger
/// mainly for open bolts to quickly close n chamber a bullet before it shots
/obj/item/gun/ballistic/operate_bolt_on_trigger(mob/living/user)
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.bolt_shootable_state != GBOLT_OPEN)
		return
	if(bolt_state != GBOLT_OPEN)
		return
	bolt_close(user, FALSE, FALSE)
	return TRUE

/// When the gun shoots, it does this to make it run through its bolt stuff
/// In terms of timing, this is just after the bullet has been shot, now its time for the
/// bolt to do a thing or two, if it should
/obj/item/gun/ballistic/operate_bolt_on_shoot(mob/living/user)
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.bolt_ignore)
		bolt_simple_cycle(user)
		return
	if(!my_mode.bolt_cycles_on_shoot && !my_mode.bolt_cycles_to_shootable_state_on_shoot)
		return // prolly a bolt action
	// bolt gotta be in a shootable position to do all this stuff
	if(my_mode.bolt_cycles_to_shootable_state_on_shoot)
		if(my_mode.bolt_shootable_state == GBOLT_CLOSED)
			if(bolt_state == GBOLT_OPEN)
				bolt_close(user, FALSE, FALSE)
			else if(bolt_state == GBOLT_CLOSED)
				bolt_open(user, FALSE, FALSE)
				bolt_close(user, FALSE, FALSE)
		else if (my_mode.bolt_shootable_state == GBOLT_OPEN)
			if(bolt_state == GBOLT_CLOSED)
				bolt_open(user, FALSE, FALSE)
	else if(my_mode.bolt_cycles_on_shoot)
		if(my_mode.bolt_shootable_state == GBOLT_CLOSED)
			bolt_open(user, FALSE, FALSE)
		else
			bolt_close(user, FALSE, FALSE)

/obj/item/gun/ballistic/operate_bolt_manually(mob/living/user)
	if(!user_can_physically_operate_this(user))
		return
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.bolt_ignore)
		bolt_simple_cycle(user)
		return
	if(bolt_state == GBOLT_OPEN)
		bolt_close(user, TRUE, TRUE)
	else
		bolt_open(user, TRUE, TRUE)

/// For guns that dont really care about the bolt, simple guns for simple people
/obj/item/gun/ballistic/proc/bolt_simple_cycle(mob/living/user)
	if(revolver)
		return
	bolt_open(user, TRUE, TRUE)
	bolt_close(user, TRUE, TRUE)

//////
/obj/item/gun/ballistic/bolt_open(mob/living/user, manually, loudly)
	if(bolt_state == GBOLT_OPEN)
		return
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.bolt_opening_delay)
		if(!do_delay(user, my_mode.bolt_opening_delay))
			to_chat(user, span_alert("You were interrupted!"))
			return FALSE
	bolt_state = GBOLT_OPEN
	bolt_opened_effects(user, manually, loudly)
	return TRUE

/obj/item/gun/ballistic/bolt_close(mob/living/user, manually, loudly)
	if(bolt_state == GBOLT_CLOSED)
		return
	var/datum/firemode/my_mode = get_current_firemode()
	if(!bolt_can_close(user, manually, loudly))
		return
	if(my_mode.bolt_closing_delay)
		if(!do_delay(user, my_mode.bolt_closing_delay))
			to_chat(user, span_alert("You were interrupted!"))
			return FALSE
	bolt_state = GBOLT_CLOSED
	bolt_closed_effects(user, manually, loudly)
	return TRUE

// mainly for open bolt guns, to refuse to close the bolt if something is
// somehow chambered when it shouldnt be
// it checks if something is chambered, *and* there's another round that
// could be chambered from the mag
/obj/item/gun/ballistic/proc/bolt_can_close(mob/living/user, manually, loudly)
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.bolt_ignore)
		return TRUE
	if(my_mode.bolt_shootable_state != GBOLT_OPEN)
		return TRUE // open bolts are special
	var/obj/item/ammo_casing/AC = get_chambered()
	if(!AC)
		return TRUE
	var/obj/item/ammo_casing/nextup = get_next_chamberable_round()
	if(!nextup)
		return TRUE
	if(user)
		to_chat(user, span_alert("[src] can't close it's bolt! There's still a round in the chamber, and another one ready to go in the magazine!"))
		to_chat(user, span_notice("Remove the magazine, then rack the bolt to eject the chambered round. Then you can put the magazine back in and close the bolt!"))
	return FALSE

/obj/item/gun/ballistic/can_still_shoot_after_operating(mob/living/user)
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.bolt_ignore)
		return TRUE
	return bolt_state == GBOLT_CLOSED

///////
/obj/item/gun/ballistic/bolt_opened_effects(mob/living/user, manually, loudly)
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.bolt_ignore)
		eject_chambered(user, loudly) // ten lines
		return
	if(manually)
		playsound(src, manual_bolt_open_sound, 70, FALSE)
	else
		playsound(src, auto_bolt_open_sound, 70, FALSE)
	if(my_mode.bolt_cocks_hammer_on_this_state == GBOLT_OPEN)
		set_hammer_state(user, GHAMMER_COCKED, manually, loudly)
	if(my_mode.bolt_ejects_on_open)
		eject_chambered(user, loudly) // ten lines
	update_icon()
	update_firemode()
	do_squish(0.75,0.75,0.3 SECONDS)

/obj/item/gun/ballistic/bolt_closed_effects(mob/living/user, manually, loudly)
	var/datum/firemode/my_mode = get_current_firemode()
	if(my_mode.bolt_ignore)
		chamber_round()
		return
	if(manually)
		playsound(src, manual_bolt_close_sound, 70, FALSE)
	else
		playsound(src, auto_bolt_close_sound, 70, FALSE)
	if(my_mode.bolt_cocks_hammer_on_this_state == GBOLT_CLOSED)
		set_hammer_state(user, GHAMMER_COCKED, manually, loudly)
	if(my_mode.bolt_chambers_on_close)
		chamber_round()
	update_icon()
	update_firemode()
	do_squish(0.75,0.75,0.3 SECONDS)

///////
// gets the delay for you stuffing that ammobox into this gun
/obj/item/gun/ballistic/proc/load_into_gun_delay(mob/user, obj/item/ammo_box/A)
	if(insert_magazine_delay <= 0)
		return TRUE
	if(doing_something(user))
		to_chat(user, span_warning("You're already doing something!"))
		return FALSE
	var/insert_delay = insert_magazine_delay * A.magazine_load_delay_mult
	return do_delay(user, insert_delay, src)

// gets the delay for you removing the magazine from this gun
/obj/item/gun/ballistic/proc/remove_magazine_delay(mob/user)
	if(!istype(magazine))
		return FALSE
	if(remove_magazine_delay <= 0)
		return TRUE
	var/insert_delay = remove_magazine_delay * magazine.magazine_load_delay_mult
	return do_delay(user, insert_delay, src)

/obj/item/gun/ballistic/proc/load_external_magazine(obj/item/ammo_box/A, mob/user)
	if(!is_magazine_allowed(A, user)) // But only if the new mag would fit
		return FALSE
	var/obj/item/ammo_box/magazine/new_mag = A
	if(HAS_TRAIT(new_mag, TRAIT_NODROP))
		to_chat(user, span_warning("You cannot seem to get \the [new_mag] out of your hands!"))
		return FALSE
	if(!check_loading(user, TRUE))
		return FALSE
	// eject and remember the old mag, if any (and toss on the ground)
	var/obj/item/ammo_box/oldmag = eject_magazine(user, FALSE, TRUE) //stop ejecting perfectly good shells!
	if(!load_into_gun_delay(user, A))
		to_chat(user, span_alert("You were interrupted!"))
		return FALSE
	// put the new mag in there
	if(!user.transferItemToLoc(new_mag, src))
		to_chat(user, span_warning("You cannot seem to get \the [new_mag] to go in there!"))
		return FALSE
	magazine = new_mag
	if(oldmag)
		if(user.put_in_hands(oldmag) && get_dist(user, oldmag) <= 1)
			to_chat(user, span_notice("You load \a [new_mag] into \the [src], keeping hold of the old one."))
		else
			to_chat(user, span_notice("You load \a [new_mag] into \the [src]."))

	if(magazine.ammo_count())
		playsound(src, "gun_insert_full_magazine", 70, FALSE)
	else
		playsound(src, "gun_insert_empty_magazine", 70, FALSE)
	new_mag.update_icon()
	update_icon()
	do_squish(0.75,0.75,0.25 SECONDS)
	return TRUE

// goes through the magazines this gun accepts, and checks if this thing fits in that thing
// then caches the result in a list
// format: /path/to/gun = list(/path/to/thing_that_fits = "yes", /path/to/thing_that_also_fits = "yes", etc)
// also records if this *doesnt* fit, in which case its cached as "no", so we dont have to keep checking every time
/obj/item/gun/ballistic/proc/casing_probably_fits_in_chamber(obj/item/ammo_casing/A)
	if(!A)
		return FALSE
	if(!islist(GLOB.gun_accepted_casings[type]))
		GLOB.gun_accepted_casings[type] = list()
	var/list/whatitake = GLOB.gun_accepted_casings[type]
	if(whatitake[type])
		return whatitake[type] == "yes"
	// new thing to check! first lets see if we have a loaded magazine and mess with that
	if(istype(magazine))
		if(magazine.does_that_fit_in_this(A))
			whatitake[A.type] = "yes"
			return TRUE
		else
			whatitake[A.type] = "no"
			return FALSE
	// unloaded, more likely to be the case(ing)
	// go through the magazines this gun accepts and see if the round would fit in any of those
	// does a lot of initializations but, should only happen once per gun per ammo
	var/yes
	for(var/mag in allowed_mags - disallowed_mags)
		if(!ispath(mag))
			continue
		var/obj/item/ammo_box/magazine/magtest = new mag() // nullspace it
		// go through the ammo that starts in that mag, and just sorta record them
		for(var/obj/item/ammo_casing/bullet in magtest.stored_ammo)
			whatitake[bullet.type] = "yes"
		if(magtest.does_that_fit_in_this(A))
			whatitake[A.type] = "yes"
			yes = TRUE
		else
			whatitake[A.type] = "no"
		qdel(magtest)
		if(yes)
			return TRUE
	return FALSE

/obj/item/gun/ballistic/proc/is_magazine_allowed(obj/item/ammo_box/mag_to_check, mob/user)
	. = FALSE
	if(!istype(mag_to_check))
		if(user)
			to_chat(user, span_phobia("Whatever you tried to stuff into \the [src] wasn't a thing! This is a bug~"))
		return FALSE
	if(istype(magazine) && magazine.fixed_mag)
		if(user)
			to_chat(user, span_alert("\the [magazine] is permanently fixed to \the [src], your [mag_to_check] won't fit in there!"))
		return FALSE
	if(mag_to_check.type in allowed_mags)
		return TRUE
	if(user)
		to_chat(user, span_alert("You can't seem to fit \the [mag_to_check] into \the [src]."))

/obj/item/gun/ballistic/proc/eject_magazine(mob/living/user, put_it_in_their_hand, makesound, maketext)
	if(!istype(magazine))
		return FALSE
	if(magazine.fixed_mag)
		return FALSE
	if(!remove_magazine_delay(user))
		return FALSE
	magazine.forceMove(drop_location())
	if(put_it_in_their_hand)
		user.put_in_hands(magazine)
	else
		user.dropItemToGround(magazine)
	var/obj/item/ammo_box/oldmag = magazine
	if(makesound)
		if(en_bloc)
			playsound(src, "sound/f13weapons/garand_ping.ogg", 70, FALSE)
		else if(magazine.ammo_count())
			playsound(src, 'sound/weapons/gun_magazine_remove_full.ogg', 70, FALSE)
		else
			playsound(src, "gun_remove_empty_magazine", 70, FALSE)
	if(maketext)
		to_chat(user, span_notice("You eject \the [magazine] from \the [src]."))
	magazine.update_icon()
	magazine = null
	update_icon()
	do_squish(0.75,0.75,0.25 SECONDS)
	return oldmag

/// Pump if click with empty thing
/obj/item/gun/ballistic/shoot_with_empty_chamber(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	..()

/obj/item/gun/ballistic/eject_chambered(mob/living/user, sounds_and_words)
	var/obj/item/ammo_casing/AC = chambered //Find chambered round
	if(istype(AC)) //there's a chambered round
		AC.forceMove(drop_location()) //Eject casing onto ground.
		var/howfar = AC.BB ? 1 : rand(4, 6)
		AC.bounce_away(TRUE, toss_direction = get_ejector_direction(user), max_dist = howfar)
		chambered = null
		if(sounds_and_words)
			to_chat(user, span_notice("You eject \a [AC] from \the [src]'s chamber."))
	return AC

/obj/item/gun/ballistic/examine(mob/user)
	. = ..()
	var/datum/firemode/my_mode = get_current_firemode()
	var/hammer_ok = check_hammer_is_in_shootable_position()
	if(!my_mode.hammer_ignore)
		if(hammer_ok)
			. += "The hammer is currently [span_green("cocked")]."
		else
			. += "The hammer is currently [span_alert("uncocked")]."
	var/bst = ""
	if(bolt_state == GBOLT_OPEN)
		bst = span_notice("open")
	else if(bolt_state == GBOLT_CLOSED)
		bst = span_love("closed")
	else
		bst = "broken"
	var/ready = ""
	var/bolt_ok = check_bolt_is_in_shootable_position()
	if(!revolver)
		if(bolt_ok)
			ready = span_green("in shootable position")
		else
			ready = span_alert("not in shootable position")
		. += "The bolt is currently [bst], and is [ready]."

	if(istype(magazine) && magazine.fixed_mag && length(magazine.caliber))
		. += "It accepts [span_notice(english_list(magazine.caliber))]"
	. += "It has [span_notice("[get_ammo()]")] round\s remaining."
	if (chambered)
		. += "A [chambered.BB ? span_green("live") : span_alert("spent")] one is in the chamber."
	if(hammer_ok && bolt_ok && chambered && chambered.BB)
		. += "It is currently " + span_green("ready to fire") + "!"
	else
		. += "It is currently " + span_alert("not ready to fire") + "!"

/obj/item/gun/ballistic/proc/get_ammo(countchambered = 1)
	var/boolets = 0 //mature var names for mature people
	if (chambered && countchambered)
		boolets++
	if (magazine)
		boolets += magazine.ammo_count()
	return boolets

/obj/item/gun/ballistic/proc/get_max_ammo(countchambered = 1)
	var/boolets = 0 //mature var names for very mature people
	if (chambered && countchambered)
		boolets++
	if (magazine)
		boolets += magazine.max_ammo
	return boolets

/obj/item/gun/ballistic/proc/sawoff(mob/user)
	if(sawn_off)
		to_chat(user, span_warning("\The [src] is already shortened!"))
		return
	user.DelayNextAction(CLICK_CD_MELEE)
	user.visible_message("[user] begins to shorten \the [src].", span_notice("You begin to shorten \the [src]..."))

	//if there's any live ammo inside the gun, makes it go off
	if(blow_up(user))
		user.visible_message(span_danger("\The [src] goes off!"), span_danger("\The [src] goes off in your face!"))
		return

	if(do_after(user, 30, target = src))
		if(sawn_off)
			return
		user.visible_message("[user] shortens \the [src]!", span_notice("You shorten \the [src]."))
		name = "sawn-off [src.name]"
		desc = sawn_desc
		w_class = WEIGHT_CLASS_SMALL
		weapon_weight = GUN_TWO_HAND_ONLY // years of ERP made me realize wrists of steel isnt a good thing
		inhand_icon_state = "gun"
		slot_flags |= INV_SLOTBIT_BELT //but you can wear it on your belt (poorly concealed under a trenchcoat, ideally)
		recoil_tag = SSrecoil.modify_gun_recoil(recoil_tag, list(2, 2))
		cock_delay = GUN_COCK_SHOTGUN_FAST
		damage_multiplier *= GUN_LESS_DAMAGE_T2 // -15% damage
		sawn_off = TRUE
		gun_accuracy_zone_type = ZONE_WEIGHT_SHOTGUN
		update_icon()
		return 1
		
		
// /obj/item/gun/ballistic/get_dud_projectile()
// 	var/proj_type
// 	if(chambered)
// 		if(!chambered.BB)
// 			return null
// 		proj_type = chambered.BB.type
// 	else if(magazine && get_ammo(0,0))
// 		var/obj/item/ammo_casing/A = magazine.stored_ammo[1]
// 		if(!A)
// 			return null
// 		if(!A.BB)
// 			return null
// 		proj_type = A.BB.type
// 	if(!proj_type)
// 		return null
// 	return new proj_type

/obj/item/gun/ballistic/ui_data(mob/user)
	var/list/data = ..()
	data["has_magazine"] = !!magazine
	data["accepted_magazines"] = LAZYACCESS(GLOB.gun_accepted_magazines, "[type]")
	if(istype(magazine))
		data["magazine_name"] = magazine.name
		data["magazine_calibers"] = english_list(magazine.caliber)
	data["shots_remaining"] = get_ammo()
	data["shots_max"] = get_max_ammo()

	return data

// Sawing guns related proc
/obj/item/gun/ballistic/proc/blow_up(mob/user)
	. = 0
	for(var/obj/item/ammo_casing/AC in magazine.stored_ammo)
		if(AC.BB)
			process_fire(user, user, FALSE)
			. = 1

/obj/item/gun/ballistic/generate_guntags()
	..()
	gun_tags |= GUN_PROJECTILE

/obj/item/gun/ballistic/refresh_upgrades()
	if(istype(magazine,/obj/item/ammo_box/magazine/internal))
		magazine?.max_ammo = initial(magazine?.max_ammo)
	..()

/obj/item/gun/ballistic/proc/get_ejector_direction(mob/user)
	if(user?.dir)
		switch(ejector_side)
			if(GUN_EJECTOR_RIGHT)
				return turn(user.dir, -90)
			if(GUN_EJECTOR_LEFT)
				return turn(user.dir, 90)
			if(GUN_EJECTOR_ANY)
				return turn(user.dir, pick(0, -90, 90, 180))
	return angle2dir_cardinal(rand(0,360)) // something fucked up, just send a direction

// /obj/item/gun/ballistic/Reload(mob/user)
// 	if(!ishuman(user))
// 		return FALSE
// 	if(on_cooldown(user) || !user.has_direct_access_to(src, STORAGE_VIEW_DEPTH))
// 		to_chat(user, span_notice("You can't reload \the [src] right now!"))
// 		return FALSE
// 	//Shotguns, bolt action rifles, etc.
// 	if(magazine?.fixed_mag)
// 		return InternalReload(user)
// 	//External magazine weapons
// 	else
// 		return MagReload(user)

// /*
// * Reloads an internal magazine of a weapon with boxes of ammo in your inventory or loose rounds. Unsafe, call Reload() instead.
// */
// /obj/item/gun/ballistic/proc/InternalReload(mob/user)
// 	//typecast the user as a human
// 	var/mob/living/carbon/human/H = user

// 	//Wait a second or two so we can't spam reload too quickly. Also if this runtimes then the gun will never be reloadable again with this proc so rip
// 	busy_action = TRUE
// 	playsound(get_turf(H), "rustle", rand(50,100), 1, SOUND_DISTANCE(7))
// 	H.visible_message(span_notice("[H] starts reloading \the [src]..."), span_notice("You start looking for a magazine to reload \the [src] with..."), span_notice("You hear the clinking of metal..."))
// 	if(!do_after(H, reloading_time, TRUE, src, TRUE, allow_movement = TRUE, stay_close = TRUE, public_progbar = TRUE))
// 		busy_action = FALSE
// 		return FALSE

// 	var/isrevolver = FALSE
// 	if(istype(src, /obj/item/gun/ballistic/revolver) || istype(magazine, /obj/item/ammo_box/magazine/internal/cylinder))//Pull any loose shells out, first.
// 		var/obj/item/gun/ballistic/revolver/R = src
// 		isrevolver = TRUE
// 		R.eject_shells(H, TRUE)
// 	else if((chambered && !chambered?.BB) || (!chambered && LAZYLEN(magazine?.stored_ammo)))//Eject any empty shells from the chamber
// 		attack_self(H)

// 	var/list/validboxes = list()
// 	var/boxedrounds = 0 //If we don't have enough boxed rounds, look for loose rounds as well
// 	var/list/validcasings = list()
// 	var/list/yourstuff = H?.contents + H?.belt?.contents + H?.back?.contents + H?.wear_suit?.contents + H?.shoes?.contents + H?.head?.contents + H?.l_store?.contents + H?.r_store?.contents + H?.s_store?.contents + H?.wear_neck?.contents
// 	//find compatible boxes of ammo
// 	for(var/obj/item/ammo_box/B in yourstuff)
// 		var/rounds = LAZYLEN(B.stored_ammo)
// 		if(rounds > 0 && B.caliber?[1] == magazine.caliber?[1] && !isgun(B.loc))
// 			boxedrounds += rounds
// 			validboxes += B
// 			validboxes[B] = rounds
// 	//find loose rounds if there aren't enough boxed rounds to fill the magazine
// 	if(LAZYLEN(validboxes) == 0 || boxedrounds < (magazine.max_ammo - magazine.ammo_count()))
// 		for(var/obj/item/ammo_casing/AC in yourstuff)
// 			if(AC.BB && (AC.caliber in magazine?.caliber) && !isgun(AC.loc))//Not spent, correct caliber
// 				if(AC.loc in validboxes)//don't count these twice
// 					continue
// 				validcasings += AC

// 	if(LAZYLEN(validboxes) || LAZYLEN(validcasings))
// 		if(LAZYLEN(validboxes) && magazine.ammo_count() < magazine.max_ammo)
// 			sortTim(validboxes, /proc/cmp_numeric_asc, TRUE)//Sort them by least to most filled so we empty the least filled ones first.
// 			for(var/obj/item/ammo_box/B in validboxes)
// 				if(isnull(B) || QDELETED(B))
// 					continue
// 				//reload from this ammo box multiple times if our magazine doesn't get filled in one go or we need to chamber a round and then fill up.
// 				if(!magazine?.multiload)//internal magazines that don't load multiple rounds at once
// 					var/numroundstoload = clamp((magazine.max_ammo - magazine.ammo_count()), 1, LAZYLEN(B.stored_ammo))
// 					for(var/i = 1; i <= numroundstoload; i++)
// 						if(do_after(H, reloading_time, TRUE, src, TRUE, allow_movement = TRUE, stay_close = TRUE, public_progbar = TRUE) && H.has_direct_access_to(B, STORAGE_VIEW_DEPTH) && attackby(B, user))
// 							continue
// 						else
// 							break
// 				else// magazines that accept multiple rounds at once
// 					if(do_after(H, reloading_time, TRUE, src, TRUE, allow_movement = TRUE, stay_close = TRUE, public_progbar = TRUE) && H.has_direct_access_to(B, STORAGE_VIEW_DEPTH) && attackby(B, user))
// 						if(!isrevolver && ((chambered && !chambered?.BB) || !chambered))//spent round or an empty chamber
// 							attack_self(H)//rack the bolt
// 							//Insert another round to top us off since we just chambered a round
// 							if(LAZYLEN(B.stored_ammo) && do_after(H, reloading_time, TRUE, src, TRUE, allow_movement = TRUE, stay_close = TRUE, public_progbar = TRUE) && magazine.ammo_count() < magazine.max_ammo && LAZYLEN(B.stored_ammo))
// 								attackby(B, user)
// 						var/newammo = LAZYLEN(B.stored_ammo)
// 						if(newammo == 0)
// 							validboxes -= B
// 						else
// 							validboxes[B] = newammo //update this box's ammo count
// 							sortTim(validboxes, /proc/cmp_numeric_asc, TRUE)			
// 				if(LAZYLEN(magazine.stored_ammo) < magazine.max_ammo)
// 					continue
// 				else
// 					break
// 		if(LAZYLEN(validcasings) && magazine.ammo_count() < magazine.max_ammo)
// 			for(var/obj/item/ammo_casing/AC in validcasings)
// 				if(isnull(AC) || QDELETED(AC) || !AC.BB)
// 					continue
// 				if(do_after(H, reloading_time, TRUE, src, TRUE, allow_movement = TRUE, stay_close = TRUE, public_progbar = TRUE) && H.has_direct_access_to(AC, STORAGE_VIEW_DEPTH) && attackby(AC, user))
// 					validcasings -= AC
// 					if(!isrevolver && ((chambered && !chambered?.BB) || !chambered))//spent round or an empty chamber
// 						attack_self(H)//rack the bolt
// 				if(magazine.ammo_count() < magazine.max_ammo)
// 					continue
// 				else
// 					break
// 	else
// 		to_chat(H, span_alert("You couldn't find any ammunition that fits into \the [src]!"))

// 	busy_action = FALSE
// 	return TRUE

// /// Reloads a magazine into a gun that uses external magazines. Unsafe, call Reload() instead.
// /obj/item/gun/ballistic/proc/MagReload(mob/user)
// 	if(!mag_type)
// 		return FALSE
// 	//typecast the user as a human
// 	var/mob/living/carbon/human/H = user

// 	//Wait a second or two so we can't spam reload too quickly. Also if this runtimes then the gun will never be reloadable again with this proc so rip
// 	busy_action = TRUE
// 	playsound(get_turf(H), "rustle", rand(50,100), 1, SOUND_DISTANCE(7))
// 	H.visible_message(span_notice("[H] starts reloading \the [src]..."), span_notice("You start looking for some ammunition to reload \the [src] with..."), span_notice("You hear the clinking of metal..."))
// 	if(!do_after(H, reloading_time, TRUE, src, TRUE, allow_movement = TRUE, stay_close = TRUE, public_progbar = TRUE))
// 		busy_action = FALSE
// 		return FALSE

// 	//First, search for compatible magazines in some predictable locations. Let's not search every item on them to save compute time. Skips organs and other weird stuff by doing it this way.
// 	var/list/validmags = list()
// 	var/list/yourstuff = H?.contents + H?.belt?.contents + H?.back?.contents + H?.wear_suit?.contents + H?.shoes?.contents + H?.head?.contents + H?.l_store?.contents + H?.r_store?.contents + H?.s_store?.contents + H?.wear_neck?.contents
// 	for(var/obj/item/ammo_box/magazine/M in yourstuff)
// 		var/rounds = LAZYLEN(M.stored_ammo)
// 		if(rounds > 0 && is_magazine_allowed(M))//valid mags have ammo and are allowed to be inserted into your gun
// 			validmags[M] = rounds
// 	yourstuff = null

// 	//Then, try to insert the one with the most ammo in it.
// 	if(LAZYLEN(validmags))
// 		sortTim(validmags, /proc/cmp_numeric_dsc, TRUE)//Sort them by most filled to least filled.
// 		for(var/obj/item/ammo_box/magazine/M in validmags)
// 			var/obj/magloc = isobj(M.loc) ? M.loc : null
// 			if(isgun(magloc))// Don't swap magazines with two guns.
// 				continue
// 			var/obj/oldmag = isobj(magazine) ? magazine : null
// 			if(H.has_direct_access_to(M, STORAGE_VIEW_DEPTH) && attackby(M, user))//Actually reload the gun
// 				if(magloc && oldmag)
// 					if(!magloc.attackby(oldmag, user))// Try to put your old mag in the new one's place
// 						H.quick_equip(oldmag)// If that fails, quick equip it.
// 				break//If we loaded a new mag successfully, stop
// 	else
// 		to_chat(H, span_alert("You couldn't find any filled magazines that fit \the [src]!"))
// 		busy_action = FALSE
// 		return FALSE

// 	busy_action = FALSE
// 	return TRUE

/////////// DEBUG STUFF

/obj/item/storage/debug/debug_ballistic_clutch
	name = "Bag of Debug Ballistic Stuff"
	desc = "A cool bag of guns to test guns and gun stuff!!!"

/obj/item/storage/debug/debug_ballistic_clutch/PopulateContents()
	. = ..()
	new /obj/item/storage/debug_box/guns_ballistic_2(src)
	new /obj/item/storage/debug_box/ammo_ballistic_2(src)
	new /obj/item/storage/debug_box/tools(src)

/obj/item/storage/debug_box/guns_ballistic_2
	name = "Debug Guns 2"
	desc = "A box of debug guns for devs to test gun!"

/obj/item/storage/debug_box/guns_ballistic_2/PopulateContents()
	. = ..()
	var/list/spawned = list()
	spawned += new /obj/item/gun/ballistic/automatic/smg/american180(src)
	spawned += new /obj/item/gun/ballistic/automatic/assault_rifle(src)
	spawned += new /obj/item/gun/ballistic/automatic/shotgun/pancor(src)
	spawned += new /obj/item/gun/ballistic/rifle/repeater/brush(src)
	spawned += new /obj/item/gun/ballistic/rifle/hunting(src)
	spawned += new /obj/item/gun/ballistic/shotgun/hunting(src)
	spawned += new /obj/item/gun/ballistic/revolver/colt357(src)
	spawned += new /obj/item/gun/ballistic/revolver/detective(src)
	for(var/obj/item/thingy in spawned)
		SEND_SIGNAL(thingy, COMSIG_GUN_MAG_ADMIN_RELOAD)

/obj/item/storage/debug_box/ammo_ballistic_2
	name = "Debug Ammo"
	desc = "A box of debug ammo for devs to gun!"

/obj/item/storage/debug_box/ammo_ballistic_2/PopulateContents()
	. = ..()
	var/list/spawned = list()
	spawned += new /obj/item/ammo_box/magazine/m22smg(src)
	spawned += new /obj/item/ammo_box/magazine/m22smg(src)
	spawned += new /obj/item/ammo_box/magazine/m556/rifle/extended(src)
	spawned += new /obj/item/ammo_box/magazine/m556/rifle/extended(src)
	spawned += new /obj/item/ammo_box/magazine/d12g/buck(src)
	spawned += new /obj/item/ammo_box/magazine/d12g/buck(src)
	spawned += new /obj/item/ammo_box/magazine/d12g/buck(src)
	spawned += new /obj/item/ammo_box/magazine/d12g/buck(src)

	spawned += new /obj/item/ammo_box/c22(src)
	spawned += new /obj/item/ammo_box/c22(src)
	spawned += new /obj/item/ammo_box/c22(src)
	spawned += new /obj/item/ammo_box/c22(src)
	spawned += new /obj/item/ammo_box/a357(src)
	spawned += new /obj/item/ammo_box/a357(src)
	spawned += new /obj/item/ammo_box/a357(src)
	spawned += new /obj/item/ammo_box/a357(src)
	spawned += new /obj/item/ammo_box/tube/c4570(src)
	spawned += new /obj/item/ammo_box/tube/c4570(src)
	spawned += new /obj/item/ammo_box/c4570box(src)

	for(var/obj/item/thingy in spawned)
		SEND_SIGNAL(thingy, COMSIG_GUN_MAG_ADMIN_RELOAD)

/obj/item/gun/ballistic/rifle/debug_boltie
	name = "Debug Boltie"
	desc = "A gun for testing bolt actions!"
	icon = 'modular_coyote/icons/objects/rifles.dmi'
	icon_state = "308"
	inhand_icon_state = "308"
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/hunting
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(1, 1)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = TRUE
	scope_state = "scope_long"
	scope_x_offset = 4
	scope_y_offset = 12
	fire_sound = 'sound/f13weapons/hunting_rifle.ogg'
	init_firemodes = list(
		/datum/firemode/bolt_using/straight_pull
	)
	manual_bolt_open_sound =        'sound/weapons/biblically_accurate_guns/bolt_rifle_open_short.ogg'
	manual_bolt_close_sound =       'sound/weapons/biblically_accurate_guns/bolt_rifle_close_short.ogg'
	casing_eject_sound =       'sound/weapons/biblically_accurate_guns/bolt_casing_eject.ogg'
	empty_casing_eject_sound = 'sound/weapons/biblically_accurate_guns/bolt_casing_eject_empty.ogg'

/obj/item/gun/ballistic/rifle/debug_boltie/c_on_open
	name = "Debug Boltie cack on open"
	desc = "A gun for testing bolt actions! this oine has a delay on opening"
	init_firemodes = list(
		/datum/firemode/bolt_using/delay_on_open
	)
	manual_bolt_open_sound =        'sound/weapons/biblically_accurate_guns/bolt_rifle_open_long.ogg'
	manual_bolt_close_sound =       'sound/weapons/biblically_accurate_guns/bolt_rifle_close_short.ogg'

/obj/item/gun/ballistic/rifle/debug_boltie/c_on_close
	name = "Debug Boltie cack on close"
	desc = "A gun for testing bolt actions! this oine has a delay on closing"
	init_firemodes = list(
		/datum/firemode/bolt_using/delay_on_close
	)
	manual_bolt_open_sound =        'sound/weapons/biblically_accurate_guns/bolt_rifle_open_short.ogg'
	manual_bolt_close_sound =       'sound/weapons/biblically_accurate_guns/bolt_rifle_close_long.ogg'

/obj/item/gun/ballistic/automatic/smg/american180/debug_open_boltie
	name = "Debug American 180 open boltie"
	desc = "A gun for testing open bolt stuff actions!"
	init_firemodes = list(
		/datum/firemode/open_bolt/automatic
	)



