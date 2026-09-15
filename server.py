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

swarm = swarm.Swarm(number_of_particles=20, number_of_parameters=len(network.get_parameters()))

inertia_weight = 0.7
cognitive_weight = 1.5
social_weight = 1.5

def respond_to_state(car_state):
    # Evaluate every particle
    return network.forward(car_state)


async def handle_client(websocket):
    print("Godot connected")

    async for message in websocket:
        data = json.loads(message)

        print("Received:", data)

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
            swarm.update_particles(data["fitness"])
            response = {
                "type": "ready"
            }
        
        await websocket.send(json.dumps(response))


async def main():
    async with websockets.serve(handle_client, HOST, PORT):
        print(f"Waiting for Godot on ws://{HOST}:{PORT}")
        await asyncio.Future()


asyncio.run(main())

