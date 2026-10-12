from kan.network import KANNetwork

network = KANNetwork(
    layer_sizes=[2,8,5],
    number_of_control_points=5,
    degree=3
)

#output = network.forward([7.5,8.0])
##   {
##     "from_layer": 0,
##     "from_neuron": 0,
##     "to_layer": 1,
##     "to_neuron": 0,
##     "points": [[-2.0, 0.1], [-1.0, 0.5], [0.0, 0.8], [1.0, 0.4], [2.0, 0.2]]
##   }
#print(network.to_JSON())
message = []
counter = 0
for layer_index, layer in enumerate(network.layers):
    for destination_index, neuron in enumerate(layer):
        for source_index, edge_function in enumerate(neuron.edge_functions):
            print(
                f"{layer_index} {source_index} -> "
                f"{layer_index + 1} {destination_index}"
            )
            message.append(
                {
                    "from_layer": layer_index,
                    "from_neuron": source_index,
                    "to_layer": layer_index + 1,
                    "to_neuron": destination_index,
                    "points": edge_function.spline.sample_curve(num_samples=20).tolist()
                }
            )
            counter +=1
print(f"Total edges: {counter}")
print(message)