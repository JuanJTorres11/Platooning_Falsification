#SET MAP AND MODEL (i.e. definitions of all referenceable vehicle types, road library, etc)
param map  = localPath('./singlelaneroad.xodr')
param lgsvl_map = 'SingleLaneRoad'
param time_step = 1.0/10
model scenic.simulators.lgsvl.model
param render = True
param verifaiSamplerType = 'ce'

# Parameters of the scenario.
param EGO_SPEED = VerifaiRange(2, 30)
param EGO_BRAKING_THRESHOLD = VerifaiRange(5, 15)

#CONSTANTS
TERMINATE_TIME = 20 / globalParameters.time_step
CAR2_SPEED = 20
CAR4_SPEED = 20
LEAD_CAR_SPEED = 20

BRAKE_ACTION = 1.0
THROTTLE_ACTION = 0.6


LEADCAR_TO_EGO = 7
EGO_TO_C3 = 7
C3_TO_C4 = 7
SPAWN = 7

C2_BRAKING_THRESHOLD = 6
C4_BRAKING_THRESHOLD = 6
LEADCAR_BRAKING_THRESHOLD = 6


## DEFINING BEHAVIORS
#COLLISION AVOIDANCE BEHAVIOR
behavior CollisionAvoidance(safety_distance=10):
	take SetBrakeAction(BRAKE_ACTION)

#EGO BEHAVIOR: Follow lane, and brake after passing a threshold distance to the leading car
behavior EgoBehavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, globalParameters.EGO_BRAKING_THRESHOLD):
		do CollisionAvoidance(globalParameters.EGO_BRAKING_THRESHOLD)

#LEAD CAR BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior LeadingCarBehavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, LEADCAR_BRAKING_THRESHOLD):
		do CollisionAvoidance(LEADCAR_BRAKING_THRESHOLD)

#CAR2 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car2Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, C2_BRAKING_THRESHOLD):
		do CollisionAvoidance(C2_BRAKING_THRESHOLD)

#CAR4 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car4Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, C4_BRAKING_THRESHOLD):
		do CollisionAvoidance(C4_BRAKING_THRESHOLD)

#PLACEMENT
initLane = network.roads[0].forwardLanes.lanes[0]
spawnPt = initLane.centerline.pointAlongBy(SPAWN)

c4 = Car at spawnPt,
	with behavior Car4Behavior(CAR4_SPEED)

ego = Car following roadDirection from c4 for C3_TO_C4,
		with behavior EgoBehavior(globalParameters.EGO_SPEED)

c2 = Car following roadDirection from ego for EGO_TO_C3,
		with behavior Car2Behavior(CAR2_SPEED)

leadCar = Car following roadDirection from c2 for LEADCAR_TO_EGO,
    with behavior LeadingCarBehavior(LEAD_CAR_SPEED)

require always (distance from ego.position to c4.position) >= 5
require always (distance from ego.position to c2.position) >= 5
terminate when simulation().currentTime > TERMINATE_TIME
