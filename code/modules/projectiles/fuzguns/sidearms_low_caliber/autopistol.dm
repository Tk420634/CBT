// browning hi-power is baseline
/obj/item/gun/ballistic/automatic/pistol/ap
	name = "autopistol template"									// use a simple common name. do NOT go overly esoteric or extravagant
	desc = "should not be here, bugreport."							// use the format "A submachine gun chambered in caliber. Optional flavor text goes here."
// cosmetic vars
	icon_state = "ninemil"											// the object's sprite name
	icon = 'icons/fallout/objects/guns/ballistic.dmi'				// location of the sprite
	mob_overlay_icon = null											// location of the back sprite. Uses icon_state. set this to null if not applicable
	inhand_icon_state = "gun"										// the inhand sprite name
	lefthand_file = 'icons/fallout/onmob/weapons/guns_lefthand.dmi'	// location of inhand sprites
	righthand_file = 'icons/fallout/onmob/weapons/guns_righthand.dmi'
	fire_sound = null 												// null means the cartridge's sound is used.
	ejector_side = GUN_EJECTOR_RIGHT								// direction casings are ejected
// performance vars
	damage_multiplier = GUN_EXTRA_DAMAGE_0							// weapon damage modifier
	mag_type = /obj/item/ammo_box/magazine/a9mm/fifteen				// family of magazines it can fit
	init_mag_type = /obj/item/ammo_box/magazine/a9mm/fifteen		// specific mag it starts with 
	extra_mag_types = list()										// extra familes of magazines it can fit
	disallowed_mags = list()										// members of magazine family it cannot fit
	init_firemodes = list(
		/datum/firemode/semi_auto/rpm600
	)
	init_recoil = HANDGUN_RECOIL(1, 1)								// recoil: first number modifies 1h recoil. second number modifies 2h recoil
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION					// determines chance of the gun hitting its intended limb
	added_spread = GUN_SPREAD_NONE									// adds extra inaccuracy
	force = GUN_MELEE_FORCE_PISTOL_LIGHT							// melee damage
	force_unwielded = GUN_MELEE_FORCE_PISTOL_LIGHT					// must be same as force. spaghet code
	force_wielded = GUN_MELEE_FORCE_PISTOL_HEAVY 					// melee damage wielding in two hands
	backstab_multiplier = 4											// bonus for pistolwhipping from behind
	throwforce = GUN_MELEE_FORCE_PISTOL_LIGHT													// damage when thrown
	throw_speed = 1													// speed of throw
	throw_range = 10												// range of throw
	block_parry_data = /datum/block_parry_data/bokken				// parrying properties
// handling vars
	w_class = WEAPON_CLASS_SMALL									// item size
	slot_flags = INV_SLOTBIT_BELT | INV_SLOTBIT_BACK				// INV_SLOTBIT_BELT | INV_SLOTBIT_BACK to fit in belt and/or back
	draw_time = GUN_DRAW_QUICK										// time between drawing and readying the gun
	slowdown = GUN_SLOWDOWN_PISTOL_LIGHT							// move speed penalty when drawn
	weapon_weight = GUN_ONE_HAND_AKIMBO								// akimbo, one handed, or two handed
	restrict_safety = FALSE											// setting to true disables safety
	auto_eject = 0													// auto-ejects empty magazine
	auto_eject_sound = null
	insert_magazine_delay = 1 SECONDS								// time to insert new mag
	remove_magazine_delay = 1 SECONDS								// time to remove mag
	can_load_magazine_through_bolt = FALSE
// accessory vars
	gun_tags = list(GUN_FA_MODDABLE)						// special weapon attachment tags

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

/obj/item/gun/ballistic/automatic/pistol/ap/hipower
	name = "worn Hi-Power"
	desc = "An autopistol chambered in 9x19mm. Affectionately called the BAP (Browning Automatic Pistol), this is one of the most widely used military pistols in history."
	can_suppress = TRUE
	suppressor_state = "pistol_suppressor"
	suppressor_x_offset = 30
	suppressor_y_offset = 19
/obj/item/gun/ballistic/automatic/pistol/ap/hipower/q2
	name = "Hi-Power"
	max_upgrades = 4
/obj/item/gun/ballistic/automatic/pistol/ap/hipower/q3
	name = "unrusted Hi-Power"
	max_upgrades = 5
