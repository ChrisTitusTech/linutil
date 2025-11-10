#!/bin/bash -e
# Ollama Diagnostic Script
# Purpose: Inspect existing Ollama installation, GPU / accelerator usage, dependencies, and
#          run a controlled short inference showing which GPU (if any) is active.
# NOTE: This script NO LONGER installs Ollama. Use your main installer for that.

# ------------------------------ Color Fallback ------------------------------
: "${YELLOW:=\033[33m}" "${GREEN:=\033[32m}" "${RED:=\033[31m}" "${RC:=\033[0m}" "${CYAN:=\033[36m}" "${MAGENTA:=\033[35m}"

# ------------------------------ Argument Parsing ---------------------------
FORCE_DGPU="0"
AUTO_FIX="0"
OUTPUT_JSON="0"
BENCHMARK_RUNS=0
while [ $# -gt 0 ]; do
    case "$1" in
        --force-dgpu) FORCE_DGPU="1" ;;
            --fix) AUTO_FIX="1" ;;
            --json) OUTPUT_JSON="1" ;;
            --benchmark)
                shift
                BENCHMARK_RUNS="${1:-5}"
                case "$BENCHMARK_RUNS" in ''|*[!0-9]*) BENCHMARK_RUNS=5;; esac
                ;;
        --help|-h)
            cat <<USAGE
Ollama Diagnostics
Usage: $0 [--force-dgpu] [--fix]
    --force-dgpu   Attempt to prefer discrete GPU (AMD HIP_VISIBLE_DEVICES=0 / NVIDIA default)
    --fix          Apply non-destructive configuration fixes (group membership hint, systemd drop-in suggestions)
USAGE
            exit 0
            ;;
        *) printf "%b\n" "${RED}Unknown option: $1${RC}"; exit 1;;
    esac
    shift
done

# ------------------------------ Pre-flight Checks --------------------------
if ! command -v ollama >/dev/null 2>&1; then
    printf "%b\n" "${RED}Ollama is not installed. Please run your installation script first.${RC}"
    exit 1
fi

if ! systemctl is-active --quiet ollama.service 2>/dev/null; then
    printf "%b\n" "${YELLOW}Ollama service not active - attempting start...${RC}"
    if systemctl start ollama.service 2>/dev/null; then
        printf "%b\n" "${GREEN}Service started.${RC}"
    else
        printf "%b\n" "${RED}Failed to start Ollama service. Continuing with client run anyway.${RC}"
    fi
fi

printf "%b\n" "${CYAN}Collecting environment & dependency info...${RC}"
uname -a || true
printf "Shell: %s\n" "$SHELL"
printf "User : %s\n" "$USER"

# Helper to find a tool even under sudo where PATH may differ
find_tool() {
    local name="$1"
    if command -v "$name" >/dev/null 2>&1; then
        command -v "$name"
        return 0
    fi
    for p in \
        "/opt/rocm/bin/$name" \
        "/usr/lib/rocm/bin/$name" \
        "/usr/local/bin/$name" \
        "/usr/bin/$name"; do
        [ -x "$p" ] && printf "%s" "$p" && return 0
    done
    return 1
}

# ------------------------------ GPU Detection ------------------------------
GPU_VENDOR="cpu"
NVIDIA_SMI="$(find_tool nvidia-smi || true)"
ROCMINFO="$(find_tool rocminfo || true)"
ROCM_SMI="$(find_tool rocm-smi || true)"

if [ -n "$NVIDIA_SMI" ] && "$NVIDIA_SMI" -L >/dev/null 2>&1; then
    GPU_VENDOR="nvidia"
elif [ -n "$ROCMINFO" ]; then
    GPU_VENDOR="amd"
elif command -v lspci >/dev/null 2>&1; then
    if lspci | grep -qi 'nvidia'; then
        GPU_VENDOR="nvidia"
    elif lspci | grep -qi 'amd\|ati'; then
        GPU_VENDOR="amd"
    elif lspci | grep -qi 'vga.*intel\|3d.*intel'; then
        GPU_VENDOR="intel"
    fi
