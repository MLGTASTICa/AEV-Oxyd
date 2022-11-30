//NOTE: THESE ARE ALL PARALLEL SO THEY WILL NOT RUN SIMULTANEOUSLY
/datum/storyevent/bluespace_storm
	id = "bluespace_storm"
	name = "Bluespace storm"
	weight = 0.8
	event_type = /datum/event/bluespace_storm
	parallel = FALSE
	event_pools = list(EVENT_LEVEL_MUNDANE = POOL_THRESHOLD_MUNDANE, EVENT_LEVEL_MODERATE = POOL_THRESHOLD_MODERATE)
	tags = list(TAG_SCARY, TAG_NEGATIVE)

/datum/event/bluespace_storm
	startWhen = 1
	announceWhen = 5
	endWhen = 350 //these 350 are failsafes in case setup() SOMEHOW fucks up

/datum/event/bluespace_storm/setup()
	endWhen = rand(300, 600)

/datum/event/bluespace_storm/announce()
	command_announcement.Announce("The scanners have detected a bluespace storm near the ship. Bluespace distortions are likely to happen while it lasts.", "Bluespace Storm")

/datum/event/bluespace_storm/end()
	command_announcement.Announce("The bluespace storm has ended.", "Bluespace Storm")

/datum/event/bluespace_storm/tick()
	if(prob(2))
		var/area/A = random_ship_area(filter_maintenance = TRUE, filter_critical = TRUE)
		bluespace_distorsion(A.random_space())

/datum/storyevent/ion_blizzard
	id = "ion_blizzard"
	name = "Ion blizzard"
	weight = 0.9
	event_type = /datum/event/ion_blizzard
	parallel = FALSE
	event_pools = list(EVENT_LEVEL_MUNDANE = POOL_THRESHOLD_MUNDANE, EVENT_LEVEL_MODERATE = POOL_THRESHOLD_MODERATE)
	tags = list(TAG_SCARY, TAG_NEGATIVE)

/datum/event/ion_blizzard
	startWhen = 1
	announceWhen = 3
	endWhen = 350

/datum/event/ion_blizzard/setup()
	endWhen = rand(300, 600)

/datum/event/ion_blizzard/announce()
	command_announcement.Announce("A severe ion storm has been detected near the ship. Lighting subsystems are currently overloaded and may not work properly.", "Ion Blizzard")

/datum/event/ion_blizzard/end()
	command_announcement.Announce("The ion blizzard has ended.", "Ion Blizzard")

/datum/event/ion_blizzard/tick() //get random ship area and do things to all light in there
	if(prob(10)) //don't check every single light every single tick jesus christ
		for(var/obj/machinery/light/L in random_ship_area())
			L.broken()
	else if(prob(80))
		for(var/obj/machinery/light/L in random_ship_area())
			L.flick_light(rand(2,5))

/datum/storyevent/photon_vortex
	id = "photon_vortex"
	name = "Photon vortex"
	weight = 0.9
	event_type = /datum/event/photon_vortex
	parallel = FALSE
	event_pools = list(EVENT_LEVEL_MUNDANE = POOL_THRESHOLD_MUNDANE, EVENT_LEVEL_MODERATE = POOL_THRESHOLD_MODERATE)
	tags = list(TAG_SCARY, TAG_NEGATIVE)

/datum/event/photon_vortex
	startWhen = 1
	announceWhen = 2
	endWhen = 350

/datum/event/photon_vortex/setup()
	endWhen = rand(300, 800)

/datum/event/photon_vortex/start()
	for(var/obj/item/device/lighting/L in world)
		L.brightness_on = L.brightness_on / 4
		L.update_icon()
	for(var/area/area as anything in ship_areas)
		for(var/obj/structure/cyberplant/c in area)
			c.brightness_on = c.brightness_on / 2
			c.doInterference()
		for(var/obj/machinery/light/l in area)
			l.brightness_range = l.brightness_range / 3
			l.brightness_power = l.brightness_power / 2
			l.update()

/datum/event/photon_vortex/announce()
	command_announcement.Announce("A photon vortex anomaly has been detected near the ship. All photon-emitting machinery gives much less light.", "Photon Vortex Anomaly")

/datum/event/photon_vortex/end()
	command_announcement.Announce("The photon vortex anomaly has moved away from the ship.", "Photon Vortex Anomaly")

	for(var/obj/item/device/lighting/L in world)
		L.brightness_on = initial(L.brightness_on)
		L.update_icon()
	for(var/area/area as anything in ship_areas)
		for(var/obj/structure/cyberplant/c in area)
			c.brightness_on = initial(c.brightness_on)
			c.doInterference()
		for(var/obj/machinery/light/l in area)
			l.brightness_range = initial(l.brightness_range)
			l.brightness_power = initial(l.brightness_power)
			l.update()

