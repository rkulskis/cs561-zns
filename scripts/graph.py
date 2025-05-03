import os
import re
import json
import matplotlib.pyplot as plt

# Configuration
BASE_DIR = "../results/json"
GRAPH_DIR = "../results/graphs"
GEOMETRIES = ["FU_ZONE", "MU4_ZONE", "MU8_ZONE", "SU_ZONE"]
MODES = ["inter", "intra"]
RWS = ["read", "write"]

def extract_util(data):
    # return data["disk_util"][0]["util"]
    return data["util"]         # since we compressed the data

def extract_iops(data, rw):
    # return data["jobs"][0][rw]["iops"]
    return data["iops"]

def get_concurrency_levels(dir_path):
    levels = set()
    if not os.path.isdir(dir_path):
        return []
    for fname in os.listdir(dir_path):
        match = re.match(r"(\d+)-", fname)
        if match:
            levels.add(int(match.group(1)))
    return sorted(levels)

def collect_iops_data(mode, geometry, rw):
    dir_path = os.path.join(BASE_DIR, f"{mode}_{rw}", geometry)
    concurrency_levels = get_concurrency_levels(dir_path)
    y_values = []
    for level in concurrency_levels:
        prefix = f"{level}-"
        try:
            filename = next(f for f in os.listdir(dir_path) if f.startswith(prefix))
            filepath = os.path.join(dir_path, filename)
            with open(filepath) as f:
                data = json.load(f)
                y_values.append(extract_iops(data, rw))
        except (StopIteration, FileNotFoundError, KeyError, json.JSONDecodeError):
            y_values.append(0)
    return concurrency_levels, y_values

def plot_geometry_iops(geometry):
    for mode in MODES:
        plt.figure(figsize=(8, 5))
        for rw in RWS:
            concurrency_levels, y_values = collect_iops_data(mode, geometry, rw)
            if concurrency_levels:
                plt.plot(concurrency_levels, y_values, marker='o', label=f"{rw}")
        plt.xlabel("Concurrency Level")
        plt.ylabel("IOPS")
        plt.title(f"{geometry} - {mode} IOPS vs Concurrency")
        plt.legend()
        plt.grid(True)
        plt.tight_layout()
        os.makedirs(GRAPH_DIR, exist_ok=True)
        out_path = os.path.join(GRAPH_DIR, f"{geometry}_{mode}_iops.png")
        plt.savefig(out_path)
        print(f"Saved graph: {out_path}")
        plt.close()

def collect_util_data(mode_rw):
    results = {}
    for geometry in GEOMETRIES:
        dir_path = os.path.join(BASE_DIR, mode_rw, geometry)
        concurrency_levels = get_concurrency_levels(dir_path)
        y_values = []
        for level in concurrency_levels:
            prefix = f"{level}-"
            try:
                filename = next(f for f in os.listdir(dir_path) if f.startswith(prefix))
                filepath = os.path.join(dir_path, filename)
                with open(filepath) as f:
                    data = json.load(f)
                    y_values.append(extract_util(data))
            except (StopIteration, FileNotFoundError, KeyError, json.JSONDecodeError):
                y_values.append(0)
        if concurrency_levels:
            results[geometry] = (concurrency_levels, y_values)
    return results

def plot_utilization(results, mode_rw):
    plt.figure(figsize=(8, 5))
    for geometry, (levels, y_values) in results.items():
        plt.plot(levels, y_values, marker='o', label=geometry)
    plt.xlabel("Concurrency Level")
    plt.ylabel("Utilization (%)")
    plt.title(f"Disk Utilization vs Concurrency ({mode_rw})")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    os.makedirs(GRAPH_DIR, exist_ok=True)
    out_path = os.path.join(GRAPH_DIR, f"utilization_{mode_rw}.png")
    plt.savefig(out_path)
    print(f"Saved graph: {out_path}")
    plt.close()

if __name__ == "__main__":
    # IOPS graphs per geometry per mode
    for geometry in GEOMETRIES:
        plot_geometry_iops(geometry)

    # Disk utilization graphs
    for mode in MODES:
        for rw in RWS:
            mode_rw = f"{mode}_{rw}"
            util_data = collect_util_data(mode_rw)
            plot_utilization(util_data, mode_rw)
