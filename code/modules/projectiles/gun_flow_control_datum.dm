/* 
 * file: gun_flow_control_datum.dm
 * date: April 6, 2026
 * author: Superlagg
 * 
 * "Anything a frickhuge list can do, a datum does better." - Superlagg, circa 514
 * Holds the vast immediate data of a gun's firing process, as relating to the
 * flow control of what its trying to do. It is owned by the gun, and coexists with it
 * from birth to death, and is wiped clean after every script is done with it.
 * 
 * its faster than a list, cus I said so
 * */

/datum/gloch_data
	// ensures the gun will hard delete, cus this game runs a little *too* well if you ask me
	var/obj/item/gun/owner
	var/current_instruction
	var/next_instruction
	var/list/branch_table
	// what invoked the flow control. click, use, or whatever else can be done
	var/input_origin
	var/pointblank
	var/mouse_params
	var/wait
	var/break_script
	var/return_value
	var/delay_next_action
	var/is_akimbo_shot
	var/in_use

/datum/gloch_data/New(obj/item/gun/owner)
	..()
	src.owner = owner

/datum/gloch_data/proc/wipe()
	current_instruction  = null
	next_instruction     = null
	branch_table         = null
	input_origin         = null
	pointblank           = null
	mouse_params         = null
	wait                 = null
	break_script         = null
	return_value         = null
	delay_next_action    = null
	is_akimbo_shot       = null
	in_use               = null

/datum/gloch_data/proc/init(point_blank, params, list/ext_data)
	mouse_params = params
	pointblank = point_blank
	if(!islist(ext_data))
		return
	is_akimbo_shot = ext_data[GDAT_AKIMBO_SHOT]


