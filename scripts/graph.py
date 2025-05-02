import os
import json
import matplotlib.pyplot as plt

# Configuration
BASE_DIR = "../results/json"
GRAPH_DIR = "../results/graphs"
CONCURRENCY_LEVELS = [1, 2, 4, 8, 16, 32, 64]
GEOMETRIES = ["FU_ZONE", "MU4_ZONE", "MU8_ZONE", "SU_ZONE"]

# Define all modes
MODES = ["inter", "intra", "rand_read", "seq_read"]

def extract_util(data):
    return data["disk_util"][0]["util"]

def extract_iops(data):
    return data["jobs"][0]["write"]["iops"]

def collect_data(metric_fn, mode):
    results = {}
    for geometry in GEOMETRIES:
        dir_path = os.path.join(BASE_DIR, mode, geometry)
        if not os.path.isdir(dir_path):
            continue
        y_values = []
        for level in CONCURRENCY_LEVELS:
            match_prefix = f"{level}-"
            try:
                filename = next(f for f in os.listdir(dir_path) if f.startswith(match_prefix))
                filepath = os.path.join(dir_path, filename)
                with open(filepath) as f:
                    data = json.load(f)
                    y_values.append(metric_fn(data))
            except (StopIteration, FileNotFoundError, KeyError):
                y_values.append(0)
        results[geometry] = y_values
    return results

def plot_data(results, mode, title, ylabel, out_prefix):
    plt.figure(figsize=(8, 5))
    for geometry, y_values in results.items():
        plt.plot(CONCURRENCY_LEVELS, y_values, marker='o', label=geometry)
    plt.xlabel("Concurrency Level")
    plt.ylabel(ylabel)
    plt.title(f"{title} ({mode})")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    os.makedirs(GRAPH_DIR, exist_ok=True)
    out_path = os.path.join(GRAPH_DIR, f"{out_prefix}_{mode}.png")
    plt.savefig(out_path)
    print(f"Saved graph: {out_path}")
    plt.close()

if __name__ == "__main__":
    for mode in ["inter", "intra"]:
        data = collect_data(extract_iops, mode=mode)
        plot_data(data, mode, title="IOPS vs Concurrency", ylabel="IOPS", out_prefix="IOPS")

    for mode in MODES:
        data = collect_data(extract_util, mode=mode)
        plot_data(data, mode, title="Disk Utilization vs Concurrency", ylabel="Utilization (%)", out_prefix="utilization")
