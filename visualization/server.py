import asyncio
import json
import websockets

HOST = "127.0.0.1"
PORT = 5000


async def handle_client(websocket):
    print("Godot connected")

    async for message in websocket:
        data = json.loads(message)

        print("Received:", data)

        if data["type"] == "hello":
            response = {
                "type": "ready"
            }

            await websocket.send(json.dumps(response))


async def main():
    async with websockets.serve(handle_client, HOST, PORT):
        print(f"Waiting for Godot on ws://{HOST}:{PORT}")
        await asyncio.Future()


asyncio.run(main())