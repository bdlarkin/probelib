// Rendezvous Script.
// Given target vessel synchronize orbits.
// Required paramater tgtVessel
// Optional parameter offset - a slide offset for constellations.

DECLARE PARAMETER tgtVessel.
DECLARE PARAMETER offset IS 1.

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
  local r1 is (ship:obt:semimajoraxis + ship:obt:semiminoraxis) / 2.
  local r2 is (target:obt:semimajoraxis + target:obt:semiminoraxis) / 2.

  return sqrt(body:mu / r1) * (sqrt( (2*r2) / (r1+r2) ) - 1).
}

// Compute time of Hohmann transfer window.
function hohmann {
  parameter dvMag.

  print "".
  local r1 is (ship:obt:semimajoraxis + ship:obt:semiminoraxis) / 2.
  local r2 is (target:obt:semimajoraxis + target:obt:semiminoraxis) / 2.

  // dv is not a vector in cartesian space, but rather in "maneuver space"
  // (z = prograde/retrograde dv)
  local dv is V(0, 0, dvMag).
  local pt is 0.5 * ((r1+r2) / (2*r2))^1.5.
  local ft is pt - floor(pt).

  // angular distance that target will travel during transfer
  local theta is 360 * ft.
  // necessary phase angle for vessel burn
  local phi is 180 - theta.

  local T is time:seconds.
  local T0 is T.
  local Tsynodic is synodicPeriod(ship:obt, target:obt).
  local Tmax is T + (3 * Tsynodic).
	
  local dt is 10.//	 s(Tmax - T) / 360.
  local etaError is min(ship:obt:period, target:obt:period) / 720.

  until false {
    local ps is positionat(ship, T) - body:position.
    local pt is positionat(target, T) - body:position.
    local vs is velocityat(ship, T):orbit.
    local vt is velocityat(target, T):orbit.

	SET PosArrow TO VECDRAW(ps,pt,PURPLE,"Position Guess",1.0,true).
	
	
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
	
	IF ABS(phit-phi) < .1  and eta > 0 {
		return T + eta.
	} ELSE IF ABS(phiT - phi) < 1 {
		IF r2 > r1 and norm:y > 0 {
			PRINT "SHIP AHEAD OF TARGET".
			SET T TO T + dt.
		} ELSE IF r2 < r1 and norm:y < 0 {
			SET T TO T + dt.
		} ELSE IF (r2 > r1 and dot > 0) OR (r2 < r1 and dot < 0) {
			PRINT "SHIP OPPOSITE OF TARGET".
			SET T TO T + dt.
		} ELSE {
			SET dt TO 0.1.
			SET T TO T + dt.
		}
	} ELSE IF ABS(phiT-phi) < 10 { 
		SET dt TO 1.
		SET T TO T + dt.
	} ELSE IF T > Tmax {
		RETURN 0.
	} ELSE {
		SET T to T + dt.
	}
	pRINT ROUND(T-T0,3) + " of  " + ROUND(Tmax - T,3) + " step " + dt + "Phase Angle " + ROUND(phit-phi,2) AT (0,0).
  }
}


// MAIN BODY

SET TARGET TO tgtVessel.
IF TARGET:BODY <> SHIP:BODY {
	PRINT "Vessels need to be in same SOI.".
} ELSE IF SHIP:OBT:ECCENTRICITY > .1 {
	PRINT SHIP:NAME + " orbital eccentricity too high e=" + ROUND(SHIP:OBT:ECCENTRICITY,4).
} ELSE IF TARGET:OBT:ECCENTRICITY > 0.1 {
	PRINT TARGET:NAME + " orbital eccentricity too high e=" + ROUND(SHIP:OBT:ECCENTRICITY,4).
} ELSE {
	PRINT "Synchronizing with " + TARGET:NAME.
	
	LOCAL node_dv is hohmannDv().
	LOCAL node_T is hohmann(node_dv).

	SET offset_t TO (((360/offset) / (1- SHIP:ORBIT:PERIOD/TARGET:ORBIT:PERIOD)/360)) * SHIP:ORBIT:PERIOD.
	If offset > 1  PRINT "Adjusting maneuver by slide time " + ROUND(offset_t,2) + "s.".
	if node_T > 0 {
		if offset > 1 {
			add node(node_T+offset_t, 0, 0, node_dv).
		} else {
			add node(node_T,0,0,node_dv).
		}
	}
}