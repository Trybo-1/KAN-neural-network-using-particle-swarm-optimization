import asyncio
import json
import websockets

from PSO import swarm
from kan import network

HOST = "127.0.0.1"
PORT = 5000


def respond_to_states(network1, network2, particles1, particles2, car_states):
    # Evaluate every particle
    outputs = []
    count = 0
    for state in car_states:
        if count < len(car_states) // 2:
            network = network1
            particles = particles1
        else:
            network = network2
            particles = particles2

        network.set_parameters(particles[count%len(particles)].position)
        outputs.append(network.forward(state))
        count += 1

    return outputs

def save_best_kan():
    best_kan = {
        "architecture": network.architecture,
        "degree": network.degree,
        "number_of_control_points": network.number_of_control_points,
        "parameters": swarm.global_best_position
    }

    with open("best_kan.kan", "w") as f:
        json.dump(best_kan, f, indent=4)

    print("Best KAN saved successfully.")

def load_best_kan():
    try:
        with open("best_kan.kan", "r") as f:
            best_kan = json.load(f)
            network.architecture = best_kan["architecture"]
            network.degree = best_kan["degree"]
            network.number_of_control_points = best_kan["number_of_control_points"]
            network.set_parameters(best_kan["parameters"])
            print("Best KAN loaded successfully.")
            return network
    except FileNotFoundError:
        print("No saved KAN found. Starting with a new network.")

def handle_evaluation(swarm1, swarm2, car_data):
    counter = 0
    for data in car_data:
        particle_index = data["car"]
        reward = data["reward"]
        if counter < len(car_data) // 2:
            swarm1.particles[particle_index].update_best(-reward)
            swarm1.update_global_best(swarm1.particles[particle_index])
        else:
            swarm2.particles[particle_index].update_best(-reward)
            swarm2.update_global_best(swarm2.particles[particle_index])

        #print(f"Swarm1 Particle {particle_index} | reward: {reward} | best reward: {-swarm1.particles[particle_index].best_fitness}")
        #print(f"Swarm2 Particle {particle_index} | reward: {reward} | best reward: {-swarm2.particles[particle_index].best_fitness}")
        counter += 1

def sample_bspline_curves():
    network_bspline.set_parameters(swarm_bspline.global_best_position)
    message = []
    for layer_index, layer in enumerate(network_bspline.layers):
        for destination_index, neuron in enumerate(layer):
            for source_index, edge_function in enumerate(neuron.edge_functions):
                message.append(
                    {
                        "from_layer": layer_index,
                        "from_neuron": source_index,
                        "to_layer": layer_index + 1,
                        "to_neuron": destination_index,
                        "points": edge_function.spline.sample_curve(num_samples=25).tolist()
                    }
                )
    return message

def sample_polynomial_curves():
    network_polynomial.set_parameters(swarm_polynomial.global_best_position)
    message = []
    for layer_index, layer in enumerate(network_polynomial.layers):
        for destination_index, neuron in enumerate(layer):
            for source_index, edge_function in enumerate(neuron.edge_functions):
                message.append(
                    {
                        "from_layer": layer_index,
                        "from_neuron": source_index,
                        "to_layer": layer_index + 1,
                        "to_neuron": destination_index,
                        "points": edge_function.sample_polynomial_curve(num_samples=25)
                    }
                )
    return message

network_bspline = network.KANNetwork(
    layer_sizes=[6, 4, 2],
    degree=2,
    number_of_control_points=5,
)

network_polynomial = network.KANNetwork(
    layer_sizes=[6, 4, 2],
    degree=2,
    number_of_control_points=5,
    type="polynomial"
)

print("Loading best KAN...")
#network = load_best_kan()

inertia_weight = 0.7
cognitive_weight = 1.5
social_weight = 1.5

num_of_particles = 20

swarm_bspline = swarm.Swarm(num_of_particles, number_of_parameters=len(network_bspline.get_parameters()))
swarm_polynomial = swarm.Swarm(num_of_particles, number_of_parameters=len(network_polynomial.get_parameters()))

swarm_bspline.particles[0].position = network_bspline.get_parameters()
swarm_bspline.global_best_position = network_bspline.get_parameters()

