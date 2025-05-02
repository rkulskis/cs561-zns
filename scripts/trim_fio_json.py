import json
import sys

def trim_fio_json(in_path, out_path, rw):
    with open(in_path) as f:
        data = json.load(f)

    trimmed = {
        "util": data["disk_util"][0]["util"],
        "iops": data["jobs"][0][rw]["iops"] if "jobs" in data else 0
    }

    with open(out_path, "w") as f:
        json.dump(trimmed, f, indent=2)

if __name__ == "__main__":
    # Usage: python trim_fio_json.py infile.json outfile.json read|write
    if len(sys.argv) != 4:
        print("Usage: python trim_fio_json.py <infile> <outfile> <read|write>")
        sys.exit(1)

    trim_fio_json(sys.argv[1], sys.argv[2], sys.argv[3])
