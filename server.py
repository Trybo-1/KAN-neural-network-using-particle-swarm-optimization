import asyncio
import json
import websockets

from PSO import swarm
from kan import network

HOST = "127.0.0.1"
PORT = 5000


def respond_to_states(particles,car_states):
    # Evaluate every particle
    outputs = []
    count = 0
    for state in car_states:
        network.set_parameters(particles[count].position)
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

def handle_evaluation(car_data):
    for data in car_data:
        particle_index = data["car"]
        reward = data["reward"]
        swarm.particles[particle_index].update_best(-reward)
        if swarm.particles[particle_index].best_fitness < swarm.global_best_fitness:
            save_best_kan()
        swarm.update_global_best(swarm.particles[particle_index])
        print(f"Particle {particle_index} | reward: {reward} | best reward: {-swarm.particles[particle_index].best_fitness}")

def sample_curves():
    network.set_parameters(swarm.global_best_position)
    message = []
    for layer_index, layer in enumerate(network.layers):
        for destination_index, neuron in enumerate(layer):
            for source_index, edge_function in enumerate(neuron.edge_functions):
                message.append(
                    {
                        "from_layer": layer_index,
                        "from_neuron": source_index,
                        "to_layer": layer_index + 1,
                        "to_neuron": destination_index,
                        "points": edge_function.spline.sample_curve(num_samples=10).tolist()
                    }
                )
    return message

network = network.KANNetwork(
    layer_sizes=[6, 16, 4, 2],
    degree=2,
    number_of_control_points=5
)

print("Loading best KAN...")
network = load_best_kan()

inertia_weight = 0.7
cognitive_weight = 1.5
social_weight = 1.5

num_of_particles = 20

swarm = swarm.Swarm(num_of_particles, number_of_parameters=len(network.get_parameters()))

swarm.particles[0].position = network.get_parameters()
swarm.global_best_position = network.get_parameters()


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
                "layer_sizes": network.architecture,
            }

        if data["type"] == "state":
            outputs = respond_to_states(swarm.particles, data["states"])
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
            handle_evaluation(data["car_data"])
            swarm.update_particles(inertia_weight, cognitive_weight, social_weight)
            print(f"Epoch {epoch} | Global best reward: {-swarm.global_best_fitness}")
            epoch += 1

            curve_data = sample_curves()
            for curve in curve_data:
                message = {
                    "type": "curve",
                    "curve_data": curve
                }
                await websocket.send(json.dumps(message))

            response = {
                "type": "restart epoch",
                "iteration": epoch,
                "global_best_reward": -swarm.global_best_fitness,
                "generation_best_reward": max([-particle.best_fitness for particle in swarm.particles])
            }
            print("done evaluating particles")

        await websocket.send(json.dumps(response))


async def main():
    async with websockets.serve(handle_client, HOST, PORT, max_size=2**22):
        print(f"Waiting for Godot on ws://{HOST}:{PORT}")
        await asyncio.Future()


asyncio.run(main())

        