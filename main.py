from datasets import sinpoly as xor
from kan.network import KANNetwork
from PSO.particle import Particle
from PSO.swarm import Swarm
from utils.metrics import calculate_fitness_xor as calculate_fitness

import matplotlib.pyplot as plt

number_of_iterations = 1700
target_fitness_threshold = 0.0005
fitness_history = []
iterations_run = 0


network = KANNetwork(
    layers=[2, 2, 1],
    degree=2
)

dimensions = len(
    network.get_parameters()
)

swarm = Swarm(30,dimensions)

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

    iterations_run += 1

    # Print progress
    print(f"Iteration {iteration + 1} | "f"Best fitness: "f"{swarm.global_best_fitness:.6f}")
    fitness_history.append(swarm.global_best_fitness)

    if swarm.global_best_fitness < target_fitness_threshold:
        print("Early stopping: fitness threshold reached.")
        break


print("\nFinal XOR predictions:")

network.set_parameters(
    swarm.global_best_position
)

for inputs, target in zip(xor.test_inputs, xor.test_targets):

    prediction = network.forward(inputs)[0]

    print(f"Input: {inputs} | " f"Target: {target:.2f} | " f"Prediction: {prediction:.4f}")

print(f"\nFinal best fitness: {swarm.global_best_fitness:.6f}")
print(calculate_fitness(network, particle, xor.test_inputs, xor.test_targets))

plt.plot(range(1, iterations_run + 1), fitness_history)
plt.show()