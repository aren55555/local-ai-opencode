# local-ai-opencode

Run [opencode](https://opencode.ai) against a local model served by [llama.cpp](https://github.com/ggml-org/llama.cpp). No API keys.

## Setup

Requires [mise](https://mise.jdx.dev) and `envsubst` (from GNU gettext, `brew install gettext`).

```sh
mise install
```

## Usage

```sh
just code-local-ai
```

Starts the server, waits for the model to load (downloads it on first run), launches opencode, and stops the server when you exit.

Run `just` to list all recipes.

## The model

The default is [Qwen3-Coder-30B-A3B-Instruct](https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF) at the UD-Q4_K_XL quant (17.7 GB): a 30B mixture-of-experts model with ~3B active parameters, trained for agentic coding and tool calling. It runs at near-8B speed on a 36 GB Apple Silicon Mac.

To swap models, change the single `model` variable at the top of the `justfile`. It takes a Hugging Face GGUF repo, optionally with `:<quant>` to pick a file. Alternatives that fit in 36 GB:

- `unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL` — dense 27B, stronger reasoning, slower
- `prism-ml/Bonsai-8B-gguf:Q1_0` — 1-bit 8B, tiny (1.2 GB) but weak at tool use

## How it fits together

- `mise.toml` installs `just`, `opencode`, and `llama.cpp`.
- `justfile` holds the server settings (`model`, host, port, context size) and the recipes.
- `opencode.json` is rendered from `opencode.json.template` (via `envsubst`) each time opencode launches. Edit the template, not the output.
