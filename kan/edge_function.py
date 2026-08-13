import random
from bspline.spline1d import Spline1d as Spline
class EdgeFunction:

    def __init__(self,degree=2, number_of_control_points=2):
        # Store the coefficients
        self.number_of_control_points = number_of_control_points
        self.spline = Spline([random.uniform(-1,1) for _ in range(number_of_control_points)], degree)


    def evaluate(self, input_value):
        # Calculate the function
        return self.spline.evaluate(input_value)
