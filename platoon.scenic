#SET MAP AND MODEL (i.e. definitions of all referenceable vehicle types, road library, etc)
param map  = localPath('./singlelaneroad.xodr')
param lgsvl_map = 'SingleLaneRoad'
param time_step = 1.0/10
model scenic.simulators.lgsvl.model
param render = True
param verifaiSamplerType = 'ce' #bo

# Parameters of the scenario.
param EGO_SPEED = VerifaiRange(5, 25)
param EGO_BRAKING_THRESHOLD = VerifaiRange(6, 10)
param MY_DELAY = VerifaiRange(10,80)

#CONSTANTS
TERMINATE_TIME = 40 / globalParameters.time_step
CAR3_SPEED = 20
CAR4_SPEED = 20
LEAD_CAR_SPEED = 20

BRAKE_ACTION = 1.0
THROTTLE_ACTION = 0.6

DISTANCE_BETWEEN_CARS = 8
SPAWN = 15

C3_BRAKING_THRESHOLD = 6
C4_BRAKING_THRESHOLD = 6
LEADCAR_BRAKING_THRESHOLD = 6


## DEFINING BEHAVIORS

#COLLISION AVOIDANCE BEHAVIOR
behavior CollisionAvoidance():
	take SetBrakeAction(BRAKE_ACTION)		

behavior BrakeBehavior():
	while True:
		take SetBrakeAction(BRAKE_ACTION)

#EGO BEHAVIOR: Follow lane, and brake after passing a threshold distance to the leading car
behavior EgoBehavior(speed=10):

	try:
		do FollowLaneBehavior(speed) for globalParameters.MY_DELAY seconds
		do BrakeBehavior() for 3 seconds
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, globalParameters.EGO_BRAKING_THRESHOLD):
		do CollisionAvoidance()

#LEAD CAR BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior LeadingCarBehavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

#CAR3 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car3Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, C3_BRAKING_THRESHOLD):
		do CollisionAvoidance()

#CAR4 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car4Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyObjs(self, C4_BRAKING_THRESHOLD):
		do CollisionAvoidance()

#PLACEMENT
initLane = network.roads[0].forwardLanes.lanes[0]
spawnPt = initLane.centerline.pointAlongBy(SPAWN)

leadCar = Car at spawnPt,
    with behavior LeadingCarBehavior(LEAD_CAR_SPEED)

ego = Car following roadDirection from leadCar for DISTANCE_BETWEEN_CARS,
	with behavior EgoBehavior(leadCar, globalParameters.EGO_SPEED)

c3 = Car following roadDirection from ego for DISTANCE_BETWEEN_CARS,
	with behavior Car3Behavior(ego, CAR3_SPEED)
	
c4 = Car following roadDirection from c3 for DISTANCE_BETWEEN_CARS,
	with behavior Car4Behavior(c3, CAR4_SPEED)

require always (distance from ego.position to c3.position) >= 5
require always (distance from ego.position to leadCar.position) >= 5
terminate when simulation().currentTime > TERMINATE_TIME