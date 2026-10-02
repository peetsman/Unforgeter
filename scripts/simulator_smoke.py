"""Boot an available iPhone Simulator and verify the initial app stays running.

Requires macOS/Xcode. This checks launch, not permission flow or real geofencing.
"""
from pathlib import Path
import json
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
BUNDLE_ID = "com.peetsman.Unforgeter"


def simctl(*args, timeout=60):
    print(f"simctl {args[0]} (timeout {timeout}s)", flush=True)
    try:
        result = subprocess.run(
            ["xcrun", "simctl", *args], check=True, capture_output=True,
            text=True, timeout=timeout,
        )
    except subprocess.CalledProcessError as error:
        print(error.stdout or "", flush=True)
        print(error.stderr or "", flush=True)
        raise
    return result.stdout


def main():
    devices = json.loads(simctl("list", "devices", "available", "--json"))["devices"]
    candidates = [
        device for runtime, values in devices.items() if "iOS" in runtime
        for device in values if device["name"].startswith("iPhone") and device.get("isAvailable")
    ]
    if not candidates:
        raise SystemExit("No available iPhone Simulator runtime installed.")
    device = candidates[0]
    udid = device["udid"]
    print(f"Launch smoke test: {device['name']} ({udid})", flush=True)
    if device["state"] != "Booted":
        simctl("boot", udid)
    simctl("bootstatus", udid, "-b", timeout=240)
    app = ROOT / "build/Debug/Build/Products/Debug-iphonesimulator/Unforgeter.app"
    # Fresh hosted simulators can need extra time for their first installation.
    simctl("install", udid, str(app), timeout=180)
    print(simctl("launch", udid, BUNDLE_ID, timeout=120), flush=True)
    time.sleep(5)
    processes = simctl("spawn", udid, "launchctl", "list")
    live = [line for line in processes.splitlines() if BUNDLE_ID in line and line.split()[0].isdigit()]
    if not live:
        raise SystemExit("App did not remain running after launch.")
    output = ROOT / "build/evidence"
    output.mkdir(parents=True, exist_ok=True)
    simctl("io", udid, "screenshot", str(output / "simulator-launch.png"))
    print("PASS: app still running after five seconds; launch screenshot captured.")
    print("This does not verify permissions, notification taps, or physical geofence delivery.")


if __name__ == "__main__":
    main()
