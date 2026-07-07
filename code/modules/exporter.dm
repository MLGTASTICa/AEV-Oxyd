

/*
#define slot_back_str		"slot_back"
#define slot_l_hand_str		"slot_l_hand"
#define slot_r_hand_str		"slot_r_hand"
#define slot_w_uniform_str	"slot_w_uniform"
#define slot_head_str		"slot_head"
#define slot_wear_suit_str	"slot_suit"
#define slot_s_store_str    "slot_s_store"

#define INV_HEAD_DEF_ICON 'icons/inventory/head/mob.dmi'
#define INV_BACK_DEF_ICON 'icons/inventory/back/mob.dmi'
#define INV_L_HAND_DEF_ICON 'icons/mob/inhands/lefthand.dmi'
#define INV_R_HAND_DEF_ICON 'icons/mob/inhands/righthand.dmi'
#define INV_W_UNIFORM_DEF_ICON 'icons/inventory/uniform/mob.dmi'
#define INV_ACCESSORIES_DEF_ICON 'icons/inventory/accessory/mob.dmi'
#define INV_SUIT_DEF_ICON 'icons/inventory/suit/mob.dmi'
#define INV_BELT_DEF_ICON 'icons/invenstory/belt/mob.dmi'

*/


/datum/exporter/New(path, user)
	. = ..()
	message_admins("checking clothings of [path]...")
	var/converted = text2path(path)
	var/data = typesof(converted)
	message_admins("found [length(data)] clothings...")
	for(var/pathed in data)
		var/obj/item/clothing/cloth = new pathed()
		var/icon/custom_icon = new/icon(cloth.icon, cloth.icon_state)
		var/basepath = "exporter/" + cloth.name +".rsi/"
		fcopy(custom_icon, basepath + "icon.png")
		if(cloth.slot_flags & SLOT_HEAD)
			fcopy(new/icon(INV_HEAD_DEF_ICON, cloth.icon_state), basepath + "equipped-HELMET.png")

		message_admins("Exported [cloth.name] to test/[cloth.name].png")
		if(cloth.item_state_slots[slot_back_str])
		if(cloth.item_state_slots[slot_l_hand_str])
		{
			var/name = cloth.icon_state
			if(cloth.item_state_slots[slot_l_hand_str])
				name = cloth.item_state_slots[slot_l_hand_str]
			var/icon/licon = new/icon(cloth.item_icons[slot_l_hand_str], name)
			fcopy(licon, basepath + "inhand-left.png")
		}
		if(cloth.item_state_slots[slot_r_hand_str])
		{
			var/name =  cloth.icon_state
			if(cloth.item_state_slots[slot_r_hand_str])
				name = cloth.item_state_slots[slot_r_hand_str]
			var/icon/licon = new/icon(cloth.item_icons[slot_r_hand_str], name)
			fcopy(licon, basepath + "inhand-right.png")
		}
		if(cloth.item_state_slots[slot_w_uniform_str])
		if(cloth.item_state_slots[slot_head_str])
		if(cloth.item_state_slots[slot_wear_suit_str])
		if(cloth.item_state_slots[slot_s_store_str])
