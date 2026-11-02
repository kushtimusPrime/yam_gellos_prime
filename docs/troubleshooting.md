# Troubleshooting

## Servos / GELLO

### Wizard finds nothing
- Is the servo **powered**? The U2D2 alone does not power servos. You need the Power Hub + supply,
  and the servo LED should blink once at power-on.
- Is the cable in the U2D2's **TTL** (3-pin) port, not the RS-485 (4-pin) one?
- Scan **both** 57600 (factory default) and 3000000, protocol **2.0**, IDs 0–252.
- Still nothing? Use Wizard's **Firmware Recovery** (Tools menu). It works even if the ID/baud is unknown.

### Permission denied on `/dev/ttyUSB*`
```bash
sudo usermod -aG dialout $USER
```
then **log out and back in** (a new terminal is not enough).

### `Failed to set torque mode for Dynamixel with ID N` then endless `warning, comm failed: -3001`
`-3001` = receive timeout: the U2D2 opened fine but **no servo answered**. The driver still prints
`Successfully initialized` and then waits forever. Press Ctrl+C, then check:
- GELLO power is on
- the **baud rate**: every servo must be at 3 Mbps (Step 1.3)
- the **IDs**: must be 1–7 (Step 1.5)
- the cable from the U2D2 to the first servo

### `Using fake Dynamixel driver`
The driver couldn't connect after its retries, so it **silently substituted a fake driver that always
reads zeros**. Teleop "runs", but nothing tracks the GELLO. Scroll up for the real error (usually
the port doesn't exist or permission was denied). Check `ls /dev/serial/by-id/` against `agent.port`
in your YAML.

### Some IDs drop out intermittently (`[DXL] Servo ID N velocity/position unavailable`)
A loose daisy-chain connector near servo N, or a cable pinched by a joint. Reseat and re-route it.
Servos after a bad connector also drop out.

### Dynamixel Wizard got closed by itself
The GELLO driver force-kills any process holding the serial port when it starts. Close Wizard
before running any script in this repo.

## Calibration / sim

See the symptom table in [Step 3](03_sim.md#32-checklist--do-this-for-every-joint).

### `ZMQError: Address already in use`
A previous `launch_yaml.py` is still running, or bimanual **sim** was attempted (not supported, see
Step 3.1).
```bash
pkill -f launch_yaml.py
```

### MuJoCo window doesn't open / GLFW display error
The sim viewer needs a local display. Run it from a desktop session, not plain SSH.

## Real robot / CAN

### CAN interface missing or `DOWN`
```bash
bash scripts/reset_all_can.sh && ip -br link show type can
```
If the interface name is missing entirely, check the udev rule serials (Step 4.1) and replug the
adapter.

### YAM motor not responding
- Re-run `bash scripts/reset_all_can.sh`.
- Power-cycle the YAM.
- Check the CAN cable at each motor. Gripper cables at the wrist are a common failure point because
  they flex with every wrist roll.

### Robot jumps at startup
The YAM and the GELLO weren't both in the zero pose when you launched. See
[Step 4.3](04_real_robot.md#43-pre-flight-checklist).
