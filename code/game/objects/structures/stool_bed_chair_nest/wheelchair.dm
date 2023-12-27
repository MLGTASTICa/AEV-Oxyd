/obj/structure/bed/chair/wheelchair
	name = "wheelchair"
	desc = "Now we're getting somewhere."
	icon_state = "wheelchair"
	anchored = FALSE
	buckle_movable = 1

	var/driving = 0
	var/mob/living/pulling = null
	var/bloodiness

/obj/structure/bed/chair/wheelchair/Initialize()
	. = ..()
	AddComponent(/datum/component/buckling, buckleFlags = BUCKLE_FORCE_STAND | BUCKLE_MOB_ONLY | BUCKLE_REQUIRE_NOT_BUCKLED | BUCKLE_MOVE_RELAY | BUCKLE_FORCE_DIR | BUCKLE_BREAK_ON_FALL, moveProc = PROC_REF(onMoveAttempt))

/obj/structure/bed/chair/wheelchair/proc/onMoveAttempt(mob/living/trier, direction)
	SIGNAL_HANDLER
	. = COMSIG_CANCEL_MOVE
	if(!istype(trier))
		return
	if(trier.incapacitated(INCAPACITATION_CANT_ACT))
		return
	if(trier.next_click > world.time)
		return
	trier.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	step(src, direction)
	trier.dir = src.dir

/obj/structure/bed/chair/wheelchair/update_icon()
	return

/obj/structure/bed/chair/wheelchair/set_dir()
	..()
	overlays.Cut()
	var/image/O = image(icon = 'icons/obj/furniture.dmi', icon_state = "w_overlay", dir = src.dir)
	O.layer = ABOVE_MOB_LAYER
	overlays += O
	if(buckled_mob)
		buckled_mob.set_dir(dir)

/obj/structure/bed/chair/wheelchair/attackby(obj/item/I, mob/living/user)
	if((QUALITY_BOLT_TURNING in I.tool_qualities) || (QUALITY_WIRE_CUTTING in I.tool_qualities) || istype(I, /obj/item/stack))
		return
	..()

/obj/structure/bed/chair/wheelchair/relaymove(mob/user, direction)
	// Redundant check?
	if(user.incapacitated(INCAPACITATION_DISABLED | INCAPACITATION_RESTRAINED))
		if(user.grabbedBy.assailant == src)
			QDEL_NULL(user.grabbedBy)
			to_chat(user, SPAN_WARNING("You lost your grip!"))
		return

	if(buckled_mob && pulling && user == buckled_mob)
		if(pulling.incapacitated(INCAPACITATION_DISABLED | INCAPACITATION_RESTRAINED))
			QDEL_NULL(pulling.grabbedBy)
			pulling = null
	if(user == pulling)
		pulling = null
		QDEL_NULL(user.grabbedBy)
		return
	if(propelled)
		return
	if(pulling && (get_dir(src.loc, pulling.loc) == direction))
		to_chat(user, SPAN_WARNING("You cannot go there."))
		return
	if(pulling && buckled_mob && (buckled_mob == user))
		to_chat(user, SPAN_WARNING("You cannot drive while being pushed."))
		return

	// Let's roll
	driving = 1
	var/turf/T = null
	//--1---Move occupant---1--//
	if(buckled_mob)
		buckled_mob.buckled = null
		step(buckled_mob, direction)
		buckled_mob.buckled = src
	//--2----Move driver----2--//
	if(pulling)
		T = pulling.loc
		if(get_dist(src, pulling) >= 1)
			step(pulling, get_dir(pulling.loc, src.loc))
	//--3--Move wheelchair--3--//
	step(src, direction)
	if(buckled_mob) // Make sure it stays beneath the occupant
		Move(buckled_mob.loc)
	set_dir(direction)
	if(pulling) // Driver
		if(pulling.loc == src.loc) // We moved onto the wheelchair? Revert!
			pulling.forceMove(T)
		else
			if(get_dist(src, pulling) > 1) // We are too far away? Losing control.
				QDEL_NULL(user.grabbedBy)
				pulling = null
			pulling.set_dir(get_dir(pulling, src)) // When everything is right, face the wheelchair
	if(bloodiness)
		create_track()
	driving = 0

/obj/structure/bed/chair/wheelchair/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0, glide_size_override = 0, initiator = src)
	. = ..()
	if(buckled_mob)
		var/mob/living/occupant = buckled_mob
		if(!driving)
			if (occupant && (src.loc != occupant.loc))
				if (propelled)
					for (var/mob/O in src.loc)
						if (O != occupant)
							Bump(O)
				/*
				else
					unbuckle_mob()
				*/
			if (pulling && (get_dist(src, pulling) > 1))
				QDEL_NULL(pulling.grabbedBy)
				to_chat(pulling,  SPAN_WARNING("You lost your grip!"))
				pulling = null
		else
			if (occupant && (src.loc != occupant.loc))
				src.forceMove(occupant.loc) // Failsafe to make sure the wheelchair stays beneath the occupant after driving

