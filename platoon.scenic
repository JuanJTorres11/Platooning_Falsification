#SET MAP AND MODEL (i.e. definitions of all referenceable vehicle types, road library, etc)
param map  = localPath('../../tests/singlelaneroad.xodr')
param lgsvl_map = 'SingleLaneRoad'
param time_step = 1.0/10
model scenic.simulators.lgsvl.model
param render = True
param verifaiSamplerType = 'ce'

# Parameters of the scenario.
param EGO_SPEED = VerifaiRange(10, 20)
param EGO_BRAKING_THRESHOLD = VerifaiRange(10, 15)

#CONSTANTS
TERMINATE_TIME = 20 / globalParameters.time_step
CAR3_SPEED = 10
CAR4_SPEED = 10
LEAD_CAR_SPEED = 10

BRAKE_ACTION = 1.0
THROTTLE_ACTION = 0.6


EGO_TO_LEADCAR = -20
C3_TO_EGO = -20
C4_TO_C3 = -20

C3_BRAKING_THRESHOLD = 15
C4_BRAKING_THRESHOLD = 15
LEADCAR_BRAKING_THRESHOLD = 15

## DEFINING BEHAVIORS
#EGO BEHAVIOR: Follow lane, and brake after passing a threshold distance to the leading car
behavior EgoBehavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyCars(self, globalParameters.EGO_BRAKING_THRESHOLD):
		take SetBrakeAction(BRAKE_ACTION)

#LEAD CAR BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior LeadingCarBehavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyCars(self, LEADCAR_BRAKING_THRESHOLD):
		take SetBrakeAction(BRAKE_ACTION)

#CAR3 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car3Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyCars(self, C3_BRAKING_THRESHOLD):
		take SetBrakeAction(BRAKE_ACTION)

#CAR4 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car4Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyCars(self, C4_BRAKING_THRESHOLD):
		take SetBrakeAction(BRAKE_ACTION)

##DEFINING SPATIAL RELATIONS
# Please refer to scenic/domains/driving/roads.py how to access detailed road infrastructure
# 'network' is the 'class Network' object in roads.py

# make sure to put '*' to uniformly randomly select from all elements of the list, 'network.lanes'
lane = Uniform(*network.lanes)

##OBJECT PLACEMENT

leadCar = Car on lane,
    with behavior LeadingCarBehavior(LEAD_CAR_SPEED)

ego = Car following roadDirection from leadCar for EGO_TO_LEADCAR,
	with behavior EgoBehavior(globalParameters.EGO_SPEED)

c3 = Car following roadDirection from ego for C3_TO_EGO,
	with behavior Car3Behavior(CAR3_SPEED)

c4 = Car following roadDirection from c3 for C4_TO_C3,
	with behavior EgoBehavior(CAR4_SPEED)

terminate when simulation().currentTime > TERMINATE_TIME
