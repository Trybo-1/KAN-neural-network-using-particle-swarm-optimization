import pygame
import math
import random

pygame.init()

# ============================================================
# SETTINGS
# ============================================================

WIDTH = 1200
HEIGHT = 800

FPS = 120

screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("2D Drift Car")

clock = pygame.time.Clock()

FONT = pygame.font.Font(None, 28)
BIG_FONT = pygame.font.Font(None, 42)


# ============================================================
# HELPERS
# ============================================================

def clamp(value, minimum, maximum):
    return max(minimum, min(maximum, value))


def rotate_vector(vector, angle):
    return vector.rotate(-math.degrees(angle))


# ============================================================
# WHEEL
# ============================================================

class Wheel:

    def __init__(
        self,
        local_position,
        steering=False,
        driven=False
    ):
        self.local_position = pygame.Vector2(local_position)

        self.steering = steering
        self.driven = driven

        self.steering_angle = 0.0

        # Debug values
        self.slip_angle = 0.0
        self.lateral_velocity = 0.0
        self.longitudinal_velocity = 0.0

    def world_position(self, car):

        return (
            car.position
            + rotate_vector(
                self.local_position,
                car.angle
            )
        )

    def velocity(self, car):

        r = rotate_vector(
            self.local_position,
            car.angle
        )

        # Velocity caused by car rotation
        rotational_velocity = pygame.Vector2(
            -car.angular_velocity * r.y,
            car.angular_velocity * r.x
        )

        return car.velocity + rotational_velocity

    def directions(self, car):

        # Car forward
        forward = pygame.Vector2(1, 0)

        forward = rotate_vector(
            forward,
            car.angle
        )

        # Steering
        forward = forward.rotate(
            -math.degrees(self.steering_angle)
        )

        right = pygame.Vector2(
            -forward.y,
            forward.x
        )

        return forward, right


# ============================================================
# CAR
# ============================================================

