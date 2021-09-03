#SET MAP AND MODEL (i.e. definitions of all referenceable vehicle types, road library, etc)
param map  = localPath('./../singlelaneroad.xodr')
param lgsvl_map = 'SingleLaneRoad'
param time_step = 1.0/10
model scenic.simulators.lgsvl.model
param render = True
param verifaiSamplerType = 'ce'

# Parameters of the scenario.
param BRAKE_INTENSITY = VerifaiRange(0, 1)
param TIME_NORMAL_BEHAVIOR = VerifaiRange(5, 40)
param TIME_BRAKE_BEHAVIOR = VerifaiRange(1, 10)

#CONSTANTS
EGO_SPEED  = 20
CAR3_SPEED = 20
CAR4_SPEED = 20
CAR2_SPEED = 20

BRAKE_ACTION = 1.0
THROTTLE_ACTION = 0.6

D_BTW_CARS = 7

BRAKING_THRESHOLD = 6

## DEFINING BEHAVIORS
#COLLISION AVOIDANCE BEHAVIOR
behavior CollisionAvoidance():
	take SetBrakeAction(BRAKE_ACTION)
#BRAKE BEHAVIOR
behavior BrakeBehavior():
	take SetBrakeAction(globalParameters.BRAKE_INTENSITY)	

#EGO BEHAVIOR: Follow lane, and brake after passing a threshold distance to the leading car
behavior EgoBehavior(speed=10):

	try:
		do FollowLaneBehavior(speed) for globalParameters.TIME_NORMAL_BEHAVIOR
		do BrakeBehavior() for globalParameters.TIME_BREAK_BEHAVIOR
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, BRAKING_THRESHOLD):
		do CollisionAvoidance()

#CAR2 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car2Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, BRAKING_THRESHOLD):
		do CollisionAvoidance()

#CAR3 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car3Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, BRAKING_THRESHOLD):
		do CollisionAvoidance()

#CAR4 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car4Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, BRAKING_THRESHOLD):
		do CollisionAvoidance()

#PLACEMENT
initLane = network.roads[0].forwardLanes.lanes[0]
spawnPt = initLane.centerline.pointAlongBy(D_BTW_CARS)

c4 = Car at spawnPt,
	with behavior Car4Behavior(CAR4_SPEED)

c3 = Car following roadDirection from c4 for D_BTW_CARS,
		with behavior Car3Behavior(CAR3_SPEED)

c2 = Car following roadDirection from c3 for D_BTW_CARS,
		with behavior Car2Behavior(CAR2_SPEED)

ego = Car following roadDirection from c2 for D_BTW_CARS,
    with behavior EgoBehavior(EGO_SPEED)

require always (distance from ego.position to c2.position) >= 5
terminate when ego._lane == None 
