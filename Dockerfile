FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV COMFYUI_PATH=/root/ComfyUI

# ============================================================
# Системные зависимости
# ============================================================

RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    aria2 \
    ffmpeg \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

RUN python -m pip install --upgrade pip setuptools wheel

# ============================================================
# PyTorch
# ============================================================

RUN pip install \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu128

# ============================================================
# Чистая установка ComfyUI
# ============================================================

WORKDIR /root

RUN git clone https://github.com/comfyanonymous/ComfyUI.git /root/ComfyUI

WORKDIR /root/ComfyUI

RUN pip install -r requirements.txt

# ============================================================
# Custom Nodes
# ============================================================

WORKDIR /root/ComfyUI/custom_nodes

# KJNodes — INTConstant
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git

# rgthree — Seed (rgthree)
RUN git clone https://github.com/rgthree/rgthree-comfy.git

# Essentials — ImageResize+
RUN git clone https://github.com/cubiq/ComfyUI_essentials.git

# Video Helper Suite — VHS_VideoCombine
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git

# VFI / RIFEInterpolation
RUN git clone https://github.com/GACLove/ComfyUI-VFI.git

# Wan Block Swap
RUN git clone https://github.com/orssorbit/ComfyUI-wanBlockSwap.git

# ============================================================
# Установка requirements всех custom nodes
# ============================================================

RUN set -eux; \
    for dir in /root/ComfyUI/custom_nodes/*; do \
        if [ -f "$dir/requirements.txt" ]; then \
            echo "Installing requirements: $dir"; \
            pip install -r "$dir/requirements.txt"; \
        fi; \
    done

# ============================================================
# Дополнительные библиотеки
# ============================================================

RUN pip install \
    accelerate \
    einops \
    imageio \
    imageio-ffmpeg \
    opencv-python-headless \
    scipy \
    safetensors \
    sentencepiece \
    protobuf \
    huggingface-hub

# ============================================================
# Папки моделей
# ============================================================

RUN mkdir -p \
    /root/ComfyUI/models/diffusion_models \
    /root/ComfyUI/models/text_encoders \
    /root/ComfyUI/models/vae \
    /root/ComfyUI/custom_nodes/ComfyUI-VFI/ckpts/rife \
    /root/ComfyUI/user/default/workflows \
    /root/ComfyUI/input \
    /root/ComfyUI/output

# ============================================================
# WAN 2.2 HIGH MODEL
# ============================================================

RUN aria2c \
    --console-log-level=warn \
    --summary-interval=10 \
    --continue=true \
    --max-connection-per-server=16 \
    --split=16 \
    --min-split-size=10M \
    --dir=/root/ComfyUI/models/diffusion_models \
    --out=Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors \
    "https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors?download=true"

# ============================================================
# WAN 2.2 LOW MODEL
# ============================================================

RUN aria2c \
    --console-log-level=warn \
    --summary-interval=10 \
    --continue=true \
    --max-connection-per-server=16 \
    --split=16 \
    --min-split-size=10M \
    --dir=/root/ComfyUI/models/diffusion_models \
    --out=Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors \
    "https://huggingface.co/limiao1666/qw_nsfw/resolve/main/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors?download=true"

# ============================================================
# NSFW WAN TEXT ENCODER
# ============================================================

RUN aria2c \
    --console-log-level=warn \
    --summary-interval=10 \
    --continue=true \
    --max-connection-per-server=16 \
    --split=16 \
    --min-split-size=10M \
    --dir=/root/ComfyUI/models/text_encoders \
    --out=nsfw_wan_umt5-xxl_fp8_scaled.safetensors \
    "https://huggingface.co/Osrivers/nsfw_wan_umt5-xxl_fp8_scaled.safetensors/resolve/main/nsfw_wan_umt5-xxl_fp8_scaled.safetensors?download=true"

# ============================================================
# WAN VAE
# Имя сохраняем именно такое, как прописано в workflow
# ============================================================

RUN aria2c \
    --console-log-level=warn \
    --summary-interval=10 \
    --continue=true \
    --max-connection-per-server=16 \
    --split=16 \
    --min-split-size=10M \
    --dir=/root/ComfyUI/models/vae \
    --out=Wan2.1_VAE.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true"

# ============================================================
# RIFE MODEL
# ============================================================

RUN aria2c \
    --console-log-level=warn \
    --summary-interval=10 \
    --continue=true \
    --max-connection-per-server=16 \
    --split=16 \
    --min-split-size=1M \
    --dir=/root/ComfyUI/custom_nodes/ComfyUI-VFI/ckpts/rife \
    --out=flownet.pkl \
    "https://huggingface.co/DeepBeepMeep/Wan2.1/resolve/main/flownet.pkl?download=true"

# ============================================================
# Только один пользовательский workflow
# ============================================================

RUN rm -rf /root/ComfyUI/user/default/workflows/*

COPY Wan2.2-Remix-I2V.json \
    /root/ComfyUI/user/default/workflows/Wan2.2-Remix-I2V.json

# Дополнительная копия для гарантированного доступа
COPY Wan2.2-Remix-I2V.json \
    /root/ComfyUI/Wan2.2-Remix-I2V.json

# ============================================================
# Start script
# ============================================================

COPY start.sh /start.sh

RUN chmod +x /start.sh

WORKDIR /root/ComfyUI

EXPOSE 8188
EXPOSE 8888

CMD ["/start.sh"]
