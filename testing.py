from kan.network import KANNetwork

network = KANNetwork(
    layer_sizes=[1, 1],
    number_of_control_points=5,
    degree=3
)

output = network.forward([7.5])