class_name Serial
extends Node

signal imu_data_received

# --- CONFIGURATION CONSTANTS ---
const PARITY_NONE = 0
const PARITY_ODD = 1
const PARITY_EVEN = 2

const STOP_BITS_ONE = 1
const STOP_BITS_TWO = 2

const FLOW_CONTROL_NONE = 0
const FLOW_CONTROL_SOFTWARE = 1
const FLOW_CONTROL_HARDWARE = 2

var serial: GdSerial

var manager: GdSerialManager

func _ready() -> void:
	run_serial_manager()

## Using GdSerialManager for non-blocking multi-port access
func run_serial_manager() -> void:
	print("\n--- Running Manager Example (Async) ---")
	manager = GdSerialManager.new()
	
	print("Available COM ports:")
	var ports: Dictionary = manager.list_ports()
	for i: int in ports:
		var port_info: Dictionary = ports[i]
		print("Port: ", port_info["port_name"], " (", port_info["device_name"], ") - Type: ", port_info["port_type"])
	# Connect signals for async events
	manager.data_received.connect(_on_serial_data)
	manager.port_disconnected.connect(_on_serial_disconnect)
	
	# Open a port in async mode
	# This starts a dedicated reader thread automatically
	if manager.open("/dev/ttyACM0", 115200, 1000):
		print("Port /dev/ttyACM0 opened using Manager")
	else:
		print("Failed to open /dev/ttyACM0 with Manager")

# For the Manager to work, you must call poll_events() periodically
# (e.g., in _process) to trigger signals and receive data
func _process(_delta: float) -> void:
	if manager:
		# poll_events() returns an Array of Dictionaries with event details
		# AND emits the data_received / port_disconnected signals
		var events: Array = manager.poll_events()
		for event: Dictionary in events:
			if event.has("disconnected"):
				print("Event Polling: Port ", event["port"], " disconnected!")

# Signal callback for new data
func _on_serial_data(port: String, data: PackedByteArray) -> void:
	var json_string := data.get_string_from_utf8()
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var linear_acceleration = Vector3(json.data.ax, json.data.ay, json.data.az)
		imu_data_received.emit(linear_acceleration)
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())

# Signal callback for disconnection
func _on_serial_disconnect(port: String) -> void:
	print("Critical: Port ", port, " was disconnected!")
