from datasets import xor 
from kan.network import KANNetwork
from PSO.particle import Particle
from PSO.swarm import Swarm

number_of_iterations = 150

def calculate_fitness(network, particle, xor_inputs, xor_targets):

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

network = KANNetwork(
    layers=[2, 2, 1],
    degree=2
)

dimensions = len(
    network.get_parameters()
)

swarm = Swarm(10,dimensions)

for iteration in range(number_of_iterations):

    # Evaluate every particle
    for particle in swarm.particles:
        fitness = calculate_fitness(network, particle, xor.inputs, xor.targets)

        # Update personal bests
        particle.update_best(fitness)

        # Update global best
        swarm.update_global_best(particle)

    # Move every particle
    swarm.update_particles(inertia_weight=0.7, cognitive_weight=1.5, social_weight=1.5)

    # Print progress
    print(f"Iteration {iteration + 1} | "f"Best fitness: "f"{swarm.global_best_fitness:.6f}")

print("\nFinal XOR predictions:")

network.set_parameters(
    swarm.global_best_position
)

for inputs, target in zip(xor.inputs, xor.targets):

    prediction = network.forward(inputs)[0]

    print(f"Input: {inputs} | " f"Target: {target} | " f"Prediction: {prediction:.4f}")