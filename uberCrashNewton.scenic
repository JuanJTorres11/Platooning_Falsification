#SET MAP AND MODEL (i.e. definitions of all referenceable vehicle types, road library, etc)
param map = localPath('/Users/kesav/Documents/Carla/Scenic-devel/tests/formats/opendrive/maps/CARLA/Town03.xodr')  # or other CARLA map that definitely works
param carla_map = localPath('/Users/kesav/Documents/Carla/Scenic-devel/tests/formats/opendrive/maps/CARLA/Town03.xodr') 
param render = True
model scenic.simulators.newtonian.model #located in scenic/simulators/carla/model.scenic
param verifaiSamplerType = 'ce'

# Parameters of the scenario.
param DISTANCE_TO_INTERSECTION = VerifaiRange(-20, -10)
param HESITATION_TIME = VerifaiRange(0, 10)
param UBER_SPEED = VerifaiRange(10, 20)

# Ego vehicle just follows the trajectory specified later on.
behavior EgoBehavior(trajectory):
    do FollowTrajectoryBehavior(trajectory=trajectory, target_speed=globalParameters.UBER_SPEED)
    terminate

# Crossing car hesitates for a certain amount of time before starting to turn.
behavior CrossingCarBehavior(trajectory):
    while simulation().currentTime < globalParameters.HESITATION_TIME:
        wait
    do FollowTrajectoryBehavior(trajectory = trajectory)
    terminate

# Find all 4-way intersections and set up trajectories for each vehicle.
fourWayIntersection = filter(lambda i: i.is4Way, network.intersections)
intersec = Uniform(*fourWayIntersection)
rightLanes = filter(lambda lane: all([section._laneToRight is None for section in lane.sections]), intersec.incomingLanes)
startLane = Uniform(*rightLanes)
straight_maneuvers = filter(lambda i: i.type == ManeuverType.STRAIGHT, startLane.maneuvers)
straight_maneuver = Uniform(*straight_maneuvers)

otherLane = straight_maneuver.endLane.group.opposite.lanes[-1]
left_maneuvers = filter(lambda i: i.type == ManeuverType.LEFT_TURN, otherLane.maneuvers)
left_maneuver = Uniform(*left_maneuvers)

ego_trajectory = [straight_maneuver.startLane, straight_maneuver.connectingLane, straight_maneuver.endLane]
crossing_car_trajectory = [left_maneuver.startLane, left_maneuver.connectingLane, left_maneuver.endLane]

# Spawn each vehicle in the middle of its starting lane.
uberSpawnPoint = startLane.centerline[-1]
crossingSpawnPoint = otherLane.centerline[-1]

ego = Car following roadDirection from uberSpawnPoint for globalParameters.DISTANCE_TO_INTERSECTION,
        with behavior EgoBehavior(trajectory = ego_trajectory)

crossing_car = Car at crossingSpawnPoint,
                with behavior CrossingCarBehavior(crossing_car_trajectory)
                
                
#### PLATOON 

#CONSTANTS
EGO_SPEED = 10
MIDDLE_CAR3_SPEED = 10
MIDDLE_CAR2_SPEED = 10
LEAD_CAR_SPEED = 10

BRAKE_ACTION = 1.0
THROTTLE_ACTION = 0.6

MC2_TO_LEADCAR = -20
MC3_TO_MC2 = -20
EGO_TO_MC3 = -20


EGO_BRAKING_THRESHOLD = 15
MC3_BRAKING_THRESHOLD = 15
MC2_BRAKING_THRESHOLD = 15
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

	interrupt when withinDistanceToAnyCars(self, MC2_BRAKING_THRESHOLD):
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
	with behavior EgoBehavior(MIDDLE_CAR2_SPEED)

c3 = Car following roadDirection from c2 for MC3_TO_MC2,
		with behavior EgoBehavior(MIDDLE_CAR3_SPEED)

ego = Car following roadDirection from c3 for EGO_TO_MC3,
	with behavior EgoBehavior(EGO_SPEED)
                