fi

printf "%b\n" "${MAGENTA}Detected GPU vendor: ${GPU_VENDOR}${RC}"

case "$GPU_VENDOR" in
    nvidia)
        [ -n "$NVIDIA_SMI" ] && "$NVIDIA_SMI" -L || true
        printf "%s\n" "Driver / CUDA summary:"; [ -n "$NVIDIA_SMI" ] && "$NVIDIA_SMI" || true
        ;;
    amd)
        [ -n "$ROCMINFO" ] && "$ROCMINFO" | grep -i 'gfx' | head -n 10 || true
        if [ -n "$ROCM_SMI" ]; then
            "$ROCM_SMI" --showuse || printf "%s\n" "rocm-smi failed to report usage."
        else
            printf "%s\n" "rocm-smi not found. Install rocm-smi for usage metrics."
        fi
        ls -l /dev/kfd 2>/dev/null || true
        if [ -n "$ROCMINFO" ] && "$ROCMINFO" 2>/dev/null | grep -qi 'gfx1102'; then
            printf "%b\n" "${YELLOW}RDNA3 (gfx1102) detected. If performance is poor on older ROCm, try HSA_OVERRIDE_GFX_VERSION=11.0.0 for the ollama service.${RC}"
        fi
        ;;
    intel)
        ls -l /dev/dri/render* 2>/dev/null || true
        ;;
    *)
        printf "%s\n" "No supported discrete GPU tools detected - using CPU."
        ;;
esac

# Show service user and groups to catch permission issues
if systemctl status ollama.service >/dev/null 2>&1; then
    svc_user=$(systemctl show -p User --value ollama.service 2>/dev/null)
    printf "%s\n" "Ollama service user: ${svc_user:-root}"
    if command -v id >/dev/null 2>&1; then
        id "${svc_user:-root}" 2>/dev/null || true
    fi
fi

# ------------------------------ Optional Fixes -----------------------------
if [ "$AUTO_FIX" = "1" ]; then
    printf "%b\n" "${YELLOW}Applying suggested (non-destructive) fixes...${RC}"
    if [ "$GPU_VENDOR" = "amd" ]; then
        # Suggest systemd drop-in if not present (do not overwrite if exists)
        DROPIN="/etc/systemd/system/ollama.service.d/rocm.conf"
        if [ ! -f "$DROPIN" ]; then
            printf "%s\n" "Creating systemd drop-in (needs sudo)..."
            if sudo test -d /etc/systemd/system/ollama.service.d; then
                sudo bash -c "printf '[Service]\nEnvironment=LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64\n# Uncomment to force dGPU selection:\n# Environment=HIP_VISIBLE_DEVICES=0\nSupplementaryGroups=render video\n' > '$DROPIN'"
                sudo systemctl daemon-reload && sudo systemctl restart ollama.service || true
            else
                sudo mkdir -p /etc/systemd/system/ollama.service.d && sudo bash -c "printf '[Service]\nEnvironment=LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64\n# Environment=HIP_VISIBLE_DEVICES=0\nSupplementaryGroups=render video\n' > '$DROPIN'" && sudo systemctl daemon-reload && sudo systemctl restart ollama.service || true
            fi
        fi
    fi
fi

# ------------------------------ Fast Test Model ----------------------------
BASE_MODEL="qwen3:0.6b"
FAST_MODEL="linutil-fast-qtest"
if ! ollama show "$FAST_MODEL" >/dev/null 2>&1; then
    TMPF=$(mktemp)
    cat >"$TMPF" <<'EOF'
