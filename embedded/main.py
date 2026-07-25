import json
import math
import sys
import time

from machine import I2C, Pin

# Constants
BMI160_I2C_ADDR = 0x68
ACCEL_SENSITIVITY = 16384.0  # ±2g sensitivity for the accelerometer in LSB/g

# Initialize I2C with specified pins
i2c = I2C(0, scl=Pin(19), sda=Pin(20), freq=400000)


def write_register(addr, reg, data):
    """Write data to a register."""
    i2c.writeto_mem(addr, reg, bytes([data]))


def read_register(addr, reg, length):
    """Read data from a register."""
    return i2c.readfrom_mem(addr, reg, length)


def initialize_bmi160():
    """Initialize the BMI160 sensor."""
    # Set accelerometer to normal mode
    write_register(BMI160_I2C_ADDR, 0x7E, 0x11)  # ACC_NORMAL_MODE
    time.sleep(0.1)


def read_raw_acceleration():
    """Read raw acceleration data."""
    data = read_register(BMI160_I2C_ADDR, 0x12, 6)  # Read accel data
    ax_raw = int.from_bytes(data[0:2], "little") - (1 << 16 if data[1] & 0x80 else 0)
    ay_raw = int.from_bytes(data[2:4], "little") - (1 << 16 if data[3] & 0x80 else 0)
    az_raw = int.from_bytes(data[4:6], "little") - (1 << 16 if data[5] & 0x80 else 0)
    return ax_raw, ay_raw, az_raw


def auto_calibrate():
    """Perform auto-calibration to remove noise or error."""
    print("Starting auto-calibration...")
    num_samples = 100
    ax_offset = 0
    ay_offset = 0
    az_offset = 0

    for _ in range(num_samples):
        ax_raw, ay_raw, az_raw = read_raw_acceleration()
        ax_offset += ax_raw
        ay_offset += ay_raw
        az_offset += az_raw
        time.sleep(0.01)  # Small delay between readings

    # Calculate average offsets
    ax_offset //= num_samples
    ay_offset //= num_samples
    az_offset //= num_samples

    # Assuming the sensor is stable, Z-axis should measure 1g (gravity)
    az_offset -= int(ACCEL_SENSITIVITY)

    print("Auto-calibration completed.")
    print("Offsets - X: {}, Y: {}, Z: {}".format(ax_offset, ay_offset, az_offset))

    return ax_offset, ay_offset, az_offset


def read_acceleration(ax_offset, ay_offset, az_offset):
    """Read raw acceleration data, apply offsets, and convert to m/s²."""
    ax_raw, ay_raw, az_raw = read_raw_acceleration()
    ax = ((ax_raw - ax_offset) / ACCEL_SENSITIVITY) * 9.81  # Convert to m/s²
    ay = ((ay_raw - ay_offset) / ACCEL_SENSITIVITY) * 9.81  # Convert to m/s²
    az = ((az_raw - az_offset) / ACCEL_SENSITIVITY) * 9.81  # Convert to m/s²
    return ax, ay, az


def calculate_tilt_angles(ax, ay, az):
    """Calculate pitch and roll angles from acceleration."""
    pitch = math.atan2(ay, math.sqrt(ax**2 + az**2)) * 180.0 / math.pi
    roll = math.atan2(-ax, az) * 180.0 / math.pi
    return pitch, roll


initialize_bmi160()
print("BMI160 Initialized")

# Perform auto-calibration
ax_offset, ay_offset, az_offset = auto_calibrate()

while True:
    try:
        # Read acceleration values
        ax, ay, az = read_acceleration(ax_offset, ay_offset, az_offset)

        # Calculate tilt angles
        pitch, roll = calculate_tilt_angles(ax, ay, az)

        data = {}
        fields = ["ax", "ay", "az", "pitch", "roll"]
        data = {name: globals()[name] for name in fields}
        sys.stdout.buffer.write(json.dumps(data).encode("utf-8"))

        # print("Acceleration (m/s²):")
        # print("  X: {:.2f} m/s², Y: {:.2f} m/s², Z: {:.2f} m/s²".format(ax, ay, az))
        #
        # print("Tilt Angles:")
        # print("  Pitch: {:.2f}°, Roll: {:.2f}°".format(pitch, roll))
        # print("=" * 50)

    except OSError as e:
        print("I2C Error: ", e)

    time.sleep(0.1)
