import math
import random
from bspline.spline import Spline as Spline

class EdgeFunction:

    def __init__(self,degree=2, number_of_control_points=2, type="bspline"):
        # Store the coefficients
        self.number_of_control_points = number_of_control_points
        self.type = type
        if self.type == "bspline":
            self.spline = Spline([random.uniform(-1,1) for _ in range(number_of_control_points)], degree)
        else:
            if self.type == "polynomial":
                self.coefficients = [random.uniform(-1,1) for _ in range(number_of_control_points)]


    def evaluate(self, input_value):
        # Calculate the function
        normalized_input = self.normalize_input(input_value)
        if self.type == "bspline":
            return self.spline.evaluate(normalized_input)/0.5  # Normalize the output to the range [-1, 1]
        else:
            if self.type == "polynomial":
                result = 0
                for i, coeff in enumerate(self.coefficients):
                    result += coeff * (input_value ** i)
                return result

    def normalize_input(self, x):
        return x / (1 + abs(x))  # Normalize input to the range [-1, 1]

    def sample_polynomial_curve(self, num_samples=25):
        sampled_points = []
        for i in range(num_samples):
            t = -1 + (2 * i / (num_samples - 1))
            point = self.evaluate(t)
            sampled_points.append([t, point])
        return sampled_points
