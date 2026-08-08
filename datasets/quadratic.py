import random

inputs = []
targets = []

test_inputs = []
test_targets = []

number_of_samples = 100

for _ in range(number_of_samples):

    x = random.uniform(1, 10)

    inputs.append([x / 1])
    targets.append(x ** 2)


for _ in range(20):

    x = random.uniform(1, 10)

    test_inputs.append([x / 1])
    test_targets.append(x ** 2)