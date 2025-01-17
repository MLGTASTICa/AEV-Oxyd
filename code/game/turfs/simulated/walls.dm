/turf/simulated/wall
	name = "wall"
	desc = "A huge chunk of metal used to seperate rooms."
	description_info = "Can be deconstructed by welding"
	description_antag = "Deconstructing these will leave fingerprints. C4 or Thermite leave none"
	icon = 'icons/turf/wall_masks.dmi'
	icon_state = "generic"
	layer = CLOSED_TURF_LAYER
	opacity = 1
	density = TRUE
	blocks_air = 1
	thermal_conductivity = WALL_HEAT_TRANSFER_COEFFICIENT
	heat_capacity = 312500 //a little over 5 cm thick , 312500 for 1 m by 2.5 m by 0.25 m plasteel wall

	var/ricochet_id = 0
	var/health = 0
	var/maxHealth = 0
	var/damage_overlay = 0
	var/active
	var/can_open = 0
	var/material/material
	var/material/reinf_material
	var/last_state
	var/construction_stage
	var/hitsound = 'sound/weapons/Genhit.ogg'
	var/list/wall_connections = list("0", "0", "0", "0")

	/*
		If set, these vars will be used instead of the icon base taken from the material.
		These should be set at authortime
		Currently, they can only be set at authortime, on specially coded wall variants

		In future we should add some way to create walls of specific styles. Possibly during the construction process
	*/
	var/icon_base_override = ""
	var/icon_base_reinf_override = ""
	var/base_color_override = ""
	var/reinf_color_override = ""

	//These will be set from the set_material function. It just caches which base we're going to use, to simplify icon updating logic.
	//These should not be set at compiletime, they will be overwritten
	var/icon_base = ""
	var/icon_base_reinf = ""
	var/base_color = ""
	var/reinf_color = ""

	var/static/list/damage_overlays
	is_wall = TRUE

// Walls always hide the stuff below them.
/turf/simulated/wall/levelupdate()
	for(var/obj/O in src)
		O.hide(TRUE)
		SEND_SIGNAL_OLD(O, COMSIG_TURF_LEVELUPDATE, TRUE)

/turf/simulated/wall/New(newloc, materialtype, rmaterialtype)
	if (!damage_overlays)
		damage_overlays = new

		var/overlayCount = 16
		var/alpha_inc = 256 / overlayCount

		for(var/i = 0; i <= overlayCount; i++)
			var/image/img = image(icon = 'icons/turf/walls.dmi', icon_state = "overlay_damage")
			img.blend_mode = BLEND_MULTIPLY
			img.alpha = (i * alpha_inc) - 1
			damage_overlays.Add(img)


	icon_state = "blank"
	if(!materialtype)
		materialtype = MATERIAL_STEEL
	material = get_material_by_name(materialtype)
	if(!isnull(rmaterialtype))
		reinf_material = get_material_by_name(rmaterialtype)
	update_material(FALSE) //We call update material with update set to false, so it won't update connections or icon yet
	..(newloc)


/turf/simulated/wall/Initialize(mapload)
	..()

	if (mapload)
		//We defer icon updates to late initialize at roundstart
		return INITIALIZE_HINT_LATELOAD

	else
		//If we get here, this wall was built during the round
		//We'll update its connections and icons as normal
		update_connections(TRUE)
		update_icon()


/turf/simulated/wall/LateInitialize()
	//If we get here, this wall was mapped in at roundstart
	update_connections(FALSE)
	/*We set propagate to false when updating connections at roundstart
	This ensures that each wall will only update itself, once.
	*/

	update_icon()

/turf/simulated/wall/proc/projectileBounceCheck(obj/item/projectile/incoming)
	return TRUE

/turf/simulated/wall/Destroy()
	STOP_PROCESSING(SSturf, src)
	dismantle_wall(null,null,1)
	. = ..()

/turf/simulated/wall/Process(wait, times_fired)
	// Calling parent will kill processing
	var/how_often = max(round(2 SECONDS / wait), 1)
	if(times_fired % how_often)
		return //We only work about every 2 seconds
	if(!radiate())
		return PROCESS_KILL

