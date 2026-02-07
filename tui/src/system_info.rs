use crate::theme::Theme;
use ratatui::{
    style::{Style, Stylize},
    text::{Line, Span},
};
use std::process::Command;

const FASTFETCH_ARGS: [&str; 6] = [
    "--logo",
    "none",
    "--separator",
    " : ",
    "--structure",
    "cpu:disk:memory:gpu",
];

pub struct SystemInfo {
    entries: Vec<InfoEntry>,
}

struct InfoEntry {
    label: &'static str,
    value: String,
}

impl SystemInfo {
    pub fn gather() -> Option<Self> {
        fastfetch_entries().map(|entries| Self { entries })
    }

    pub fn entries_len(&self) -> usize {
        self.entries.len()
    }

    pub fn render_lines(&self, theme: &Theme, max_width: usize) -> Vec<Line<'static>> {
        self.entries
            .iter()
            .map(|entry| {
                let prefix = format!("{:>4}: ", entry.label);
                let value_width = max_width.saturating_sub(prefix.len());
                let value = truncate_value(&entry.value, value_width);
                Line::from(vec![
                    Span::styled(
                        format!("{:>4}", entry.label),
                        Style::default().fg(theme.tab_color()).bold(),
                    ),
                    Span::styled(": ", Style::default().fg(theme.unfocused_color())),
                    Span::styled(value, Style::default().fg(theme.cmd_color())),
                ])
            })
            .collect()
    }
}

fn fastfetch_entries() -> Option<Vec<InfoEntry>> {
    let output = Command::new("fastfetch")
        .args(FASTFETCH_ARGS)
        .env("NO_COLOR", "1")
        .output()
        .ok()?;

    if !output.status.success() {
        return None;
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let cleaned = strip_ansi_codes(&stdout);

    let mut cpu = None;
    let mut disk = None;
    let mut ram = None;
    let mut gpu = None;

    for line in cleaned.lines() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }

        let mut parts = line.splitn(2, ':');
        let label = parts.next().unwrap_or("").trim();
        let value = parts.next().unwrap_or("").trim();
        if value.is_empty() {
            continue;
        }

        let label_lower = label.to_ascii_lowercase();
        if cpu.is_none() && label_lower.starts_with("cpu") {
            cpu = Some(normalize_value("cpu", value));
        } else if disk.is_none() && label_lower.starts_with("disk") {
            disk = Some(normalize_value("disk", value));
        } else if ram.is_none()
            && (label_lower.starts_with("memory") || label_lower.starts_with("ram"))
        {
            ram = Some(normalize_value("ram", value));
        } else if gpu.is_none() && label_lower.starts_with("gpu") {
            gpu = Some(normalize_value("gpu", value));
        }
    }

    if cpu.is_none() && disk.is_none() && ram.is_none() && gpu.is_none() {
        return None;
    }

    Some(vec![
        InfoEntry {
            label: "CPU",
            value: cpu.unwrap_or_else(|| "n/a".to_string()),
        },
        InfoEntry {
            label: "DISK",
            value: disk.unwrap_or_else(|| "n/a".to_string()),
        },
        InfoEntry {
            label: "RAM",
            value: ram.unwrap_or_else(|| "n/a".to_string()),
        },
        InfoEntry {
            label: "GPU",
            value: gpu.unwrap_or_else(|| "n/a".to_string()),
        },
    ])
}

fn strip_ansi_codes(input: &str) -> String {
    let mut output = String::with_capacity(input.len());
    let mut chars = input.chars().peekable();

    while let Some(c) = chars.next() {
        if c == '\x1b' && matches!(chars.peek(), Some('[')) {
            chars.next();
            for next in chars.by_ref() {
                if next == 'm' {
                    break;
                }
            }
            continue;
        }
        output.push(c);
    }

    output
}

fn normalize_value(label: &str, value: &str) -> String {
    match label {
        "cpu" => strip_device_details(value),
        "gpu" => strip_device_details(value),
        "disk" => extract_total(value),
        "ram" => extract_total(value),
        _ => value.trim().to_string(),
    }
}

fn strip_device_details(value: &str) -> String {
    let mut trimmed = value.trim().to_string();
    if let Some(idx) = trimmed.find(" @") {
        trimmed.truncate(idx);
        trimmed = trimmed.trim().to_string();
    }
    if let Some(idx) = trimmed.find(" (") {
        trimmed.truncate(idx);
        trimmed = trimmed.trim().to_string();
    }
    if let Some(idx) = trimmed.find(" [") {
        trimmed.truncate(idx);
        trimmed = trimmed.trim().to_string();
    }
    trimmed
}

fn extract_total(value: &str) -> String {
    let mut parts = value.splitn(2, '/');
    let _used = parts.next();
    let Some(total_part) = parts.next() else {
        return value.trim().to_string();
    };
    let mut tokens = total_part.split_whitespace();
    let Some(amount) = tokens.next() else {
        return total_part.trim().to_string();
    };
    let Some(unit) = tokens.next() else {
        return amount.to_string();
    };
    format!("{amount} {unit}")
}

fn truncate_value(value: &str, max_width: usize) -> String {
    if max_width == 0 {
        return String::new();
    }

    let value_chars: Vec<char> = value.chars().collect();
    if value_chars.len() <= max_width {
        return value.to_string();
    }

    if max_width <= 3 {
        return value_chars.iter().take(max_width).collect();
    }

    let slice: String = value_chars.iter().take(max_width - 3).collect();
    format!("{slice}...")
}
