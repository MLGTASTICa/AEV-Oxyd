

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
		var/protostring = "- type: entity\n  parent: "
		var/list/parents = list()
		var/rsirefpath = "Oxyd/erisported/clothing/"
		if(istype(cloth, /obj/item/clothing/head))
			if(istype(cloth, /obj/item/clothing/head/space))
				parents.Add("ClothingHeadHardsuitBase")
				if(cloth.brightness_on > 0)
					parents.Add("ClothingHeadSuitWithLightBase")
			else
				parents.Add("ClothingHeadBase")
				if(cloth.brightness_on > 0)
					parents.Add("ClothingHeadLightBase")
			rsirefpath += "head/"
		// set parents
		if(length(parents) > 1)
			var/form = "[ "
			for(var/par in parents)
				form += i + " "
			form += "]"
			protostring += form + "\n"
		else if (length(parents) == 1)
			protostring += parents[1] + "\n"
		// desc  + name + id + base comps!
		var/basepath = "exporter/" + rsirefpath + cloth.name +".rsi"
		protostring += {"
		  id: ["erisport_"+cloth.name+]\n
		  name: [cloth.name]\n"
		  description: [cloth.desc]\n"
		  components:\n
		    - type: Sprite
			  sprite: [basepath]
			- type: Clothing
			  sprite: [basepath]
			  quickEquip: true
		 "}
		basepath += '/'
		fcopy(custom_icon, basepath + "icon.png")
		if(cloth.slot_flags & SLOT_HEAD)
			fcopy(new/icon(INV_HEAD_DEF_ICON, cloth.icon_state), basepath + "equipped-HELMET.png")
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
