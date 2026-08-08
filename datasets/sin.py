import math
import random

inputs = []
targets = []

test_inputs = []
test_targets = []

number_of_samples = 100

for _ in range(number_of_samples):
    x = random.uniform(0, 2 * math.pi)

    # Normalize input to [0, 1]
    normalized_x = x / (2 * math.pi)

    inputs.append([normalized_x])

    # Keep the original mathematical target
    targets.append(math.sin(x))

for _ in range(20):
    x = random.uniform(0, 2 * math.pi)

    normalized_x = x / (2 * math.pi)

    test_inputs.append([normalized_x])

    test_targets.append(math.sin(x))