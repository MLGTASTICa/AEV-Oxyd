/datum/component/internal_wound
	var/name = "internal injury"
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/list/treatments_item = list()	// list(/obj/item = amount)
	var/list/treatments_tool = list()	// list(QUALITY_TOOL = FAILCHANCE)
	var/list/treatments_chem = list()	// list(CE_CHEMEFFECT = strength)
	var/datum/component/scar			// If defined, applies this wound type when successfully treated

	var/diagnosis_stat					// BIO for organic, MEC for robotic
	var/diagnosis_difficulty			// basic - 25, adv - 40

	var/severity						// How much the wound contributes to internal organ damage
	var/severity_max = 2				// How far the wound can progress, default is 2
	var/can_damage_organ = TRUE			// Does wound severity damage the parent organ?

	var/can_progress = FALSE			// Whether the wound can progress or not
	var/datum/component/next_wound		// If defined, applies a wound of this type when severity is at max
	var/progression_threshold = 90		// How many ticks until the wound progresses, default is 3 minutes
	var/current_progression_tick		// Current tick towards progression

	var/can_spread = FALSE				// Whether the wound can spread throughout the body or not
	var/spread_threshold = 0			// Severity at which the wound spreads a single time

	var/wound_nature					// Make sure we don't apply organic wounds to robotic organs and vice versa

	// Damage applied to mob each process tick
	var/hal_damage
	var/oxy_damage
	var/tox_damage
	var/clone_damage		// This is fairly dangerous as it can cause more wounds. Use with caution.
	var/psy_damage			// Not the same as sanity damage, but does deal sanity damage

	// Additional effects
	var/can_hallucinate = FALSE			// Will this wound cause hallucinations?
	var/ticks_per_hallucination = 60	// 2 minutes
	var/current_hallucination_tick

	// Organ adjustments - preferably used for more severe wounds
	var/specific_organ_size_multiplier = null
	var/max_blood_storage_multiplier = null
	var/blood_req_multiplier = null
	var/nutriment_req_multiplier = null
	var/oxygen_req_multiplier = null

	// Parent organ adjustments
	var/status_flag

/datum/component/internal_wound/RegisterWithParent()
	// Internal organ parent
	RegisterSignal(parent, COMSIG_WOUND_EFFECTS, .proc/apply_effects)
	RegisterSignal(parent, COMSIG_WOUND_FLAGS_ADD, .proc/apply_flags)
	RegisterSignal(parent, COMSIG_WOUND_FLAGS_REMOVE, .proc/remove_flags)
	RegisterSignal(parent, COMSIG_WOUND_DAMAGE, .proc/apply_damage)
	RegisterSignal(parent, COMSIG_WOUND_AUTODOC, .proc/treatment)

	// Surgery
	RegisterSignal(src, COMSIG_ATTACKBY, .proc/apply_tool)

/datum/component/internal_wound/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_WOUND_EFFECTS)
	UnregisterSignal(parent, COMSIG_WOUND_FLAGS_ADD)
	UnregisterSignal(parent, COMSIG_WOUND_FLAGS_REMOVE)
	UnregisterSignal(parent, COMSIG_WOUND_DAMAGE)
	UnregisterSignal(parent, COMSIG_WOUND_AUTODOC)
	UnregisterSignal(src, COMSIG_ATTACKBY)

/datum/component/internal_wound/Process(delta_time)
	var/obj/item/organ/O = parent
	var/obj/item/organ/external/E = O.parent
	var/mob/living/carbon/human/H = O.owner

	if(O.status & ORGAN_DEAD)
		SSinternal_wounds.processing -= src
		return

	// Doesn't need to be inside someone to get worse
	if(can_progress)
		++current_progression_tick
		if(current_progression_tick >= progression_threshold)
			current_progression_tick = 0
			progress()

	if(!H)
		return

	// Chemical treatment handling
	var/is_treated = FALSE
	var/list/owner_ce = H.chem_effects
	for(var/chem_effect in owner_ce)
		var/to_remove = LAZYACCESS(treatments_chem, chem_effect)
		if(owner_ce[chem_effect] >= to_remove)
			owner_ce[chem_effect] -= to_remove
			is_treated = TRUE
			treatment(FALSE)
			break

	if(is_treated)
		return

	// Spread once
	if(can_spread)
		if(severity == spread_threshold)
			var/list/internal_organs_sans_parent = H.internal_organs.Copy() - O
			var/obj/item/organ/next_organ = pick(internal_organs_sans_parent)
			SEND_SIGNAL(next_organ, COMSIG_I_ORGAN_ADD_WOUND, type)

	if(!severity)
		return

	// Deal damage
	if(E && (tox_damage || oxy_damage || clone_damage || hal_damage))
		H.apply_damages(null, null, tox_damage * severity, oxy_damage * severity, clone_damage * severity, hal_damage * severity, E)

	if(psy_damage)
		H.apply_damage(psy_damage * severity, PSY)

	// Apply effects
	if(can_hallucinate)
		++current_hallucination_tick
		if(current_hallucination_tick >= ticks_per_hallucination && H.sanity)
			var/num = rand(1,4)
			switch(num)
				if(1)
					H.sanity.effect_emote()
				if(2)
					H.sanity.effect_quote()
				if(3)
					H.sanity.effect_sound()
				if(4)
					H.sanity.effect_hallucination()
			current_hallucination_tick = 0

