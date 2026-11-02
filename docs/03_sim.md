# Step 3 — Drive a simulated YAM with the GELLO (MuJoCo)

**Goal:** before touching the real robot, confirm in sim that every joint, and the gripper, moves the
**right direction, by the right amount**. A calibration mistake here costs nothing. On the real arm
it means a sudden motion.

The sim uses the YAM model in `third_party/mujoco_menagerie/i2rt_yam/` (from
[MuJoCo Menagerie](https://github.com/google-deepmind/mujoco_menagerie/tree/main/i2rt_yam)).
No tasks, objects, or recording. It's just the arm.

---

## 3.1 Launch (one arm at a time)

Needs a desktop session, because a MuJoCo window opens. It won't work over plain SSH.

Hold the GELLO in roughly the **zero pose** from Step 2 (the sim arm starts there), then:

```bash
source .venv/bin/activate && python experiments/launch_yaml.py --left-config-path configs/yam_auto_generated_sim_left.yaml
```

What happens:
1. A MuJoCo viewer window opens with one YAM.
2. The terminal prints `Moving robot to start position: [0. 0. 0. 0. 0. 0. 1.]`, then
   `Start 🚀🚀🚀`.
3. From then on the sim arm **follows the GELLO**. The terminal shows the loop rate, which should be
   close to the GELLO read rate (hundreds of Hz).

**To quit:** press **Ctrl+C** in the terminal. Closing the viewer window alone does not stop the
program.

Then test the right arm the same way. Note that it's still passed as `--left-config-path`:

```bash
python experiments/launch_yaml.py --left-config-path configs/yam_auto_generated_sim_right.yaml
```

> **Why not both arms at once?** `launch_yaml.py` does not support bimanual **sim**. Passing two sim
> configs fails with `ZMQError: Address already in use (addr='tcp://127.0.0.1:6001')`, because each
> sim arm starts its own server on the same port. Bimanual works on the **real** robot (Step 4).
> Testing each arm alone in sim is enough to validate its calibration.

## 3.2 Checklist — do this for every joint

Move **one joint at a time** on the GELLO and watch the sim:

| Check | Expected |
|-------|----------|
| GELLO in zero pose | Sim arm in zero pose (folded flat, pointing forward), like the photo in Step 2 |
| Joint 1 (base) | Sim base rotates the **same direction** as the GELLO base |
| Joints 2–6 | Each one moves the same direction, by about the same angle |
| No joint is 90°/180° off | e.g. GELLO wrist straight → sim wrist straight |
| Squeeze trigger | Sim fingers **close**. Release → fingers **open** fully |
| Move fast | Sim follows smoothly, no jumps or freezes |

If anything fails, **stop and fix it before Step 4**:

| Symptom | Likely cause → fix |
|---------|--------------------|
| A joint is off by exactly 90°/180°/360° | GELLO wasn't in pose during calibration → redo Step 2 |
| A joint moves the opposite way | Wrong joint sign for this hardware. Flip that joint's entry in `joint_signs` (1 ↔ -1) in **both** YAMLs for that arm, or remount the servo |
| Gripper stuck open/closed, or only half range | Trigger was squeezed during calibration → redo Step 2 with it released |
| Wrong arm moves / joints swapped | Left/right U2D2 mixed up → check `agent.port` in each YAML |
| Sim arm doesn't move at all, all zeros | Driver fell back to its **fake** servo driver (prints `Using fake Dynamixel driver`) → it couldn't reach the GELLO. See [troubleshooting](troubleshooting.md#using-fake-dynamixel-driver) |
| `Address already in use` | A previous run is still alive → `pkill -f launch_yaml.py`, retry |

✅ **Done when:** both arms pass the checklist.

Next: [Step 4 — GELLO → real YAM](04_real_robot.md)
