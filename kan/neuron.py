from edge_function import EdgeFunction
class KANNeuron:

    def __init__(self, edge_functions):
        # Store the edge functions
        self.edge_functions = edge_functions

    def forward(self, inputs):
        # Evaluate every edge function
        # Add the results
        # Return the final output

        if len(inputs) != len(self.edge_functions):
            raise ValueError
        
        output = 0
        for input_value, edge_function in zip(inputs, self.edge_functions):
            output += edge_function.evaluate(input_value)
        return output
