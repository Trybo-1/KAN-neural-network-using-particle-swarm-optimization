import pygame
from car import car

class visualizer:

    def __init__(self):
        self.car = car(600,400,0)


    def visualize(self):
        car = self.car
        # pygame setup
        pygame.init()
        screen = pygame.display.set_mode((1280, 720))
        clock = pygame.time.Clock()
        running = True

        while running:

            for event in pygame.event.get():

                if event.type == pygame.QUIT:
                    running = False

            keys = pygame.key.get_pressed()
            if keys[pygame.K_w]:
                car.drive(1)
            if keys[pygame.K_s]:
                car.brake(1)

            car.update()
            

            screen.fill((20, 20, 30))
            carrect = pygame.Rect(car.position[0],car.position[1],25,15)
            pygame.draw.rect(screen,(250,0,0),carrect)

            pygame.display.flip()

            clock.tick(60)
