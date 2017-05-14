//SetMidcourseCorrection(periapsis-alt km)
// script to perform a midcourse correction burn to fine tune a given periapsis at the destination planet.
// TODO :
//		1. does not take into account the inclination.
// 		2. Use RCS if available?

DECLARE PARAMETER targetPE IS 10.

IF ORBIT:HASNEXTPATCH AND ORBIT:TRANSITION = "Encounter" { // Check to see if we have an encounter.
	LOCK CurrentPE TO ORBIT:NEXTPATCH:PERIAPSIS.
	LOCAL T IS 0.
	LOCK THROTTLE TO T.
	
	LOCAL SASStatus to SAS.
	
	SAS OFF.
	
	// Change thrust of engines to be less than 1%
	LIST ENGINES IN ENGLIST.
	LOCAL ENGVAL IS LIST().
	LOCAL i IS 0.
	
	FOR ENG IN ENGLIST {
		IF ENG:IGNITION {
			ENGVAL:ADD(ENG:THRUSTLIMIT).
			SET ENG:THRUSTLIMIT TO 1. // Set tweakable to 1%.
		}
	}
	
	IF targetPE > ORBIT:NEXTPATCH:BODY:SOIRADIUS*0.9 {
		PRINT "TargetPE is too close to SOI boundary.  Choose less than " + ORBIT:NEXTPATCH:BODY:SOIRADIUS*.9 + ".".
	} ELSE {
		PRINT "Adjusting " + SHIP:NAME "'s" + ORBIT:NEXTPATCH:BODY:NAME + " Orbit.".
		SET targetPE TO targetPE * 1000. // Change to meters
		
		WAIT 1.
		PRINT "Aligning.".
		IF targetPE > CurrentPE { // Need to increase prograde velocity.
			LOCK STEERING TO PROGRADE.	
			WAIT 1.
			WAIT UNTIL ABS(STEERINGMANAGER:ANGLEERROR) < 0.1.
		} ELSE { // Need to decrease prograde velocity.
			LOCK STEERING TO RETROGRADE.
			WAIT 1.
			WAIT UNTIL ABS(STEERINGMANAGER:ANGLEERROR) < 0.1.
		}
		
		PRINT "Burning.".
		
		UNTIL ABS(targetPE-CurrentPE) < 200 AND CurrentPE > 0 {
			SET CurrentPE TO ORBIT:NEXTPATCH:PERIAPSIS.
			SET T to 0.1.
		}
		SET T TO 0.
		UNLOCK STEERING.
		UNLOCK THROTTLE.
		LOCK STEERING TO "kill".
		
		IF SASStatus {
			SAS ON.
		} ELSE {
			SAS OFF.
		}.
		
		WAIT 1.
		
		PRINT "Mid-course correction complete.".
		PRINT "New Periapsis = " + ROUND(ORBIT:NEXTPATCH:PERIAPSIS/1000) + "km".
	}
	SET i TO 0.
	FOR ENG IN ENGLIST {
		IF ENG:IGNITION {
			SET ENG:THRUSTLIMIT TO ENGVAL[i].
		}
	}.
} ELSE PRINT "No encounter found.".

	