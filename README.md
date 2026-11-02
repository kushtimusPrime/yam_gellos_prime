# YAM GELLO

Teleoperate one or two [I2RT YAM](https://i2rt.com/) arms with
[GELLO](https://wuphilipp.github.io/gello_site/) leader arms, in MuJoCo sim or on the real robot.

This is a **trimmed copy** of [`wuphilipp/gello_software`](https://github.com/wuphilipp/gello_software)
(via the lab fork [`nidhya-s/yam_gello_software`](https://github.com/nidhya-s/yam_gello_software)
@ `35e37d4`). It contains **only** the YAM + Dynamixel code path. The code is unchanged from that fork;
only files for other robots (UR, xArm, Franka, ROS 2, Quest, SpaceMouse, cameras, FACTR) were removed.
See [Where's the rest?](#wheres-the-rest-of-the-gello-code--history).

## Getting started — follow these in order

| Step | Guide | You'll have |
|------|-------|-------------|
| 0 | [Install](#install) (below) | Python env with everything |
| 1 | [Servos & Dynamixel Wizard](docs/01_dynamixel_wizard.md) | Every servo has ID 1–7 @ 3 Mbps and reads correctly |
| 2 | [Calibration](docs/02_calibration.md) | `configs/yam_auto_generated_{,sim_}{left,right}.yaml` |
| 3 | [GELLO in MuJoCo sim](docs/03_sim.md) | Verified joint directions + gripper, safely |
| 4 | [GELLO → real YAM](docs/04_real_robot.md) | Real teleop, one arm then both |
| — | [Troubleshooting](docs/troubleshooting.md) | |

**Don't skip Step 3.** Sim is where calibration mistakes are free.

## Hardware (per arm)

- GELLO leader arm for YAM: 7 Dynamixel servos (6 joints + gripper trigger)
- ROBOTIS **U2D2** (USB ↔ Dynamixel) + **U2D2 Power Hub** + power supply
- I2RT **YAM** arm with `linear_4310` gripper + its USB-CAN adapter and power supply
- Linux PC (Ubuntu 22.04/24.04)

GELLO mechanical build (STLs, BOM): <https://github.com/wuphilipp/gello_mechanical>

## Install

```bash
git clone --recurse-submodules <this-repo-url> yam_gello && cd yam_gello && bash setup.sh
```

`setup.sh` installs [uv](https://docs.astral.sh/uv/) if needed and creates `.venv/` (Python 3.12) with:
this package, `requirements.txt`, the Dynamixel SDK (`third_party/DynamixelSDK`), and the YAM driver
[i2rt](https://github.com/kushtimusPrime/i2rt) (`third_party/i2rt`). The first run builds `ruckig` from
source, which takes a few minutes.

In every new terminal:
```bash
cd yam_gello && source .venv/bin/activate
```

<details><summary>Manual install (what setup.sh does)</summary>

```bash
git submodule update --init --recursive
uv venv --python 3.12 .venv && source .venv/bin/activate
uv pip install -r requirements.txt
uv pip install -e .
uv pip install -e third_party/DynamixelSDK/python
uv pip install --build-constraint constraints/build-constraints.txt -e third_party/i2rt
```
The build constraint is needed because i2rt pins `ruckig==0.15.3`, which has no prebuilt wheel and
fails to build with `scikit-build-core>=0.10`.
</details>

## Repo layout

```
experiments/launch_yaml.py      # THE entry point: GELLO -> sim or real YAM (Steps 3, 4)
scripts/generate_yam_config.py  # calibration (Step 2)
scripts/gello_get_offset.py     # older manual offset finder (generate_yam_config.py supersedes it)
scripts/reset_all_can.sh        # bring CAN interfaces up at 1 Mbit/s (Step 4)
scripts/install_ftdi_latency_udev.sh  # optional persistent low-latency USB (Step 1.7)
configs/templates/              # templates generate_yam_config.py fills in
gello/
  agents/gello_agent.py         # GelloAgent: reads a GELLO, outputs 6 joints + gripper [0,1]
  robots/dynamixel.py           # raw servo angles -> joint angles (offsets, signs, gripper map)
  dynamixel/driver.py           # Dynamixel bus I/O (background sync-read thread)
  robots/yam.py                 # YAMRobot: real arm over CAN via i2rt
  robots/sim_robot.py           # MujocoRobotServer: simulated arm + viewer
  robots/robot.py, agents/agent.py  # Robot/Agent protocols + Bimanual wrappers
  env.py, zmq_core/, utils/     # control loop plumbing
third_party/
  i2rt/                         # submodule: YAM CAN driver
  DynamixelSDK/                 # submodule: ROBOTIS SDK
  mujoco_menagerie/i2rt_yam/    # vendored YAM MuJoCo model (not the full 1.4 GB menagerie)
```

`launch_yaml.py` also supports `--use-save-interface` for recording teleop data (kept from the fork,
not covered by these guides).

## Where's the rest of the GELLO code / history?

This repo starts with a fresh git history to stay small. Everything removed is in the originals:

- **Upstream GELLO** (all robots, ROS 2, Docker, full history):
  `git clone https://github.com/wuphilipp/gello_software.git`
- **Lab fork this was trimmed from** (YAM-specific changes on top of upstream):
  `git clone https://github.com/nidhya-s/yam_gello_software.git && cd yam_gello_software && git checkout 35e37d4`

To browse that history next to this repo without merging it:
```bash
git remote add fork https://github.com/nidhya-s/yam_gello_software.git && git fetch fork && git log fork/main --oneline
```
Use `git show fork/main:path/to/file` to look at any file that was removed here.

## License

MIT (see `LICENSE`), from upstream GELLO. The YAM MuJoCo model in `third_party/mujoco_menagerie/i2rt_yam`
is MIT-licensed by i2rt robotics (see its `LICENSE`).

## Citation

```bibtex
@misc{wu2023gello,
    title={GELLO: A General, Low-Cost, and Intuitive Teleoperation Framework for Robot Manipulators},
    author={Philipp Wu and Yide Shentu and Zhongke Yi and Xingyu Lin and Pieter Abbeel},
    year={2023},
}
```
