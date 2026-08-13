from kan.edge_function import EdgeFunction
class KANNeuron:

    def __init__(self, input_size = 2, degree = 2, number_of_control_points = 4):
        self.edge_functions = []

        for _ in range(input_size):
            self.edge_functions.append(EdgeFunction(degree = degree, number_of_control_points = number_of_control_points))

    def forward(self, inputs):

        if len(inputs) != len(self.edge_functions):
            raise ValueError(
                "The number of inputs must match the number of edge functions"
            )
        
        output = 0.0
        for input_value, edge_function in zip(inputs, self.edge_functions):
            output += edge_function.evaluate(input_value)
        return output

