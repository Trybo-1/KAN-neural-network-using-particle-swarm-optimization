import random

class Particle:

    def __init__(self, dimensions):

        # Create the position
        self.position = []

        for _ in range(dimensions):
            value = random.uniform(-1, 1)
            self.position.append(value)

        # Create the velocity

        self.velocity = []

        for _ in range(dimensions):
            value = random.uniform(-0.1, 0.1)
            self.velocity.append(value)

        # Store the particle's best position
        self.best_position = self.position.copy()

        # Store the particle's best fitness
        self.best_fitness = float("inf")

    def update_best(self, fitness):

        if fitness < self.best_fitness:

            #save the new best fitness
            self.best_fitness = fitness

            #save a copy of the current position
            self.best_position = self.position.copy()

    def update(self, global_best_position, inertia_weight, cognitive_weight, social_weight):

        for i in range(len(self.position)):

            # Generate r1 and r2
            r1,r2 = random.random(), random.random()

            # Calculate inertia
            inertia = inertia_weight * self.velocity[i]

            # Calculate cognitive influence
            cognitive = cognitive_weight * r1 * (self.best_position[i] - self.position[i])

            # Calculate social influence
            social = social_weight * r2 * (global_best_position[i] - self.position[i])

            # Update velocity
            self.velocity[i] = inertia + cognitive + social

            # Update position
            self.position[i] += self.velocity[i]
