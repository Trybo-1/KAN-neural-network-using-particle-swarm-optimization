import random
import math

number_of_samples = 200

inputs = []
targets = []

test_inputs = []
test_targets = []

for _ in range(number_of_samples):

    x1 = random.uniform(0, 2 * math.pi)
    x2 = random.uniform(0, 2 * math.pi)

    # Normalize inputs to [0, 1]
    normalized_x1 = x1 / (2 * math.pi)
    normalized_x2 = x2 / (2 * math.pi)

    inputs.append([normalized_x1, normalized_x2])

    # Keep the original mathematical target
    targets.append(math.sin(x1) + x2 ** 2)


for _ in range(20):

    x1 = random.uniform(0, 2 * math.pi)
    x2 = random.uniform(0, 2 * math.pi)

    normalized_x1 = x1 / (2 * math.pi)
    normalized_x2 = x2 / (2 * math.pi)

    test_inputs.append([normalized_x1, normalized_x2])

    test_targets.append(math.sin(x1) + x2 ** 2)


