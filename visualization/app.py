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

                if event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 1:
                        edge = (self.network_view.get_clicked_edge(event.pos))

                        if edge is not None:

                            self.network_view.selected_edge = edge

                            print(
                                "Selected edge:",
                                f"Layer {edge['layer']}",
                                f"Input {edge['input_index']}",
                                f"Output {edge['output_index']}"
                            )

                        else:

                            self.network_view.selected_edge = None

            self.screen.fill((20, 20, 30))

            self.network_view.draw(self.screen)

            pygame.display.flip()

            self.clock.tick(60)

        pygame.quit()