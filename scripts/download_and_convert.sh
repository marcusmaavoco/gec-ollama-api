#!/usr/bin/env bash
set -euo pipefail

MODEL_TYPE="${MODEL_TYPE:-gec}"
QUANTIZATION="${QUANTIZATION:-q4_k_m}"
CACHE_ROOT="${HF_HOME:-/cache/huggingface}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"

case "${MODEL_TYPE}" in
  gec|ged|gee) ;;
  *) echo "MODEL_TYPE must be one of: gec, ged, gee" >&2; exit 2 ;;
esac

case "${MODEL_TYPE}" in
  gec) DEFAULT_HF_MODEL="tartuNLP/Llama-3.1-8B-est-gec-july-2025" ;;
  ged) DEFAULT_HF_MODEL="tartuNLP/Llama-3.1-8B-est-ged-july-2025" ;;
  gee) DEFAULT_HF_MODEL="tartuNLP/Llama-3.1-8B-est-gee-july-2025" ;;
esac

HF_MODEL_NAME="${HF_MODEL_NAME:-${DEFAULT_HF_MODEL}}"
MODEL_CACHE_DIR="${CACHE_ROOT}/models/${HF_MODEL_NAME}"
SOURCE_GGUF="/tmp/${MODEL_TYPE}.f16.gguf"
OUTPUT_FILE="${OUTPUT_DIR}/${MODEL_TYPE}-${QUANTIZATION}.gguf"
MODELFILE="${OUTPUT_DIR}/${MODEL_TYPE}-${QUANTIZATION}.Modelfile"

mkdir -p "${MODEL_CACHE_DIR}" "${OUTPUT_DIR}"

echo "Model type: ${MODEL_TYPE}"
echo "Hugging Face model: ${HF_MODEL_NAME}"
echo "Quantization: ${QUANTIZATION}"

echo "Synchronizing the persistent Hugging Face cache..."
hf download "${HF_MODEL_NAME}" --local-dir "${MODEL_CACHE_DIR}"

if [[ ! -f "${MODEL_CACHE_DIR}/config.json" ]]; then
  echo "Download is incomplete: ${MODEL_CACHE_DIR}/config.json is missing" >&2
  exit 1
fi

if [[ -f "${OUTPUT_FILE}" ]]; then
  echo "Replacing existing export: ${OUTPUT_FILE}"
  rm -f "${OUTPUT_FILE}" "${MODELFILE}"
fi

echo "Converting the cached model to GGUF..."
python3 /opt/llama.cpp/convert_hf_to_gguf.py "${MODEL_CACHE_DIR}" --outfile "${SOURCE_GGUF}"

if [[ ! -s "${SOURCE_GGUF}" ]]; then
  echo "GGUF conversion failed: ${SOURCE_GGUF} was not created" >&2
  exit 1
fi

case "${QUANTIZATION}" in
  full|orig|f16)
    mv "${SOURCE_GGUF}" "${OUTPUT_FILE}"
    ;;
  *)
    llama-quantize "${SOURCE_GGUF}" "${OUTPUT_FILE}" "${QUANTIZATION}"
    rm -f "${SOURCE_GGUF}"
    ;;
esac

if [[ ! -s "${OUTPUT_FILE}" ]]; then
  echo "Export failed: ${OUTPUT_FILE} was not created" >&2
  exit 1
fi

cat > "${MODELFILE}" <<EOF
FROM ./${MODEL_TYPE}-${QUANTIZATION}.gguf
EOF

echo "Export complete: ${OUTPUT_FILE}"
echo "Ollama import file: ${MODELFILE}"
