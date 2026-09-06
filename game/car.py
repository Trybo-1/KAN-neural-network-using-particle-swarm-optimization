import pygame
from wheel import Wheel


class Car:

    def __init__(self, position):

        # =================================================
        # POSITION / MOVEMENT
        # =================================================

        self.position = pygame.Vector2(position)

        self.velocity = pygame.Vector2(0, 0)

        # =================================================
        # ROTATION
        # =================================================

        self.angle = 0.0
        self.angular_velocity = 0.0

        # =================================================
        # PHYSICAL PROPERTIES
        # =================================================

        self.mass = 1200.0

        # Moment of inertia
        self.inertia = 3000.0

        # =================================================
        # CAR DIMENSIONS
        # =================================================

        self.length = 90.0
        self.width = 50.0

        # =================================================
        # ENGINE
        # =================================================

        self.engine_force = 8000.0

        # =================================================
        # BRAKES
        # =================================================

        self.brake_force = 12000.0

        # =================================================
        # STEERING
        # =================================================

        self.max_steering_angle = 30.0

        # =================================================
        # TIRE PHYSICS
        # =================================================

        self.tire_stiffness = 1.0

        self.tire_grip = 1.0

        # Rear grip multiplier when handbrake is used
        self.handbrake_grip = 0.15

        # =================================================
        # WHEELS
        # =================================================

        wheel_x = self.length * 0.35
        wheel_y = self.width * 0.5

        self.wheels = [

            # -------------------------
            # Front Left
            # -------------------------

            Wheel(
                (wheel_x, -wheel_y),
                steering=True,
                driven=False,
                grip=1.0,
                max_grip=1.0
            ),

            # -------------------------
            # Front Right
            # -------------------------

            Wheel(
                (wheel_x, wheel_y),
                steering=True,
                driven=False,
                grip=1.0,
                max_grip=1.0
            ),

            # -------------------------
            # Rear Left
            # -------------------------

            Wheel(
                (-wheel_x, -wheel_y),
                steering=False,
                driven=True,
                grip=0.85,
                max_grip=0.85
            ),

            # -------------------------
            # Rear Right
            # -------------------------

            Wheel(
                (-wheel_x, wheel_y),
                steering=False,
                driven=True,
                grip=0.85,
                max_grip=0.85
            )
        ]

    # =====================================================
    # UPDATE
    # =====================================================

    def update(
        self,
        throttle,
        brake,
        steering,
        handbrake,
        dt
    ):

        # =================================================
        # CLAMP INPUTS
        # =================================================

        throttle = max(
            0.0,
            min(1.0, throttle)
        )

        brake = max(
            0.0,
            min(1.0, brake)
        )

        steering = max(
            -1.0,
            min(1.0, steering)
        )

        handbrake = bool(handbrake)

        # =================================================
        # STEERING
        # =================================================

        steering_angle = (
            steering
            * self.max_steering_angle
        )

        # =================================================
        # TOTAL FORCES
        # =================================================

        total_force = pygame.Vector2(0, 0)

        total_torque = 0.0

        # =================================================
        # WHEEL FORCES
        # =================================================

        for i, wheel in enumerate(self.wheels):

            # ---------------------------------------------
            # Steering
            # ---------------------------------------------

            if wheel.steering:

                wheel.steering_angle = (
                    steering_angle
                )

            else:

                wheel.steering_angle = 0.0

            # ---------------------------------------------
            # Handbrake
            # ---------------------------------------------

            # Rear wheels only
            if i >= 2:

                wheel.handbrake = handbrake

            else:

                wheel.handbrake = False

            # ---------------------------------------------
            # Calculate forces
            # ---------------------------------------------

            force, torque = wheel.calculate_forces(
                self,
                throttle,
                brake,
                dt
            )

            total_force += force

            total_torque += torque

        # =================================================
        # AIR RESISTANCE
        # =================================================

        speed = self.velocity.length()

        if speed > 0.01:

            drag_force = (
                -self.velocity.normalize()
                * speed
                * speed
                * 0.15
            )

            total_force += drag_force

        # =================================================
        # LINEAR ACCELERATION
        # =================================================

        acceleration = (
            total_force
            / self.mass
        )

        self.velocity += (
            acceleration * dt
        )

        # =================================================
        # POSITION
        # =================================================

        self.position += (
            self.velocity * dt
        )

        # =================================================
        # ANGULAR ACCELERATION
        # =================================================

        angular_acceleration = (
            total_torque
            / self.inertia
        )

        self.angular_velocity += (
            angular_acceleration * dt
        )

        # =================================================
        # ROTATION
        # =================================================

        self.angle += (
            self.angular_velocity * dt
        )

    # =====================================================
    # RESET
    # =====================================================

    def reset(self, position):

        self.position = pygame.Vector2(
            position
        )

        self.velocity = pygame.Vector2(
            0,
            0
        )

        self.angle = 0.0

        self.angular_velocity = 0.0