/mob/living/danimal/slime/update_mobility()
	. = ..()
	if(Tempstun && !buckled)
		DISABLE_BITFIELD(., MOBILITY_MOVE)
		mobility_flags = .
