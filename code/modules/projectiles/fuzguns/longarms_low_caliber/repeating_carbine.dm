// Winchester 1873 is baseline
/obj/item/gun/ballistic/rifle/repeating_carbine
	name = "repeating carbine template"								// use a simple common name. do NOT go overly esoteric or extravagant
	desc = "should not be here, bugreport."							// use the format "A submachine gun chambered in caliber. Optional flavor text goes here."
// cosmetic vars
	icon_state = "mp5"												// the object's sprite name
	icon = 'modular_coyote/icons/objects/automatic.dmi'				// location of the sprite
	mob_overlay_icon = 'modular_coyote/icons/objects/back.dmi'		// location of the back sprite. Uses icon_state. set this to null if not applicable
	inhand_icon_state = "p38"										// the inhand sprite name
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'	// location of inhand sprites
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	fire_sound = null 												// null means the cartridge's sound is used.
	ejector_side = GUN_EJECTOR_RIGHT								// direction casings are ejected
// performance vars
	damage_multiplier = GUN_EXTRA_DAMAGE_0							// weapon damage modifier
	mag_type = /obj/item/ammo_box/magazine/uzim9mm					// family of magazines it can fit
	init_mag_type = /obj/item/ammo_box/magazine/uzim9mm				// specific mag it starts with 
	extra_mag_types = list()										// extra familes of magazines it can fit
	disallowed_mags = list()										// members of magazine family it cannot fit
	init_firemodes = list(											// fire modes and fire rate
		/datum/firemode/bolt_using/straight_pull
	)
	init_recoil = AUTOCARBINE_RECOIL(1, 1)							// recoil: first number modifies 1h recoil. second number modifies 2h recoil
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION					// determines chance of the gun hitting its intended limb
	added_spread = GUN_SPREAD_NONE									// adds extra inaccuracy
	force = GUN_MELEE_FORCE_PISTOL_HEAVY							// melee damage
	force_unwielded = 10											// must be same as force. spaghet code
	force_wielded = 25												// melee damage wielding in two hands
	backstab_multiplier = 1											// bonus for pistolwhipping from behind
	throwforce = 25													// damage when thrown
	throw_speed = 1													// speed of throw
	throw_range = 10												// range of throw
	block_parry_data = /datum/block_parry_data/bokken				// parrying properties
// handling vars
	w_class = WEIGHT_CLASS_NORMAL									// item size
	slot_flags = INV_SLOTBIT_BELT | INV_SLOTBIT_BACK				// INV_SLOTBIT_BELT | INV_SLOTBIT_BACK to fit in belt and/or back
	draw_time = GUN_DRAW_NORMAL										// time between drawing and readying the gun
	slowdown = GUN_SLOWDOWN_PISTOL_HEAVY							// move speed penalty when drawn
	weapon_weight = GUN_ONE_HAND_ONLY								// akimbo, one handed, or two handed
	restrict_safety = FALSE											// setting to true disables safety
	insert_magazine_delay = 0.5 SECONDS								// time to insert new mag
	remove_magazine_delay = 0.5 SECONDS								// time to remove mag
	can_load_magazine_through_bolt = TRUE							// Load with the bolt closed, like hatch loaded lever actions
// accessory vars
	gun_tags = list(GUN_FA_MODDABLE, GUN_SCOPE)						// special weapon attachment tags

	zoom_factor = 0													// integrated scope zoom. requires can_scope = false
	can_scope = FALSE												// can attach a scope
	scope_state = "scope"											// sprites are located in 'icons/fallout/objects/guns/attachments.dmi'
	scope_x_offset = 0												// varedit in test server to zero in
	scope_y_offset = 0

	silenced = FALSE												// integrated suppressor. requires can_suppress = false
	can_suppress = FALSE											// can attach a suppressor
	suppressor_state = null											// sprites are located in 'icons/fallout/objects/guns/attachments.dmi'
	suppressor_x_offset = 0											// varedit in test server to zero in
	suppressor_y_offset = 0

	can_flashlight = FALSE											// can attach a flashlight
	gunlight_state = "flight"										// sprites are located in 'icons/fallout/objects/guns/attachments.dmi'
	flight_x_offset = 0												// varedit in test server to zero in
	flight_y_offset = 0

	can_bayonet = FALSE												// can attach a bayonet
	bayonet_state = "bayonetstraight"								// sprites are located in 'icons/fallout/objects/guns/attachments.dmi'
	knife_x_offset = 0												// varedit in test server to zero in
	knife_y_offset = 0

/obj/item/gun/ballistic/automatic/repeating_carbine/m1873
	name = " worn Model 1873"
	desc = "A repeating carbine chambered in .357 mag."
/obj/item/gun/ballistic/automatic/repeating_carbine/m1873/q2
	name = "Model 1873"
	max_upgrades = 4
/obj/item/gun/ballistic/automatic/repeating_carbine/m1873/q3
	name = "unrusted Model 1873"
	max_upgrades = 5
