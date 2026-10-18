#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$ROOT/GPT-SoVITS/GPT_SoVITS/pretrained_models"
RELEASE="https://github.com/PandragonXIII/arknights-mizuki-tts-GPT-SoVITS/releases/latest/download"

download() {
    local url="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [[ -s "$dest" ]]; then
        echo "Exists: $dest"
        return
    fi
    echo "Downloading $dest"
    curl -fL --retry 3 "$url" -o "$dest"
}

# Project fine-tunes must be attached to the latest GitHub Release.
download "$RELEASE/mizuki_v4-e20.ckpt" "$ROOT/GPT-SoVITS/GPT_weights_v4/mizuki_v4-e20.ckpt"
download "$RELEASE/mizuki_v4_e8_s136_l32.pth" "$ROOT/GPT-SoVITS/SoVITS_weights_v4/mizuki_v4_e8_s136_l32.pth"

# GPT-SoVITS v4 inference assets.
download "https://huggingface.co/RVC-Boss/GPT-SoVITS/resolve/main/GPT_SoVITS/pretrained_models/gsv-v4-pretrained/s2Gv4.pth" "$BASE/gsv-v4-pretrained/s2Gv4.pth"
download "https://huggingface.co/RVC-Boss/GPT-SoVITS/resolve/main/GPT_SoVITS/pretrained_models/gsv-v4-pretrained/vocoder.pth" "$BASE/gsv-v4-pretrained/vocoder.pth"
download "https://huggingface.co/lj1995/Voice本色-Hubert/resolve/main/pytorch_model.bin" "$BASE/chinese-hubert-base/pytorch_model.bin"
download "https://huggingface.co/hfl/chinese-roberta-wwm-ext-large/resolve/main/pytorch_model.bin" "$BASE/chinese-roberta-wwm-ext-large/pytorch_model.bin"
download "https://huggingface.co/hfl/chinese-roberta-wwm-ext-large/resolve/main/config.json" "$BASE/chinese-roberta-wwm-ext-large/config.json"
download "https://huggingface.co/hfl/chinese-roberta-wwm-ext-large/resolve/main/tokenizer.json" "$BASE/chinese-roberta-wwm-ext-large/tokenizer.json"
download "https://huggingface.co/hfl/chinese-roberta-wwm-ext-large/resolve/main/tokenizer_config.json" "$BASE/chinese-roberta-wwm-ext-large/tokenizer_config.json"
download "https://huggingface.co/hfl/chinese-roberta-wwm-ext-large/resolve/main/vocab.txt" "$BASE/chinese-roberta-wwm-ext-large/vocab.txt"
download "https://huggingface.co/hfl/chinese-roberta-wwm-ext-large/resolve/main/special_tokens_map.json" "$BASE/chinese-roberta-wwm-ext-large/special_tokens_map.json"
download "https://huggingface.co/daanzu/fasttext-langdetect/resolve/main/lid.176.bin" "$BASE/fast_langdetect/lid.176.bin"

# The source tree already contains small G2PW metadata, so install the archive into it directly.
G2PW_DIR="$ROOT/GPT-SoVITS/GPT_SoVITS/text/G2PWModel"
if [[ ! -s "$G2PW_DIR/g2pW.onnx" ]]; then
    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT
    echo "Downloading G2PW model"
    curl -fL --retry 3 "https://www.modelscope.cn/models/kamiorinn/g2pw/resolve/master/G2PWModel_1.1.zip" \
        -o "$TMP_DIR/G2PWModel_1.1.zip"
    unzip -oq "$TMP_DIR/G2PWModel_1.1.zip" -d "$TMP_DIR"
    cp -a "$TMP_DIR/G2PWModel_1.1/." "$G2PW_DIR/"
fi

echo "Model downloads complete."
