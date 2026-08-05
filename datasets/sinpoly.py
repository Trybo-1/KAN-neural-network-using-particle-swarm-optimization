import random
import math
    
number_of_samples = 100

inputs = []
targets = []

test_inputs = []
test_targets = []

for _ in range(number_of_samples):
    x1 = random.uniform(0, 2*math.pi)
    x2 = random.uniform(0, 2*math.pi)
    inputs.append([x1, x2])
    targets.append(math.sin(x1) + x2**2)


for _ in range(20):
    x1 = random.uniform(0, 2*math.pi)
    x2 = random.uniform(0, 2*math.pi)
    test_inputs.append([x1, x2])
    test_targets.append(math.sin(x1) + x2**2)


