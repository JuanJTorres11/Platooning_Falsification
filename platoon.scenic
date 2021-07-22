#SET MAP AND MODEL (i.e. definitions of all referenceable vehicle types, road library, etc)
param map = localPath('Town01.xodr') 
param render = True
model scenic.simulators.newtonian.model #located in scenic/simulators/carla/model.scenic
param verifaiSamplerType = 'ce'

#### PLATOON 
# Parameters of the scenario.
param MIDDLE_CAR2_SPEED = VerifaiRange(10, 20)
param MC2_BRAKING_THRESHOLD = VerifaiRange(10, 15)

#CONSTANTS
EGO_SPEED = 10
MIDDLE_CAR3_SPEED = 10
LEAD_CAR_SPEED = 10

BRAKE_ACTION = 1.0
THROTTLE_ACTION = 0.6

MC2_TO_LEADCAR = -20
MC3_TO_MC2 = -20
EGO_TO_MC3 = -20

EGO_BRAKING_THRESHOLD = 15
MC3_BRAKING_THRESHOLD = 15
LEADCAR_BRAKING_THRESHOLD = 15

## DEFINING BEHAVIORS
#EGO BEHAVIOR: Follow lane, and brake after passing a threshold distance to the leading car
behavior EgoBehavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyCars(self, EGO_BRAKING_THRESHOLD):
		take SetBrakeAction(BRAKE_ACTION)

#LEAD CAR BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior LeadingCarBehavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyCars(self, LEADCAR_BRAKING_THRESHOLD):
		take SetBrakeAction(BRAKE_ACTION)

#CAR2 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car2Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyCars(self, globalParameters.MC2_BRAKING_THRESHOLD):
		take SetBrakeAction(BRAKE_ACTION)

#CAR3 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car3Behavior(speed=10):

	try:
		do FollowLaneBehavior(speed)

	interrupt when withinDistanceToAnyCars(self, MC3_BRAKING_THRESHOLD):
		take SetBrakeAction(BRAKE_ACTION)

##DEFINING SPATIAL RELATIONS
# Please refer to scenic/domains/driving/roads.py how to access detailed road infrastructure
# 'network' is the 'class Network' object in roads.py

# make sure to put '*' to uniformly randomly select from all elements of the list, 'network.lanes'
lane = Uniform(*network.lanes)

##OBJECT PLACEMENT

leadCar = Car with behavior LeadingCarBehavior(LEAD_CAR_SPEED)

c2 = Car following roadDirection from leadCar for MC2_TO_LEADCAR,
	with behavior EgoBehavior(globalParameters.MIDDLE_CAR2_SPEED)

c3 = Car following roadDirection from c2 for MC3_TO_MC2,
		with behavior EgoBehavior(MIDDLE_CAR3_SPEED)

ego = Car following roadDirection from c3 for EGO_TO_MC3,
	with behavior EgoBehavior(EGO_SPEED)
                