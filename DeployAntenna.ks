// Deploy antennas, both RT and stock.

FOR RTmodule IN SHIP:MODULESNAMED("ModuleRTAntenna") {
	IF RTmodule:PART:MODULES:CONTAINS("ModuleAnimateGeneric") {
		//If so, deploy
		RTmodule:DOACTION("activate",TRUE).
	}.
}.
