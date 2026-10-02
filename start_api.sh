#!/usr/bin/env bash
# 启动水月 TTS API 服务
# 用法: bash start_api.sh          (默认 GPU 0, 端口 9880)
#       GPU=2 PORT=9881 bash start_api.sh
set -e
cd "$(dirname "$0")/GPT-SoVITS"

GPU="${GPU:-0}"
PORT="${PORT:-9880}"
BIND="${BIND:-0.0.0.0}"
PY="${PY:-python}"

exec env CUDA_VISIBLE_DEVICES="$GPU" "$PY" api_v2.py \
    -a "$BIND" -p "$PORT" \
    -c GPT_SoVITS/configs/tts_infer_mizuki_v4.yaml
