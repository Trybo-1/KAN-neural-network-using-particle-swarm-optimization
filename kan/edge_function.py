import random
from bspline.spline1d import Spline1d as Spline
class EdgeFunction:

    def __init__(self,degree=2, number_of_control_points=4):
        # Store the coefficients
        self.spline = Spline([random.uniform(-1, 1) for _ in range(number_of_control_points)], degree)
        self.degree = degree
    

    def evaluate(self, input_value):
        # Calculate the function
        return self.spline.evaluate(input_value)
