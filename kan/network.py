from kan.neuron import KANNeuron
class KANNetwork:

    def __init__(self, layers , degree = 2):
        self.layers = []
        self.degree = degree

        for i in range(1, len(layers)):

            input_size = layers[i-1]
            output_size = layers[i]

            layer = []

            for _ in range(output_size):
                layer.append(KANNeuron(input_size,degree))

            self.layers.append(layer)


    def forward(self, inputs):
        current_values = inputs

        for layer in self.layers:
            next_values = []

            for neuron in layer:
                output = neuron.forward(current_values)
                next_values.append(output)

            current_values = next_values

        return current_values

    def get_parameters(self):

        parameters = []

        for layer in self.layers:
            for neuron in layer:
                for edge_function in neuron.edge_functions:
                    # Add this edge's coefficients
                    parameters.extend(edge_function.coeff)

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

                    coefficient_count = len(edge_function.coeff)

                    edge_function.coeff = parameters[index:index + coefficient_count]

                    index += coefficient_count


