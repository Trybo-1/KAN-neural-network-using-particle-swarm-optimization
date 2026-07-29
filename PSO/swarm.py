from PSO.particle import Particle

class Swarm:

    def __init__(self, number_of_particles, dimensions):

        #creating particles for swarm
        self.particles = []

        for _ in range(number_of_particles):
            particle = Particle(dimensions)
            self.particles.append(particle)

        #global best position
        self.global_best_position = None

        #global best fitness
        self.global_best_fitness = float("inf")

    def update_global_best(self, particle):
        #compare particle fitness to global fitness
        if particle.best_fitness < self.global_best_fitness:

            #store best fitness and postition
            self.global_best_fitness = particle.best_fitness
            self.global_best_position = particle.best_position.copy()

    def update_particles(self, inertia_weight, cognitive_weight, social_weight):
        for particle in self.particles:
            particle.update(self.global_best_position, inertia_weight, cognitive_weight, social_weight)

        



        