/datum/storyevent/harmonic_feedback
	id = "harmonic_feedback_surge"
	name = "Harmonic feedback surge anomaly"
	weight = 0.5
	event_type = /datum/event/harmonic_feedback
	parallel = FALSE
	event_pools = list(EVENT_LEVEL_MUNDANE = POOL_THRESHOLD_MUNDANE, EVENT_LEVEL_MODERATE = POOL_THRESHOLD_MODERATE)
	tags = list(TAG_DESTRUCTIVE, TAG_NEGATIVE)

/datum/event/harmonic_feedback
	startWhen = 1
	announceWhen = 3
	endWhen = 350

/datum/event/harmonic_feedback/setup()
	endWhen = rand(300, 450)

/datum/event/harmonic_feedback/announce()
	command_announcement.Announce("The ship is currently passing through intense gravitational wavefronts. They will heavily disrupt hull shields for a short duration.", "Harmonic Feedback Surge Anomaly")

/datum/event/harmonic_feedback/end()
	command_announcement.Announce("The gravitational wavefronts have passed.", "Harmonic Feedback Surge Anomaly")

/datum/event/harmonic_feedback/tick() //around two seconds
	for(var/obj/machinery/power/shield_generator/G in GLOB.machines)
		G.take_damage(10, SHIELD_DAMTYPE_EM)

/datum/storyevent/micro_debris
	id = "micro_debris"
	name = "micro debris field"
	weight = 0.9
	parallel = FALSE
	event_type = /datum/event/micro_debris
	event_pools = list(EVENT_LEVEL_MUNDANE = POOL_THRESHOLD_MUNDANE, EVENT_LEVEL_MODERATE = POOL_THRESHOLD_MODERATE)
	tags = list(TAG_DESTRUCTIVE, TAG_NEGATIVE)

/datum/event/micro_debris
	startWhen	= 1
	announceWhen = 2
	endWhen		= 60
	var/list/debris_types = list(
		/obj/effect/meteor/dust/glass=40,\
		/obj/effect/meteor/dust/rods=30,\
		/obj/effect/meteor/dust/metal=20,\
		/obj/effect/meteor/dust/ice=10
	)

/datum/event/micro_debris/announce()
	command_announcement.Announce("The ship is now passing through a micro debris field.", "Micro Debris Field Alert")

/datum/event/micro_debris/end()
	command_announcement.Announce("The ship has now passed through the micro debris field.", "Micro Debris Field Notice")

/datum/event/micro_debris/tick()
	if(prob(30))
		for(var/i in 0 to rand(1,3))
			spawn_debris(pickweight(debris_types), pick(cardinal), pick(GLOB.maps_data.station_levels))

/datum/event/micro_debris/proc/spawn_debris(debris, start_side, zlevel)
	var/turf/start_turf = spaceDebrisStartLoc(start_side, zlevel)
	var/turf/destination = spaceDebrisFinishLoc(start_side, zlevel)
	var/obj/effect/meteor/M = new debris(start_turf)
	M.dest = destination
	walk_towards(M, M.dest, 1)
	return

/datum/storyevent/graveyard
	id = "graveyard"
	name = "Space Graveryard"
	weight = 0.6
	parallel = FALSE
	event_type = /datum/event/graveyard
	event_pools = list(EVENT_LEVEL_MUNDANE = POOL_THRESHOLD_MUNDANE, EVENT_LEVEL_MODERATE = POOL_THRESHOLD_MODERATE)
	tags = list(TAG_SCARY, TAG_NEGATIVE)

/datum/event/graveyard
	startWhen = 1
	announceWhen = 3
	endWhen = 350

/datum/event/graveyard/setup()
	endWhen = rand(300, 600)

/datum/event/graveyard/start()
	GLOB.GLOBAL_SANITY_MOD = 1.5

/datum/event/graveyard/announce()
	command_announcement.Announce("Drifting wrecks of a space station have been detected near the ship. Telecommunication systems are not responsible for any strain on the crew's psychological wellbeing.", "Space Graveyard")

