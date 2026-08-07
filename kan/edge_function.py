import random
import numpy as np
from bspline.spline1d import Spline1d as Spline
class EdgeFunction:

    def __init__(self,degree=2):
        # Store the coefficients
        self.spline = Spline([random.uniform(-1, 1) for _ in range(degree + 1)], degree)
        self.degree = degree
    

    def evaluate(self, x):
        # Calculate the function
        return self.spline.evaluate(x)
