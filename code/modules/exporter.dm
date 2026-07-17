

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

#define HIDEGLOVES      0x1
#define HIDESUITSTORAGE 0x2
#define HIDEJUMPSUIT    0x4
#define HIDESHOES       0x8
#define HIDETAIL        0x10

// WARNING: The following flags apply only to the helmets and masks!
#define HIDEMASK 0x1
#define HIDEEARS 0x2 // Headsets and such.
#define HIDEEYES 0x4 // Glasses.
#define HIDEFACE 0x8 // Dictates whether we appear as "Unknown".

//This flag applies to gloves, uniforms, shoes, masks, ear items, glasses
#define ALWAYSDRAW	0x16//If set, this item is always rendered even if its slot is hidden by other clothing
//Note that the item may still not be visible if its sprite is actually covered up.

#define BLOCKHEADHAIR   0x20    // Hides the user's hair overlay. Leaves facial hair.
#define BLOCKHAIR       0x40    // Hides the user's hair, facial and otherwise.
#define BLOCKFACEHAIR   0x80    // Hides the user's facial hair. Leaves head hair

/mob/living/carbon/human/proc/get_gender_icon(g = MALE, slot)
	var/list/icons = list(
		"uniform"		= (g == MALE) ? 'icons/inventory/uniform/mob.dmi' : 'icons/inventory/uniform/mob_fem.dmi',
		"suit"			= (g == MALE) ? 'icons/inventory/suit/mob.dmi' : 'icons/inventory/suit/mob_fem.dmi',
		"gloves"		= 'icons/inventory/hands/mob.dmi',
		"glasses"		= 'icons/inventory/eyes/mob.dmi',
		"ears"			= 'icons/inventory/ears/mob.dmi',
		"mask"			= 'icons/inventory/face/mob.dmi',
		"hat"			= 'icons/inventory/head/mob.dmi',
		"shoes"			= 'icons/inventory/feet/mob.dmi',
		"misk"			= 'icons/mob/mob.dmi',
		"belt"			= 'icons/inventory/belt/mob.dmi',
		"s_store"		= 'icons/inventory/on_suit/mob.dmi',
		"backpack"		= 'icons/inventory/back/mob.dmi',
		"underwear"		= 'icons/inventory/underwear/mob.dmi'
		)
	return icons[slot]

*/

#define LIGHT_ONICON 'icons/obj/light_overlays.dmi'
#define LIGHT_ONMOB 'icons/mob/light_overlays.dmi'