class Car:

    def __init__(self, position):

        self.position = pygame.Vector2(position)

        self.velocity = pygame.Vector2(0, 0)

        self.angle = 0.0

        self.angular_velocity = 0.0

        # ----------------------------------------------------
        # Dimensions
        # ----------------------------------------------------

        self.length = 90
        self.width = 48

        # ----------------------------------------------------
        # Mass
        # ----------------------------------------------------

        self.mass = 1100

        # Moment of inertia
        self.inertia = 2800

        # ----------------------------------------------------
        # Engine
        # ----------------------------------------------------

        self.engine_force = 8500

        self.reverse_force = 4500

        # ----------------------------------------------------
        # Brakes
        # ----------------------------------------------------

        self.brake_force = 10000

        # ----------------------------------------------------
        # Steering
        # ----------------------------------------------------

        self.max_steering_angle = math.radians(32)

        # ----------------------------------------------------
        # Tire physics
        # ----------------------------------------------------

        self.tire_stiffness = 7.5

        self.front_grip = 1.0

        self.rear_grip = 0.82

        self.handbrake_grip = 0.12

        # Maximum lateral force per wheel
        self.max_tire_force = 5200

        # ----------------------------------------------------
        # Rolling resistance
        # ----------------------------------------------------

        self.rolling_resistance = 80

        # ----------------------------------------------------
        # Aerodynamic drag
        # ----------------------------------------------------

        self.air_drag = 0.35

        # ----------------------------------------------------
        # Wheels
        # ----------------------------------------------------

        wheel_x = 30
        wheel_y = 24

        self.wheels = [

            # Front left
            Wheel(
                (wheel_x, -wheel_y),
                steering=True,
                driven=False
            ),

            # Front right
            Wheel(
                (wheel_x, wheel_y),
                steering=True,
                driven=False
            ),

            # Rear left
            Wheel(
                (-wheel_x, -wheel_y),
                steering=False,
                driven=True
            ),

            # Rear right
            Wheel(
                (-wheel_x, wheel_y),
                steering=False,
                driven=True
            )
        ]

        # ----------------------------------------------------
        # Smoke
        # ----------------------------------------------------

        self.smoke_particles = []

    # ========================================================
    # UPDATE
    # ========================================================

    def update(
        self,
        throttle,
        brake,
        steering,
        handbrake,
        dt
    ):

        throttle = clamp(throttle, 0.0, 1.0)

        brake = clamp(brake, 0.0, 1.0)

        steering = clamp(
            steering,
            -1.0,
            1.0
        )

        # ----------------------------------------------------
        # Steering
        # ----------------------------------------------------

        steering_angle = (
            steering
            * self.max_steering_angle
        )

        # ----------------------------------------------------
        # Forces
        # ----------------------------------------------------

        total_force = pygame.Vector2(0, 0)

        total_torque = 0.0

        # ----------------------------------------------------
        # Calculate wheel forces
        # ----------------------------------------------------

        for index, wheel in enumerate(self.wheels):

            # -----------------------------------------------
            # Steering
            # -----------------------------------------------

            if wheel.steering:
                wheel.steering_angle = steering_angle
            else:
                wheel.steering_angle = 0.0

            # -----------------------------------------------
            # Wheel position
            # -----------------------------------------------

            r = rotate_vector(
                wheel.local_position,
                self.angle
            )

            # -----------------------------------------------
            # Wheel velocity
            # -----------------------------------------------

            wheel_velocity = wheel.velocity(self)

            # -----------------------------------------------
            # Wheel directions
            # -----------------------------------------------

            forward, right = wheel.directions(self)

            # -----------------------------------------------
            # Velocity components
            # -----------------------------------------------

            longitudinal_velocity = (
                wheel_velocity.dot(forward)
            )

            lateral_velocity = (
                wheel_velocity.dot(right)
            )

            wheel.longitudinal_velocity = (
                longitudinal_velocity
            )

            wheel.lateral_velocity = (
                lateral_velocity
            )

            # -----------------------------------------------
            # Slip angle
            # -----------------------------------------------

            if abs(longitudinal_velocity) > 0.5:

                wheel.slip_angle = math.atan2(
                    lateral_velocity,
                    abs(longitudinal_velocity)
                )

            else:

                wheel.slip_angle = 0.0

            # -----------------------------------------------
            # Grip
            # -----------------------------------------------

            if wheel.driven:

                grip = self.rear_grip

            else:

                grip = self.front_grip

            # Handbrake reduces rear grip
            if handbrake and wheel.driven:

                grip *= self.handbrake_grip

            # -----------------------------------------------
            # Lateral tire force
            # -----------------------------------------------

            lateral_force = (
                -lateral_velocity
                * self.tire_stiffness
                * grip
                * self.mass
                / 4
            )

            # -----------------------------------------------
            # Tire force limit
            # -----------------------------------------------

            max_force = (
                self.max_tire_force
                * grip
            )

            lateral_force = clamp(
                lateral_force,
                -max_force,
                max_force
            )

            # -----------------------------------------------
            # Engine force
            # -----------------------------------------------

            longitudinal_force = 0.0

            if wheel.driven:

                if throttle > 0:

                    longitudinal_force += (
                        throttle
                        * self.engine_force
                    )

            # -----------------------------------------------
            # Brake force
            # -----------------------------------------------

            if brake > 0:

                if abs(longitudinal_velocity) > 0.2:

                    brake_direction = (
                        -math.copysign(
                            1,
                            longitudinal_velocity
                        )
                    )

                    longitudinal_force += (
                        brake_direction
                        * brake
                        * self.brake_force
                    )

            # -----------------------------------------------
            # Wheel force
            # -----------------------------------------------

            wheel_force = (
                forward * longitudinal_force
                + right * lateral_force
            )

            total_force += wheel_force

            # -----------------------------------------------
            # Torque
            # -----------------------------------------------

            torque = (
                r.x * wheel_force.y
                - r.y * wheel_force.x
            )

            total_torque += torque

        # ====================================================
        # DRAG
        # ====================================================

        speed = self.velocity.length()

        if speed > 0.01:

            drag = (
                self.velocity
                * -speed
                * self.air_drag
            )

            total_force += drag

        # ====================================================
        # ROLLING RESISTANCE
        # ====================================================

        if speed > 0.01:

            rolling_force = (
                -self.velocity.normalize()
                * self.rolling_resistance
            )

            total_force += rolling_force

        # ====================================================
        # APPLY LINEAR PHYSICS
        # ====================================================

        acceleration = (
            total_force
            / self.mass
        )

        self.velocity += (
            acceleration * dt
        )

        self.position += (
            self.velocity * dt
        )

        # ====================================================
        # APPLY ROTATIONAL PHYSICS
        # ====================================================

        angular_acceleration = (
            total_torque
            / self.inertia
        )

        self.angular_velocity += (
            angular_acceleration
            * dt
        )

        # Rotational damping
        self.angular_velocity *= (
            1.0 - 1.5 * dt
        )

        self.angle += (
            self.angular_velocity
            * dt
        )

        # ====================================================
        # LIMIT EXTREME SPEED
        # ====================================================

        max_speed = 900

        if self.velocity.length() > max_speed:

            self.velocity.scale_to_length(
                max_speed
            )

        # ====================================================
        # SMOKE
        # ====================================================

        self.update_smoke(
            handbrake,
            dt
        )

    # ========================================================
    # SMOKE
    # ========================================================

    def update_smoke(self, handbrake, dt):

        # Spawn smoke when rear tires are sliding
        for wheel in self.wheels[2:]:

            if (
                abs(wheel.lateral_velocity) > 40
                or (
                    handbrake
                    and self.velocity.length() > 100
                )
            ):

                position = wheel.world_position(
                    self
                )

                self.smoke_particles.append(
                    {
                        "position": pygame.Vector2(
                            position
                        ),
                        "radius": random.uniform(
                            3,
                            6
                        ),
                        "life": 0.5
                    }
                )

        # Update particles
        for particle in self.smoke_particles:

            particle["life"] -= dt

            particle["radius"] += (
                8 * dt
            )

        # Remove dead particles
        self.smoke_particles = [
            particle
            for particle in self.smoke_particles
            if particle["life"] > 0
        ]

    # ========================================================
    # RESET
    # ========================================================

    def reset(self, position):

        self.position = pygame.Vector2(
            position
        )

        self.velocity = pygame.Vector2(
            0,
            0
        )

        self.angle = 0

        self.angular_velocity = 0

        self.smoke_particles.clear()


