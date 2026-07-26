// .45acp is the standard, plus .357mag for the revolver


///////////////////////////////
////////// .45acp ammo //////////
///////////////////////////////

///////////////casing///////////////

/obj/item/ammo_casing/a45
	name = "handloaded .45ACP bullet casing"
	desc = "A low-grade .45ACP bullet casing."
	caliber = CALIBER_45ACP
	projectile_type = /obj/item/projectile/bullet/a45
	material_class = BULLET_IS_HEAVY_PISTOL
	custom_materials = list(
		/datum/material/iron = MATS_PISTOL_HEAVY_CASING + MATS_PISTOL_HEAVY_BULLET,
		/datum/material/blackpowder = MATS_PISTOL_HEAVY_POWDER)
	fire_power = CASING_POWER_HEAVY_PISTOL * CASING_POWER_MOD_HANDLOAD
	sound_properties = CSP_PISTOL_HEAVY

/obj/item/ammo_casing/a45/q2
	name = ".45ACP bullet casing"
	desc = "A .45ACP bullet casing."
	projectile_type = /obj/item/projectile/bullet/a45/q2
	custom_materials = list(
		/datum/material/iron = MATS_PISTOL_HEAVY_CASING + MATS_PISTOL_HEAVY_BULLET,
		/datum/material/blackpowder = MATS_PISTOL_HEAVY_POWDER)
	fire_power = CASING_POWER_HEAVY_PISTOL * CASING_POWER_MOD_SURPLUS

/obj/item/ammo_casing/a45/q3
	name = "match .45ACP bullet casing"
	desc = "A high-grade .45ACP bullet casing."
	projectile_type = /obj/item/projectile/bullet/a45/q3
	custom_materials = list(
		/datum/material/iron = MATS_PISTOL_HEAVY_CASING + MATS_PISTOL_HEAVY_BULLET,
		/datum/material/blackpowder = MATS_PISTOL_HEAVY_POWDER)
	fire_power = CASING_POWER_HEAVY_PISTOL * CASING_POWER_MOD_MATCH

///////////////bullet///////////////

/obj/item/projectile/bullet/a45
	name = ".45ACP bullet"
	damage = BULLET_DAMAGE_PISTOL_45ACP_HANDLOAD //36
	damage_list = list("30" = 30, "36" = 30, "40" = 30, "41" = 2, "42" = 2, "43" = 2, "44" = 2, "45" = 1, "50" = 0.5, "55" = 0.5)
	stamina = BULLET_STAMINA_PISTOL_45ACP
	spread = BULLET_SPREAD_HANDLOAD
	recoil = BULLET_RECOIL_PISTOL_45ACP

	wound_bonus = BULLET_WOUND_PISTOL_45ACP
	bare_wound_bonus = BULLET_WOUND_PISTOL_45ACP_NAKED_MULT
	wound_falloff_tile = BULLET_WOUND_FALLOFF_PISTOL_HEAVY

	pixels_per_second = BULLET_SPEED_PISTOL_45ACP
	damage_falloff = BULLET_FALLOFF_DEFAULT_PISTOL_HEAVY

/obj/item/projectile/bullet/a45/q2
	damage = BULLET_DAMAGE_PISTOL_45ACP_SURPLUS
	spread = BULLET_SPREAD_SURPLUS

/obj/item/projectile/bullet/a45/q3
	damage = BULLET_DAMAGE_PISTOL_45ACP_MATCH
	spread = BULLET_SPREAD_MATCH

///////////////ammo box///////////////

/obj/item/ammo_box/a45
	name = ".45ACP ammo box (handload)"
	icon = 'icons/fallout/objects/guns/ammo.dmi'
	icon_state = "45box"
	multiple_sprites = 2
	caliber = list(CALIBER_45ACP)
	ammo_type = /obj/item/ammo_casing/a45
	max_ammo = 50 // don't change this for new calibers
	w_class = WEIGHT_CLASS_SMALL
	custom_materials = list(/datum/material/iron = MATS_RIFLE_SMALL_BOX)
	randomize_ammo_count = FALSE

/obj/item/ammo_box/a45/q2
	name = ".45ACP ammo box (standard)"
	ammo_type = /obj/item/ammo_casing/a45/q2

/obj/item/ammo_box/a45/q3
	name = ".45ACP ammo box (match)"
	ammo_type = /obj/item/ammo_casing/a45/q3

