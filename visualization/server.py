import socket
import json

from PSO.swarm import Swarm
from kan.network import KANNetwork


HOST = "127.0.0.1"
PORT = 5000


server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind((HOST, PORT))
server.listen(1)

print(f"Waiting for Godot on {HOST}:{PORT}")

connection, address = server.accept()

print(f"Godot connected: {address}")


data = {
    "message": "Hello from Python",
    "architecture": [2, 2, 1],
    "layer_values": [
        [0.2, 0.8],
        [0.5, 0.6],
        [0.7]
    ]
}

json_data = json.dumps(data) + "\n"

connection.sendall(
    json_data.encode("utf-8")
)

print("Data sent to Godot")

connection.close()
server.close()

def send_data_to_godot(network : KANNetwork, swarm : Swarm, fitness_history : list):
    json_data = json.dumps(data) + "\n"