import random

number_of_samples = 100

inputs = []
targets = []

test_inputs = []
test_targets = []

for _ in range(number_of_samples):
    x1 = random.uniform(0, 1)
    x2 = random.uniform(0, 1)
    inputs.append([x1, x2])
    targets.append(x1 + x2 - 2 * x1 * x2)


for _ in range(20):
    x1 = random.uniform(0, 1)
    x2 = random.uniform(0, 1)
    test_inputs.append([x1, x2])
    test_targets.append(x1 + x2 - 2 * x1 * x2)


