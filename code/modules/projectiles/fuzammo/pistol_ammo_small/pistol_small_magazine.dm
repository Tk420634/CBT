/obj/item/ammo_box/magazine/internal/cylinder/a38
	name = ".38 cylinder"
	ammo_type = /obj/item/ammo_casing/a38
	caliber = list(CALIBER_38)

/obj/item/ammo_box/magazine/internal/cylinder/a38/six
	max_ammo = 6

/obj/item/ammo_box/magazine/a9mm
	name = "magazine template (9mm)"
	desc = "should not be here, bugreport."
	icon = 'icons/fallout/objects/guns/ammo.dmi'
	ammo_type = /obj/item/ammo_casing/a9mm
	caliber = list(CALIBER_9MM)
	multiple_sprites = 2

/obj/item/ammo_box/magazine/a9mm/fifteen
	name = "pistol magazine (9mm)"
	icon_state = "m9mmds"
	max_ammo = 15
	custom_materials = list(/datum/material/iron = MATS_MEDIUM_PISTOL_MAGAZINE)

/obj/item/ammo_box/magazine/a9mm/fifteen/empty
	start_empty = 1

/datum/design/ammolathe/a9mm_15
	name = "pistol magazine (9mm)"
	id = "a9mm_15"
	materials = list(/datum/material/iron = 4000)
	build_path = /obj/item/ammo_box/magazine/a9mm/fifteen/empty
	category = list("initial", "Simple Magazines")
