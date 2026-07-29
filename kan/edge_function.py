import random
class EdgeFunction:

    def __init__(self,degree=2):
        # Store the coefficients
        self.coeff = []
        self.degree = degree

        for i in range(degree+1):
            self.coeff.append(random.uniform(-0.1, 0.1))
    

    def evaluate(self, x):
        # Calculate the function
        output = 0
        for i in range(len(self.coeff)):
            output += self.coeff[i] * x**i
        return output
