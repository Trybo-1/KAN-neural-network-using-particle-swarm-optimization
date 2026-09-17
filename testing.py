from kan.network import KANNetwork

network = KANNetwork(
    layer_sizes=[2, 8,2],
    number_of_control_points=5,
    degree=3
)

output = network.forward([7.5,8.0])

print(network.to_JSON())