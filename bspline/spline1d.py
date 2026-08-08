import numpy as np

from bspline.basis import (create_knot_vector, basis_function)

class Spline1d:

    def __init__(self, control_points, degree=3):

        self.control_points = np.array(control_points, dtype=float)

        self.degree = degree

        self.knots = create_knot_vector(len(self.control_points), self.degree)


    def evaluate(self, parameter):

        value = 0

        for i in range(len(self.control_points)):

            influence = basis_function(i, self.degree, parameter, self.knots)
            value += (influence * self.control_points[i])

        return value


    def create_curve(self, resolution=500):

        curve_points = []

        parameter_values = np.linspace(self.knots[self.degree], self.knots[-self.degree - 1], resolution)

        for parameter in parameter_values:

            point = self.evaluate(parameter)
            curve_points.append(point)

        return np.array(curve_points)