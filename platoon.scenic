#SET MAP AND MODEL (i.e. definitions of all referenceable vehicle types, road library, etc)
param map  = localPath('../../tests/cubetown.xodr')
param lgsvl_map = 'CubeTown'
param time_step = 1.0/10
model scenic.simulators.lgsvl.model
param render = True
param verifaiSamplerType = 'ce'

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

##DEFINING SPATIAL RELATIONS
threeWayIntersections = filter(lambda i: i.is3Way, network.intersections)
intersection = Uniform(*threeWayIntersections)

left_maneuvers = filter(lambda m: m.type == ManeuverType.LEFT_TURN, intersection.maneuvers)
ego_maneuver = Uniform(*left_maneuvers)
actor_centerlines = [ego_maneuver.startLane, ego_maneuver.connectingLane, ego_maneuver.endLane]

## DEFINING BEHAVIORS
#EGO BEHAVIOR: Follow lane, and brake after passing a threshold distance to the leading car
behavior EgoBehavior(speed=10, trajectory = None):

	try:
		do FollowTrajectoryBehavior(target_speed=speed, trajectory=trajectory)

	interrupt when withinDistanceToAnyCars(self, EGO_BRAKING_THRESHOLD):
		take SetBrakeAction(BRAKE_ACTION)

#LEAD CAR BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior LeadingCarBehavior(speed=10, trajectory = None):

	try:
		do FollowTrajectoryBehavior(target_speed=speed, trajectory=trajectory)

	interrupt when withinDistanceToAnyCars(self, LEADCAR_BRAKING_THRESHOLD):
		take SetBrakeAction(BRAKE_ACTION)

#CAR2 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car2Behavior(speed=1, trajectory = None):

	try:
		do FollowTrajectoryBehavior(target_speed=speed, trajectory=trajectory)

	interrupt when withinDistanceToAnyCars(self, globalParameters.MC2_BRAKING_THRESHOLD):
		take SetBrakeAction(BRAKE_ACTION)

#CAR3 BEHAVIOR: Follow lane, and brake after passing a threshold distance to obstacle
behavior Car3Behavior(speed=10, trajectory = None):

	try:
		do FollowTrajectoryBehavior(target_speed=speed, trajectory=trajectory)

	interrupt when withinDistanceToAnyCars(self, MC3_BRAKING_THRESHOLD):
		take SetBrakeAction(BRAKE_ACTION)

##OBJECT PLACEMENT
leadCar = Car on ego_maneuver.startLane,
		with blueprint 'vehicle.tesla.model3',
		with behavior LeadingCarBehavior(LEAD_CAR_SPEED, actor_centerlines)

c2 = Car following roadDirection from leadCar for MC2_TO_LEADCAR,
	with behavior Car2Behavior(globalParameters.MIDDLE_CAR2_SPEED, actor_centerlines)

c3 = Car following roadDirection from c2 for MC3_TO_MC2,
	with behavior Car3Behavior(MIDDLE_CAR3_SPEED, actor_centerlines)

ego = Car following roadDirection from c3 for EGO_TO_MC3,
	with behavior EgoBehavior(EGO_SPEED, actor_centerlines)
