# KAN Neural Networks with Particle Swarm Optimization

A real-time experiment comparing **Kolmogorov–Arnold Networks (KANs)** with different learnable edge functions by training them to drive in a Godot retro-racing game.

The project connects a Python KAN/PSO backend to a Godot game over WebSocket. Cars receive observations from the track, the KAN produces steering and throttle actions, and the game evaluates driving performance. Particle Swarm Optimization (PSO) then updates the network parameters using the cars' rewards.

The two edge-function approaches being compared are:

- **B-spline KAN** — represents each edge function using a spline defined by control points. B-splines can model flexible, locally shaped curves.
- **Polynomial KAN** — represents each edge function as a polynomial. Polynomial functions use a different parameterization and can produce different curve shapes and optimization behaviour.

The project makes these learned functions visible, so the comparison is not limited to the cars' driving performance: you can also inspect how the edge functions change during training.

## Screenshots

### Main game, track, and training graphs

![Retro Racer main game showing the track and training graphs](images/game.png)

### Car loader

![Car loader interface](images/car_loader.png)

### Track selector

![Track selector interface](images/track_selector.png)

> If your image files use different names or capitalization, update the paths above to match the exact filenames in `images/`. GitHub paths are case-sensitive.

## What is being compared?

Both approaches use the same general KAN-based driving setup and are trained in the same game environment using PSO. The key difference is the **representation of the learnable functions on the network's edges**.

| Aspect | B-spline edge functions | Polynomial edge functions |
| --- | --- | --- |
| Function representation | Spline curves controlled by control points | Polynomial functions parameterized by coefficients |
| Curve flexibility | Can shape curves locally through spline control points | Polynomial coefficients affect the overall polynomial curve |
| What the visualizer shows | The learned spline curves on network edges | The learned polynomial curves on network edges |
| Training comparison | Track reward/fitness as PSO updates parameters | Track reward/fitness as PSO updates parameters |

The racing task provides a practical way to compare these choices. The game sends each car's state to Python, the KAN maps that state to driving actions, and the resulting driving performance is converted into a reward. PSO uses these evaluations to search for better network parameters.

The interface exposes two useful views of the comparison:

1. **Driving performance:** compare the reward/fitness curves over training iterations to see how each approach improves and how consistently it performs.
2. **Learned edge functions:** inspect the plotted functions associated with network connections to see the shapes learned by each representation.

The goal is to investigate how the choice of edge-function representation affects learning and driving performance in this environment. Results can depend on the network architecture, PSO settings, initialization, and run-to-run variation, so a single best run should not be treated as conclusive proof that one function type is always better.

## Requirements

### Python server

- Python 3
- NumPy
- `websockets`

The server uses Python standard-library modules as well as NumPy. It also requires the third-party `websockets` package for communication with Godot.

Install the dependencies:

```bash
python -m pip install numpy websockets
```

## Running the project

### 1. Start the Python server

1. Clone or download this repository.
2. Open a terminal in the repository root — the directory containing `server.py`.
3. Install the Python dependencies listed above.
4. Start the server:

   ```bash
   python server.py
   ```

The server listens at:

```text
ws://127.0.0.1:5000
```

Keep the terminal and server running while using the game.

### 2. Launch the Godot game

1. Open the game's `game/` folder.
2. Extract the game files if they are provided in an archive.
3. Run `retro racer.exe`.
4. Ensure the Python server is running so the game can connect to it.

**Start the Python server before launching the game.**

## Loading saved cars for inference

Saved networks are provided in the `saved_cars/` directory. To load them in the packaged game, copy the saved-car folder into the Godot user-data directory. The game uses Godot's `user://` path rather than loading saved cars directly from the repository directory.

1. Close the game if it is running.
2. Locate the Godot user-data directory for this project. On Windows, it is typically under:

   ```text
   %APPDATA%\Godot\app_userdata\<Project Name>\
   ```

   Replace `<Project Name>` with the actual data folder name used by this build.
3. Copy the `saved_cars/` folder into that directory. Preserve its internal structure, including the separate `bspline/` and `polynomial/` folders.
4. Start the Python server, then launch `retro racer.exe`.
5. Select an **inference track** in the track selector.
6. Open the car loader and select a saved network.

**Important:** inference cars can only be loaded when an inference track is selected. If the cars do not appear, check the Godot user-data location and make sure the saved folder structure has been preserved.

## How the system works

1. **Godot sends observations:** car state information is sent to Python over WebSocket.
2. **KAN inference:** the selected network maps the inputs to throttle and steering outputs.
3. **Game evaluation:** cars drive around the track and their performance is converted into rewards.
4. **PSO optimization:** the reward feedback is used to update particle bests and the swarm's global best, and PSO proposes new network parameters.
5. **Visual feedback:** the game displays fitness/reward curves and visualizations of the learned edge functions.
6. **Inference mode:** saved network parameters can be loaded to control cars without training those saved networks.

The server initializes both training networks with architecture `[6, 8, 2]`, polynomial degree `2`, and `5` control points as the initial configuration. Saved inference networks include their own architecture and parameters.

## Repository contents

| Path | Description |
| --- | --- |
| `server.py` | Python WebSocket server connecting Godot with the KAN and PSO implementations. |
| `kan/` | KAN network implementation. |
| `PSO/` | Particle Swarm Optimization implementation. |
| `bspline/` | B-spline edge-function implementation. |
| `datasets/` | Dataset-related code. |
| `utils/` | Supporting utilities. |
| `saved_cars/` | Saved network parameters for inference. |
| `images/` | Screenshots of the car loader, main game interface, and track selector. |
| `game/` | Packaged Godot game files, including `retro racer.exe`. |

## Troubleshooting

- **The game does not connect:** confirm that `python server.py` is running and listening at `ws://127.0.0.1:5000`.
- **Python reports a missing module:** run `python -m pip install numpy websockets` with the same Python installation used to start the server.
- **Inference cars are missing:** copy `saved_cars/` into the correct Godot user-data directory and preserve its subfolders.
- **The car loader will not load a car:** select an inference track before opening the car loader.

## Notes

The repository contains the Python-side KAN/PSO implementation and supporting assets for the Godot demonstration. The packaged game is launched separately from the Python server; both are needed for the connected experience.
