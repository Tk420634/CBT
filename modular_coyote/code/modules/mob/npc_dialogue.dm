/datum/component/npc_ui
	var/range = 2 // how many tiles can you click on the NPC?
	var/ui_ref = "NPCDialogue"

// /datum/component/npc_ui/Initialize()
// 	if(!ismob(parent))
// 		return COMPONENT_INCOMPATIBLE
	
// 	. = ..()

/datum/component/npc_ui/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_ATTACK_PAW), PROC_REF(on_attack_hand))

/datum/component/npc_ui/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_ATTACK_PAW))

/datum/component/npc_ui/proc/on_attack_hand(datum/source, mob/user)
	SIGNAL_HANDLER
	var/mob/M = user
	var/mob/parentM = parent

	if(parentM.stat != CONSCIOUS)
		return

	if(M)
		if(M.get_active_held_item() || M.a_intent != INTENT_HELP)
			return // Do not open UI under these conditions

	. = COMPONENT_NO_ATTACK

	INVOKE_ASYNC(src, PROC_REF(present_ui), user)


/datum/component/npc_ui/trader
	ui_ref = "NPCTrading"

	var/product_records = list()

	///Default price of items if not overridden
	var/default_price = PRICE_NORMAL

	var/force_free

	var/vend_ready

	var/stored_caps = 0
	var/icon_vend


/datum/component/npc_ui/proc/present_ui(mob/user, datum/tgui/ui)
	var/atom/A = parent
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, parent, ui_ref, A.name)
		ui.open()


/datum/component/npc_ui/trader/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/vending),
	)

/datum/component/npc_ui/trader/ui_static_data(mob/user)
	. = list()
	// .["onstation"] = onstation
	// .["department"] = payment_department
	.["product_records"] = list()
	for (var/datum/data/vending_product/R in product_records)
		var/list/data = list(
			asset = get_spritesheet_icon_key_from_type(R.product_path),
			name = R.name,
			price = R.custom_price || default_price,
			max_amount = R.max_amount,
			ref = REF(R)
		)
		.["product_records"] += list(data)
	// .["coin_records"] = list()
	// for (var/datum/data/vending_product/R in coin_records)
	// 	var/list/data = list(
	// 		asset = get_spritesheet_icon_key_from_type(R.product_path),
	// 		name = R.name,
	// 		price = R.custom_premium_price || extra_price,
	// 		max_amount = R.max_amount,
	// 		ref = REF(R),
	// 		premium = TRUE
	// 	)
	// 	.["coin_records"] += list(data)
	// .["hidden_records"] = list()
	// for (var/datum/data/vending_product/R in hidden_records)
	// 	var/list/data = list(
	// 		asset = get_spritesheet_icon_key_from_type(R.product_path),
	// 		name = R.name,
	// 		price = R.custom_premium_price || extra_price, //may cause breakage. please note
	// 		max_amount = R.max_amount,
	// 		ref = REF(R),
	// 		premium = TRUE
	// 	)
	// 	.["hidden_records"] += list(data)

/datum/component/npc_ui/trader/ui_data(mob/user)
	. = list()
	var/mob/living/carbon/human/H
	var/obj/item/card/id/C
	if(ishuman(user))
		H = user
		C = H.get_idcard()
		if(C?.registered_account)
			.["user"] = list()
			.["user"]["name"] = C.registered_account.account_holder
			.["user"]["cash"] = C.registered_account.account_balance
	.["stock"] = list()
	for (var/datum/data/vending_product/R in product_records)
		.["stock"][R.name] = R.amount
	// .["extended_inventory"] = extended_inventory
	.["insertedCoins"] = stored_caps ? stored_caps : "0"
	.["forceFree"] = force_free


/datum/component/npc_ui/trader/ui_act(action,params)
	. = ..()
	if(.)
		return
	switch(action)
		if("vend")
			. = TRUE
			if(!vend_ready)
				return
			vend_ready = FALSE //One thing at a time!!
			var/datum/data/vending_product/R = locate(params["ref"])
			var/list/record_to_check = product_records // + coin_records
			// if(extended_inventory)
			// 	record_to_check = product_records + coin_records + hidden_records
			if(!R || !istype(R) || !R.product_path)
				vend_ready = TRUE
				return

			//debug 
			// Not needed cause we don't need this :3
			// if(product_records.Find(R) && hidden_records.Find(R))
			// 	log_runtime("WARN - vendor [src] @ [loc] has Duplicate [R] accross normal and hidden product tables!")
			// if(product_records.Find(R) && coin_records.Find(R))
			// 	log_runtime("WARN - vendor [src] @ [loc] has Duplicate [R] accross normal and premium product tables!")

			//Set price for the item we're using.
			var/price_to_use = default_price
			if(R.custom_price)
				price_to_use = R.custom_price
			// if(coin_records.Find(R) || hidden_records.Find(R))
			// 	price_to_use = R.custom_premium_price ? R.custom_premium_price : extra_price

			//Make sure we actually have the item.
			// if(R in hidden_records)
			// 	if(!extended_inventory)
			// 		vend_ready = TRUE
			// 		return
			if (!(R in record_to_check))
				vend_ready = TRUE
				message_admins("Vending machine exploit attempted by [ADMIN_LOOKUPFLW(usr)]!")
				return
			if (R.amount <= 0)
				//say("Sold out of [R.name].")
				//flick(icon_deny,src)
				// parent.say(pick(locale["sold_out"]))
				vend_ready = TRUE
				return

			//Thank them like any megaglobal corp should.
			// if(last_shopper != REF(usr) || purchase_message_cooldown < world.time)
			// 	say("Thank you for shopping with [src]!")
			// 	purchase_message_cooldown = world.time + 5 SECONDS
			// 	last_shopper = REF(usr)

			//Do we have the money inserted to buy this item?
			if(price_to_use > stored_caps && !force_free)
				to_chat(usr, span_alert("Not enough coins to pay for [R.name]!"))
				vend_ready = TRUE
				return

			//Deduct that price if we're not overridden to be free.
			if(!force_free)
				stored_caps = stored_caps - price_to_use

			//use power, play animations and sounds.
			if(icon_vend) //Show the vending animation if needed
				flick(icon_vend,src)
			playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3) // lmao keeping this in for now

			// TODO: Make NPC fetch and retrieve the item from the inventory.

			//Set up what we're vending and actually vend it to the person buying it.
			var/obj/item/vended = new R.product_path(get_turf(parent))
			R.amount--

			// if(usr.can_reach(src) && usr.put_in_hands(vended))
			// 	to_chat(usr, span_notice("You take [R.name] out of the slot."))
			// else
			// 	to_chat(usr, span_warning("[capitalize(R.name)] falls onto the floor!"))

			SSblackbox.record_feedback("nested tally", "vending_machine_usage", 1, list("[type]", "[R.product_path]"))
			vend_ready = TRUE

		if("ejectCaps")
			//remove_all_caps()
