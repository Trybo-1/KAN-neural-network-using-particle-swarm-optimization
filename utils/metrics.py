def calculate_mean_square_error(network, parameters, xor_inputs, xor_targets):

    # Put this particle's coefficients into the KAN
    network.set_parameters(parameters)

    total_error = 0

    # Test the KAN on XOR
    for inputs, target in zip(xor_inputs, xor_targets):

        prediction = network.forward(inputs)

        # The network returns a list with one output
        predicted_value = prediction[0]

        # Squared error
        error = (predicted_value - target) ** 2

        total_error += error

    # Return mean squared error
    return total_error / len(xor_inputs)

