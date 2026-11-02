# Step 1 — Set up and verify the servos with Dynamixel Wizard

**Goal:** every servo in each GELLO arm has the right **ID (1–7, base → gripper)** and
**Baud Rate (3 Mbps)**, answers on the bus, and reports a sensible position when moved by hand.

Do this once per GELLO arm (left and right). It takes ~20 minutes per arm the first time.

---

## What you need

| Item | Notes |
|------|-------|
| GELLO arm | 7 Dynamixel servos: joints 1–6 + gripper trigger (ID 7). |
| **U2D2** | ROBOTIS USB ↔ Dynamixel adapter. Shows up on Linux as an FTDI serial device. One per arm. |
| **U2D2 Power Hub** (blue board) + power supply | The U2D2 **does not power the servos**. Power comes in through the hub's barrel jack. |
| Short 3-pin Dynamixel cable | For connecting a single servo during ID setup. |
| Linux PC | Ubuntu 22.04/24.04 tested. |

> ⚠️ **Check the supply voltage before you plug anything in.** Read the model printed on each
> servo's label (e.g. `XL330-M288-T`, `XC330-T288-T`, `XM430-W210-T`) and look up its rated
> voltage in the [ROBOTIS e-Manual](https://emanual.robotis.com/docs/en/dxl/x/). XL330 servos are
> **5 V** parts and will be damaged by a 12 V supply. Every servo on one bus shares the same supply,
> so they all need to accept that voltage.

---

## 1.1 Install Dynamixel Wizard 2.0 (Linux)

1. Download the Linux installer from
   <https://emanual.robotis.com/docs/en/software/dynamixel/dynamixel_wizard2/>
   (section "Software Installation" → Linux).
2. Make it executable and run it:
   ```bash
   chmod 775 DynamixelWizard2Setup-x86_64 && ./DynamixelWizard2Setup-x86_64
   ```
3. Give your user access to serial ports, then **log out and back in** (or reboot):
   ```bash
   sudo usermod -aG dialout $USER
   ```
   Without this, Wizard (and every script in this repo) gets "permission denied" on `/dev/ttyUSB*`.

## 1.2 Find your U2D2's serial device

Plug the U2D2 into the PC over USB and run:
```bash
ls -l /dev/serial/by-id/
```
You should see something like:
```
usb-FTDI_USB__-__Serial_Converter_FT3M9NVB-if00-port0 -> ../../ttyUSB0
```
- The `FT3M9NVB` part is that U2D2's **serial number**. It never changes, so this repo's configs always
  use the full `/dev/serial/by-id/...` path, not `/dev/ttyUSB0`, which can swap between the two arms
  after a reboot.
- **Label each U2D2 with its serial** (tape on the cable). With two arms you need to know which is left
  and which is right.
- To tell them apart: plug in only one, run `ls /dev/serial/by-id/`, and write down the name.

## 1.3 Set each servo's ID and baud rate — **one servo at a time**

New Dynamixels all ship as **ID 1 @ 57600 baud**. If two servos with the same ID share a bus, their
replies collide and neither can be configured. So connect **only one servo** to the U2D2/Power Hub at
a time while setting IDs. Unplug the daisy-chain cable at the servo you're working on, or set up
servos before assembly.

For each servo, starting at the **base (joint 1)** and ending at the **gripper trigger (7)**:

1. Connect: PC USB → U2D2 → Power Hub → **this one servo**. Power on. The servo's red LED blinks once.
2. In Wizard: **Options** (gear icon) → Scan settings:
   - Protocol: **2.0**
   - Port: your `ttyUSB*`
   - Baud rates: tick **57600** (factory default) **and 3000000** (in case it was already configured)
   - ID range: 0–252 (or 0–20 to make it faster)
3. Click **Scan**. The servo appears in the left panel with its model name and current ID.
   *Nothing found?* See [troubleshooting](troubleshooting.md#wizard-finds-nothing).
4. Select it. Make sure **Torque Enable (address 64) is OFF**. EEPROM fields are greyed out while torque is on.
5. Set **ID** (address 7) to this joint's number (1 for the base … 7 for the gripper trigger) → **Save**.
6. Set **Baud Rate** (address 8) to **3 Mbps** (value `5` on X-series) → **Save**.
   The servo drops off the scan list because it now talks at 3 Mbps. That's expected.
7. Rescan at **3000000** only. It should reappear with the new ID.
8. Physically label the servo with its ID (a dot of tape works).

| Joint | ID | Where |
|-------|----|-------|
| 1 | 1 | base yaw (bottom) |
| 2 | 2 | shoulder |
| 3 | 3 | elbow |
| 4 | 4 | wrist 1 |
| 5 | 5 | wrist 2 |
| 6 | 6 | wrist roll |
| gripper | 7 | trigger on the handle |

Both GELLO arms use IDs **1–7**. That's fine because each arm has its own U2D2 and bus.

## 1.4 Verify each servo actually works

Still in Wizard, with the servo selected:

1. **Read test (most important for a GELLO):** with **Torque OFF**, turn the servo horn by hand and
   watch **Present Position** (address 132) in the control table. It should change smoothly. A full turn
   is 4096 ticks, so ~11 ticks per degree. If the value jumps or freezes, the servo or cable is bad.
2. **Status:** **Hardware Error Status** (address 70) should be `0`. Non-zero usually means overvoltage,
   overheating, or overload. Check the supply voltage.
3. *(Optional)* **LED test:** toggle **LED** (address 65) to confirm writes work.
4. *(Optional, only if the servo is NOT yet in the arm)* **Motion test:** turn Torque ON, drag the
   goal-position dial a little, and the horn should move. **Turn Torque OFF again afterwards.** A GELLO is
   passive and the software expects torque off.

## 1.5 Verify the whole chain

Once all 7 servos have IDs:

1. Daisy-chain them as built (base → … → gripper), with the U2D2 + Power Hub at the base.
2. In Wizard, scan at **3000000 only**, IDs 0–20. You should see **exactly 7 servos, IDs 1–7**.
   - Fewer than 7: a cable between two servos is loose or damaged. The missing IDs tell you where the
     chain breaks, since everything after a bad cable also disappears.
   - Duplicate or garbled entries: two servos share an ID. Go back to 1.3 for the duplicated one.
3. Move each joint by hand, one at a time, and confirm only the matching ID's Present Position changes.
   This catches servos that got the wrong ID.
4. **Disconnect Wizard from the port** (Disconnect button, or close Wizard). Only one program can use
   the serial port at a time.
   > ⚠️ The GELLO driver in this repo **kills any process holding the port** when it starts
   > (`fuser -k` in `gello/dynamixel/driver.py`). If Wizard is still connected it will be force-closed
   > and you may lose unsaved changes. Close it yourself first.

## 1.6 Verify from Python (same code path the teleop uses)

After [installing this repo](../README.md#install), with Wizard closed, read all 7 servos
through the repo's driver (replace the port with yours):

```bash
source .venv/bin/activate && python -c "import time; from gello.dynamixel.driver import DynamixelDriver; d = DynamixelDriver([1,2,3,4,5,6,7], port='/dev/serial/by-id/usb-FTDI_USB__-__Serial_Converter_FT3M9NVB-if00-port0', baudrate=3000000, use_fake_fallback=False); [print(d.get_joints().round(2)) or time.sleep(0.2) for _ in range(50)]; d.close()"
```

- **Good:** 50 lines of 7 numbers (radians) that change as you move the GELLO.
- **Bad:** `Failed to set torque mode for Dynamixel with ID N` followed by endless
  `warning, comm failed: -3001`. Servo N (or everything) isn't answering. `-3001` is a receive
  timeout. Press Ctrl+C, then check power, the cable, and the ID/baud from 1.3–1.5.

> `use_fake_fallback=False` matters: by default the driver silently switches to a **fake** servo
> driver that always reads zeros if it can't connect, which looks like "working" but isn't.

## 1.7 (Optional) Persistent low-latency USB

The driver puts the FTDI adapter into 1 ms low-latency mode each time it connects, so this is optional.
To make it stick across unplug/reboot, install a udev rule. **Pass your own U2D2 serials**, because the
script's built-in defaults are one specific lab's adapters:
```bash
bash scripts/install_ftdi_latency_udev.sh FT3M9NVB FTAKRMFX
```

✅ **Done when:** Wizard sees exactly IDs 1–7 at 3 Mbps on each arm, every joint's Present Position
tracks hand motion, and the Python read in 1.6 prints changing values.

Next: [Step 2 — Calibration](02_calibration.md)