///////////////ammo crate///////////////

/obj/item/ammo_box/a45/crate
	name = ".45ACP ammo crate (handload)"
	desc = "A wooden crate of ammo."
	icon = 'modular_coyote/icons/objects/c13ammo.dmi'
	icon_state = "wood_ammobox"
	w_class = WEIGHT_CLASS_HUGE // don't you dare make this any smaller!
	multiple_sprites = 4
	max_ammo = 120 // don't change this for new calibers
	load_behavior = AMMOB_CRATE

/obj/item/ammo_box/a45/crate/q2
	name = ".45ACP ammo crate (standard)"
	ammo_type = /obj/item/ammo_casing/a45/q2

/obj/item/ammo_box/a45/crate/q3
	name = ".45ACP ammo crate (match)"
	ammo_type = /obj/item/ammo_casing/a45/q3

///////////////ammo box recipe///////////////

/datum/design/ammolathe/a45
	name = ".45ACP ammo box (handload)"
	id = "a45"
	build_path = /obj/item/ammo_box/a45
	category = list("initial", "Basic Ammo")

/datum/design/ammolathe/a45_2
	name = ".45ACP ammo box (standard)"
	id = "a45_2"
	build_path = /obj/item/ammo_box/a45/q2
	category = list("initial", "Basic Ammo")

/datum/design/ammolathe/a45_3
	name = ".45ACP ammo box (match)"
	id = "a45_3"
	build_path = /obj/item/ammo_box/a45/q3
	category = list("initial", "Basic Ammo")

///////////////ammo crate recipe///////////////

/datum/design/ammolathe/a45crate
	name = ".45ACP ammo crate (surplus)"
	id = "a45crate"
	build_path = /obj/item/ammo_box/a45/crate
	category = list("initial", "Basic ammo")

/datum/design/ammolathe/a45crate2
	name = ".45ACP ammo crate (standard)"
	id = "a45crate2"
	build_path = /obj/item/ammo_box/a45/crate/q2
	category = list("initial", "Basic ammo")

/datum/design/ammolathe/a45crate3
	name = ".45ACP ammo crate (match)"
	id = "a45crate3"
	build_path = /obj/item/ammo_box/a45/crate/q3
	category = list("initial", "Basic ammo")




//////////////////////////////////
////////// .357mag ammo //////////
//////////////////////////////////

///////////////casing///////////////

/obj/item/ammo_casing/a357
	name = "handloaded .357mag bullet casing"
	desc = "A low-grade .357mag bullet casing."
	caliber = CALIBER_357
	projectile_type = /obj/item/projectile/bullet/a357
	material_class = BULLET_IS_LIGHT_PISTOL
	custom_materials = list(
		/datum/material/iron = MATS_PISTOL_HEAVY_CASING + MATS_PISTOL_HEAVY_BULLET,
		/datum/material/blackpowder = MATS_PISTOL_HEAVY_POWDER)
	fire_power = CASING_POWER_HEAVY_PISTOL * CASING_POWER_MOD_HANDLOAD
	sound_properties = CSP_PISTOL_LIGHT

/obj/item/ammo_casing/a357/q2
	name = ".357mag bullet casing"
	desc = "A .357mag bullet casing."
	projectile_type = /obj/item/projectile/bullet/a357/q2
	custom_materials = list(
		/datum/material/iron = MATS_PISTOL_HEAVY_CASING + MATS_PISTOL_HEAVY_BULLET,
		/datum/material/blackpowder = MATS_PISTOL_HEAVY_POWDER)
	fire_power = CASING_POWER_HEAVY_PISTOL * CASING_POWER_MOD_SURPLUS

/obj/item/ammo_casing/a357/q3
	name = "match .357mag bullet casing"
	desc = "A high-grade .357mag bullet casing."
	projectile_type = /obj/item/projectile/bullet/a357/q3
	custom_materials = list(
		/datum/material/iron = MATS_PISTOL_HEAVY_CASING + MATS_PISTOL_HEAVY_BULLET,
		/datum/material/blackpowder = MATS_PISTOL_HEAVY_POWDER)
	fire_power = CASING_POWER_HEAVY_PISTOL * CASING_POWER_MOD_MATCH

///////////////bullet///////////////

