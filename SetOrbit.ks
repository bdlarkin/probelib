// Launch script
//
// Goal is to Match to an orbit.


DECLARE PARAMETER targetAP IS 0. //Apoapsis of target orbit
DECLARE PARAMETER targetPE IS 0. //Periapsis of target orbit
PARAMETER targetInc is 9999. 	 // Inclination
PARAMETER targetLAN is 9999.    // Longitude of Ascending Node.

SET targetAP to targetAP * 1000.
SET targetPE to targetPE * 1000.


FUNCTION NewOrbit {
	// Should probably check to make sure we hvae enough deltav in the active stage to do burn
	DECLARE PARAMETER newAlt.
	DECLARE PARAMETER nodeTime.
	
	LOCAL mu IS SHIP:BODY:MU.
	LOCAL rb IS SHIP:OBT:BODY:RADIUS.

	// present orbit properties
	set vom to velocityAt(ship,time:seconds+nodeTime):ORBIT:MAG. // actual velocity
	set r to rb + ship:body:altitudeOf(positionAt(ship,time:seconds + nodeTime)). // actual distance to body at time of burn
	
	
	set va to sqrt( vom^2).//+ 2*mu*(1/ra - 1/r) ). // velocity in apoapsis
	set a to (periapsis + 2*rb + apoapsis)/2. // semi major axis present orbit
	// future orbit properties
	
	set r2 to rb + ship:body:altitudeof(positionAt(ship,time:seconds + nodeTime)).    // distance after burn at apoapsis
	set a2 to (newAlt + 2*rb + ship:body:altitudeof(positionAt(ship,time:seconds + nodeTime)))/2. // semi major axis target orbit
	set v2 to sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/a - 1/a2 ) ) ).
	
	// setup node 
	set deltav to v2 - va.
	
	RETURN node(time:seconds + nodeTime, 0, 0, deltav).
	
}

	
FUNCTION NewInclination {
	DECLARE PARAMETER I. // Desired Inclination
	
	// Match inclinations with target by planning a burn at the ascending or
// descending node, whichever comes first.
	LOCAL pos IS SHIP:POSITION - SHIP:BODY:POSITION.
	LOCAL vel IS SHIP:VELOCITY:ORBIT.
	LOCAL vela iS 4 * SHIP:OBT:INCLINATION / SHIP:OBT:PERIOD.
	LOCAL eq IS V(pos:X,0,pos:Z).
	LOCAL eqa IS VANG(pos,eq).
	
	IF pos:Y > 0 {
		IF vel:Y > 0 {
			// Above and Traveling away from equator; need to raise inc. 
			SET eqa TO 2 * SHIP:OBT:INCLINATION - abs(eqa).
		}
	} ELSE {
		IF vel:Y < 0 {
			// Below and traveling away from the equator.
			SET eqa TO 2 * SHIP:OBT:INCLINATION - abs(eqa).
		}.
	}.

	LOCAL frac IS (eqa / (4 * SHIP:OBT:INCLINATION)).
	LOCAL dt IS frac * SHIP:OBT:PERIOD.
	LOCAL t IS TIME + dt.

	LOCAL ri IS ABS(SHIP:OBT:INCLINATION - I).
	LOCAL v IS VelocityAT(SHIP,T):ORBIT.
	LOCAL dv is 2 * V:MAG * SIN(ri/2).
	
	
	IF V:Y > 0 { // anti-normal at AN
		LOCAL N IS NODE(T:SECONDS,0,-dv,0).
		RETURN N.
	} ELSE { // normal at DN
		LOCAL N IS NODE(T:SECONDS,0,dv,0).
		RETURN N.
	}.
	
}.


// Variable Tests

IF targetPE = 0 SET targetPE TO targetAP.
IF targetAP = 0 OR targetPE = 0 OR targetAP < targetPE {
	PRINT "ERROR in parameters".
	//BREAK.
}.

IF targetInc = 9999 { // Keep same inclination
	SET targetInc TO SHIP:ORBIT:INCLINATION.
} ELSE IF targetLAN <> 9999 { // Need to change inclination at a specific point.
	
} ELSE {
	IF ABS(SHIP:OBT:INCLINATION - targetInc) > 0.1
	{
		IF EXISTS("BurnNode.ks") OR EXISTS("BurnNode.ksm") RUN BurnNode(NewInclination(targetInc)).  //Need to match inclination
	}

}

IF ABS(SHIP:APOAPSIS - targetAP) > 1000 { //Need to raise the APOAPSIS
	IF SHIP:OBT:ECCENTRICITY < 0.001  { // burn anywhere
		IF EXISTS("BurnNode.ks") OR EXISTS("BurnNode.ksm") RUN BurnNode(NewOrbit(targetAP,120)).
	}
	ELSE IF EXISTS("BurnNode.ks") OR EXISTS("BurnNode.ksm") RUN BurnNode(NewOrbit(targetAP,ETA:PERIAPSIS)).
}

IF ABS(SHIP:PERIAPSIS - targetPE) > 1000 { // Need to raise PERIAPSIS
	
	IF SHIP:OBT:ECCENTRICITY < 0.001 {
		IF EXISTS("BurnNode.ks") OR EXISTS("BurnNode.ksm") RUN BurnNode(NewOrbit(targetPE,120)).
	}
	ELSE IF EXISTS("BurnNode.ks") OR EXISTS("BurnNode.ksm") RUN BurnNode(NewOrbit(targetPE,ETA:APOAPSIS)).
}







	
	







