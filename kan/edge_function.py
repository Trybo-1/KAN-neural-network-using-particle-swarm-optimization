class EdgeFunction:

    def __init__(self,coeff: list):
        # Store the coefficients
        self.coeff = coeff
    

    def evaluate(self, x):
        # Calculate the function
        output = 0
        for i in range(len(self.coeff)):
            output += self.coeff[i] * x**i
        return output
