import math

from datasets import sinpoly as continuous_xor
from kan.network import KANNetwork
from PSO.swarm import Swarm
from utils.metrics import calculate_mean_square_error 
from visualization.app import App

import matplotlib.pyplot as plt

#settings
number_of_iterations = 50
target_fitness_threshold = 0.0005

inertia_weight = 0.7
cognitive_weight = 1.5
social_weight = 1.5


#creating network
network = KANNetwork(
    layer_sizes=[2, 2, 1],
    degree=2,
    number_of_control_points=3
)

#creating swarm
number_of_particles = 30
number_of_parameters = len(network.get_parameters())

swarm = Swarm(number_of_particles, number_of_parameters)

#training loop

fitness_history = []
iterations_run = 0


for iteration in range(number_of_iterations):

    # Evaluate every particle
    for particle in swarm.particles:
        fitness = calculate_mean_square_error(network, particle.position, continuous_xor.inputs, continuous_xor.targets)

        # Update personal bests
        particle.update_best(fitness)

        # Update global best
        swarm.update_global_best(particle)

    # Move every particle
    swarm.update_particles(inertia_weight, cognitive_weight, social_weight)

    iterations_run += 1

    # Print progress
    print(f"Iteration {iteration + 1} | "f"Best fitness: "f"{swarm.global_best_fitness:.6f}")
    fitness_history.append(swarm.global_best_fitness)

    if swarm.global_best_fitness < target_fitness_threshold:
        print("Early stopping: fitness threshold reached.")
        break

#testing network with best parameters
print("\nFinal XOR predictions:")

network.set_parameters(
    swarm.global_best_position
)

for inputs, target in zip(continuous_xor.test_inputs, continuous_xor.test_targets):

    prediction = network.forward(inputs)[0]

    print(f"Input: {inputs} | " f"Target: {target:.2f} | " f"Prediction: {prediction:.4f}")

print(f"\nFinal best fitness: {swarm.global_best_fitness:.6f}")
print(calculate_mean_square_error(network, swarm.global_best_position, continuous_xor.test_inputs, continuous_xor.test_targets))


#actual vs predicted plot
predictions = []

for inputs in continuous_xor.inputs:

    prediction = network.forward(inputs)[0]

    predictions.append(prediction)

plt.figure()

plt.scatter(
    continuous_xor.targets,
    predictions
)

plt.xlabel("Actual")
plt.ylabel("Predicted")

plt.show()

#visualization of the network
app = App(network)
app.run()

#3d plot of the continuous XOR function
x1 = [inputs[0] for inputs in continuous_xor.inputs]
x2 = [inputs[1] for inputs in continuous_xor.inputs]
y = continuous_xor.targets

fig = plt.figure()

ax = fig.add_subplot(111, projection="3d")

ax.scatter(x1, x2, y)

ax.set_xlabel("X1")
ax.set_ylabel("X2")
ax.set_zlabel("Target")

plt.show()

