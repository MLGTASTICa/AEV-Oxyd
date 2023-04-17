#define LEVEL_BELOW 0
#define LEVEL_TURF 0.2
#define LEVEL_LYING 0.3
#define LEVEL_LOWWALL 0.5
#define LEVEL_TABLE 0.6
#define LEVEL_STANDING 0.8
#define LEVEL_ABOVE 1

/// Pixels per turf
#define PPT 32
SUBSYSTEM_DEF(bullets)
	name = "Bullets"
	wait = 1
	priority = SS_PRIORITY_BULLETS
	init_order = INIT_ORDER_BULLETS

	var/list/datum/bullet_data/current_queue = list()
	var/list/datum/bullet_data/bullet_queue = list()

/// You might ask why use a bullet data datum, and not store all the vars on the bullet itself, honestly its to keep track and initialize firing relevant vars only when needed
/// This data is guaranteed to be of temporary use spanning 15-30 seconds or how long the bullet moves for. Putting them on the bullet makes each one take up more ram
/// And ram is not a worry , but its better to initialize less and do the lifting on fire.
/datum/bullet_data
	var/obj/item/projectile/referencedBullet = null
	var/aimedZone = ""
	var/atom/firer = null
	var/turf/firedTurf = null
	var/list/firedCoordinates = list(0,0,0)
	var/firedLevel = 0
	var/atom/target = null
	var/turf/targetTurf = null
	var/list/targetCoords = list(0,0,0)
	var/turf/currentTurf = null
	var/currentCoords = list(0,0,0)
	var/movementRatios = list(0,0,0,0)
	var/list/turf/coloreds = list()
	var/targetLevel = 0
	var/currentLevel = 0
	var/turfsPerTick = 0
	var/projectileAccuracy = 0
	var/lifetime = 10
	var/bulletLevel = 0

/datum/bullet_data/New(atom/referencedBullet, aimedZone, atom/firer, atom/target, list/targetCoords, turfsPerTick, projectileAccuracy, lifetime)
	src.referencedBullet = referencedBullet
	src.currentTurf = get_turf(referencedBullet)
	src.currentCoords = list(referencedBullet.pixel_x, referencedBullet.pixel_y)
	src.aimedZone = aimedZone
	src.firer = firer
	src.firedTurf = get_turf(firer)
	src.target = target
	src.targetTurf = get_turf(target)
	//src.targetCoords = targetCoords
	src.targetCoords = list(8,8)
	src.turfsPerTick = turfsPerTick
	src.projectileAccuracy = projectileAccuracy
	src.lifetime = lifetime
	if(ismob(firer))
		if(iscarbon(firer))
			if(firer:lying)
				src.firedLevel = LEVEL_LYING
			else
				src.firedLevel = LEVEL_STANDING
		else
			src.firedLevel = LEVEL_STANDING
	else
		src.firedLevel = LEVEL_STANDING
	if(ismob(target))
		if(iscarbon(target))
			if(target:lying)
				src.targetLevel = LEVEL_LYING
			else
				src.targetLevel = LEVEL_STANDING
		else
			src.targetLevel = LEVEL_STANDING
	else if(istype(target, /obj/structure/low_wall))
		src.targetLevel = LEVEL_LOWWALL
	else if(istype(target, /obj/structure/window))
		src.targetLevel = LEVEL_STANDING
	else if(istype(target, /obj/structure/table))
		src.targetLevel = LEVEL_TABLE
	else if(iswall(target))
		src.targetLevel = LEVEL_STANDING
	else if(isturf(target))
		src.targetLevel = LEVEL_TURF
	else if(isitem(target))
		src.targetLevel = LEVEL_TURF
	src.firedCoordinates[1] = 8
	src.firedCoordinates[2] = 8
	src.firedCoordinates[3] = referencedBullet.z
	updateCoordinateRatio()
	SSbullets.bullet_queue += src

