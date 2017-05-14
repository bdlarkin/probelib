// Orbit Return.
// Orient spacecraft for atmospheric return, arm chutes, and retroburn

IF SHIP:BODY:ATM:EXISTS {

	// Trigger to Deploy chutes when safe.

	WHEN (NOT CHUTESSAFE) THEN {
		CHUTESSAFE ON.
		RETURN (NOT CHUTES).

	}.
}

RUN SetOrbit(APOAPSIS/1000,10,SHIP:OBT:INCLINATION).

LOCK STEERING to SHIP:SRFRETROGRADE.

WAIT UNTIL SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED".
UNLOCK STEERING.

PRINT SHIP:NAME + " landed on " + SHIP:BODY:NAME.

