// SetAlarm.ks.
// Create KAC alarm
DECLARE PARAMETER t.
DECLARE PARAMETER Message.

IF ADDONS:KAC:AVAILABLE {
	LOCAL circAlarm IS ADDALARM("RAW",TIME:SECONDS+t,SHIP:NAME + " " + Message,"").
	SET circAlarm:ACTION TO "KillWarpOnly".
}.