swarm_polynomial.particles[0].position = network_polynomial.get_parameters()
swarm_polynomial.global_best_position = network_polynomial.get_parameters()

async def handle_client(websocket):
    print("Godot connected")
    particle_index = 0
    epoch = 0

    async for message in websocket:
        data = json.loads(message)

        #print("Received:", data['type'])

        if data["type"] == "hello":
            response = {
                "type": "ready",
                "layer_sizes_bspline": network_bspline.architecture,
                "layer_sizes_polynomial": network_polynomial.architecture,
            }

        if data["type"] == "state":
            outputs = respond_to_states(network_bspline, network_polynomial, swarm_bspline.particles, swarm_polynomial.particles, data["states"])
            response = {
                "type": "action",
                "step": data["step"],
                "action": {
                    "throttle": [output[0]/(1+abs(output[0])) for output in outputs],
                    "steering": [output[1]/(1+abs(output[1])) for output in outputs]
                }
            }

        if data["type"] == "evaluation":
            #print(data)

            print("Evaluating particles...")
            handle_evaluation(swarm_bspline, swarm_polynomial, data["car_data"])
            swarm_bspline.update_particles(inertia_weight, cognitive_weight, social_weight)
            swarm_polynomial.update_particles(inertia_weight, cognitive_weight, social_weight)
            print(f"Epoch {epoch} | Global best reward bspline: {-swarm_bspline.global_best_fitness}")
            print(f"Epoch {epoch} | Global best reward polynomial: {-swarm_polynomial.global_best_fitness}")
            epoch += 1

            curve_data = sample_bspline_curves()
            for curve in curve_data:
                message = {
                    "type": "curve_bspline",
                    "from_layer": curve["from_layer"],
                    "from_neuron": curve["from_neuron"],
                    "to_layer": curve["to_layer"],
                    "to_neuron": curve["to_neuron"],
                    "points": curve["points"]
                }
                await websocket.send(json.dumps(message))
            
            curve_data = sample_polynomial_curves()
            for curve in curve_data:
                message = {
                    "type": "curve_polynomial",
                    "from_layer": curve["from_layer"],
                    "from_neuron": curve["from_neuron"],
                    "to_layer": curve["to_layer"],
                    "to_neuron": curve["to_neuron"],
                    "points": curve["points"]
                }
                await websocket.send(json.dumps(message))

            response = {
                "type": "restart epoch",
                "iteration": epoch,
                "global_best_reward_bspline": -swarm_bspline.global_best_fitness,
                "global_best_reward_polynomial": -swarm_polynomial.global_best_fitness,
            }
            print("done evaluating particles")

        if data["type"] == "best_cars_request":

            architecture = network_bspline.architecture
            degree = network_bspline.degree
            edge_function_type = network_bspline.type
            no_of_control_points = network_bspline.number_of_control_points
            fitness_bspline = -swarm_bspline.global_best_fitness
            best_position_bspline = swarm_bspline.global_best_position
            print(edge_function_type)
            message1 = {
                "type": "best_cars_response",
                "architecture": architecture,
                "degree": degree,
                "edge_function_type": edge_function_type,
                "number_of_control_points": no_of_control_points,
                "fitness": fitness_bspline,
                "parameters": best_position_bspline,
            }
            await websocket.send(json.dumps(message1))
            architecture = network_polynomial.architecture
            degree = network_polynomial.degree
            edge_function_type = network_polynomial.type
            no_of_control_points = network_polynomial.number_of_control_points
            fitness_polynomial = -swarm_polynomial.global_best_fitness
            best_position_polynomial = swarm_polynomial.global_best_position
            message2 = {
                "type": "best_cars_response",
                "architecture": architecture,
                "degree": degree,
                "edge_function_type": edge_function_type,
                "number_of_control_points": no_of_control_points,
                "fitness": fitness_polynomial,
                "parameters": best_position_polynomial,
            }
            await websocket.send(json.dumps(message2))

        await websocket.send(json.dumps(response))


async def main():
    async with websockets.serve(handle_client, HOST, PORT, max_size=2**22):
        print(f"Waiting for Godot on ws://{HOST}:{PORT}")
        await asyncio.Future()


asyncio.run(main())

        