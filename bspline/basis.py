import numpy as np


def create_knot_vector(num_control_points, degree):

    num_knots = num_control_points + degree + 1

    knots = np.zeros(num_knots)

    internal_knots = num_knots - 2 * (degree + 1)

    if internal_knots > 0:
        knots[degree + 1:-degree - 1] = np.linspace(0, 1, internal_knots + 2)[1:-1]

    knots[-degree - 1:] = 1
    return knots

#Influence of the degree on the knot vector for smoothing the curve
def basis_function(i, degree, t, knots):

    # Base case
    if degree == 0:
        if knots[i] <= t < knots[i + 1]:
            return 1.0
        return 0.0

    left, right = 0.0 , 0.0

    left_denom = knots[i + degree] - knots[i]
    right_denom = knots[i + degree + 1] - knots[i + 1]

    if left_denom != 0:
        left = (t-knots[i]) / left_denom * basis_function(i, degree - 1, t, knots)#left influnce

    if right_denom != 0:
        right = (knots[i + degree + 1] - t) / right_denom * basis_function(i + 1, degree - 1, t, knots)#right influence

    return left + right

