import numpy as np

from bspline.basis import (create_knot_vector, basis_function)

class Spline1d:

    def __init__(self, control_points, degree=3):

        self.control_points = np.array(control_points, dtype=float)

        self.degree = degree

        self.knots = create_knot_vector(len(self.control_points), self.degree)


    def evaluate(self, x):

        #t = self.normalize_input(x)
        output = 0.0

        for i in range(len(self.control_points)):

            influence = basis_function(
                i,
                self.degree,
                x,
                self.knots
            )

            output += influence * self.control_points[i]

        return output

    def create_curve(self, resolution=1000):

        curve_points = []

        parameter_values = np.linspace(self.knots[self.degree], self.knots[-self.degree - 1], resolution)

        for parameter in parameter_values:

            point = self.evaluate(parameter)
            curve_points.append(point)

        return np.array(curve_points)
    

    def normalize_input(self, x):

        domain_min, domain_max = self.domain

        if domain_min == domain_max:
            raise ValueError("Spline domain cannot have zero width.")

        if x < domain_min or x > domain_max:
            raise ValueError(
                f"x={x} is outside the spline domain "
                f"{self.domain}"
            )

        # Convert real-world x to [0, 1]
        t = (x - domain_min) / (domain_max - domain_min)

        return t