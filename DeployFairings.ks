// Pop Fairings
// Iterates over a list of all parts with the stock fairings module
FOR fairingModule IN SHIP:MODULESNAMED("ModuleProceduralFairing") { // Stock and KW Fairings
	// and deploys them
	fairingModule:DOEVENT("deploy").
}.
	// Iterates over a list of all parts using the fairing module from the Procedural Fairings Mod
FOR fairingModule IN SHIP:MODULESNAMED("ProceduralFairingDecoupler") { // Procedural Fairings
	// and jettisons them (PF uses the word jettison in the right click menu instead of deploy)
	fairingModule:DOEVENT("jettison").
}.