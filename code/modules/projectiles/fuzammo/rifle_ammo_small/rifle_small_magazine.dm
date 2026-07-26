/obj/item/ammo_box/magazine/a223
	name = "magazine template (.223)"
	desc = "should not be here, bugreport."
	icon = 'icons/fallout/objects/guns/ammo.dmi'
	ammo_type = /obj/item/ammo_casing/a223
	caliber = list(CALIBER_223)
	multiple_sprites = 2


/obj/item/ammo_box/magazine/a223/thirty
	name = "box magazine (.223)"
	icon_state = "r30"
	max_ammo = 30
	custom_materials = list(/datum/material/iron = MATS_MEDIUM_SMALL_RIFLE_MAGAZINE)

/obj/item/ammo_box/magazine/a223/thirty/empty
	start_empty = 1

/datum/design/ammolathe/a223_30
	name = "box magazine (.223)"
	id = "a223_30"
	materials = list(/datum/material/iron = 4000)
	build_path = /obj/item/ammo_box/magazine/a223/thirty/empty
	category = list("initial", "Simple Magazines")
