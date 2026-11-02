#!/usr/bin/env bash
# One-time install: creates .venv/ with everything needed for docs/01-04.
# Usage: bash setup.sh
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v uv >/dev/null 2>&1; then
  echo "Installing uv (Python package manager)..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

git submodule update --init --recursive

uv venv --python 3.12 .venv
# shellcheck disable=SC1091
source .venv/bin/activate

uv pip install -r requirements.txt
uv pip install -e .
uv pip install -e third_party/DynamixelSDK/python
# i2rt = YAM follower-arm CAN driver. Its ruckig pin needs an older build backend.
uv pip install --build-constraint constraints/build-constraints.txt -e third_party/i2rt

python -c "import gello, i2rt, mujoco, dm_control, dynamixel_sdk; print('Install OK')"
echo
echo "Done. In every new terminal, run:  source .venv/bin/activate"
