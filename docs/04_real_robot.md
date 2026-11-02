# Step 4 — GELLO → real YAM arm(s)

**Goal:** teleoperate the real YAM(s) over CAN with the same `launch_yaml.py` used in sim. The only
difference is the config: `configs/yam_auto_generated_left.yaml` instead of `..._sim_left.yaml`.

> ⚠️ **Only do this after both arms pass the [Step 3 sim checklist](03_sim.md#32-checklist--do-this-for-every-joint).**
> The real arm follows the GELLO immediately and stiffly. A calibration error becomes a fast,
> unexpected motion. Clear the workspace, keep the YAM's power switch / e-stop within reach, and
> run with two people the first time.

---

## 4.1 Name the CAN interfaces

Each YAM connects to the PC through its own USB-CAN adapter. Linux calls them `can0`, `can1`, …
in whatever order they enumerate, which can change between reboots. Give each a fixed name with a udev
rule so `left` is always the left arm.

1. Plug in **one** arm's CAN adapter and get its serial:
   ```bash
   udevadm info -a -p /sys/class/net/can* | grep -i serial
   ```
2. Repeat for the other adapter, plugging in one at a time so you know which serial is which.
3. Create the rules file:
   ```bash
   sudo nano /etc/udev/rules.d/90-can.rules
   ```
   with one line per arm. These names must match `robot.channel` in your configs. This repo's
   examples use `can_follow_l` / `can_follow_r`:
   ```
   SUBSYSTEM=="net", ACTION=="add", ATTRS{serial}=="<left-CAN-serial>", NAME="can_follow_l"
   SUBSYSTEM=="net", ACTION=="add", ATTRS{serial}=="<right-CAN-serial>", NAME="can_follow_r"
   ```
4. Reload, then **unplug and replug** both adapters:
   ```bash
   sudo udevadm control --reload-rules && sudo systemctl restart systemd-udevd && sudo udevadm trigger
   ```
5. Bring the interfaces up at 1 Mbit/s:
   ```bash
   bash scripts/reset_all_can.sh
   ```
6. Check:
   ```bash
   ip -br link show type can
   ```
   Expected: both names listed and `UP`.
   ```
   can_follow_r     UP             <NOARP,UP,LOWER_UP,ECHO>
   can_follow_l     UP             <NOARP,UP,LOWER_UP,ECHO>
   ```

Run `bash scripts/reset_all_can.sh` again any time after a reboot, a replug, or a CAN error.

If you named the interfaces differently, or skipped `--channel` in Step 2, fix `robot.channel` in
`configs/yam_auto_generated_left.yaml` / `_right.yaml` to match.

## 4.2 (Optional) Check the YAM by itself first

The YAM driver library ([i2rt](https://github.com/i2rt-robotics/i2rt), in `third_party/i2rt`) has a
zero-gravity demo: the arm holds itself up but moves freely by hand. It's a good way to confirm
CAN, power, and all motors before involving the GELLO:

```bash
python third_party/i2rt/i2rt/robots/motor_chain_robot.py --channel can_follow_l --gripper_type linear_4310
```

Move each joint by hand and confirm the arm compensates gravity smoothly. If a motor doesn't respond,
see [troubleshooting](troubleshooting.md#yam-motor-not-responding). Ctrl+C to exit, and be ready to
support the arm when you do.

## 4.3 Pre-flight checklist

Before every session:

- [ ] Both arms passed the sim checklist with **these exact configs** (no re-calibration since)
- [ ] `ip -br link show type can` shows both interfaces `UP`
- [ ] YAM(s) resting in the **zero pose** (folded, as in the [calibration photo](02_calibration.md#21-put-the-gello-in-the-calibration-zero-pose))
- [ ] GELLO(s) held in the **same zero pose**, trigger released
- [ ] Workspace clear, nothing within the arm's reach
- [ ] A hand on the YAM power switch / e-stop
- [ ] Dynamixel Wizard closed

**Why the zero pose matters** (from reading `experiments/launch_yaml.py` and `gello/robots/yam.py`):
on start, the script commands the YAM to `start_joints` (all zeros, gripper open), then immediately
starts following the GELLO. There is no gradual "catch up". So if the YAM rests elsewhere, it moves to
zero at startup. And if the GELLO isn't near zero when teleop begins, the YAM jumps to wherever the
GELLO is.

## 4.4 Launch — one arm first

```bash
source .venv/bin/activate && python experiments/launch_yaml.py --left-config-path configs/yam_auto_generated_left.yaml
```

Expected output:
```
Waiting for hardware server to start on 127.0.0.1:6001...
Moving robot to start position: [0. 0. 0. 0. 0. 0. 1.]
Launching robot: YAMRobot, agent: GelloAgent
Control loop: 100 Hz

Start 🚀🚀🚀
t=  3.21s Hz=... loop=...ms act(p50/p99)=... cmd(p50/p99)=... obs(p50/p99)=...
```

First moves: go **slowly**, one joint at a time, small motions. Confirm the real arm matches what you
saw in sim. Then try the gripper.

**To stop:** bring the GELLO back to the zero pose so the YAM is folded and resting, then press
**Ctrl+C**. The first time, keep a hand near the arm when you stop so you see how it behaves on exit.

Then test the right arm alone the same way with `configs/yam_auto_generated_right.yaml`
(still passed as `--left-config-path`).

## 4.5 Launch — both arms

```bash
python experiments/launch_yaml.py --left-config-path configs/yam_auto_generated_left.yaml --right-config-path configs/yam_auto_generated_right.yaml
```

Both GELLOs are read in parallel, and both YAMs are commanded in parallel
(`Bimanual YAM command dispatch: parallel`). General settings such as `hz` come from the **left** config.

✅ **Done when:** each YAM tracks its GELLO smoothly through the full range, grippers open and close
fully, and the terminal loop rate stays steady.

Problems? → [troubleshooting](troubleshooting.md)
