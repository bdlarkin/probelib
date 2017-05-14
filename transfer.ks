// Rendezvous with body
DECLARE PARAMETER tgtBody IS MUN.
DECLARE PARAMETER targetAP IS 10.
DECLARE PARAMETER setCW IS TRUE.

FUNCTION node_inc_tgt {
	local t0 is time:seconds.
	local ship_orbit_normal is vcrs(ship:velocity:orbit,positionat(ship,t0)-ship:body:position).
	local target_orbit_normal is vcrs(target:velocity:orbit,target:position-ship:body:position).
	local lineofnodes is vcrs(ship_orbit_normal,target_orbit_normal).
	local angle_to_node is vang(positionat(ship,t0)-ship:body:position,lineofnodes).
	local angle_to_node2 is vang(positionat(ship,t0+5)-ship:body:position,lineofnodes).
	local angle_to_opposite_node is vang(positionat(ship,t0)-ship:body:position,-1*lineofnodes).
	local relative_inclination is vang(ship_orbit_normal,target_orbit_normal).
	local angle_to_node_delta is angle_to_node2-angle_to_node.

	local ship_orbital_angular_vel is (ship:velocity:orbit:mag / (body:radius+ship:altitude))  * (180/constant():pi).
	local time_to_node is angle_to_node / ship_orbital_angular_vel.
	local time_to_opposite_node is angle_to_opposite_node / ship_orbital_angular_vel.

	// the nearest node might be in the past, in which case we want the opposite
	// node. test this by looking at our angular velocity w/r/t the node. There's
	// probably a more straightforward way to do this...
	local t is 0.
	if angle_to_node_delta < 0 {
		set t to (time + time_to_node):seconds.
	} else {
		set t to (time + time_to_opposite_node):seconds.
	}

	local v is velocityat(ship, t):orbit.
	local vt is velocityat(target, t):orbit.
	local diff is vt - v.
	local dv is 2 * v:mag * sin(relative_inclination / 2).

	if (v:y <= 0 and vt:y <= 0)  {
		return node(t, 0, dv, 0).
	} else {
		return node(t, 0, dv, 0).
	}

}

function synodicPeriod {
  parameter o1, o2.

  if o1:period > o2:period {
    local o is o2.
    set o2 to o1.
    set o1 to o.
  }

  return 1 / ( (1 / o1:period) - (1 / o2:period) ).
}

// Compute prograde delta-vee required to achieve Hohmann transfer; < 0 means
// retrograde burn.
function hohmannDv {
	LOCAL r1 IS (SHIP:OBT:SEMIMAJORAXIS + SHIP:OBT:SEMIMINORAXIS) / 2. //Average radius of ship orbit
	// Want to overestimate DV required to hit backside of plannet inside SOI.  For Minmus transfers this can save days.
	LOCAL r2 IS (TARGET:OBT:SEMIMAJORAXIS + TARGET:OBT:SEMIMINORAXIS) / 2.  // Average radius of target orbit

	RETURN SQRT(body:mu / r1) * (sqrt( (2*r2) / (r1+r2) ) - 1). // See https://en.wikipedia.org/wiki/Hohmann_transfer_orbit#Calculation
}

// Compute time of Hohmann transfer window.
function hohmann {
  parameter dvMag.

  LOCAL r1 IS (ship:obt:semimajoraxis + ship:obt:semiminoraxis) / 2.  // Average Radius of ship orbit
  LOCAL r2 IS (target:obt:semimajoraxis + target:obt:semiminoraxis) / 2. // Average Radius of target orbit.

  //https://docs.google.com/document/d/1IX6ykVb0xifBrB4BRFDpqPO6kjYiLvOcEo3zwmZL0sQ/edit
  LOCAL pt IS 0.5 * ((r1+r2) / (2*r2))^1.5. // Number of orbits target will take during transfer
  LOCAL ft IS pt - floor(pt). // Fractional part of orbits

    
  // angular distance that target will travel during transfer
  local theta is 360 * ft.
  
  
  // necessary phase angle for vessel burn
  local phi is 180 - theta.
	
	
  
  local T is time:seconds.
  local Tsynodic is synodicPeriod(ship:obt, target:obt).
  local Tmax is T + (3 * Tsynodic).  // Max Time to look for a transfer orbit.  

  local dt is (Tmax - T) / 36.
  local etaError is min(ship:obt:period, target:obt:period) / 720.

  until false {
    local ps is positionat(ship, T) - body:position.
    local pt is positionat(target, T) - body:position.
    local vs is velocityat(ship, T):orbit.
    local vt is velocityat(target, T):orbit.

    // angular velocity of vessel
    local omega is (vs:mag / ps:mag)  * (180/constant():pi).
    // angular velocity of the target
    local omega2 is (vt:mag / pt:mag)  * (180/constant():pi).

    // unsigned magnitude of the phase angle between ship and target
    local phiT is vang(ps, pt).
    // if r2 > r1, then norm:y is negative when ship is "behind" the target
    local norm is vcrs(ps, pt).
    // < 0 if ship is on opposite side of planet
    local dot is vdot(vs, vt).

    local eta is 0.

    if r2 > r1 {
      set eta to (phiT - phi) / (omega - omega2).
    } else {
      set eta to (phiT + phi) / (omega2 - omega).
    }

    if T > Tmax {
      return 0. // Couldn't find a transfer window in 3 synodic periods....
    } else if r2 > r1 and norm:y > 0 { // SHIP in front of target
      set T to T + dt. //
    } else if r2 < r1 and norm:y < 0 { // SHIP In front of target.
      set T to T + dt.
    } else if (r2 > r1 and dot > 0) or (r2 < r1 and dot < 0) { //SHIP is on opposite side of planet
      set T to T + dt.
    } else if eta < 0 { // Passed up phase angle
      set T to T - max(1, abs(eta) / 8).
    } else if abs(eta) > etaError { // ETA too far in the future?
      set T to T + max(1, eta / 4).
    } else {
      return T + eta.  // Return ETA time.
    }
  }
}