/turf/simulated/wall/bullet_act(obj/item/projectile/hittingProjectile)
	var/projectileDamage = hittingProjectile.get_structure_damage()
	if(istype(hittingProjectile,/obj/item/projectile/beam))
		burn(500)//TODO : fucking write these two procs not only for plasma (see plasma in materials.dm:283) ~
	else if(istype(hittingProjectile,/obj/item/projectile/ion))
		burn(500)
	else if(istype(hittingProjectile,/obj/item/projectile/bullet))
		var/list/lastMoves = hittingProjectile.dataRef.lastChanges
		var/angle = hittingProjectile.dataRef.movementRatios[4]
		var/ricochet = FALSE
		message_admins("Bullet hit wall at [angle]")
		switch(angle)
			if(-180 to -155)
				if((abs(lastMoves[2]) >= abs(lastMoves[1]))  && abs(lastMoves[1]))
					hittingProjectile.dataRef.bounce(1)
					ricochet = TRUE
			if(-115 to -65)
				if((abs(lastMoves[1]) >= abs(lastMoves[2]))  && abs(lastMoves[2]))
					hittingProjectile.dataRef.bounce(2)
					ricochet = TRUE
			if(-25 to 25)
				if((abs(lastMoves[2]) >= abs(lastMoves[1])) && abs(lastMoves[1]))
					hittingProjectile.dataRef.bounce(1)
					ricochet = TRUE
			if(65 to 115)
				if((abs(lastMoves[1]) >= abs(lastMoves[2]))  && abs(lastMoves[2]))
					hittingProjectile.dataRef.bounce(2)
					ricochet = TRUE
			if(155 to 180)
				if((abs(lastMoves[2]) >= abs(lastMoves[1]))  && abs(lastMoves[1]))
					hittingProjectile.dataRef.bounce(1)
					ricochet = TRUE
		if(ricochet)
			message_admins("Ricochet!")
			take_damage(round(projectileDamage * 0.33))
			return PROJECTILE_CONTINUE

	take_damage(projectileDamage)
	if(health < maxHealth * 0.4 && prob(projectileDamage))
		var/obj/item/trash/material/metal/slug = new(get_turf(hittingProjectile))
		slug.matter.Cut()
		slug.matter[reinf_material ? reinf_material.name : material.name] = 0.1
		slug.throw_at(get_turf(hittingProjectile), 0, 1)

	hittingProjectile.on_hit(src)

/turf/simulated/wall/hitby(AM as mob|obj, var/speed=THROWFORCE_SPEED_DIVISOR)
	..()
	if(ismob(AM))
		return

	var/tforce = AM:throwforce * (speed/THROWFORCE_SPEED_DIVISOR)
	if (tforce < 15)
		return

	take_damage(tforce)


/turf/simulated/wall/proc/clear_plants()
	for(var/obj/effect/overlay/wallrot/WR in src)
		qdel(WR)
	for(var/obj/effect/plant/plant in range(src, 1))
		if(plant.wall_mount == src) //shrooms drop to the floor
			qdel(plant)
		plant.update_neighbors()

/turf/simulated/wall/ChangeTurf(var/newtype)
	clear_plants()
	clear_bulletholes()
	..(newtype)

//Appearance
/turf/simulated/wall/examine(mob/user)
	var/description = ""
	if(health == maxHealth)
		description += SPAN_NOTICE("It looks fully intact.")
	else
		var/hratio = health / maxHealth
		if(hratio <= 0.3)
			description += SPAN_WARNING("It looks heavily damaged.")
		else if(hratio <= 0.6)
			description += SPAN_WARNING("It looks moderately damaged.")
		else
			description += SPAN_DANGER("It looks lightly damaged.")

	if(locate(/obj/effect/overlay/wallrot) in src)
		description += SPAN_WARNING("\n There is fungus growing on [src].")

	..(user, afterDesc = description)

//health

