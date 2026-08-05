def calculate_fitness_xor(network, particle, xor_inputs, xor_targets):

    # Put this particle's coefficients into the KAN
    network.set_parameters(particle.position)

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