/datum/exporter/New()
	. = ..()
	message_admins("collecting items...")
	var/list/data = typesof(/obj/item/clothing)
	data.Add(typesof(/obj/item/storage/belt))
	data.Add(typesof(/obj/item/storage/backpack))
	var/list/alreadyExported = list()
	message_admins("found [length(data)] clothings...")
	for(var/pathed in data)
		var/list/createdFiles = list()
		var/list/multistate = list()
		var/obj/item/clothing/cloth = new pathed()
		if(!cloth.icon_state || !cloth.icon)
			message_admins("skipping [cloth.name] because it has no icon_state or icon")
			continue
		if(istype(cloth, /obj/item/clothing/accessory))
			message_admins("skipping [cloth.name] because it is an accessory")
			continue
		message_admins("exporting [cloth.name]...")
		var/icon/custom_icon = new/icon(cloth.icon, cloth.icon_state)
		var/protostring = "- type: entity\n  parent: "
		var/list/parents = list()
		var/rsirefpath = "Oxyd/erisported/clothing/"
		var/ymlrefpath = "Oxyd/erisported/prototypes/"
		var/safename = replacetext(cloth.name, " ", "_")
		if(safename in alreadyExported)
			message_admins("skipping [cloth.name] because it has already been exported")
			continue
		alreadyExported.Add(safename)
		var/basepath = rsirefpath + safename +".rsi"
		var/ymlrsirefpath = basepath
		basepath = "exporter/"+ basepath + "/"
		var/postcomps = ""
		if(istype(cloth, /obj/item/storage/belt))
			parents.Add("ClothingBeltBase")
			ymlrefpath += "belt/"
			rsirefpath += "belt/"
		else if(istype(cloth, /obj/item/storage/backpack))
			if(istype(cloth, /obj/item/storage/backpack/duffelbag))
				parents.Add("ClothingBackpackDuffel")
			else if(istype(cloth, /obj/item/storage/backpack/satchel))
				parents.Add("ClothingBackpackSatchel")
			else
				parents.Add("ClothingBackpack")
			ymlrefpath += "backpack/"
			rsirefpath += "backpack/"
		if(istype(cloth, /obj/item/clothing))
			// cloth start
			if(istype(cloth, /obj/item/clothing/under))
				parents.Add("ClothingUniformBase")
				ymlrefpath += "under/"
				rsirefpath += "under/"
			if(istype(cloth, /obj/item/clothing/suit))
				ymlrefpath += "suit/"
				rsirefpath += "suit/"
				if(istype(cloth, /obj/item/clothing/suit/space))
					if(istype(cloth, /obj/item/clothing/suit/space/void))
						var/obj/item/clothing/suit/space/void/castingSpace = cloth
						if(!castingSpace.helmet)
							parents.Add("ClothingOuterEVASuitBase")
						else
							parents.Add("ClothingOuterEVASuitBaseToggleable")
							var/helmetName = "erisport_" + replacetext(castingSpace.helmet.name, " ", "_")
							postcomps += "  - type: ToggleableClothing\n    clothingPrototype: [helmetName]\n"
					else
						parents.Add("ClothingOuterEVASuitBase")
					ymlrefpath+= "space/"
					rsirefpath+= "space/"
				else if(istype(cloth, /obj/item/clothing/suit/storage))
					parents.Add("ClothingOuterStorageBase")
					ymlrefpath += "storage/"
					rsirefpath += "storage/"
				else
					parents.Add("ClothingOuterBase")
			else if(istype(cloth, /obj/item/clothing/shoes))
				parents.Add("ClothingShoesBase")
				ymlrefpath += "feet/"
				rsirefpath += "feet/"
			else if(istype(cloth, /obj/item/clothing/gloves))
				parents.Add("ClothingHandsBase")
				ymlrefpath += "hand/"
				rsirefpath += "hand/"
			else if(istype(cloth, /obj/item/clothing/mask))
				if(istype(cloth, /obj/item/clothing/mask/gas))
					parents.Add("ClothingMaskGas")
				else
					parents.Add("ClothingMaskBase")
				ymlrefpath += "mask/"
				rsirefpath += "mask/"
			else if(istype(cloth, /obj/item/clothing/glasses))
				parents.Add("ClothingEyesBase")
				ymlrefpath += "eye/"
				rsirefpath += "eye/"
			else if(istype(cloth, /obj/item/clothing/head))
				if(istype(cloth, /obj/item/clothing/head/space))
					parents.Add("ClothingHeadHardsuitBase")
					if(cloth.brightness_on > 0)
						parents.Add("ClothingHeadSuitWithLightBase")
						postcomps += "  - type: PointLight\n    radius: [cloth.brightness_on]\n    energy: [cloth.light_power]\n    color: \"#FFFFFF\"\n"
				else
					parents.Add("ClothingHeadBase")
					if(cloth.brightness_on > 0)
						parents.Add("ClothingHeadLightBase")
						postcomps += "  - type: PointLight\n    radius: [cloth.brightness_on]\n    energy: [cloth.light_power]\n    color: \"#FFFFFF\"\n"
				rsirefpath += "head/"
				ymlrefpath += "head/"
				// set parents
			var/list/hidingLayers = list()
			var/coverage = 0
			if(cloth.flags_inv & HIDEFACE)
				coverage |= 4
			if(cloth.flags_inv & HIDEEYES)
				coverage |= 2
			if(cloth.flags_inv & HIDEMASK)
				coverage |= 1
			if(coverage > 0)
				postcomps += "  - type: IdentityBlocker\n    coverage:"
				if(coverage & 4 || coverage & 3)
					postcomps += " FULL\n"
				else if(coverage & 2)
					postcomps += " EYES\n"
				else if(coverage & 1)
					postcomps += " MOUTH\n"
			if(cloth.flags_inv & BLOCKHEADHAIR)
				hidingLayers += "      Hair: HEAD"
			if(cloth.flags_inv & BLOCKFACEHAIR)
				hidingLayers += "      FacialHair: HEAD"
			if(cloth.body_parts_covered & FACE)
				postcomps += "  - type: IngestionBlocker\n"
			if(length(hidingLayers) > 0)
				postcomps += "  - type: HideLayerClothing\n"
				postcomps+= "    layers:\n"
				for(var/l in hidingLayers)
					postcomps += l + "\n"
			if(cloth.brightness_on && cloth.light_overlay)
				custom_icon.Blend(new/icon(LIGHT_ONICON, cloth.light_overlay),ICON_OVERLAY)
				fcopy(custom_icon, basepath + "icon-flash.png")
				createdFiles.Add("icon-flash")
				multistate.Add(0)
			if(cloth.slot_flags & SLOT_HEAD )
				if(!cloth.brightness_on)
					fcopy(new/icon(INV_HEAD_DEF_ICON, cloth.icon_state), basepath + "equipped-HELMET.png")
					createdFiles.Add("equipped-HELMET")
					multistate.Add(1)
				else
					var/icon/blendedCon = new/icon(INV_HEAD_DEF_ICON, cloth.icon_state)
					fcopy(blendedCon, basepath + "off-equipped-HELMET.png")
					createdFiles.Add("off-equipped-HELMET")
					multistate.Add(1)
					if(cloth.light_overlay)
						blendedCon.Blend(new/icon(LIGHT_ONMOB, cloth.light_overlay), ICON_OVERLAY)
						fcopy(blendedCon, basepath + "on-equipped-HELMET.png")
						createdFiles.Add("on-equipped-HELMET")
						multistate.Add(1)
			if(cloth.slot_flags & SLOT_OCLOTHING)
				fcopy(new/icon(INV_SUIT_DEF_ICON, cloth.icon_state), basepath + "equipped-OUTERCLOTHING.png")
				createdFiles.Add("equipped-OUTERCLOTHING")
				multistate.Add(1)
			if(cloth.slot_flags & SLOT_GLOVES)
				fcopy(new/icon("icons/inventory/hands/mob.dmi", cloth.icon_state), basepath + "equipped-HAND.png")
				createdFiles.Add("equipped-HAND")
				multistate.Add(1)
			if(cloth.slot_flags & SLOT_FEET )
				fcopy(new/icon("icons/inventory/feet/mob.dmi", cloth.icon_state), basepath + "equipped-FEET.png")
				createdFiles.Add("equipped-FEET")
				multistate.Add(1)
			if(cloth.slot_flags & SLOT_EYES)
				fcopy(new/icon("icons/inventory/eyes/mob.dmi", cloth.icon_state), basepath + "equipped-EYES.png")
				createdFiles.Add("equipped-EYES")
				multistate.Add(1)
			if(cloth.slot_flags & SLOT_MASK)
				fcopy(new/icon("icons/inventory/face/mob.dmi", cloth.icon_state), basepath + "equipped-MASK.png")
				createdFiles.Add("equipped-MASK")
				multistate.Add(1)
			if(cloth.slot_flags & SLOT_ICLOTHING )
				fcopy(new/icon("icons/inventory/uniform/mob.dmi", cloth.icon_state), basepath + "equipped-INNERCLOTHING.png")
				createdFiles.Add("equipped-INNERCLOTHING")
				multistate.Add(1)
		if(cloth.slot_flags & SLOT_BELT)
			fcopy(new/icon("icons/inventory/belt/mob.dmi", cloth.icon_state), basepath + "equipped-BELT.png")
			createdFiles.Add("equipped-BELT")
			multistate.Add(1)
		if(cloth.slot_flags & SLOT_BACK)
			fcopy(new/icon("icons/inventory/back/mob.dmi", cloth.icon_state), basepath + "equipped-BACKPACK.png")
			createdFiles.Add("equipped-BACKPACK")
			multistate.Add(1)
		// cloth end
		if(length(parents) > 1)
			var/form = @"[ "
			var/i = 1
			while(i <= length(parents))
				form += parents[i]
				if(i != length(parents))
					form += " , "
				i++
			form += @"]"
			protostring += form
		else if (length(parents) == 1)
			protostring += parents[1]
		// desc  + name + id + base comps!
		if(cloth.w_class == ITEM_SIZE_NORMAL)
			postcomps += "  - type: Item\n    size: Normal\n"
		if(cloth.w_class == ITEM_SIZE_BULKY)
			postcomps += "  - type: Item\n    size: Large\n"
		if(cloth.w_class == ITEM_SIZE_HUGE)
			postcomps += "  - type: Item\n    size: Huge\n"
		protostring += {"
  id: ["erisport_"+safename]
  name: [cloth.name]
  description: [cloth.desc]
  components:
  - type: Sprite
    sprite: [ymlrsirefpath]
  - type: Clothing
    sprite: [ymlrsirefpath]
    quickEquip: true
  - type: Tag
    tags:
    - ClothMade
    - Recyclable[(cloth.type in GLOB.chameleon_blacklist) ? "\n" : "\n    - WhitelistChameleon"]
[postcomps]"}
		var/ymlfile = file("exporter/"+ ymlrefpath + safename + ".yml")
		ymlfile << protostring
		custom_icon = new/icon(cloth.icon, cloth.icon_state)
		fcopy(custom_icon, basepath + "icon.png")
		createdFiles.Add("icon")
		multistate.Add(0)
		if(cloth.item_state_slots[slot_l_hand_str] || cloth.item_icons[slot_l_hand_str])
		{
			var/name = cloth.icon_state
			if(cloth.item_state_slots[slot_l_hand_str])
				name = cloth.item_state_slots[slot_l_hand_str]
			var/icon/licon = new/icon(cloth.item_icons[slot_l_hand_str], name)
			if(length(icon_states(licon)) > 1)
				message_admins("WARNING: [cloth.name] has multiple icon states for left hand, skipping")
			else
				fcopy(licon, basepath + "inhand-left.png")
				createdFiles.Add("inhand-left")
				multistate.Add(1)
		}
		if(cloth.item_state_slots[slot_r_hand_str] || cloth.item_icons[slot_r_hand_str])
		{
			var/name =  cloth.icon_state
			if(cloth.item_state_slots[slot_r_hand_str])
				name = cloth.item_state_slots[slot_r_hand_str]
			var/icon/licon = new/icon(cloth.item_icons[slot_r_hand_str], name)
			if(length(icon_states(licon)) > 1)
				message_admins("WARNING: [cloth.name] has multiple icon states for right hand, skipping")
			else
				fcopy(licon, basepath + "inhand-right.png")
				createdFiles.Add("inhand-right")
				multistate.Add(1)
		}

		var/rsijsonfile = file(basepath + "meta.json")
		var/jsonstates = @" ["+"\n"
		for(var/tp in 1 to length(createdFiles)-1)
			jsonstates += "        {\n            \"name\": \"[createdFiles[tp]]\""
			if(multistate[tp])
				jsonstates += ",\n            \"directions\": 4"
			jsonstates+="\n        },\n"
		jsonstates += "        {\n            \"name\": \"[createdFiles[length(createdFiles)]]\""
		if(multistate[length(createdFiles)])
			jsonstates += ",\n            \"directions\": 4"
		jsonstates+="\n        }\n"
		jsonstates += "\n      ]"
		rsijsonfile << {"
{
  "version": 1,
  "license": "",
  "copyright": "https://github.com/discordia-space/CEV-Eris",
  "size": {
    "x": 32,
    "y": 32
  },
  "states": [jsonstates]
}
"}
