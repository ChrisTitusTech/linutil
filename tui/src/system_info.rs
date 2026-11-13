use crate::theme::Theme;
use ratatui::{
    style::Style,
    text::{Line, Span},
};
use std::process::Command;
use unicode_width::{UnicodeWidthChar, UnicodeWidthStr};

const FASTFETCH_ARGS: [&str; 8] = [
    "--config",
    "none",
    "--logo",
    "none",
    "--separator",
    " : ",
    "--structure",
    "cpu:gpu:memory:disk",
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
                let label = truncate_value(entry.label, max_width);
                let label_width = label.width();
                let value_width = max_width.saturating_sub(label_width + 1);
                let value = truncate_value(&entry.value, value_width);
                let gap = max_width.saturating_sub(label_width + value.width());
                Line::from(vec![
                    Span::styled(label, Style::default().fg(theme.muted())),
                    Span::raw(" ".repeat(gap)),
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

    output
        .status
        .success()
        .then(|| parse_entries(&String::from_utf8_lossy(&output.stdout)))
}

fn parse_entries(stdout: &str) -> Vec<InfoEntry> {
    let cleaned = strip_ansi_codes(stdout);
    let mut values: [Option<String>; 4] = [None, None, None, None];

    for line in cleaned.lines() {
        let Some((label, value)) = line.trim().split_once(':') else {
            continue;
        };
        let label = label.trim().to_ascii_lowercase();
        let value = value.trim();
        if value.is_empty() {
            continue;
        }
        let index = if label.starts_with("cpu") {
            0
        } else if label.starts_with("gpu") {
            1
        } else if label.starts_with("memory") || label.starts_with("ram") {
            2
        } else if label.starts_with("disk") {
            3
        } else {
            continue;
        };
        if values[index].is_none() {
            values[index] = Some(if index >= 2 {
                // Fastfetch appends utilization and filesystem details after capacity.
                value.split(" (").next().unwrap_or(value).trim().to_owned()
            } else {
                value.to_owned()
            });
        }
    }

    ["CPU", "GPU", "Memory", "Disk"]
        .into_iter()
        .zip(values)
        .map(|(label, value)| InfoEntry {
            label,
            value: value.unwrap_or_else(|| "n/a".to_owned()),
        })
        .collect()
}

fn strip_ansi_codes(input: &str) -> String {
    let mut output = String::with_capacity(input.len());
    let mut chars = input.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\x1b' && matches!(chars.peek(), Some('[')) {
            chars.next();
            for next in chars.by_ref() {
                if ('@'..='~').contains(&next) {
                    break;
                }
            }
        } else {
            output.push(c);
        }
    }
    output
}

fn truncate_value(value: &str, max_width: usize) -> String {
    if value.width() <= max_width {
        return value.to_owned();
    }
    if max_width == 0 {
        return String::new();
    }
    let mut truncated = String::new();
    let mut width = 0;
    for c in value.chars() {
        let char_width = c.width().unwrap_or(0);
        if width + char_width > max_width - 1 {
            break;
        }
        truncated.push(c);
        width += char_width;
    }
    truncated.push('…');
    truncated
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_full_devices_and_used_total_capacity_in_dashboard_order() {
        let entries = parse_entries(
            "\x1b[34mCPU\x1b[0m : Example CPU (8) @ 3.00 GHz\n\
             Disk (/) : 100.00 GiB / 500.00 GiB (20%) - ext4\n\
             Memory : 4.00 GiB / 16.00 GiB (25%)\n\
             GPU : Example GPU @ 1.00 GHz [Integrated]\n",
        );
        assert_eq!(
            entries.iter().map(|e| e.label).collect::<Vec<_>>(),
            ["CPU", "GPU", "Memory", "Disk"]
        );
        assert_eq!(entries[0].value, "Example CPU (8) @ 3.00 GHz");
        assert_eq!(entries[1].value, "Example GPU @ 1.00 GHz [Integrated]");
        assert_eq!(entries[2].value, "4.00 GiB / 16.00 GiB");
        assert_eq!(entries[3].value, "100.00 GiB / 500.00 GiB");
    }

    #[test]
    fn missing_devices_are_explicitly_unavailable() {
        let entries = parse_entries("CPU : Test CPU\nGPU : \nUnknown : ignored\n");
        assert_eq!(entries[0].value, "Test CPU");
        assert!(entries[1..].iter().all(|entry| entry.value == "n/a"));
        assert!(parse_entries("").iter().all(|entry| entry.value == "n/a"));
    }

    #[test]
    fn lines_fit_the_terminal_cell_width_even_with_wide_characters() {
        let info = SystemInfo {
            entries: parse_entries("CPU : 处理器 AMD\nGPU : Graphics\n"),
        };
        for width in 0..40 {
            for line in info.render_lines(&Theme::Compatible, width) {
                assert_eq!(line.width(), width);
            }
        }
        assert_eq!(truncate_value("处理器 AMD", 5), "处理…");
    }
}
