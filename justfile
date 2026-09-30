# Run `just` to list recipes.

# Hugging Face GGUF repo, optionally ":<quant>" (llama-server -hf syntax)
model := "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL"
# Model id for opencode, derived from `model` (e.g. qwen3-coder-30b-a3b-instruct-gguf-ud-q4_k_xl)
model_id := lowercase(replace(file_name(model), ":", "-"))
host := "127.0.0.1"
port := "8080"
ctx := "32768"
logs := ".logs"
log := logs + "/llama-server.log"
opencode_log := logs + "/opencode.log"
opencode_log_level := "DEBUG"

# List available recipes
[private]
default:
    @just --list --unsorted

# Install tool dependencies declared in mise.toml
install:
    mise install

# Start the llama.cpp server on 127.0.0.1:8080 (foreground). Downloads the model on first run.
serve:
    llama-server \
        -hf {{model}} \
        --host {{host}} --port {{port}} \
        --ctx-size {{ctx}} \
        -ngl 999 -fa on \
        --jinja

# Check that the llama.cpp server is up and list its models
status:
    curl -sf http://{{host}}:{{port}}/health && echo && curl -sf http://{{host}}:{{port}}/v1/models

# Send a quick test prompt to the running server
chat prompt="Say hello in one sentence.":
    curl -sf http://{{host}}:{{port}}/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -d '{"model":"{{model_id}}","messages":[{"role":"user","content":"{{prompt}}"}]}' \
        | jq -r '.choices[0].message.content'

# Launch opencode in this repo using the local llama.cpp provider (logs to .logs/opencode.log)
code *args: opencode-config
    @mkdir -p {{logs}}
    opencode --print-logs --log-level {{opencode_log_level}} -m llamacpp/{{model_id}} {{args}} 2>>{{opencode_log}}

# Start llama.cpp if needed, launch opencode, shut both down on exit
code-local-ai *args: opencode-config
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p {{logs}}
    health="http://{{host}}:{{port}}/health"
    if curl -sf "$health" >/dev/null 2>&1; then
        echo "llama-server already running on {{host}}:{{port}} (will be left running)"
    else
        echo "starting llama-server on {{host}}:{{port}} (log: {{log}})"
        llama-server \
            -hf {{model}} \
            --host {{host}} --port {{port}} \
            --ctx-size {{ctx}} \
            -ngl 999 -fa on \
            --jinja >{{log}} 2>&1 &
        server_pid=$!
        cleanup() {
            printf '\nstopping llama-server (pid %s)\n' "$server_pid"
            kill "$server_pid" 2>/dev/null || true
            wait "$server_pid" 2>/dev/null || true
        }
        trap cleanup EXIT INT TERM
        spinner='|/-\\'
        start=$SECONDS
        i=0
        until curl -sf "$health" >/dev/null 2>&1; do
            if ! kill -0 "$server_pid" 2>/dev/null; then
                printf '\r\033[Kllama-server exited early; last log lines:\n'
                tail -20 {{log}}
                exit 1
            fi
            printf '\r\033[K%s loading model... %ds (first run downloads it)' \
                "${spinner:$((i % 4)):1}" "$((SECONDS - start))"
            i=$((i + 1))
            sleep 0.25
        done
        printf '\r\033[Kmodel ready in %ds\n' "$((SECONDS - start))"
    fi
    opencode --print-logs --log-level {{opencode_log_level}} -m llamacpp/{{model_id}} {{args}} 2>>{{opencode_log}}

# Tail the opencode and llama-server logs
logs:
    tail -n 50 -F {{opencode_log}} {{log}}

# Render opencode.json from opencode.json.template with the current model settings
[private]
opencode-config:
    MODEL="{{model}}" MODEL_ID="{{model_id}}" HOST="{{host}}" PORT="{{port}}" CTX="{{ctx}}" \
        envsubst '$MODEL $MODEL_ID $HOST $PORT $CTX' < opencode.json.template > opencode.json

# Stop any running llama.cpp server
stop:
    pkill -f 'llama-server.*--port {{port}}' || echo "no server running"
