# Estonian GEC model exporter

This project uses Docker only as a temporary conversion environment. It downloads a selected TartuNLP model, converts it to GGUF, and writes an Ollama-importable artifact to `output/`. It does not run an Ollama server or test inference inside Docker.

## Requirements

- Docker Desktop running
- NVIDIA Container Toolkit / Docker Desktop GPU support only for GPU mode
- A Hugging Face token only when the selected model requires authentication

## Configure

Copy the example settings and edit the values you need:

```powershell
Copy-Item .env.example .env
```

`MODEL_TYPE` can be `gec`, `ged`, or `gee`. `QUANTIZATION` supports `full`, `orig`, `f16`, and the llama.cpp quantization names such as `q4_k_m` and `q8_0`. Set `HF_MODEL_NAME` only to override the standard model for the selected type.

`HF_TOKEN` is passed only to the one-off downloader. It is not built into an image or exported with the model.

Conversion temporarily needs room for the downloaded source model, a full-precision GGUF, and the final export. If C: is tight, set `HOST_CACHE_DIR` and `HOST_OUTPUT_DIR` in `.env` to folders on another drive before running the converter.

## Export a model

CPU mode:

```powershell
docker compose --profile cpu run --rm converter-cpu
```

NVIDIA GPU mode:

```powershell
docker compose --profile gpu run --rm converter-gpu
```

The first conversion downloads the selected Hugging Face model to `cache/huggingface/`. Later conversions reuse that source model, including when you choose another quantization. Generated GGUF files and their matching Ollama `Modelfile`s are written to `output/`.

## Import into local Ollama

For a GEC `q4_k_m` export:

```powershell
cd output
ollama create gec -f .\gec-q4_k_m.Modelfile
```

Use the matching generated `Modelfile` for another model type or quantization.

## Output layout

```text
cache/huggingface/     Persistent downloaded Hugging Face model files
output/
  gec-q4_k_m.gguf      Generated GGUF model
  gec-q4_k_m.Modelfile Ollama import file
```