/datum/component/internal_wound/proc/progress()
	if(!can_progress)
		return

	if(severity < severity_max)
		++severity
	else
		can_progress = FALSE
		if(next_wound && ispath(next_wound, /datum/component))
			var/chosen_wound_type = pick(typesof(next_wound))
			SEND_SIGNAL(parent, COMSIG_I_ORGAN_ADD_WOUND, chosen_wound_type)

	SEND_SIGNAL(parent, COMSIG_I_ORGAN_REFRESH_SELF)

/datum/component/internal_wound/proc/apply_tool(obj/item/I, mob/user)
	var/success = FALSE

	if(!I.tool_qualities || !LAZYLEN(I.tool_qualities))
		var/charges_needed = LAZYACCESS(treatments_item, I.type)
		var/can_treat = TRUE
		if(charges_needed)
			if(istype(I, /obj/item/stack))
				var/obj/item/stack/S = I
				if(!S.use(charges_needed))
					can_treat = FALSE
			if(can_treat && do_after(user, WORKTIME_NORMAL - user.stats.getStat(diagnosis_stat), parent))
				success = TRUE
	else
		for(var/tool_quality in treatments_tool)
			if(I.use_tool(user, parent, WORKTIME_NORMAL, tool_quality, treatments_tool[tool_quality], diagnosis_stat))
				success = TRUE
				break

	if(success)
		treatment(TRUE)

	if(user)
		if(success)
			to_chat(user, SPAN_NOTICE("You treat the [name] with \the [I]."))
		else
			to_chat(user, SPAN_WARNING("You cannot treat the [name] with \the [I]."))

	return success

/datum/component/internal_wound/proc/treatment(used_tool, used_autodoc = FALSE)
	if(severity > 0 && !used_tool)
		--severity
		can_progress = initial(can_progress)	// If it was turned off by reaching the max, turn it on again.
	else
		if(!used_autodoc && scar && ispath(scar, /datum/component))
			SEND_SIGNAL(parent, COMSIG_I_ORGAN_ADD_WOUND, scar)
		SEND_SIGNAL(parent, COMSIG_I_ORGAN_REMOVE_WOUND, src)

/datum/component/internal_wound/proc/apply_effects()
	var/obj/item/organ/internal/O = parent

	if(specific_organ_size_multiplier)
		O.specific_organ_size *= 1 + round(specific_organ_size_multiplier, 0.01)
	if(max_blood_storage_multiplier)
		O.max_blood_storage *= 1 - round(max_blood_storage_multiplier, 0.01)
	if(blood_req_multiplier)
		O.blood_req *= 1 + round(blood_req_multiplier, 0.01)
	if(nutriment_req_multiplier)
		O.nutriment_req *= 1 + round(nutriment_req_multiplier, 0.01)
	if(oxygen_req_multiplier)
		O.oxygen_req *= 1 + round(oxygen_req_multiplier, 0.01)

/datum/component/internal_wound/proc/apply_flags()
	var/obj/item/organ/internal/O = parent

	if(!O.parent)
		return

	if(status_flag)
		O.parent.status |= status_flag

/datum/component/internal_wound/proc/remove_flags()
	var/obj/item/organ/internal/O = parent

	if(!O.parent)
		return

	if(status_flag)
		O.parent.status &= ~status_flag

/datum/component/internal_wound/proc/apply_damage()
	if(!can_damage_organ)
		return

	var/obj/item/organ/internal/O = parent

	if(severity)
		O.damage += severity