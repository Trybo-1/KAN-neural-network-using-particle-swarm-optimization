import numpy as np

from bspline.basis import (create_knot_vector, basis_function)

class Spline1d:

    def __init__(self, control_points, degree=3):

        self.control_points = np.array(control_points, dtype=float)

        self.degree = degree

        self.knots = create_knot_vector(len(self.control_points), self.degree)


    def evaluate(self, t):

        output = 0

        for i in range(len(self.control_points)):

            influence = basis_function(i, self.degree, t, self.knots)
            output += (influence * self.control_points[i])

        return output


    def create_curve(self, resolution=500):

        curve_points = []

        t_values = np.linspace(self.knots[self.degree], self.knots[-self.degree - 1], resolution)

        for t in t_values:

            point = self.evaluate(t)
            curve_points.append(point)

        return np.array(curve_points)