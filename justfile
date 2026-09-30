# Commands for running the Bonsai 8B local model with opencode.
# Run `just` to list recipes.

model_repo := "prism-ml/Bonsai-8B-gguf"
model_file := "Bonsai-8B-Q1_0.gguf"
host := "127.0.0.1"
port := "8080"
ctx := "32768"
log := "/tmp/bonsai-llama-server.log"

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
        --hf-repo {{model_repo}} --hf-file {{model_file}} \
        --host {{host}} --port {{port}} \
        --ctx-size {{ctx}} \
        --jinja

# Check that the llama.cpp server is up and list its models
status:
    curl -sf http://{{host}}:{{port}}/health && echo && curl -sf http://{{host}}:{{port}}/v1/models

# Send a quick test prompt to the running server
chat prompt="Say hello in one sentence.":
    curl -sf http://{{host}}:{{port}}/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -d '{"model":"bonsai-8b","messages":[{"role":"user","content":"{{prompt}}"}]}' \
        | jq -r '.choices[0].message.content'

# Launch opencode in this repo using the local llama.cpp provider
code *args:
    opencode -m llamacpp/bonsai-8b {{args}}

# Start llama.cpp if needed, launch opencode, shut both down on exit
code-local-ai *args:
    #!/usr/bin/env bash
    set -euo pipefail
    health="http://{{host}}:{{port}}/health"
    if curl -sf "$health" >/dev/null 2>&1; then
        echo "llama-server already running on {{host}}:{{port}} (will be left running)"
    else
        echo "starting llama-server on {{host}}:{{port}} (log: {{log}})"
        llama-server \
            --hf-repo {{model_repo}} --hf-file {{model_file}} \
            --host {{host}} --port {{port}} \
            --ctx-size {{ctx}} \
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
    opencode -m llamacpp/bonsai-8b {{args}}

# Stop any running llama.cpp server
stop:
    pkill -f 'llama-server.*--port {{port}}' || echo "no server running"
