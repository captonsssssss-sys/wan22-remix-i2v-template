#!/usr/bin/env bash

set -euo pipefail

COMFYUI_PATH="/root/ComfyUI"
WORKFLOW_NAME="Wan2.2-Remix-I2V.json"
WORKFLOW_SOURCE="${COMFYUI_PATH}/${WORKFLOW_NAME}"
WORKFLOW_DIRECTORY="${COMFYUI_PATH}/user/default/workflows"
WORKFLOW_TARGET="${WORKFLOW_DIRECTORY}/${WORKFLOW_NAME}"

echo "============================================================"
echo " Starting Wan2.2 Remix I2V Template"
echo "============================================================"

# ============================================================
# Проверка ComfyUI
# ============================================================

if [ ! -d "${COMFYUI_PATH}" ]; then
    echo "ERROR: ComfyUI directory not found:"
    echo "${COMFYUI_PATH}"
    exit 1
fi

if [ ! -f "${COMFYUI_PATH}/main.py" ]; then
    echo "ERROR: ComfyUI main.py not found:"
    echo "${COMFYUI_PATH}/main.py"
    exit 1
fi

# ============================================================
# Создание необходимых папок
# ============================================================

mkdir -p \
    "${COMFYUI_PATH}/input" \
    "${COMFYUI_PATH}/output" \
    "${COMFYUI_PATH}/temp" \
    "${COMFYUI_PATH}/user/default/workflows" \
    "${COMFYUI_PATH}/models/diffusion_models" \
    "${COMFYUI_PATH}/models/text_encoders" \
    "${COMFYUI_PATH}/models/vae"

# ============================================================
# Оставляем только один workflow
# ============================================================

echo "Cleaning workflow directory..."

find "${WORKFLOW_DIRECTORY}" \
    -mindepth 1 \
    -maxdepth 1 \
    -type f \
    -delete

find "${WORKFLOW_DIRECTORY}" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -exec rm -rf {} +

if [ ! -f "${WORKFLOW_SOURCE}" ]; then
    echo "ERROR: Workflow source not found:"
    echo "${WORKFLOW_SOURCE}"
    exit 1
fi

cp -f "${WORKFLOW_SOURCE}" "${WORKFLOW_TARGET}"

echo "Installed workflow:"
echo "${WORKFLOW_TARGET}"

# ============================================================
# Проверка основных моделей
# ============================================================

check_file() {
    local file_path="$1"

    if [ -f "${file_path}" ]; then
        echo "FOUND: ${file_path}"
    else
        echo "WARNING: File not found: ${file_path}"
    fi
}

echo "============================================================"
echo " Checking models"
echo "============================================================"

check_file "${COMFYUI_PATH}/models/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors"
check_file "${COMFYUI_PATH}/models/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors"
check_file "${COMFYUI_PATH}/models/text_encoders/nsfw_wan_umt5-xxl_fp8_scaled.safetensors"
check_file "${COMFYUI_PATH}/models/vae/Wan2.1_VAE.safetensors"
check_file "${COMFYUI_PATH}/custom_nodes/ComfyUI-VFI/ckpts/rife/flownet.pkl"

# ============================================================
# Проверка custom nodes
# ============================================================

echo "============================================================"
echo " Checking custom nodes"
echo "============================================================"

check_directory() {
    local directory_path="$1"

    if [ -d "${directory_path}" ]; then
        echo "FOUND: ${directory_path}"
    else
        echo "WARNING: Directory not found: ${directory_path}"
    fi
}

check_directory "${COMFYUI_PATH}/custom_nodes/ComfyUI-KJNodes"
check_directory "${COMFYUI_PATH}/custom_nodes/rgthree-comfy"
check_directory "${COMFYUI_PATH}/custom_nodes/ComfyUI_essentials"
check_directory "${COMFYUI_PATH}/custom_nodes/ComfyUI-VideoHelperSuite"
check_directory "${COMFYUI_PATH}/custom_nodes/ComfyUI-VFI"
check_directory "${COMFYUI_PATH}/custom_nodes/ComfyUI-wanBlockSwap"

# ============================================================
# Запуск ComfyUI
# ============================================================

echo "============================================================"
echo " Starting ComfyUI on port 8188"
echo "============================================================"

cd "${COMFYUI_PATH}"

exec python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --enable-cors-header "*"
