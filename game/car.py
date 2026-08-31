from pygame import Vector2

from wheel import wheel

class car:
    
    def __init__(self, x, y, angle):
        self.position = Vector2(x, y)
        self.angle = angle
        self.velocity = Vector2(0, 0)
        self.wheels = [wheel(Vector2(0,1)),wheel(Vector2(0,0)),wheel(Vector2(0,0)),wheel(Vector2(0,0))]
        self.max_velocity = 3
        self.max_stopping_velocity = 4
        self.friction = Vector2(0.02,0)
    
    def drive(self,x : float):
        y = x 
        if self.velocity[0] > self.max_velocity:
            y = 0
        self.velocity += Vector2(y,0).rotate(-self.angle)

    def brake(self,x:float):
        y=x
        if self.velocity[0] < -self.max_stopping_velocity:
            y = 0
        self.velocity -= Vector2(y,0).rotate(-self.angle)

    def update(self):
        if self.velocity[0] > 0:
            self.velocity -= self.friction
        if self.velocity[0] < 0:
            self.velocity += self.friction
        self.position += self.velocity