# 水月 TTS 部署仓库

明日方舟「水月」（CV: 村濑步）音色克隆 TTS 推理部署，基于 **GPT-SoVITS v4** 微调模型，提供 HTTP API 服务。

- 训练数据：22 条日文游戏语音（约 4 分钟）
- 输出：48kHz，支持日文及中文跨语言合成
- 显存占用：fp16 下峰值约 **2.3 GB**（实测 A40，RTX 3060 12GB 可流畅运行）

## 仓库结构

```
mizuki-tts/
├── README.md               # 本文档
├── requirements.txt        # Python 依赖（验证过的版本）
├── start_api.sh            # API 启动脚本
├── client_example.py       # 调用示例（无第三方依赖）
├── refs.json               # 参考音说明（文本/音高/用途）
├── refs/                   # 6 个参考音（3~10 秒）
└── GPT-SoVITS/             # 精简后的 GPT-SoVITS 源码
    ├── api_v2.py           # FastAPI 服务入口
    └── GPT_SoVITS/pretrained_models/           # 下载后存放底模/声码器/BERT 等
```

## 下载模型

模型权重未纳入 Git。运行前执行以下命令下载微调权重和推理所需底模（约 2 GB）：

```bash
bash download_models.sh
```

微调 GPT/SoVITS 权重从本项目 [GitHub Releases](https://github.com/PandragonXIII/arknights-mizuki-tts-GPT-SoVITS/releases) 下载。若 Release 尚未上传 `mizuki_v4-e20.ckpt` 和 `mizuki_v4_e8_s136_l32.pth`，请联系维护者补齐发布资源。底模来自 [GPT-SoVITS 官方仓库](https://github.com/RVC-Boss/GPT-SoVITS)及其公开模型源；下载脚本会将文件放回推理配置所需路径。

## 安装

要求：Python 3.10、NVIDIA GPU（≥4GB 显存）、CUDA 12.x。

```bash
python -m venv .venv
source .venv/bin/activate

# 1. 安装 torch（CUDA 12.1 版本，国内可加 -i https://mirrors.aliyun.com/pypi/simple/ 之外的源）
pip install torch==2.5.1 torchaudio==2.5.1 --index-url https://download.pytorch.org/whl/cu121

# 2. 安装其余依赖
pip install -r requirements.txt
```

> transformers 必须用 4.51.3（与 torch 2.5.1 兼容，更高版本会报 `_dynamo` 相关错误）。

## 启动服务

首次启动前确保已按上文下载模型。

```bash
bash start_api.sh                    # 默认 GPU 0、端口 9880
GPU=2 PORT=9881 bash start_api.sh    # 指定 GPU 和端口
PY=/path/to/python bash start_api.sh # 指定解释器
```

启动后输出 `Uvicorn running on http://0.0.0.0:9880` 即就绪（模型加载约 5~10 秒）。

## 调用

### Python 客户端

```bash
python client_example.py "ドクター、おはようございます。今日もよろしくね。" out.wav
python client_example.py --ref ref_sad "そう……なんだ。ちょっと、寂しいな。" out2.wav
python client_example.py --ref ref_high --lang zh "博士，你好。今天也一起加油吧。" out3.wav
```

### curl

```bash
curl -X POST http://127.0.0.1:9880/tts \
  -H "Content-Type: application/json" \
  -d '{
    "text": "ドクター、おはようございます。今日もよろしくね。",
    "text_lang": "ja",
    "ref_audio_path": "refs/ref_high.wav",
    "prompt_text": "さあ、悪人の数を減らせたね。全部ドクターのおかげだよ。",
    "prompt_lang": "ja",
    "text_split_method": "cut0"
  }' -o out.wav
```

### 主要参数

| 参数 | 说明 |
|---|---|
| `text` / `text_lang` | 目标文本及语言（`ja` / `zh`） |
| `ref_audio_path` | 参考音路径（必须 **3~10 秒**，否则报错） |
| `prompt_text` / `prompt_lang` | 参考音对应台词（越准越好） |
| `text_split_method` | 切句方式：`cut0` 不切（短文本）、`cut5` 按标点切（长文本建议） |
| `speed_factor` | 语速（默认 1.0） |
| `top_k` / `top_p` / `temperature` | 采样参数（默认 15 / 1.0 / 1.0） |
| `batch_size` | 并行批大小，长文本加速 |

### 常用接口

- `GET /tts` 参数同上（query string）
- `POST /set_gpt_weights` / `POST /set_sovits_weights` 运行时换权重
- `GET /control?command=exit` 关闭服务

## 参考音说明

参考音决定生成语音的**音高与情绪**（模型会跟随参考音的音高和语气）：

| 文件 | 中位 F0 | 情绪 | 用途 |
|---|---|---|---|
| ref_high.wav | 317 Hz | 轻快 | 高音/默认 |
| ref_low.wav | 211 Hz | 平静 | 低音、沉稳叙述 |
| ref_happy.wav | 251 Hz | 兴奋 | 开心语气 |
| ref_sad.wav | 234 Hz | 忧郁 | 低落语气 |
| ref_surprise.wav | 268 Hz | 惊讶 | 惊讶语气 |
| ref_neutral.wav | 229 Hz | 严肃 | 战斗/中性 |

详细台词见 `refs.json`。注意 `ref_audio_path` 建议用**绝对路径**（服务端进程的相对路径基准是 `GPT-SoVITS/`）。

## 性能实测（A40, fp16）

| 场景 | 耗时 | 输出 |
|---|---|---|
| 短句（约 20 字） | 3.4s | 3.4s 音频 |
| 长段落（约 150 字） | 6.9s | 22s 音频 |

显存：加载后 1.7GB，推理峰值 2.2GB（进程含 CUDA context 共约 2.7GB）。

## 常见问题

1. **参考音必须 3~10 秒**：超范围直接报错，可用 ffmpeg 剪辑。
2. **首次中文合成较慢**：会加载 G2PW 多音字模型（已内置，约 600MB）。
3. **不要升级 transformers**：4.51.3 是验证过的版本。
4. **换其他 epoch 权重**：本仓库只含 e20(GPT)+e8(LoRA) 组合；原训练目录还有 e4/e12/e16 等 LoRA 与 e5/e10/e15 GPT 权重可替换。

## 版权说明

- GPT-SoVITS 源码遵循其原 MIT 许可（见 `GPT-SoVITS/LICENSE`）
- 水月语音数据版权归鹰角网络，本仓库仅供个人学习研究，**请勿商用或再分发**
