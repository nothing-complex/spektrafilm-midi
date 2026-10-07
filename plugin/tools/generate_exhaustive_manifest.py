import json
from pathlib import Path

def create_candidate(name, tags, quality, env, args):
    return {
        "name": name,
        "quality_policy": quality,
        "tags": tags,
        "env": env,
        "perf_args": args
    }

candidates = []

# Baseline is automatically included by the harness

# 1. Threadgroup
for tg in ["auto", "16x16", "32x8", "8x32", "64x4"]:
    candidates.append(create_candidate(
        f"tg-{tg}", ["threadgroup", "core"], "exact",
        {"SPEKTRAFILM_THREADGROUP": tg},
        ["--threadgroup", tg]
    ))

# 2. Scratch storage
for ss in ["private", "shared"]:
    candidates.append(create_candidate(
        f"scratch-{ss}", ["scratch", "core"], "exact",
        {"SPEKTRAFILM_SCRATCH_STORAGE": ss},
        ["--scratch-storage", ss]
    ))

# 3. Scanner optimizations
candidates.append(create_candidate("scanner-texture", ["scanner", "exact"], "exact",
    {"SPEKTRAFILM_SCANNER_IMAGE_STORAGE": "texture"}, ["--scanner-image-storage", "texture"]))
candidates.append(create_candidate("scanner-mps", ["scanner", "mps", "approximate"], "report_only",
    {"SPEKTRAFILM_SCANNER_MPS": "1"}, ["--scanner-mps", "1"]))
candidates.append(create_candidate("scanner-mps-texture", ["scanner", "mps", "approximate", "combined"], "report_only",
    {"SPEKTRAFILM_SCANNER_MPS": "1", "SPEKTRAFILM_SCANNER_IMAGE_STORAGE": "texture"}, 
    ["--scanner-mps", "1", "--scanner-image-storage", "texture"]))

# 4. Halation
candidates.append(create_candidate("halation-grouped-tail", ["halation", "grouped-tail", "approximate"], "report_only",
    {"SPEKTRAFILM_HALATION_GROUPED_TAIL": "1"}, ["--halation-grouped-tail", "1"]))

# 5. Diffusion
for size in ["1", "2", "4"]:
    candidates.append(create_candidate(
        f"diffusion-group-{size}", ["diffusion", "group-size", "exact"], "exact",
        {"SPEKTRAFILM_DIFFUSION_GROUP_SIZE": size},
        ["--diffusion-group-size", size]
    ))

# 6. Blur Backend
for backend in ["auto", "mps", "custom"]:
    candidates.append(create_candidate(
        f"blur-backend-{backend}", ["blur", "backend", "approximate" if backend != "custom" else "exact"], 
        "report_only" if backend != "custom" else "exact",
        {"SPEKTRAFILM_BLUR_BACKEND": backend},
        ["--blur-backend", backend]
    ))

# 7. Blur Downsample
for ds in ["2", "4", "8", "auto"]:
    candidates.append(create_candidate(
        f"blur-downsample-{ds}", ["blur", "downsample", "approximate"], "report_only",
        {"SPEKTRAFILM_BLUR_DOWNSAMPLE": ds},
        ["--blur-downsample", ds]
    ))

# 8. Intermediate Precision
candidates.append(create_candidate("precision-half-blur", ["precision", "half", "blur", "approximate"], "report_only",
    {"SPEKTRAFILM_INTERMEDIATE_PRECISION": "half-blur"}, ["--intermediate-precision", "half-blur"]))

# 9. Diffusion Cluster Sigma
for sigma in ["0.05", "0.10"]:
    candidates.append(create_candidate(
        f"diffusion-cluster-{sigma.replace('.', '')}", ["diffusion", "cluster", "approximate"], "report_only",
        {"SPEKTRAFILM_DIFFUSION_CLUSTER_SIGMA": sigma},
        ["--diffusion-cluster-sigma", sigma]
    ))

# 10. Grain Blur Recurrence
candidates.append(create_candidate("grain-blur-recurrence", ["grain", "blur", "recurrence", "exact"], "exact",
    {"SPEKTRAFILM_GRAIN_BLUR_RECURRENCE": "1"}, ["--grain-blur-recurrence", "1"]))

# 11. DIR Tail Backend
candidates.append(create_candidate("dir-tail-mps", ["dir", "mps", "approximate"], "report_only",
    {"SPEKTRAFILM_DIR_TAIL_BACKEND": "mps"}, ["--dir-tail-backend", "mps"]))
candidates.append(create_candidate("dir-tail-fused", ["dir", "fused", "exact"], "exact",
    {"SPEKTRAFILM_DIR_TAIL_BACKEND": "fused"}, ["--dir-tail-backend", "fused"]))

# Grain synthesis modes are intentionally omitted from exhaustive perf sweeps.
# The sweep now covers preview grain and production grain only.

manifest = {
    "schema_version": 1,
    "include_defaults": True,
    "candidates": candidates
}

Path("tools/perf_candidates_exhaustive.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(f"Generated {len(candidates)} candidates in tools/perf_candidates_exhaustive.json")
