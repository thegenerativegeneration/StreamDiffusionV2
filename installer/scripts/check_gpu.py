"""GPU and CUDA prerequisite checker for StreamDiffusionV2."""
import subprocess
import sys

MIN_DRIVER_VERSION = 550  # Minimum for CUDA 12.4

def main():
    try:
        result = subprocess.run(
            ["nvidia-smi", "--query-gpu=name,driver_version,memory.total",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=10
        )
    except FileNotFoundError:
        print("ERROR: nvidia-smi not found.")
        print("Please install NVIDIA GPU drivers from https://www.nvidia.com/drivers/")
        return 1
    except subprocess.TimeoutExpired:
        print("ERROR: nvidia-smi timed out.")
        return 1

    if result.returncode != 0:
        print("ERROR: nvidia-smi failed.")
        print(result.stderr.strip())
        print("Please ensure NVIDIA drivers are properly installed.")
        return 1

    lines = [l.strip() for l in result.stdout.strip().split("\n") if l.strip()]
    if not lines:
        print("ERROR: No NVIDIA GPU detected.")
        return 1

    has_warning = False
    for line in lines:
        parts = [p.strip() for p in line.split(",")]
        if len(parts) < 3:
            continue

        name, driver_ver, vram_mb = parts[0], parts[1], parts[2]
        vram_gb = int(vram_mb) / 1024

        print(f"  GPU: {name}")
        print(f"  Driver: {driver_ver}")
        print(f"  VRAM: {vram_gb:.1f} GB")

        # Check driver version
        try:
            major = int(driver_ver.split(".")[0])
            if major < MIN_DRIVER_VERSION:
                print(f"  WARNING: Driver {driver_ver} may be too old for CUDA 12.4.")
                print(f"  Recommended: driver version {MIN_DRIVER_VERSION}+")
                print(f"  Update at: https://www.nvidia.com/drivers/")
                has_warning = True
        except (ValueError, IndexError):
            pass

        # VRAM recommendations
        vram_gb_val = float(vram_gb)
        if vram_gb_val < 7.5:
            print(f"  WARNING: {vram_gb:.1f} GB VRAM is below the minimum (8 GB).")
            print("  StreamDiffusionV2 may not run properly.")
            has_warning = True
        elif vram_gb_val < 24:
            print(f"  Recommended model: 1.3B (requires 8+ GB VRAM)")
        else:
            print(f"  Recommended model: 14B (you have enough VRAM for the full model)")
        print()

    return 0 if not has_warning else 0  # warnings are non-fatal


if __name__ == "__main__":
    sys.exit(main())
