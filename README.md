# KAN Neural Network with Particle Swarm Optimization

A real-time demonstration of **Kolmogorov–Arnold Networks (KANs)** trained with **Particle Swarm Optimization (PSO)** inside a Godot retro racing game.

The project connects a Python backend to a Godot game over a WebSocket. During training, the game evaluates cars controlled by KANs and sends their rewards back to Python, where PSO updates the candidate network parameters. The project compares two edge-function types:

- **B-spline KAN**
- **Polynomial KAN**

The game also supports loading saved networks for inference, so trained cars can be tested on inference tracks.

## Project screenshots

The `images/` folder contains three screenshots:
- The car loader.
- The main game view, including the track, graphs, and fitness curve.
- The track selector.

Open the images in that folder to view the interface.

## Requirements

### Python server

- Python 3
- NumPy
- `websockets`

The Python code uses standard-library modules as well as NumPy, but **`websockets` is also a required third-party dependency** because the server communicates with Godot over WebSocket.

Install the dependencies:

```bash
python -m pip install numpy websockets
```

## Running the project

### 1. Start the Python server

1. Clone or download this repository.
2. Open a terminal in the repository's root directory — the directory containing `server.py`.
3. Install the Python dependencies listed above.
4. Start the server:

   ```bash
   python server.py
   ```

The server listens on:

```text
ws://127.0.0.1:5000
```

Keep the terminal and server running while you use the game.

### 2. Launch the Godot game

1. Open the game's `game/` folder.
2. Extract the game files if they are provided in an archive.
3. Run `retro racer.exe`.
4. Make sure the Python server is running so the game can connect to it.

Start the Python server **before** launching the game to avoid connection issues.

## Loading saved cars for inference

The repository includes a `saved_cars/` directory containing saved network data. The game uses Godot's `user://` data directory for loading saved cars, rather than loading them directly from the repository folder.

1. Close the game if it is running.
2. Locate the Godot user-data directory for this project. On Windows, Godot user data is typically stored under:

   ```text
   %APPDATA%\Godot\app_userdata\<Project Name>\
   ```

   Replace `<Project Name>` with the actual project/application data folder used by this build.
3. Copy the repository's `saved_cars/` folder into that user-data directory. Preserve the folder structure, including the separate `bspline/` and `polynomial/` folders.
4. Start the Python server, then launch `retro racer.exe`.
5. Select an **inference track** in the track selector before trying to load an inference car.
6. Use the car loader to choose a saved network.

**Important:** Saved inference cars can only be loaded while an inference track is selected. If cars do not appear, check that the `saved_cars` folder is in the correct Godot user-data directory and that its internal folder structure has not changed.

## How it works

1. **Godot sends state data** for the cars to the Python server over WebSocket.
2. **KANs produce driving actions** from the state inputs, including throttle and steering outputs.
3. **The cars are evaluated in the game** and receive rewards based on their performance.
4. **PSO updates network parameters** using the evaluation results.
5. **The interface displays training information**, including fitness/reward curves and visualizations of the networks' edge functions.
6. **Inference mode loads saved parameters** so a trained network can control a car without running the training process for that saved model.

The Python server currently initializes B-spline and polynomial KANs with the architecture `[6, 8, 2]`, degree `2`, and `5` control points. These are the server's initial training configurations; saved inference networks carry their own architecture and parameters.

## Repository contents

| Path | Description |
| --- | --- |
| `server.py` | Python WebSocket server connecting the game and KAN/PSO implementation. |
| `kan/` | KAN network implementation. |
| `PSO/` | Particle Swarm Optimization implementation. |
| `bspline/` | B-spline edge-function implementation. |
| `datasets/` | Dataset-related code. |
| `utils/` | Supporting utilities. |
| `saved_cars/` | Saved network parameters for inference. |
| `images/` | Screenshots of the car loader, main game interface, and track selector. |
| `game/` | Folder where the packaged Godot game executable is expected to be distributed. |

## Troubleshooting

- **The game does not connect:** Confirm that `python server.py` is still running and that the server reports it is waiting at `ws://127.0.0.1:5000`.
- **Python reports a missing module:** Run `python -m pip install numpy websockets` using the same Python installation that runs the server.
- **Inference cars are missing:** Copy `saved_cars/` into the correct Godot user-data directory and preserve the subfolders and saved files.
- **The car loader will not load a car:** Switch to an inference track first, then open the car loader again.

## Notes

This repository contains both the Python-side KAN/PSO implementation and supporting assets for the Godot demonstration. The packaged game is run separately from the Python server; both are needed for the connected experience.
