
from pygame import Vector2

class wheel:
    def __init__(self, position : Vector2, isDriven : bool = False, has_brakes: bool = False):
        self.relative_position = position
        self.isDriven = isDriven
        self.has_brakes = has_brakes
        self.steering_angle =  0.0

