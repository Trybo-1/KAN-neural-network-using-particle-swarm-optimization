import pygame

class NetworkVisual:

    def __init__(self, network,width, height):
        self.network = network
        self.width = width
        self.height = height
        self.neuron_radius = 20
        self.positions = self.get_neuron_positions()
        self.inputs = [0.25,0.75]

        self.selected_edge = None

        #Fonts
        self.title_font = pygame.font.Font(None, 30)

        self.label_font = pygame.font.Font( None, 22)

        self.value_font = pygame.font.Font(None, 18)

    def draw(self, screen):

        self.network.forward(self.inputs)

        for layer_index in range(len(self.positions) - 1):

            current_layer = self.positions[layer_index]
            next_layer = self.positions[layer_index + 1]

            for input_index, pos1 in enumerate(current_layer):

                for output_index, pos2 in enumerate(next_layer):

                    selected = (
                        self.selected_edge is not None
                        and self.selected_edge["layer"] == layer_index
                        and self.selected_edge["input_index"] == input_index
                        and self.selected_edge["output_index"] == output_index
                    )

                    if selected:
                        line_color = (255, 200, 50)
                        line_width = 5

                    else:
                        line_color = (120, 120, 120)
                        line_width = 2

                    pygame.draw.line(
                        screen,
                        line_color,
                        pos1,
                        pos2,
                        line_width
                    )

        for layer in self.positions:
            for pos in layer:
                pygame.draw.circle(screen, (50, 150, 255), pos, self.neuron_radius)

        self.draw_layer_labels(
            screen
        )

        self.draw_neuron_values(
            screen
        )

    def get_neuron_positions(self):
        positions = []
        layer_sizes = self.network.architecture
        index = 0

        for layer in layer_sizes:
            layer_positions = []

            for j in range(layer):
                x = (self.width / (len(layer_sizes) + 1)) * (index + 1)
                y = (self.height / (layer + 1)) * (j + 1)
                layer_positions.append((int(x), int(y)))
            positions.append(layer_positions)
            index += 1
        return positions

    def draw_layer_labels(self, screen):

        labels = []
        number_of_layers = len(self.positions)

        for layer_index in range(number_of_layers):

            if layer_index == 0:
                label = "Input"

            elif (layer_index == number_of_layers - 1):
                label = "Output"

            else:
                label = (f"Hidden {layer_index}")

            labels.append(label)

        for layer_index, label in enumerate(labels):

            layer = (self.positions[layer_index])

            x = layer[0][0]

            text = (self.label_font.render(label, True, (230, 230, 230)))

            text_x = (x - text.get_width() / 2)

            screen.blit(text,(text_x,40))
            
    def draw_neuron_values(self, screen):

        for layer_index, layer in enumerate(self.positions):
            values = (self.network.layer_values[layer_index])

            for neuron_index, position in enumerate(layer):

                value = (values[neuron_index])
                value_text = (f"{value:.2f}")
                text = (self.value_font.render(value_text,True,(255, 255, 255)))
                text_rectangle = (text.get_rect(center=position))
                screen.blit(text,text_rectangle)

    def get_edges(self):

        edges = []

        for layer_index in range(len(self.positions) - 1):

            current_layer = self.positions[layer_index]
            next_layer = self.positions[layer_index + 1]

            for input_index, start_position in enumerate(current_layer):

                for output_index, end_position in enumerate(next_layer):

                    edges.append({
                        "start": start_position,
                        "end": end_position,
                        "layer": layer_index,
                        "input_index": input_index,
                        "output_index": output_index
                    })

        return edges

    def distance_to_line(self, point, start, end):

        px, py = point
        x1, y1 = start
        x2, y2 = end

        dx = x2 - x1
        dy = y2 - y1

        if dx == 0 and dy == 0:
            return ((px - x1) ** 2 + (py - y1) ** 2) ** 0.5

        t = (
            (px - x1) * dx +
            (py - y1) * dy
        ) / (dx * dx + dy * dy)

        t = max(0, min(1, t))

        closest_x = x1 + t * dx
        closest_y = y1 + t * dy

        distance = (
            (px - closest_x) ** 2 +
            (py - closest_y) ** 2
        ) ** 0.5

        return distance

    def get_clicked_edge(self, mouse_position):

        edges = self.get_edges()

        for edge in edges:

            distance = self.distance_to_line(
                mouse_position,
                edge["start"],
                edge["end"]
            )

            if distance < 8:
                return edge

        return None