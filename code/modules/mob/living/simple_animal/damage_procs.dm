
/mob/living/danimal/proc/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && (status_flags & GODMODE))
		return FALSE
	bruteloss = round(clamp(bruteloss + amount, 0, maxHealth),DAMAGE_PRECISION)
	if(updating_health)
		updatehealth()
	return amount

/mob/living/danimal/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE, include_roboparts = TRUE)
	if(forced)
		. = adjustHealth(amount * CONFIG_GET(number/damage_multiplier), updating_health, forced)
	else if(damage_coeff[BRUTE])
		. = adjustHealth(amount * damage_coeff[BRUTE] * CONFIG_GET(number/damage_multiplier), updating_health, forced)

/mob/living/danimal/adjustFireLoss(amount, updating_health = TRUE, forced = FALSE, include_roboparts = TRUE)
	if(forced)
		. = adjustHealth(amount * CONFIG_GET(number/damage_multiplier), updating_health, forced)
	else if(damage_coeff[BURN])
		. = adjustHealth(amount * damage_coeff[BURN] * CONFIG_GET(number/damage_multiplier), updating_health, forced)

/mob/living/danimal/adjustOxyLoss(amount, updating_health = TRUE, forced = FALSE)
	if(forced)
		. = adjustHealth(amount * CONFIG_GET(number/damage_multiplier), updating_health, forced)
	else if(damage_coeff[OXY])
		. = adjustHealth(amount * damage_coeff[OXY] * CONFIG_GET(number/damage_multiplier), updating_health, forced)

/mob/living/danimal/adjustToxLoss(amount, updating_health = TRUE, forced = FALSE, force_be_heal)
	if(forced)
		. = adjustHealth(amount * CONFIG_GET(number/damage_multiplier), updating_health, forced)
	else if(damage_coeff[TOX])
		. = adjustHealth(amount * damage_coeff[TOX] * CONFIG_GET(number/damage_multiplier), updating_health, forced)

/mob/living/danimal/adjustCloneLoss(amount, updating_health = TRUE, forced = FALSE)
	if(forced)
		. = adjustHealth(amount * CONFIG_GET(number/damage_multiplier), updating_health, forced)
	else if(damage_coeff[CLONE])
		. = adjustHealth(amount * damage_coeff[CLONE] * CONFIG_GET(number/damage_multiplier), updating_health, forced)

/mob/living/danimal/getStaminaLoss()
	return staminaloss

/mob/living/danimal/adjustStaminaLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && (status_flags & GODMODE))
		return FALSE
	if(stamcrit_threshold == SIMPLEMOB_NO_STAMCRIT || amount > 0)
		return
	if(damage_coeff[STAMINA])
		staminaloss = clamp((staminaloss + (amount * damage_coeff[STAMINA] * CONFIG_GET(number/damage_multiplier))), 0, stamcrit_threshold * 1.2)
	update_stamina()
	return staminaloss

/mob/living/danimal/setStaminaLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && (status_flags & GODMODE))
		return FALSE
	if(stamcrit_threshold == SIMPLEMOB_NO_STAMCRIT || amount > 0)
		return
	staminaloss = amount
	update_stamina()
	return staminaloss
