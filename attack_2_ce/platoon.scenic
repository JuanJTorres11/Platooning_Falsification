#SET MAP AND MODEL (i.e. definitions of all referenceable vehicle types, road library, etc)
param map  = localPath('./../singlelaneroad.xodr')
param lgsvl_map = 'SingleLaneRoad'
param time_step = 1.0/10
model scenic.simulators.lgsvl.model
param render = True
param verifaiSamplerType = 'ce'

# Parameters of the scenario.
param BRAKE_INTENSITY = VerifaiRange(0, 1)
param TIME_DELAY = VerifaiRange(5, 15)

#CONSTANTS
EGO_SPEED = 20
CAR3_SPEED = 20
CAR4_SPEED = 20
LEAD_CAR_SPEED = 20

BRAKE_ACTION = 1.0
THROTTLE_ACTION = 0.6


D_BTW_CARS = 7

BRAKING_THRESHOLD = 6


## DEFINING BEHAVIORS
#COLLISION AVOIDANCE BEHAVIOR
behavior CollisionAvoidance(safety_distance=10):
	take SetBrakeAction(BRAKE_ACTION)

#EGO BEHAVIOR: Follow lane, and brake after passing a threshold distance to the leading car
behavior EgoBehavior(speed=10):
	last_stop = 0
	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, BRAKING_THRESHOLD):
		do CollisionAvoidance(BRAKING_THRESHOLD)
	interrupt when simulation().currentTime - last_stop  > globalParameters.TIME_DELAY:
		take SetBrakeAction(globalParameters.BRAKE_INTENSITY)
		last_stop = simulation().currentTime		

#LEAD CAR BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior LeadingCarBehavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, BRAKING_THRESHOLD):
		do CollisionAvoidance(BRAKING_THRESHOLD)

#CAR3 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car3Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, BRAKING_THRESHOLD):
		do CollisionAvoidance(BRAKING_THRESHOLD)

#CAR4 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car4Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, BRAKING_THRESHOLD):
		do CollisionAvoidance(BRAKING_THRESHOLD)

#PLACEMENT
initLane = network.roads[0].forwardLanes.lanes[0]
spawnPt = initLane.centerline.pointAlongBy(D_BTW_CARS)

c4 = Car at spawnPt,
	with behavior Car4Behavior(CAR4_SPEED)

c3 = Car following roadDirection from c4 for D_BTW_CARS,
		with behavior Car3Behavior(CAR3_SPEED)

ego = Car following roadDirection from c3 for D_BTW_CARS,
		with behavior EgoBehavior(EGO_SPEED)

leadCar = Car following roadDirection from ego for D_BTW_CARS,
    with behavior LeadingCarBehavior(LEAD_CAR_SPEED)

require always (distance from ego.position to c3.position) > 4.5
require always (distance from ego.position to leadCar.position) > 4.5
terminate when leadCar.lane == None
