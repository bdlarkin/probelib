// setup a Hohmann transfer orbit
// prerequisite: ship in circular orbit
declare parameter tgtbody.

SET TARGET TO tgtbody.

set done to False.
until done {
    // move origin to central body (i.e. Kerbin)
    set ps to V(0,0,0) - body:position.
    set pt to TARGET:position - body:position.
    // Hohmann transfer orbit period
    set ra to BODY:RADIUS + (periapsis+apoapsis)/2.  // average radius (burn angle not yet known)
    set vom to velocity:orbit:mag.          // actual velocity
    set r to BODY:RADIUS + altitude.                 // actual distance to body
    set va to sqrt( vom^2 - 2*BODY:MU*(1/ra - 1/r) ). // average velocity 
	
	set sma to TARGET:OBT:SEMIMAJORAXIS. //(target:apoapsis + 2*target:body:radius + target:periapsis)/2. // Could be this be TARGET:OBT:SEMIMAJORAXIS?
	set soi to TARGET:SOIRADIUS. //sma*(target:BODY:MU/target:BODY:MU)^0.4.  // SOI for Target Body. // Could be TARGET:SOIRADIUS?
	print "soi for " + target:name + ": " + round(soi/1000) + "km".
    
	set apoh to pt:mag.//- TARGET:BODY:RADIUS. //- 10000.  // soi/2.				// Set transfer orbit apoapsis to be halfway into target SOI.
    set smah to (ra + apoh)/2.  		// Semi Major axis of transfer orbit.
    set oph to 2 * CONSTANT:PI * sqrt(smah^3/BODY:MU). // Period of transfer orbit.
    print "T+" + round(missiontime) + " Hohmann apoapsis: " + round(apoh/1000) + "km, transfer time: " + round(oph/120) + "min".
    // current target angular position 
    set at0 to arctan2(pt:x,pt:z).
    // target angular position after transfer
    set smat to TARGET:OBT:SEMIMAJORAXIS.                       // mun/minmus have a circular orbit - Couldnnt this be TARGET:OBT:SEMIMAJORAXIS?
    set opt to TARGET:OBT:PERIOD.      // mun/minmus orbital period  Could be TARGET:OBT:PERIOD?
    set smas to SHIP:OBT:SEMIMAJORAXIS.                       // ship semi major axis?
    set ops to SHIP:OBT:PERIOD. //2 * CONSTANT:PI * sqrt(smas^3/BODY:MU).      // ship orbital period ?  SHIP:OBT:PERIOD?
    set da to (oph/2) / opt * 360.            // mun/minmus angle for hohmann transfer
    set das to (ops/2) / opt * 360.           // half a ship orbit to reduce max error to half orbital period
    set at1 to at0 - das - da.                // assume counterclockwise orbits
    print "T+" + round(missiontime) + " " + TARGET:name + ", orbital period: " + round(opt/60,1) + "min".
    print "T+" + round(missiontime) + " | now: " + round(at0) + "', xfer: " + round(da) + "', rdvz: " + round(at1) + "'".
    // current ship angular position 
    set asnow to arctan2(ps:x,ps:z).
    // ship angular position for maneuver
    set as0 to mod(at1 + 180, 360).
    // eta to maneuver node
    set asm to as0.
	PRINT "asnow = " + asnow + " as0 = " + as0.
    until asnow > asm { 
		set asm to asm - 360. 
		PRINT "ASM = " + asm.
	}
    set meta to (asnow - asm) / 360 * ops.
    if meta < 60 {
		// Transfer window is within 60 seconds.. too close.
        set meta to meta+ ops.
        print "T+" + round(missiontime) + " too close for maneuver, waiting for one orbit, " + round(ops/60,1) + "m".
    }
    print "T+" + round(missiontime) + " ship, orbital period: " + round(ops/60,1) + "m".
    print "T+" + round(missiontime) + " | now: " + round(asnow) + "', maneuver: " + round(asm) + "' in " + round(meta/60,1) + "m".
    // hohmann orbit properties
    set vh to sqrt( va^2 - BODY:MU * (1/smah - 1/smas ) ).
    set dv to vh - va.
    print "T+" + round(missiontime) + " Hohmann burn: " + round(vom) + ", dv:" + round(dv) + " -> " + round(vh) + "m/s".
    // setup node 
    set nd to node(time:seconds + meta, 0, 0, dv).
    add nd.
    IF  ENCOUNTER = "None" OR ENCOUNTER:BODY:NAME = TARGET:name {
        set done to True.
    } else {
        print "T+" + round(missiontime) + " Trajectory intercepts " + encounter:body:name + ", wait for one orbit.".
        WAIT UNTIL TIME:SECONDS > TIME:SECONDS + ops.
		remove nd.
        // recalculation of maneuver angle required (Minmus has moved to new location)
    }
}
if NOT(ENCOUNTER = "None") AND ENCOUNTER:BODY:NAME = TARGET:name {
    print "T+" + round(missiontime) + " Encounter: " + ENCOUNTER:BODY:NAME + ", periapsis: " + round(encounter:periapsis/1000) + "km".
    print "T+" + round(missiontime) + " Node created.".
} else {
    print "T+" + round(missiontime) + " WARNING! No encounter found.".
   // remove nd.
}
    
