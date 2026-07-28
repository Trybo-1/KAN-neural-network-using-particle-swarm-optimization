from neuron import KANNeuron
class KANNetwork:

    def __init__(self, layers = [2,2,1], degree = 2):
        self.layers = []

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

network = KANNetwork(
    layers=[2, 2, 1],
    degree=2
)

print(network.forward([0, 1]))