FROM qwen3:0.6b
PARAMETER temperature 0
PARAMETER num_predict 32
PARAMETER num_gpu_layers -1
SYSTEM You are concise and do not explain your reasoning. Answer in one short sentence.
EOF
    if ollama create "$FAST_MODEL" -f "$TMPF" >/dev/null 2>&1; then
        printf "%b\n" "${GREEN}Fast diagnostic compose model created: $FAST_MODEL${RC}"
    else
        printf "%b\n" "${YELLOW}Failed to create compose model; falling back to base model.${RC}"
        FAST_MODEL="$BASE_MODEL"
    fi
    rm -f "$TMPF"
fi

# Ensure base model present
ollama pull "$BASE_MODEL" >/dev/null 2>&1 || true

# ------------------------------ Inference & GPU Use ------------------------
PROMPT="/set verbose\n/set nothink\n/set quiet\n/set noformat\nReply with ONLY one short friendly greeting."

GPU_LOG="$(mktemp)"

# Resolve the running Ollama server PID (systemd or standalone)
get_server_pid() {
    local pid
    pid=$(systemctl show -p MainPID --value ollama.service 2>/dev/null || echo 0)
    if [ -z "$pid" ] || [ "$pid" = "0" ]; then
        pid=$(pgrep -x ollama | head -n1)
    fi
    printf "%s" "$pid"
}

