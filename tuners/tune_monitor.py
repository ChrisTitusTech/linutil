#!/usr/bin/env python3
"""
Monitoring script: logs snapshots to SQLite with profile tag,
including extended metrics (swap in/out, dirty limits, etc.).
"""
import sqlite3, threading, time, subprocess, os

DB = os.path.expanduser("~/perf_metrics_full.db")

def init_db():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute('''
      CREATE TABLE IF NOT EXISTS metrics (
        ts INTEGER,
        profile TEXT,
        cpu_idle REAL,
        cpu_iowait REAL,
        load_1 REAL,
        load_5 REAL,
        load_15 REAL,
        mem_free_kb INTEGER,
        swap_used_kb INTEGER,
        swap_in_kb_s REAL,
        swap_out_kb_s REAL,
        io_read_kb_s REAL,
        io_write_kb_s REAL,
        dev_avgqu_sz REAL,
        dev_await_ms REAL,
        dev_util_percent REAL,
        dirty_ratio INTEGER,
        dirty_background_ratio INTEGER,
        vfs_cache_pressure INTEGER
      )
    ''')
    conn.commit()
    conn.close()

def get_cpu_stats():
    out = subprocess.check_output(["top","-b","-n","1"]).decode()
    idle = 0.0
    iowait = 0.0
    for line in out.splitlines():
        if line.startswith("%Cpu(s):"):
            parts = line.split()
            idle = float(parts[7].strip(","))
            iowait = float(parts[5].strip(","))
            break
    return idle, iowait

def get_loadavg():
    with open("/proc/loadavg","r") as f:
        parts = f.read().split()
    return float(parts[0]), float(parts[1]), float(parts[2])

def get_mem_swap():
    vm = subprocess.check_output(["vmstat","-s"]).decode()
    mem_free = 0
    swap_used = 0
    for line in vm.splitlines():
        if "free memory" in line:
            mem_free = int(line.strip().split()[0])
        if "used swap" in line:
            swap_used = int(line.strip().split()[0])
    return mem_free, swap_used

def get_swap_io():
    # Using vmstat to get si/so
    out = subprocess.check_output(["vmstat","1","2"]).decode().splitlines()
    si = 0.0
    so = 0.0
    for line in out[::-1]:
        if line and line[0].isdigit():
            parts = line.split()
            # swap-in (si) column is at pos maybe index 6, swap-out (so) at 7
            si = float(parts[6])
            so = float(parts[7])
            break
    return si, so

def get_io_stats():
    try:
        io_out = subprocess.check_output(["iostat","-d","1","2","-m"]).decode().splitlines()
        read_s = 0.0; write_s = 0.0
        for l in io_out[::-1]:
            if l and l[0].isdigit():
                parts = l.split()
                read_s = float(parts[-2])
                write_s = float(parts[-1])
                break
    except Exception:
        read_s = 0.0; write_s = 0.0
    return read_s, write_s

def get_dev_queue():
    try:
        out = subprocess.check_output(["iostat","-x","-m","1","2"]).decode().splitlines()
        avgqu = 0.0; await_ms = 0.0; util = 0.0
        for l in out[::-1]:
            if l and l[0].isdigit():
                parts = l.split()
                avgqu = float(parts[6])
                await_ms = float(parts[7])
                util = float(parts[9])
                break
    except Exception:
        avgqu = 0.0; await_ms = 0.0; util = 0.0
    return avgqu, await_ms, util

def get_dirty_and_cache():
    with open("/proc/sys/vm/dirty_ratio","r") as f:
        dirty_ratio = int(f.read().strip())
    with open("/proc/sys/vm/dirty_background_ratio","r") as f:
        dirty_background_ratio = int(f.read().strip())
    with open("/proc/sys/vm/vfs_cache_pressure","r") as f:
        vfs_cache_pressure = int(f.read().strip())
    return dirty_ratio, dirty_background_ratio, vfs_cache_pressure

def worker(profile):
    init_db()
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    try:
        while True:
            ts = int(time.time())
            idle, iowait = get_cpu_stats()
            load1, load5, load15 = get_loadavg()
            mem_free, swap_used = get_mem_swap()
            si, so = get_swap_io()
            io_r, io_w = get_io_stats()
            avgqu, await_ms, util = get_dev_queue()
            dirty_ratio, dirty_background_ratio, vfs_cache_pressure = get_dirty_and_cache()

            c.execute('''
              INSERT INTO metrics (
                ts, profile, cpu_idle, cpu_iowait,
                load_1, load_5, load_15,
                mem_free_kb, swap_used_kb, swap_in_kb_s, swap_out_kb_s,
                io_read_kb_s, io_write_kb_s,
                dev_avgqu_sz, dev_await_ms, dev_util_percent,
                dirty_ratio, dirty_background_ratio, vfs_cache_pressure
              ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            ''', (
              ts, profile, idle, iowait,
              load1, load5, load15,
              mem_free, swap_used, si, so,
              io_r, io_w,
              avgqu, await_ms, util,
              dirty_ratio, dirty_background_ratio, vfs_cache_pressure
            ))
            conn.commit()

            print(f"{time.strftime('%Y-%m-%d %H:%M:%S')} [{profile}] idle={idle:.1f}%, iowait={iowait:.1f}%, "
                  f"load={load1:.2f}/{load5:.2f}/{load15:.2f}, mem_free={mem_free}KB, swap_used={swap_used}KB, "
                  f"si={si:.1f}, so={so:.1f}, io_r={io_r}KB/s, io_w={io_w}KB/s, "
                  f"avgqu={avgqu:.2f}, await={await_ms:.2f}ms, util={util:.1f}%, dirty_ratio={dirty_ratio}, "
                  f"dirty_bg_ratio={dirty_background_ratio}, vfs_cache_pressure={vfs_cache_pressure}")
            time.sleep(60)
    except KeyboardInterrupt:
        print("Stopped monitoring.")
    finally:
        conn.close()

if __name__ == "__main__":
    import sys
    prof = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    worker(prof)