# ============================================================
# TRACK
# ============================================================

class Track:

    def __init__(self):

        self.outer = pygame.Rect(
            100,
            80,
            1000,
            640
        )

        self.inner = pygame.Rect(
            300,
            240,
            600,
            320
        )

    def draw(self, surface, camera):

        # World offset
        outer = self.outer.move(
            -camera.x,
            -camera.y
        )

        inner = self.inner.move(
            -camera.x,
            -camera.y
        )

        # Grass
        surface.fill(
            (35, 110, 45)
        )

        # Track
        pygame.draw.rect(
            surface,
            (65, 65, 65),
            outer
        )

        # Grass in center
        pygame.draw.rect(
            surface,
            (35, 110, 45),
            inner
        )

        # Track lines
        pygame.draw.rect(
            surface,
            (220, 220, 220),
            outer,
            5
        )

        pygame.draw.rect(
            surface,
            (220, 220, 220),
            inner,
            5
        )

        # Center dashed line
        center_y = (
            self.inner.top
            + self.inner.height // 2
        )

        for x in range(
            self.inner.left,
            self.inner.right,
            50
        ):

            pygame.draw.line(
                surface,
                (180, 180, 180),
                (
                    x - camera.x,
                    center_y - camera.y
                ),
                (
                    x + 25 - camera.x,
                    center_y - camera.y
                ),
                2
            )


# ============================================================
# DRAW CAR
# ============================================================

def draw_car(
    surface,
    car,
    camera
):

    screen_position = (
        car.position
        - camera
    )

    # --------------------------------------------------------
    # Smoke
    # --------------------------------------------------------

    for particle in car.smoke_particles:

        position = (
            particle["position"]
            - camera
        )

        alpha = int(
            150
            * (
                particle["life"]
                / 0.5
            )
        )

        smoke_surface = pygame.Surface(
            (
                int(particle["radius"] * 2),
                int(particle["radius"] * 2)
            ),
            pygame.SRCALPHA
        )

        pygame.draw.circle(
            smoke_surface,
            (190, 190, 190, alpha),
            (
                int(particle["radius"]),
                int(particle["radius"])
            ),
            int(particle["radius"])
        )

        surface.blit(
            smoke_surface,
            (
                position.x
                - particle["radius"],
                position.y
                - particle["radius"]
            )
        )

    # --------------------------------------------------------
    # Car body
    # --------------------------------------------------------

    car_surface = pygame.Surface(
        (
            car.length,
            car.width
        ),
        pygame.SRCALPHA
    )

    # Main body
    pygame.draw.rect(
        car_surface,
        (210, 40, 40),
        (
            0,
            0,
            car.length,
            car.width
        ),
        border_radius=8
    )

    # Windows
    pygame.draw.rect(
        car_surface,
        (35, 45, 55),
        (
            35,
            5,
            30,
            car.width - 10
        ),
        border_radius=4
    )

    # Front bumper
    pygame.draw.rect(
        car_surface,
        (230, 230, 230),
        (
            car.length - 5,
            4,
            5,
            car.width - 8
        )
    )

    # Rotate
    rotated = pygame.transform.rotate(
        car_surface,
        math.degrees(car.angle)
    )

    rect = rotated.get_rect(
        center=screen_position
    )

    surface.blit(
        rotated,
        rect
    )

    # --------------------------------------------------------
    # Wheels
    # --------------------------------------------------------

    for wheel in car.wheels:

        position = (
            wheel.world_position(car)
            - camera
        )

        wheel_surface = pygame.Surface(
            (20, 10),
            pygame.SRCALPHA
        )

        pygame.draw.rect(
            wheel_surface,
            (15, 15, 15),
            (0, 0, 20, 10),
            border_radius=2
        )

        wheel_angle = (
            math.degrees(car.angle)
            + math.degrees(
                wheel.steering_angle
            )
        )

        rotated_wheel = (
            pygame.transform.rotate(
                wheel_surface,
                wheel_angle
            )
        )

        wheel_rect = (
            rotated_wheel.get_rect(
                center=position
            )
        )

        surface.blit(
            rotated_wheel,
            wheel_rect
        )