/// I hate trigonometry, but i hate ATAN2 more.
/datum/bullet_data/proc/updateCoordinateRatio()
	var/list/coordinates = list(0,0,0)
	// These add 0.0001 so in the case we are firing straight we don't have to handle special cases(division by 0)
	// The 0.0001 are meaningless overall considering the scale of calculation.
	coordinates[1] = ((targetTurf.x - firedTurf.x) * PPT + targetCoords[1] - firedCoordinates[1]) / PPT + 0.0001
	coordinates[2] = ((targetTurf.y - firedTurf.y) * PPT + targetCoords[2] - firedCoordinates[2]) / PPT + 0.0001
	var/r = sqrt(coordinates[1] ** 2 + coordinates[2] ** 2)
	// [1] is X ratio , [2] is Y ratio,  [3] is Z-ratio
	movementRatios = list(coordinates[1]/r, coordinates[2]/r, (targetCoords[3] - firedLevel[3])/r + firedLevel - targetLevel)

/datum/bullet_data/proc/updateLevel()
	switch(currentCoords[3])
		if(-INFINITY to LEVEL_BELOW)
			currentLevel = LEVEL_BELOW
		if(LEVEL_BELOW to LEVEL_TURF)
			currentLevel = LEVEL_TURF
		if(LEVEL_TURF to LEVEL_LYING)
			currentLevel = LEVEL_LYING
		if(LEVEL_LYING to LEVEL_LOWWALL)
			currentLevel = LEVEL_LOWWALL
		if(LEVEL_LOWWALL to LEVEL_TABLE)
			currentLevel = LEVEL_TABLE
		if(LEVEL_TABLE to LEVEL_STANDING)
			currentLevel = LEVEL_STANDING
		if(LEVEL_STANDING to INFINITY)
			currentLevel = LEVEL_ABOVE

/datum/controller/subsystem/bullets/fire(resumed)
	if(!resumed)
		current_queue = bullet_queue.Copy()
	for(var/datum/bullet_data/bullet in current_queue)
		current_queue -= bullet
		if(!istype(bullet.referencedBullet, /obj/item/projectile/bullet))
			bullet_queue -= bullet
			continue
		var/px = bullet.movementRatios[1] * bullet.turfsPerTick + bullet.currentCoords[1]
		var/py = bullet.movementRatios[2] * bullet.turfsPerTick + bullet.currentCoords[2]
		var/pz = bullet.movementRatios[3] * bullet.turfsPerTick + bullet.currentCoords[3]
		var/x_change = 0
		var/y_change = 0
		var/z_change = 0
		var/turf/target_turf
		while(px >= PPT/2 || py >= PPT/2 || px <= -PPT/2 || py <= -PPT/2 || pz != bullet.currentCoords[3])
			message_admins("Moving [bullet.referencedBullet], y = [round(py/PPT)], py = [py], x = [round(px/PPT)], px = [px]")
			if(QDELETED(bullet.referencedBullet))
				break
			x_change = px >= PPT/2 ? 1 : px <= -PPT/2 ? -1 : 0
			y_change = py >= PPT/2 ? 1 : py <= -PPT/2 ? -1 : 0
			if(round(pz) > bullet.currentCoords[3])
				z_change = 1
			else if(round(pz) < round(bullet.currentCoords[3]))
				z_change = -1
			px += -1 * x_change * PPT/2
			py += -1 * y_change * PPT/2
			pz += z_change
			target_turf = locate(bullet.referencedBullet.x + x_change, bullet.referencedBullet.y + y_change, bullet.referencedBullet.z + z_change)
			bullet.updateLevel()
			bullet.referencedBullet.Move(target_turf)
			bullet.coloreds |= target_turf
			target_turf.color = "#2fff05ee"


		bullet.currentCoords[1] = px
		bullet.currentCoords[2] = py
		bullet.currentCoords[3] = pz
		bullet.referencedBullet.pixel_x = round(bullet.currentCoords[1])
		bullet.referencedBullet.pixel_y = round(bullet.currentCoords[2])
		if(QDELETED(bullet.referencedBullet))
			bullet_queue -= bullet
			for(var/turf/thing in bullet.coloreds)
				thing.color = initial(thing.color)
#undef LEVEL_BELOW
#undef LEVEL_TURF
#undef LEVEL_LYING
#undef LEVEL_LOWWALL
#undef LEVEL_TABLE
#undef LEVEL_STANDING
#undef LEVEL_ABOVE

