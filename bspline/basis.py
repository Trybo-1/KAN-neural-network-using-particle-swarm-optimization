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
def basis_function(index, degree, parameter, knots):

    # Base case
    if degree == 0:
        if knots[index] <= parameter < knots[index + 1] or (parameter == 1.0 and knots[index + 1] == 1.0):
            return 1.0
        return 0.0

    left, right = 0.0 , 0.0

    left_denom = knots[index + degree] - knots[index]
    right_denom = knots[index + degree + 1] - knots[index + 1]

    if left_denom != 0:
        left = (parameter-knots[index]) / left_denom * basis_function(index, degree - 1, parameter, knots)#left influnce

    if right_denom != 0:
        right = (knots[index + degree + 1] - parameter) / right_denom * basis_function(index + 1, degree - 1, parameter, knots)#right influence

    return left + right

