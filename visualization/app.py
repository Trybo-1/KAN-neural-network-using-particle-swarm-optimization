import pygame

from visualization.network_visual import (NetworkVisual)


class App:

    def __init__(self, network):

        pygame.init()

        self.width = 960
        self.height = 540

        self.screen = (pygame.display.set_mode(( self.width, self.height)))

        pygame.display.set_caption("KAN Visualizer")

        self.clock = pygame.time.Clock()

        self.running = True

        self.network_view = NetworkVisual( network, self.width, self.height)


    def run(self):

        while self.running:

            for event in pygame.event.get():

                if (event.type == pygame.QUIT):
                    self.running = False


            self.screen.fill((20, 20, 30))

            self.network_view.draw(self.screen)

            pygame.display.flip()

            self.clock.tick(60)


        pygame.quit()