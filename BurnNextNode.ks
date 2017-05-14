// BurnNextNode in Maneuver Planner
// BurnNextNode.ks

IF HASNODE {
	SET N TO NEXTNODE.
	REMOVE N.
	IF EXISTS("burnnode.ks") OR EXISTS("burnnode.ksm") RUN BurnNode(N).
}