/obj/structure/bed/chair/wheelchair/CtrlClick(var/mob/user)
	if(in_range(src, user))
		if(!ishuman(user))	return
		if(user == buckled_mob)
			to_chat(user, SPAN_WARNING("You realize you are unable to push the wheelchair you're sitting in."))
			return
		if(!pulling)
			pulling = user
			var/obj/item/grab/g = new(user, src)
			g.state = GRAB_PASSIVE
			user.put_in_active_hand(g)
			g.synch()
			user.set_dir(get_dir(user, src))
			to_chat(user, "You grip \the [name]'s handles.")
		else
			to_chat(user, "You let go of \the [name]'s handles.")
			QDEL_NULL(pulling.grabbedBy)
			pulling = null
		return

/obj/structure/bed/chair/wheelchair/Bump(atom/A)
	..()
	if(!buckled_mob)	return

	if(propelled || (pulling && (pulling.a_intent == I_HURT)))
		var/mob/living/occupant = null //unbuckle_mob()

		if (pulling && (pulling.a_intent == I_HURT))
			occupant.throw_at(A, 3, 3, pulling)
		else if (propelled)
			occupant.throw_at(A, 3, 3, propelled)

		var/def_zone = ran_zone()

		occupant.throw_at(A, 3, propelled)
		occupant.apply_effect(6, STUN, occupant.getarmor(def_zone, ARMOR_BLUNT))
		occupant.apply_effect(6, WEAKEN, occupant.getarmor(def_zone, ARMOR_BLUNT))
		occupant.apply_effect(6, STUTTER, occupant.getarmor(def_zone, ARMOR_BLUNT))
		occupant.damage_through_armor(list(ARMOR_BLUNT=list(DELEM(BRUTE,6))), def_zone, src, 1, 1, FALSE)

		playsound(src.loc, 'sound/weapons/punch1.ogg', 50, 1, -1)

		if(isliving(A))

			var/mob/living/victim = A
			def_zone = ran_zone()

			victim.apply_effect(6, STUN, victim.getarmor(def_zone, ARMOR_BLUNT))
			victim.apply_effect(6, WEAKEN, victim.getarmor(def_zone, ARMOR_BLUNT))
			victim.apply_effect(6, STUTTER, victim.getarmor(def_zone, ARMOR_BLUNT))
			victim.damage_through_armor(list(ARMOR_BLUNT=list(DELEM(BRUTE,6))), def_zone, src, 1, 1, FALSE)

		if(pulling)
			occupant.visible_message(SPAN_DANGER("[pulling] has thrusted \the [name] into \the [A], throwing \the [occupant] out of it!"))
			admin_attack_log(pulling, occupant, "Crashed their victim into \an [A].", "Was crashed into \an [A].", "smashed into \the [A] using")
		else
			occupant.visible_message(SPAN_DANGER("[occupant] crashed into \the [A]!"))

/obj/structure/bed/chair/wheelchair/proc/create_track()
	var/obj/effect/decal/cleanable/blood/tracks/B = new(loc)
	var/newdir = get_dir(get_step(loc, dir), loc)
	if(newdir == dir)
		B.set_dir(newdir)
	else
		newdir = newdir | dir
		if(newdir == 3)
			newdir = 1
		else if(newdir == 12)
			newdir = 4
		B.set_dir(newdir)
	bloodiness--

/proc/equip_wheelchair(mob/living/carbon/human/H) //Proc for spawning in a wheelchair if a new character has no legs. Used in new_player.dm
	var/obj/structure/bed/chair/wheelchair/W = new(H.loc)
	// W.buckle_mob(H)

/obj/item/wheelchair
	name = "wheelchair"
	desc = "A folded wheelchair that can be carried around."
	icon = 'icons/obj/furniture.dmi'
	icon_state = "wheelchair_folded"
	volumeClass = ITEM_SIZE_HUGE
	var/obj/structure/bed/chair/wheelchair/unfolded

/obj/item/wheelchair/attack_self(mob/user)
	if(unfolded)
		unfolded.forceMove(get_turf(src))
	else
		new/obj/structure/bed/chair/wheelchair(get_turf(src))
	qdel(src)

/obj/structure/bed/chair/wheelchair/MouseDrop(over_object, src_location, over_location)
	..()
	if(over_object == usr && Adjacent(usr))
		if(!ishuman(usr) || usr.incapacitated())
			return
		if(buckled_mob)
			return 0
		if(pulling)
			return 0 // You can't fold a wheelchair when somebody holding the handles.
		visible_message("[usr] collapses \the [src.name].")
		var/obj/item/wheelchair/R = new/obj/item/wheelchair(get_turf(src))
		R.name = src.name
		R.color = src.color
		R.unfolded = src
		src.forceMove(R)
		return
