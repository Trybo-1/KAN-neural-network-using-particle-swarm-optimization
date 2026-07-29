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
