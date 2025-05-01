import os
import json
import matplotlib.pyplot as plt

BASE_DIR = "../results/csv"
CONCURRENCY_LEVELS = [1, 2, 4, 8, 16]

GEOMETRIES = ["FU_ZONE", "MU4_ZONE", "MU8_ZONE", "SU_ZONE"]
MODES = ["inter", "intra"]

def get_iops_from_file(filepath):
    with open(filepath) as f:
        data = json.load(f)
        return data["jobs"][0]["write"]["iops"]

def collect_data(mode):
    results = {}
    for geometry in GEOMETRIES:
        dir_name = f"{geometry}-{mode}"
        full_path = os.path.join(BASE_DIR, dir_name)
        y_values = []
        for level in CONCURRENCY_LEVELS:
            match_prefix = f"{mode}_{level}-"
            filename = next((f for f in os.listdir(full_path) if f.startswith(match_prefix)), None)
            if filename:
                filepath = os.path.join(full_path, filename)
                y_values.append(get_iops_from_file(filepath))
            else:
                y_values.append(0)
        results[geometry] = y_values
    return results

def plot_data(results, mode):
    plt.figure(figsize=(8, 5))
    for geometry, y_values in results.items():
        plt.plot(CONCURRENCY_LEVELS, y_values, marker='o', label=geometry)
    plt.xlabel("Queue Depth")
    plt.ylabel("Throughput (IOPs)")
    plt.title(f"Throughput vs Queue Depth")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(f"throughput_{mode}.png")
    plt.show()

if __name__ == "__main__":
    for mode in MODES:
        data = collect_data(mode)
        plot_data(data, mode)