/datum/event/graveyard/tick()
	if(prob(5)) //random broadcasts
		var/message = pick("They are ", "He is ", "All of them are ", "I'm ", "We are ")
		message += pick("going to die... ", "about to turn into those spider mutants... ", "being forcefully converted... ")
		message += pick("Run while you still can.", "Help!", "Angels bless our souls...", "It's... too late.")

		global_announcer.autosay(message, "Emergency Broadcast")
	else if(prob(5)) //predetermined broadcasts
		var/message_list = list(
			"Blessed Angels, guide us to safety!",
			"Comrades, we have captured the last survivors on this wreck. Expecting extraction at-",
			"Whoever hears this, RUN WHILE YOU STILL CAN!",
			"We are barely managing to keep this place safe. Please, whoever recieves this signal, pick us up at-",
			"Our food and water supplies are going to run out soon. We have money. Just help us, anyone, please...",
			"Security is... All gone. With medical bay soon to follow. These abominations know nothing but hunger, consumed most of our crew, and yet they remain unsatiated... Do not try to help in any way. This station is a lost cause."
		)

		global_announcer.autosay(pick(message_list), "Emergency Broadcast")
	else if(prob(1)) //sekrit stuf
		global_announcer.autosay("Man, all those people really suck. Just don't get hit and beat everything until it dies.", "Emergency Broadcast")

/datum/event/graveyard/end()
	command_announcement.Announce("The station wrecks have moved away from the ship.", "Space Graveyard")
	GLOB.GLOBAL_SANITY_MOD = 1

/datum/storyevent/nebula
	id = "nebula"
	name = "Dark matter nebula"
	weight = 0.8
	parallel = FALSE
	event_type = /datum/event/nebula
	event_pools = list(EVENT_LEVEL_MUNDANE = POOL_THRESHOLD_MUNDANE, EVENT_LEVEL_MODERATE = POOL_THRESHOLD_MODERATE)
	tags = list(TAG_SCARY, TAG_NEGATIVE)

/datum/event/nebula
	startWhen = 1
	announceWhen = 3
	endWhen = 350

/datum/event/nebula/setup()
	endWhen = rand(400, 700)

/datum/event/nebula/start()
	GLOB.GLOBAL_INSIGHT_MOD = 0.5

/datum/event/nebula/announce()
	command_announcement.Announce("Uncharacteristically high concentrations of dark matter from a nearby nebula currently envelop the ship. Crew might experience certain issues with their mental wellbeing.", "Dark Matter Nebula")

/datum/event/nebula/end()
	command_announcement.Announce("The dark matter nebula has moved away from the ship.", "Dark Matter Nebula")
	GLOB.GLOBAL_INSIGHT_MOD = 1

/datum/storyevent/interphase
	id = "bluespace_interphase"
	name = "Bluespace Interphase"
	weight = 0.5
	parallel = FALSE
	event_type = /datum/event/interphase
	event_pools = list(EVENT_LEVEL_MODERATE = POOL_THRESHOLD_MODERATE, EVENT_LEVEL_MAJOR = POOL_THRESHOLD_MAJOR)
	tags = list(TAG_SCARY, TAG_NEGATIVE)

/datum/event/interphase
	startWhen = 1
	announceWhen = 3
	endWhen = 350

/datum/event/interphase/setup()
	endWhen = rand(300, 600)

/datum/event/interphase/announce()
	command_announcement.Announce("The fabric of bluespace has begun to break up, allowing an overlap of parallel universes on different dimensional planes. There is no additional data.", "Bluespace Interphase")

/datum/event/interphase/tick()
	if(prob(3))
		var/list/servers = list()
		for(var/obj/machinery/telecomms/server/S in telecomms_list)
			if(S.network == "eris" && S.log_entries.len != 0) //yep, only for eris so that non-eris servers don't get involved(duh!)
				servers += S								//also checks if there are any log entries (not an empty list)
		if(servers.len != 0)
			var/obj/machinery/telecomms/server/chosen_server = pick(servers)
			var/datum/comm_log_entry/C = pick(chosen_server.log_entries)
			global_announcer.autosay(C.parameters["message"], C.parameters["name"])
	if(prob(10)) //spooky bluspess ghost
		var/area/location = random_ship_area()
		var/mob/living/carbon/human/to_copy = pick(GLOB.human_mob_list)
		var/mob/ghost = new(location.random_space())
		ghost.icon = to_copy.icon
		ghost.icon_state = to_copy.icon_state
		ghost.dir = to_copy.dir
		ghost.appearance = to_copy.appearance
		ghost.mouse_opacity = 0
		ghost.density = 0
		sleep(20)
		if(ghost)//no idea how it could be gone in 20 seconds but gamers will find a way
			qdel(ghost)

/datum/event/interphase/end()
	command_announcement.Announce("The bluespace interphase stabilized itself.", "Bluespace Interphase")