/turf/simulated/wall/melt()

	if(!can_melt())
		return

	src.ChangeTurf(/turf/simulated/floor/plating)

	var/turf/simulated/floor/F = src
	if(!F)
		return
	F.burn_tile()
	F.icon_state = "wall_thermite"
	visible_message(SPAN_DANGER("\The [src] spontaneously combusts!")) //!!OH SHIT!!
	return

/turf/simulated/wall/take_damage(damage)
	if(locate(/obj/effect/overlay/wallrot) in src)
		damage *= 10
	. = health - damage < 0 ? damage - (damage - health) : damage
	health -= damage
	if(health <= 0)
		var/leftover = abs(health)
		if (leftover > 150)
			dismantle_wall(no_product = TRUE)
		else
			dismantle_wall()
		// because we can do changeTurf and lose the var
		return
	update_icon()
	return

/turf/simulated/wall/explosion_act(target_power, explosion_handler/handler)
	var/absorbed = take_damage(target_power)
	// All health has been blocked
	if(absorbed == target_power)
		return target_power
	return absorbed + ..(target_power - absorbed)

/turf/simulated/wall/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)//Doesn't fucking work because walls don't interact with air :(
	burn(exposed_temperature)

/turf/simulated/wall/adjacent_fire_act(turf/simulated/floor/adj_turf, datum/gas_mixture/adj_air, adj_temp, adj_volume)
	burn(adj_temp)
	if(adj_temp > material.melting_point)
		take_damage(log(RAND_DECIMAL(0.9, 1.1) * (adj_temp - material.melting_point)))

	return ..()

/turf/simulated/wall/proc/dismantle_wall(devastated, explode, no_product, mob/user)
	playsound(src, 'sound/items/Welder.ogg', 100, 1)
	if(!no_product)
		if(reinf_material)
			reinf_material.place_dismantled_girder(src, reinf_material)
		else
			material.place_dismantled_girder(src)
		var/obj/sheets = material.place_sheet(src, amount=3)
		sheets.add_fingerprint(user)

	for(var/obj/O in src.contents) //Eject contents!
		if(istype(O,/obj/item/contraband/poster))
			var/obj/item/contraband/poster/P = O
			P.roll_and_drop(src)
		else
			O.forceMove(src)

	clear_plants()
	clear_bulletholes()
	material = get_material_by_name("placeholder")
	reinf_material = null
	update_connections(1)

	ChangeTurf(/turf/simulated/floor/plating)

/turf/simulated/wall/proc/can_melt()
	if(material.flags & MATERIAL_UNMELTABLE)
		return 0
	return 1

/turf/simulated/wall/proc/thermitemelt(mob/user)
	if(!can_melt())
		return
	var/obj/effect/overlay/O = new/obj/effect/overlay(src)
	O.name = "Thermite"
	O.desc = "Looks hot."
	O.icon = 'icons/effects/fire.dmi'
	O.icon_state = "2"
	O.anchored = TRUE
	O.density = TRUE
	O.layer = 5

	src.ChangeTurf(/turf/simulated/floor/plating)

	var/turf/simulated/floor/F = src
	F.burn_tile()
	F.icon_state = "wall_thermite"
	to_chat(user, SPAN_WARNING("The thermite starts melting through the wall."))

	spawn(100)
		if(O)
			qdel(O)
//	F.sd_LumReset()		//TODO: ~Carn
	return

/turf/simulated/wall/proc/radiate()
	var/total_radiation = material.radioactivity + (reinf_material ? reinf_material.radioactivity / 2 : 0)
	if(!total_radiation)
		return

	for(var/mob/living/L in range(3,src))
		L.apply_effect(total_radiation, IRRADIATE,0)
	return total_radiation

/turf/simulated/wall/proc/burn(temperature)
	if(material.combustion_effect(src, temperature, 0.7))//it wont return something in any way, this proc is commented and it belongs to plasma material.(see materials.dm:283)
		spawn(2)
			new /obj/structure/girder(src)
			src.ChangeTurf(/turf/simulated/floor)
			for(var/turf/simulated/wall/W in RANGE_TURFS(3, src) - src)
				W.burn((temperature/4))
			for(var/obj/machinery/door/airlock/plasma/D in range(3,src))
				D.ignite(temperature/4)
