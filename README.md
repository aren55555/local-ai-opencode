# local-ai-opencode

Run [opencode](https://opencode.ai) against [Bonsai 8B](https://huggingface.co/prism-ml/Bonsai-8B-gguf), served locally by [llama.cpp](https://github.com/ggml-org/llama.cpp). No API keys.

## Setup

Requires [mise](https://mise.jdx.dev).

```sh
mise install
```

## Usage

```sh
just code-local-ai
```

Starts the server, waits for the model to load (downloads ~1.2 GB on first run), launches opencode, and stops the server when you exit.

Run `just` to list all recipes.

## The model

[Bonsai 8B](https://huggingface.co/prism-ml/Bonsai-8B-gguf) by Prism ML is an 8B-parameter model (Qwen3-8B architecture) with end-to-end 1-bit weights. Every weight is a single sign bit, with one FP16 scale shared per group of 128 weights, giving about 1.125 bits per weight. The GGUF Q1_0 file is 1.15 GB, about 14x smaller than FP16, while scoring close to full-precision 8B models on benchmarks. It supports a 64k context and runs on Metal, CUDA, and CPU. Apache 2.0 licensed.

## How it fits together

- `mise.toml` installs `just`, `opencode`, and `llama.cpp`.
- `justfile` holds the server settings (model, host, port, context size) and the recipes.
- `opencode.json` points opencode at the server's OpenAI-compatible endpoint at `http://127.0.0.1:8080/v1` as the `bonsai-8b` model.
