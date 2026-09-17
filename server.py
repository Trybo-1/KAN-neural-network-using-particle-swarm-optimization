import asyncio
import json
import websockets

from PSO import swarm
from kan import network

HOST = "127.0.0.1"
PORT = 5000


network = network.KANNetwork(
    layer_sizes=[6, 18, 9, 2],
    degree=2,
    number_of_control_points=5
)

inertia_weight = 0.7
cognitive_weight = 1.5
social_weight = 1.5

num_of_particles = 20

swarm = swarm.Swarm(num_of_particles, number_of_parameters=len(network.get_parameters()))



def respond_to_state(car_state):
    # Evaluate every particle
    return network.forward(car_state)

def save_best_kan():
    best_kan = {
        "architecture": network.architecture,
        "degree": network.degree,
        "number_of_control_points": network.number_of_control_points,
        "parameters": swarm.global_best_position
    }

    with open("best_kan.kan", "w") as f:
        json.dump(best_kan, f, indent=4)

def load_best_kan():
    try:
        with open("best_kan.kan", "r") as f:
            best_kan = json.load(f)
            network.architecture = best_kan["architecture"]
            network.degree = best_kan["degree"]
            network.number_of_control_points = best_kan["number_of_control_points"]
            network.set_parameters(best_kan["parameters"])
            print("Best KAN loaded successfully.")
    except FileNotFoundError:
        print("No saved KAN found. Starting with a new network.")


async def handle_client(websocket):
    print("Godot connected")
    particle_index = 0
    epoch = 0

    async for message in websocket:
        data = json.loads(message)

        #print("Received:", data)

        if data["type"] == "hello":
            response = {
                "type": "ready"
            }

        if data["type"] == "state":
            outputs = respond_to_state(data["state"])
            response = {
                "type": "action",
                "step": data["step"],
                "action": {
                    "throttle": outputs[0]/(1+abs(outputs[0])),
                    "steering": outputs[1]/(1+abs(outputs[1]))
                }
            }

        if data["type"] == "evaluation":

            #update the particle's best position and fitness
            swarm.particles[particle_index].update_best(-data["reward"])

            if swarm.particles[particle_index].best_fitness < swarm.global_best_fitness:
                save_best_kan()


            swarm.update_global_best(swarm.particles[particle_index])
            print(f"Epoch {epoch} | Particle {particle_index} | Best fitness: {swarm.particles[particle_index].best_fitness:.6f} | Global best fitness: {swarm.global_best_fitness:.6f}")

            
            particle_index = particle_index + 1
            if particle_index >= num_of_particles:
                particle_index = 0
                epoch += 1
                swarm.update_particles(inertia_weight, cognitive_weight, social_weight)

            network.set_parameters(swarm.particles[particle_index].position)

            response = {
                "type": "restart epoch"
            }
        
        await websocket.send(json.dumps(response))


async def main():
    async with websockets.serve(handle_client, HOST, PORT):
        print(f"Waiting for Godot on ws://{HOST}:{PORT}")
        await asyncio.Future()


asyncio.run(main())

        