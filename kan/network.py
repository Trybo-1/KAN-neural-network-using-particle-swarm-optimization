from kan.neuron import KANNeuron
class KANNetwork:

    def __init__(self, layer_sizes , degree = 2, number_of_control_points = 4):
        self.layers = []
        self.degree = degree
        self.architecture = layer_sizes.copy()
        self.number_of_control_points = number_of_control_points

        for layer_index in range(1, len(layer_sizes)):

            input_size = layer_sizes[layer_index-1]
            output_size = layer_sizes[layer_index]

            layer = []

            for _ in range(output_size):
                layer.append(KANNeuron(input_size,self.degree, self.number_of_control_points))

            self.layers.append(layer)


    def forward(self, inputs):
        current_values = inputs.copy()

        self.layer_values = [current_values.copy()]

        for layer in self.layers:
            next_values = []

            for neuron in layer:
                output = neuron.forward(current_values)
                next_values.append(output)

            current_values = next_values

            self.layer_values.append(current_values.copy())

        return current_values

    def get_parameters(self):

        parameters = []

        for layer in self.layers:
            for neuron in layer:
                for edge_function in neuron.edge_functions:
                    # Add this edge's coefficients
                    parameters.extend(edge_function.spline.control_points)

        return parameters


    def set_parameters(self, parameters):
        index = 0

        if len(parameters) != len(self.get_parameters()):
            raise ValueError(
                "Number of parameters provided is incorrect!"
            )

        for layer in self.layers:
            for neuron in layer:
                for edge_function in neuron.edge_functions:

                    coefficient_count = len(edge_function.spline.control_points)

                    edge_function.spline.control_points = parameters[index:index + coefficient_count]

                    index += coefficient_count


