"""Console-based model downloader for StreamDiffusionV2."""
import os
import sys

# Disable hf-xet transfer backend (causes connection resets on Windows)
os.environ["HF_HUB_DISABLE_XET"] = "1"

# Determine install directory (script is in <install>/scripts/)
INSTALL_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

APP_DIR = os.path.join(INSTALL_DIR, "app")

MODELS = {
    "1": {
        "key": "1.3B",
        "label": "1.3B (~14 GB download, requires 8+ GB VRAM)",
        "base_repo": "Wan-AI/Wan2.1-T2V-1.3B",
        "base_dest": os.path.join(APP_DIR, "wan_models", "Wan2.1-T2V-1.3B"),
        "ckpt_repo": "jerryfeng/StreamDiffusionV2",
        "ckpt_pattern": "wan_causal_dmd_v2v/*",
        "ckpt_dest": os.path.join(APP_DIR, "ckpts"),
    },
    "2": {
        "key": "14B",
        "label": "14B (~40 GB download, requires 24+ GB VRAM)",
        "base_repo": "Wan-AI/Wan2.1-T2V-14B",
        "base_dest": os.path.join(APP_DIR, "wan_models", "Wan2.1-T2V-14B"),
        "ckpt_repo": "jerryfeng/StreamDiffusionV2",
        "ckpt_pattern": "wan_causal_dmd_v2v_14b/*",
        "ckpt_dest": os.path.join(APP_DIR, "ckpts"),
    },
}


def detect_gpu():
    """Detect GPU name and VRAM."""
    import subprocess
    try:
        result = subprocess.run(
            ["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            parts = [p.strip() for p in result.stdout.strip().split(",")]
            if len(parts) >= 2:
                return parts[0], f"{int(parts[1]) / 1024:.1f} GB"
    except Exception:
        pass
    return "Unknown", "Unknown"


def download_snapshot(repo_id, local_dir, allow_patterns=None):
    """Download a repo (or subset) from HuggingFace."""
    from huggingface_hub import snapshot_download

    os.makedirs(local_dir, exist_ok=True)

    print(f"  Downloading from {repo_id}...")
    if allow_patterns:
        print(f"  Filter: {allow_patterns}")
    snapshot_download(
        repo_id=repo_id,
        local_dir=local_dir,
        allow_patterns=allow_patterns,
    )


def main():
    print("=" * 60)
    print("  StreamDiffusionV2 - Model Downloader")
    print("=" * 60)
    print()

    gpu_name, vram = detect_gpu()
    print(f"  GPU:  {gpu_name}")
    print(f"  VRAM: {vram}")
    print()
    print("-" * 60)
    print()
    print("  Select a model to download:")
    print()
    for num, info in MODELS.items():
        print(f"    {num}) {info['label']}")
    print()

    while True:
        choice = input("  Enter choice (1 or 2): ").strip()
        if choice in MODELS:
            break
        print("  Invalid choice. Please enter 1 or 2.")

    model = MODELS[choice]
    print()
    print(f"  Downloading {model['key']} model...")
    print()

    # Download base model
    print("=" * 60)
    print(f"  [1/2] Base model: {model['base_repo']}")
    print(f"  Destination: {model['base_dest']}")
    print("=" * 60)
    print()

    try:
        download_snapshot(model["base_repo"], model["base_dest"])
    except Exception as e:
        print(f"\n  ERROR: Base model download failed: {e}")
        print("  Please check your internet connection and try again.")
        input("\n  Press Enter to exit...")
        sys.exit(1)

    print()

    # Download checkpoint
    print("=" * 60)
    print(f"  [2/2] Checkpoint: {model['ckpt_repo']} ({model['ckpt_pattern']})")
    print(f"  Destination: {model['ckpt_dest']}")
    print("=" * 60)
    print()

    try:
        download_snapshot(model["ckpt_repo"], model["ckpt_dest"],
                         allow_patterns=model["ckpt_pattern"])
    except Exception as e:
        print(f"\n  ERROR: Checkpoint download failed: {e}")
        print("  Please check your internet connection and try again.")
        input("\n  Press Enter to exit...")
        sys.exit(1)

    print()
    print("=" * 60)
    print("  All downloads completed successfully!")
    print("  You can now launch the Web UI from the Start Menu.")
    print("=" * 60)
    input("\n  Press Enter to exit...")


if __name__ == "__main__":
    main()