/obj/item/projectile/bullet/a357
	name = ".357mag bullet"
	damage = BULLET_DAMAGE_PISTOL_45ACP_HANDLOAD // same as the .45acp right now as they are heavy pistol baseline
	damage_list = list("30" = 30, "36" = 30, "40" = 30, "41" = 2, "42" = 2, "43" = 2, "44" = 2, "45" = 1, "50" = 0.5, "55" = 0.5)
	stamina = BULLET_STAMINA_PISTOL_45ACP
	spread = BULLET_SPREAD_HANDLOAD
	recoil = BULLET_RECOIL_PISTOL_45ACP

	wound_bonus = BULLET_WOUND_PISTOL_45ACP
	bare_wound_bonus = BULLET_WOUND_PISTOL_45ACP_NAKED_MULT
	wound_falloff_tile = BULLET_WOUND_FALLOFF_PISTOL_HEAVY

	pixels_per_second = BULLET_SPEED_PISTOL_45ACP
	damage_falloff = BULLET_FALLOFF_DEFAULT_PISTOL_HEAVY

/obj/item/projectile/bullet/a357/q2
	damage = BULLET_DAMAGE_PISTOL_45ACP_SURPLUS
	spread = BULLET_SPREAD_SURPLUS

/obj/item/projectile/bullet/a357/q3
	damage = BULLET_DAMAGE_PISTOL_45ACP_MATCH
	spread = BULLET_SPREAD_MATCH

///////////////ammo box///////////////

/obj/item/ammo_box/a357
	name = ".357mag ammo box (handload)"
	icon = 'icons/fallout/objects/guns/ammo.dmi'
	icon_state = "357box"
	multiple_sprites = 2
	caliber = list(CALIBER_357)
	ammo_type = /obj/item/ammo_casing/a357
	max_ammo = 50 // don't change this for new calibers
	w_class = WEIGHT_CLASS_SMALL
	custom_materials = list(/datum/material/iron = MATS_RIFLE_SMALL_BOX)
	randomize_ammo_count = FALSE

/obj/item/ammo_box/a357/q2
	name = ".357mag ammo box (standard)"
	ammo_type = /obj/item/ammo_casing/a357/q2

/obj/item/ammo_box/a357/q3
	name = ".357mag ammo box (match)"
	ammo_type = /obj/item/ammo_casing/a357/q3

///////////////ammo crate///////////////

/obj/item/ammo_box/a357/crate
	name = ".357mag ammo crate (handload)"
	desc = "A wooden crate of ammo."
	icon = 'modular_coyote/icons/objects/c13ammo.dmi'
	icon_state = "wood_ammobox"
	w_class = WEIGHT_CLASS_HUGE // don't you dare make this any smaller!
	multiple_sprites = 4
	max_ammo = 300 // don't change this for new calibers
	load_behavior = AMMOB_CRATE

/obj/item/ammo_box/a357/crate/q2
	name = ".357mag ammo crate (standard)"
	ammo_type = /obj/item/ammo_casing/a357/q2

/obj/item/ammo_box/a357/crate/q3
	name = ".357mag ammo crate (match)"
	ammo_type = /obj/item/ammo_casing/a357/q3

///////////////ammo box recipe///////////////

/datum/design/ammolathe/a357
	name = ".357mag ammo box (handload)"
	id = "a357"
	build_path = /obj/item/ammo_box/a357
	category = list("initial", "Basic Ammo")

/datum/design/ammolathe/a357_2
	name = ".357mag ammo box (standard)"
	id = "a357_2"
	build_path = /obj/item/ammo_box/a357/q2
	category = list("initial", "Basic Ammo")

/datum/design/ammolathe/a357_3
	name = ".357mag ammo box (match)"
	id = "a357_3"
	build_path = /obj/item/ammo_box/a357/q3
	category = list("initial", "Basic Ammo")

///////////////ammo crate recipe///////////////

/datum/design/ammolathe/a357crate
	name = ".357mag ammo crate (handload)"
	id = "a357crate"
	build_path = /obj/item/ammo_box/a357/crate
	category = list("initial", "Basic ammo")

/datum/design/ammolathe/a357crate2
	name = ".357mag ammo crate (standard)"
	id = "a357crate2"
	build_path = /obj/item/ammo_box/a357/crate/q2
	category = list("initial", "Basic ammo")

/datum/design/ammolathe/a357crate3
	name = ".357mag ammo crate (match)"
	id = "a357crate3"
	build_path = /obj/item/ammo_box/a357/crate/q3
	category = list("initial", "Basic ammo")