sample_gpu_usage() {
    vendor="$1"; pid="$2"; loops=0
    while kill -0 "$pid" 2>/dev/null && [ $loops -lt 40 ]; do
        case "$vendor" in
                nvidia) nvidia-smi --query-compute-apps=pid,process_name,gpu_uuid,used_memory --format=csv,noheader 2>/dev/null | grep "$pid" >>"$GPU_LOG" ;;
                amd)
                    if command -v rocm-smi >/dev/null 2>&1; then
                        # Prefer per-process view if available; fall back to plain text
                        rocm-smi --showpids --json 2>/dev/null >>"$GPU_LOG" \
                        || rocm-smi --showuse --json 2>/dev/null >>"$GPU_LOG" \
                        || rocm-smi --showuse 2>/dev/null >>"$GPU_LOG"
                    fi
                    ;;
            intel) cat /sys/class/drm/*/device/gt_busy_percent 2>/dev/null >>"$GPU_LOG" || true ;;
        esac
        sleep 0.25; loops=$((loops+1))
    done
}

ENV_CMD=""
if [ "$FORCE_DGPU" = "1" ] && [ "$GPU_VENDOR" = "amd" ]; then
    ENV_CMD="HIP_VISIBLE_DEVICES=0"
fi

parse_metrics() {
    # Parses verbose output to extract durations and token rates
    infile="$1"
        eval_rate=$(grep -i 'eval rate' "$infile" | tail -n1 | awk '{print $3}')
    eval_count=$(grep -i '^eval count' "$infile" | tail -n1 | awk '{print $3}')
    prompt_eval_count=$(grep -i '^prompt eval count' "$infile" | tail -n1 | awk '{print $4}')
}

run_one_infer() {
    local outfile
    outfile=$(mktemp)
    (
        eval "$ENV_CMD" OLLAMA_NOHISTORY=1 ollama run "$FAST_MODEL" <<<"$PROMPT"
    ) >"$outfile" 2>&1 &
    local pid=$!
    # Use server PID if available for sampling (persistent process)
    SERVER_PID="${SERVER_PID:-$(get_server_pid)}"
    sample_gpu_usage "$GPU_VENDOR" "${SERVER_PID:-$pid}" &
    local spid=$!
    wait "$pid" 2>/dev/null
    wait "$spid" 2>/dev/null || true
    parse_metrics "$outfile"
    cat "$outfile"
    rm -f "$outfile"
}

TOKS_PER_SEC_SUM=0
RUNS_DONE=0
if [ "$BENCHMARK_RUNS" -gt 0 ]; then
    printf "%b\n" "${YELLOW}Running benchmark ($BENCHMARK_RUNS runs)...${RC}"
    i=1
    while [ $i -le "$BENCHMARK_RUNS" ]; do
        out=$(run_one_infer)
        printf "%s\n" "$out"
        # accumulate eval rate if present
        if [ -n "$eval_rate" ]; then
            TOKS_PER_SEC_SUM=$(awk -v a="$TOKS_PER_SEC_SUM" -v b="$eval_rate" 'BEGIN{printf "%.2f", a + b}')
            RUNS_DONE=$((RUNS_DONE+1))
        fi
        i=$((i+1))
    done
else
    printf "%b\n" "${YELLOW}Starting short diagnostic inference...${RC}"
    SERVER_PID="$(get_server_pid)"
    out=$(run_one_infer)
    printf "%b\n" "${GREEN}Inference output:${RC}"
    printf "%s\n" "$out"
fi

printf "%b\n" "${CYAN}GPU usage samples (raw):${RC}"
if [ -s "$GPU_LOG" ]; then
    head -n 20 "$GPU_LOG"
else
    printf "%s\n" "(No GPU usage samples captured or tool unavailable)"
fi

# Show the exact device bindings used by the server process
print_gpu_bindings() {
    local pid="${SERVER_PID:-}"
    [ -z "$pid" ] && return 0
    printf "%b\n" "${CYAN}Server GPU device bindings (PID $pid):${RC}"
    if command -v lsof >/dev/null 2>&1; then
        lsof -p "$pid" 2>/dev/null | awk '{print $9}' | grep -E '/dev/(kfd|dri/renderD[0-9]+)' | sort -u | while read -r dev; do
            [ -z "$dev" ] && continue
            if echo "$dev" | grep -q 'renderD'; then
                base=$(basename "$dev")
                sysdir="/sys/class/drm/$base/device"
                vendor=$(cat "$sysdir/vendor" 2>/dev/null)
                device=$(cat "$sysdir/device" 2>/dev/null)
                printf "  %s vendor=%s device=%s\n" "$dev" "${vendor:-?}" "${device:-?}"
            else
                printf "  %s\n" "$dev"
            fi
        done
    else
        readlink -f /proc/"$pid"/fd/* 2>/dev/null | grep -E '/dev/(kfd|dri/renderD[0-9]+)' | sort -u || true
    fi
}

print_gpu_bindings
rm -f "$GPU_LOG"

# ------------------------------ Summary ------------------------------------
printf "%b\n" "${MAGENTA}Summary:${RC}"
AVG_TOKS_PER_SEC=""
if [ "$RUNS_DONE" -gt 0 ]; then
    AVG_TOKS_PER_SEC=$(awk -v s="$TOKS_PER_SEC_SUM" -v n="$RUNS_DONE" 'BEGIN{ if (n>0) printf "%.2f", s/n; else print "" }')
fi
case "$GPU_VENDOR" in
    nvidia) printf "%s\n" "If GPU usage lines show your inference PID, CUDA acceleration is active." ;;
    amd) printf "%s\n" "If rocm-smi busy percentage increased during sampling, HIP offload is active. Use --force-dgpu if mixed iGPU/dGPU causes slow fallbacks." ;;
    intel) printf "%s\n" "Intel iGPU busy percent indicates Level Zero / OpenCL activity." ;;
    cpu) printf "%s\n" "No GPU acceleration detected; all tokens computed on CPU." ;;
esac

if [ "$OUTPUT_JSON" = "1" ]; then
    # Minimal JSON summary (no jq dependency)
        printf '{"gpu_vendor":"%s","avg_toks_per_sec":"%s","runs":%s,"eval_count":"%s","prompt_eval_count":"%s"}\n' \
            "$GPU_VENDOR" "${AVG_TOKS_PER_SEC:-}" "${RUNS_DONE:-0}" "${eval_count:-}" "${prompt_eval_count:-}"
fi

printf "%b\n" "${GREEN}Diagnostics complete.${RC}"