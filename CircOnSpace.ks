// Launch Circulization and housekeeping script
// Designed to complete circulization burn after seperate launch script or tool such as Gravity Turn.
FUNCTION CurrentThrust {
	LIST ENGINES IN EngList.
	LOCAL t IS 0.
	
	FOR Eng In EngList IF Eng:IGNITION SET t TO t + Eng:THRUST.
	RETURN t.
}.

IF SHIP:STATUS = "prelaunch" OR SHIP:STATUS = "flying" {

	WHEN SHIP:ALTITUDE >= BODY:ATM:HEIGHT * 0.3 THEN {
		WHEN SHIP:Q < 0.003 THEN { //Pop fairings and antennas
			IF EXISTS("DeployFairing.ks") OR EXISTS("DeployFairing.ksm") RUN DeployFairing.
			IF EXISTS("DeployAntenna.ks") OR EXISTS("DeployFairing.ksm") RUN DeployAntenna.
		}.
	}.

	PRINT "Waiting for Launch. Will circualize after Apoapsis has been reached.".
	WAIT UNTIL SHIP:ALTITUDE > SHIP:BODY:ATM:HEIGHT.
	WAIT UNTIL CurrentThrust = 0.
	// Now in space and not thrusting so AP should be constant.
		
	// Turn on Solar PANELS
	PANELS ON.
	// Turn on Lights if any
	LIGHTS ON.
	
	WAIT 10.
	// Set Orbit at circular at current AP and Inclination.
	IF EXISTS("SetOrbit.ks") OR EXISTS("SetOrbit.ksm") RUN SetOrbit(APOAPSIS/1000,APOAPSIS/1000).
	
	PRINT SHIP:NAME + " is now in a " + ROUND(APOAPSIS/1000) + "km x " + ROUND(PERIAPSIS/1000) + "km orbit.".

}.