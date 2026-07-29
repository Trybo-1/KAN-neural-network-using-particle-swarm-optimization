from kan.edge_function import EdgeFunction
class KANNeuron:

    def __init__(self, input_size = 2, degree = 2):
        # Store the edge functions
        self.edge_functions = []

        for i in range(input_size):
            self.edge_functions.append(EdgeFunction(degree))

    def forward(self, inputs):
        # Evaluate every edge function
        # Add the results
        # Return the final output

        if len(inputs) != len(self.edge_functions):
            raise ValueError(
                "The number of inputs do not match the number of edge functions"
            )
        
        output = 0
        for input_value, edge_function in zip(inputs, self.edge_functions):
            output += edge_function.evaluate(input_value)
        return output