FUNCTION HohmannAdjust {
	DECLARE PARAMETER N. // Transfer Node
	DECLARE PARAMETER TargetPE. // desired PE of ship in target SOI.
	DECLARE PARAMETER Clockwise. // Inclination > 90 or < 90. May want to make this a desired inclination
	
	LOCAL dt IS 0.  // Time step
	
	SET CurrentPE TO ENCOUNTER:PERIAPSIS.
	SET CurrentInc TO ENCOUNTER:INCLINATION.
	
	
	
	SET TargetPE TO TargetPE * 1000.
	IF TargetPE > (ENCOUNTER:BODY:SOIRADIUS/2) { 
		// TargetPE to high. Reset. Don't want to plan near SOI limit.
		SET TargetPE TO ENCOUNTER:BODY:SOIRADIUS.
		PRINT "TargetPE to High.  New TargetPE = " + TargetPE.
	}
	
	LOCAL r1 IS (SHIP:OBT:SEMIMAJORAXIS + SHIP:OBT:SEMIMINORAXIS) / 2. //Average radius of ship orbit
	// Want to overestimate DV required to hit backside of plannet inside SOI.  For Minmus transfers this can save days.
	LOCAL r2 IS (ENCOUNTER:BODY:OBT:SEMIMAJORAXIS + ENCOUNTER:BODY:OBT:SEMIMINORAXIS) / 2.  // Average radius of target orbit
	SET r2 TO r2 + ENCOUNTER:BODY:SOIRADIUS/2.
	SET dvr TO SQRT(body:mu / r1) * (sqrt( (2*r2) / (r1+r2) ) - 1).
	SET dvr TO dvr - N:PROGRADE.
	
	SET dv to dvr.
	SET BodyRadius TO ENCOUNTER:BODY:RADIUS.
	
	PRINT "Analyzing".
	
	UNTIL ABS(CurrentPE - TargetPE) < 1000  {
		IF ENCOUNTER = "None" {
			PRINT "Lost Encounter".
			BREAK.
		} ELSE {
			SET CurrentPE TO ENCOUNTER:PERIAPSIS.
			SET dt TO MIN(10,ABS(CurrentPE/(ENCOUNTER:BODY:RADIUS))).
			IF Clockwise {
				IF CurrentPE > TargetPE AND ENCOUNTER:INCLINATION > 90 { //Need to decrease PE.  Reduce time
					SET N:ETA TO N:ETA-dt.
				} ELSE { //Need to increase PE increase time 
					SET N:ETA TO N:ETA+dt.
				}
			} ELSE {
				IF CurrentPE > TargetPE AND ENCOUNTER:INCLINATION < 90  { // Need to decrease PE increase time 
					SET N:ETA TO N:ETA+dt.
				} ELSE { // Need to incrase PE decrease time 
					SET N:ETA TO N:ETA-dt.
				}
			}
			IF dv >= 0 {
				IF CurrentPE < ENCOUNTER:BODY:SOIRADIUS/2 {
					PRINT "Adding DV".
					SET N:PROGRADE TO N:PROGRADE + 0.01.
					SET dv TO dv - 0.01.
				}
			}
		}
		PRINT ROUND(CurrentPE/1000) + " - " + targetPE/1000.
	}
}
	

// Main Body

SET TARGET TO tgtBody.

if ship:body <> target:body {
	PRINT "Not compatible SOI's".
	wait 5.
	reboot.
}

if abs(obt:inclination - target:obt:inclination) > 1 {
	PRINT "Matching " + TARGET:BODY:NAME + " inclination.".
	IF EXISTS("BurnNode.ks") OR EXISTS("BurnNode.ksm") RUN BurnNode(node_inc_tgt).
}

SET node_dv TO hohmannDv().
SET node_T TO hohmann(node_dv).


SET TN TO node(node_T, 0, 0, node_dv).
ADD TN.
UNTIL NOT node_T {
	IF NOT (ENCOUNTER = "None") AND ENCOUNTER:BODY:NAME = TARGET:NAME {
		PRINT "Encounter found with planet " + ENCOUNTER:BODY:NAME + ".".
		WAIT 1.
		PRINT "Adjusting for final PE".
		HohmannAdjust(TN,targetAP,setCW).
		REMOVE TN.
		PRINT "Transition Node Ready.".
		IF EXISTS("BurnNode.ks") OR EXISTS("BurnNode.ksm") RUN BurnNode(TN).
		SET node_T TO 0.
	} ELSE IF ENCOUNTER = "None" OR ENCOUNTER:BODY:NAME <> TARGET:NAME {
		IF NOT (ENCOUNTER = "None") PRINT "Encounter found with non target planet " + ENCOUNTER:BODY:NAME + ".".
		PRINT "WAITING for one Orbit.".
		If EXISTS("SetAlarm.ks") OR EXISTS("SetAlarm.ksm") RUN SetAlarm(SHIP:OBT:PERIOD,"Re-calculate transfer burn").
		REMOVE TN.
		WAIT UNTIL TIME:SECONDS >= TIME:SECONDS + SHIP:ORBIT:PERIOD.
		SET node_T TO hohmann(node_dv).
		SET TN TO node(node_T,0,0,node_dv).
		ADD TN.
	}
}