# ============================================================
# DEBUG
# ============================================================

def draw_debug(
    surface,
    car
):

    # Car forward
    forward = rotate_vector(
        pygame.Vector2(1, 0),
        car.angle
    )

    pygame.draw.line(
        surface,
        (0, 255, 0),
        car.position,
        car.position + forward * 70,
        3
    )

    # Velocity
    if car.velocity.length() > 1:

        velocity_direction = (
            car.velocity.normalize()
            * 70
        )

        pygame.draw.line(
            surface,
            (255, 255, 0),
            car.position,
            car.position + velocity_direction,
            3
        )


# ============================================================
# MAIN
# ============================================================

car = Car(
    (
        WIDTH / 2,
        HEIGHT / 2
    )
)

track = Track()

running = True

while running:

    dt = clock.tick(FPS) / 1000.0

    dt = min(
        dt,
        0.02
    )

    # ========================================================
    # EVENTS
    # ========================================================

    for event in pygame.event.get():

        if event.type == pygame.QUIT:

            running = False

        if event.type == pygame.KEYDOWN:

            if event.key == pygame.K_r:

                car.reset(
                    (
                        WIDTH / 2,
                        HEIGHT / 2
                    )
                )

    # ========================================================
    # INPUT
    # ========================================================

    keys = pygame.key.get_pressed()

    # Throttle
    throttle = 0.0

    if keys[pygame.K_w]:

        throttle = 1.0

    # Brake
    brake = 0.0

    if keys[pygame.K_s]:

        brake = 1.0

    # Steering
    steering = 0.0

    if keys[pygame.K_a]:

        steering -= 1.0

    if keys[pygame.K_d]:

        steering += 1.0

    # Handbrake
    handbrake = keys[pygame.K_SPACE]

    # ========================================================
    # UPDATE
    # ========================================================

    car.update(
        throttle,
        brake,
        steering,
        handbrake,
        dt
    )

    # ========================================================
    # CAMERA
    # ========================================================

    camera = (
        car.position
        - pygame.Vector2(
            WIDTH / 2,
            HEIGHT / 2
        )
    )

    # ========================================================
    # DRAW
    # ========================================================

    track.draw(
        screen,
        camera
    )

    draw_car(
        screen,
        car,
        camera
    )

    # ========================================================
    # DEBUG
    # ========================================================

    draw_debug(
        screen,
        car
    )

    # ========================================================
    # UI
    # ========================================================

    speed = (
        car.velocity.length()
        * 0.12
    )

    speed_text = FONT.render(
        f"Speed: {speed:.0f} km/h",
        True,
        (255, 255, 255)
    )

    screen.blit(
        speed_text,
        (20, 20)
    )

    # Drift angle
    drift_angle = 0.0

    if car.velocity.length() > 10:

        forward = rotate_vector(
            pygame.Vector2(1, 0),
            car.angle
        )

        velocity_direction = (
            car.velocity.normalize()
        )

        dot = clamp(
            forward.dot(
                velocity_direction
            ),
            -1.0,
            1.0
        )

        drift_angle = math.degrees(
            math.acos(dot)
        )

    drift_text = FONT.render(
        f"Drift angle: {drift_angle:.1f}°",
        True,
        (255, 255, 255)
    )

    screen.blit(
        drift_text,
        (20, 50)
    )

    controls = FONT.render(
        "W: throttle   S: brake   "
        "A/D: steer   SPACE: handbrake   R: reset",
        True,
        (255, 255, 255)
    )

    screen.blit(
        controls,
        (
            20,
            HEIGHT - 40
        )
    )

    # ========================================================
    # DISPLAY
    # ========================================================

    pygame.display.flip()


pygame.quit()