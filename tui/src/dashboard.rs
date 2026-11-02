use crate::{
    stars::{basic_terminal, linux_console},
    theme::Theme,
};
use ratatui::{prelude::*, symbols::border, widgets::Block};
use std::sync::OnceLock;
use unicode_width::{UnicodeWidthChar, UnicodeWidthStr};

pub const FLAGS: &[(&str, &str)] = &[
    ("D", "Disk modifications"),
    ("FI", "Flatpak installation"),
    ("FM", "File modification"),
    ("I", "Installation"),
    ("K", "Kernel modifications"),
    ("MP", "Package manager actions"),
    ("SI", "Full system installation"),
    ("SS", "Systemd actions"),
    ("RP", "Package removal"),
    ("P", "Privileged prefix (e.g. PFM)"),
];
pub const CONTROLS: &[(&str, &str)] = &[
    ("k/j/up/down", "Move selection"),
    ("enter/right", "Open/run"),
    ("h/left", "Parent directory"),
    ("tab/shift+tab", "Switch category"),
    ("t", "Change theme"),
    ("p", "Script preview"),
    ("?", "Help"),
    ("q/ctrl+c", "Quit Linutil"),
];

fn is_basic_terminal() -> bool {
    static BASIC: OnceLock<bool> = OnceLock::new();
    *BASIC
        .get_or_init(|| basic_terminal(&std::env::var("TERM").unwrap_or_default(), linux_console()))
}

/// Rounded corners, or square ones on a basic terminal: Linux console fonts
/// have no rounded corners.
pub fn border_set() -> border::Set<'static> {
    border_set_for(is_basic_terminal())
}

/// Italic, except on a basic terminal: the Linux console shows italic text
/// in another colour (green by default) instead.
pub fn italic(style: Style) -> Style {
    if is_basic_terminal() {
        style
    } else {
        style.italic()
    }
}

fn border_set_for(basic: bool) -> border::Set<'static> {
    if basic {
        border::PLAIN
    } else {
        border::ROUNDED
    }
}

pub fn block<'a>(title: impl Into<Line<'a>>, theme: &Theme, focused: bool) -> Block<'a> {
    Block::bordered()
        .border_set(border_set())
        .title(title)
        .border_style(Style::default().fg(if focused {
            theme.focused_color()
        } else {
            theme.unfocused_color()
        }))
        .title_style(Style::default().fg(theme.tab_color()).bold())
        .style(Style::default().bg(theme.bg()).fg(theme.cmd_color()))
}

pub fn truncate(text: &str, width: usize) -> String {
    let mut used = 0;
    text.chars()
        .take_while(|c| {
            used += c.width().unwrap_or(0);
            used <= width
        })
        .collect()
}

fn wrap(text: &str, width: usize) -> Vec<String> {
    if width == 0 {
        return vec![];
    }
    let mut rows = Vec::new();
    let mut line = String::new();
    for word in text.split_whitespace() {
        if !line.is_empty() && line.width() + 1 + word.width() > width {
            rows.push(std::mem::take(&mut line));
        }
        if !line.is_empty() {
            line.push(' ');
        }
        for c in word.chars() {
            if line.width() + c.width().unwrap_or(0) > width {
                rows.push(std::mem::take(&mut line));
            }
            line.push(c);
        }
    }
    if !line.is_empty() {
        rows.push(line);
    }
    rows
}

pub fn legend(
    items: &[(&str, &str)],
    width: u16,
    two_columns_at: u16,
    theme: &Theme,
) -> Vec<Line<'static>> {
    let columns = if width >= two_columns_at { 2 } else { 1 };
    let widths = if columns == 2 && two_columns_at == 64 {
        let first = ((width - 3) / 2).max(41.min(width.saturating_sub(36)));
        vec![first, width - 3 - first]
    } else {
        vec![(width.saturating_sub((columns - 1) * 3)) / columns; columns as usize]
    };
    let count = items.len().div_ceil(columns as usize);
    let mut cells: Vec<Vec<Line<'static>>> = Vec::new();
    for (column, column_width) in widths.iter().enumerate() {
        let group =
            &items[(column * count).min(items.len())..((column + 1) * count).min(items.len())];
        let key_width = group.iter().map(|(key, _)| key.width()).max().unwrap_or(0) + 2;
        let mut lines = Vec::new();
        for (key, description) in group {
            let desc_width = (*column_width as usize).saturating_sub(key_width).max(1);
            for (row, part) in wrap(description, desc_width).into_iter().enumerate() {
                let key = if row == 0 {
                    key.to_string()
                } else {
                    String::new()
                };
                let padding = key_width.saturating_sub(key.width());
                lines.push(Line::from(vec![
                    Span::styled(key, Style::default().fg(theme.purple())),
                    Span::raw(" ".repeat(padding)),
                    Span::styled(part, Style::default().fg(theme.muted())),
                ]));
            }
        }
        cells.push(lines);
    }
    let rows = cells.iter().map(Vec::len).max().unwrap_or(0);
    (0..rows)
        .map(|row| {
            let mut spans = Vec::new();
            for (column, lines) in cells.iter().enumerate() {
                let line = lines.get(row).cloned().unwrap_or_default();
                let padding = (widths[column] as usize).saturating_sub(line.width());
                spans.extend(line.spans);
                if column + 1 < cells.len() {
                    spans.push(Span::raw(" ".repeat(padding + 3)));
                }
            }
            Line::from(spans)
        })
        .collect()
}

pub fn help_lines(width: u16, theme: &Theme) -> Vec<Line<'static>> {
    legend(CONTROLS, width, 64, theme)
}

#[cfg(feature = "tips")]
pub fn tip_lines(tip: &str, width: u16, theme: &Theme) -> Vec<Line<'static>> {
    wrap(tip, width as usize)
        .into_iter()
        .map(|line| Line::styled(line, Style::default().fg(theme.muted())))
        .collect()
}

pub struct DashboardLayout {
    pub commands: Rect,
    pub system: Rect,
    pub logo: Rect,
    pub selection: Rect,
    pub flags: Rect,
    pub help: Rect,
    pub tip: Rect,
    pub links: Rect,
}

impl DashboardLayout {
    pub fn new(area: Rect, flags_height: u16, help_height: u16, tip_height: u16) -> Self {
        let w = area.width;
        let base = ((f64::from(w) * 0.58).floor().max(42.0) * 1.2).round() as u16;
        let left = base.saturating_sub(7).min(if w >= 195 {
            w - 91
        } else if w >= 147 {
            w - 81
        } else {
            ((f64::from(w) * 0.45) as u16 + 3)
                .max(45)
                .min(w.saturating_sub(45))
        });
        let commands_width = left.saturating_sub(3).min(w);
        let right_x = (commands_width + 1).min(w);
        let right_width = w.saturating_sub(right_x);
        let body_y = 3.min(area.height);
        let body_height = area.height.saturating_sub(body_y);
        let system_height = 9.min(body_height);
        let logo_width = if right_width >= 65 { 28 } else { 0 };
        let selection_y = (body_y + system_height).min(area.height);
        let remaining = area.height.saturating_sub(selection_y);
        // Reserve a heading row above the full tip and a blank row before the links.
        let links_height = if remaining >= tip_height + 10 { 3 } else { 0 };
        let tip_height = tip_height.min(remaining.saturating_sub(7));
        let tail_height = tip_height
            + u16::from(tip_height > 0)
            + links_height
            + u16::from(tip_height > 0 && links_height > 0);
        let panel_room = remaining.saturating_sub(tail_height);
        let help_height = if panel_room >= help_height + 7 {
            help_height
        } else {
            0
        };
        let flags_height = if panel_room >= flags_height + help_height + 7 {
            flags_height
        } else {
            0
        };
        let selection_height = panel_room.saturating_sub(flags_height + help_height + 2);
        let flags_y = selection_y + selection_height;
        let help_y = flags_y + flags_height;
        let tip_y = help_y + help_height + u16::from(tip_height > 0);
        let links_y = tip_y + tip_height + 2 * u16::from(tip_height > 0 && links_height > 0);
        let rect = |x, y, width, height| {
            Rect::new(area.x + x, area.y + y, width, height).intersection(area)
        };
        Self {
            commands: rect(0, body_y, commands_width, body_height),
            system: rect(
                right_x,
                body_y,
                right_width.saturating_sub(logo_width),
                system_height,
            ),
            logo: rect(
                right_x + right_width.saturating_sub(logo_width),
                0,
                logo_width,
                (body_y + system_height).saturating_sub(1),
            ),
            selection: rect(right_x, selection_y, right_width, selection_height),
            flags: rect(right_x, flags_y, right_width, flags_height),
            help: rect(right_x, help_y, right_width, help_height),
            tip: rect(right_x, tip_y, right_width, tip_height),
            links: rect(right_x, links_y, right_width, links_height),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basic_terminals_get_square_corners() {
        // The Linux console fonts (default8x16, Lat2-Terminus16, eurlatgr)
        // have ┌┐└┘ but not ╭╮╰╯.
        assert_eq!(border_set_for(true), border::PLAIN);
        assert_eq!(border_set_for(false), border::ROUNDED);
    }

    #[cfg(feature = "tips")]
    #[test]
    fn full_tips_fit_below_quick_help_with_blank_rows() {
        let theme = Theme::default();
        for (width, height) in [(90, 25), (90, 40), (147, 40), (200, 50), (250, 53)] {
            let area = Rect::new(0, 0, width, height);
            let panel_width = DashboardLayout::new(area, 0, 0, 0).selection.width - 4;
            let flags = legend(FLAGS, panel_width, 56, &theme);
            let help = help_lines(panel_width, &theme);
            for tip in include_str!("../cool_tips.txt").lines() {
                let lines = tip_lines(tip, panel_width, &theme);
                let layout = DashboardLayout::new(
                    area,
                    flags.len() as u16 + 2,
                    help.len() as u16 + 2,
                    lines.len() as u16,
                );
                assert_eq!(layout.tip.height as usize, lines.len());
                let displayed = lines
                    .iter()
                    .map(ToString::to_string)
                    .collect::<Vec<_>>()
                    .join(" ");
                assert_eq!(
                    displayed,
                    tip.split_whitespace().collect::<Vec<_>>().join(" ")
                );
                if !layout.help.is_empty() {
                    assert_eq!(layout.tip.y, layout.help.bottom() + 1);
                }
                if !layout.flags.is_empty() && !layout.help.is_empty() {
                    assert_eq!(layout.help.y, layout.flags.bottom());
                    assert_eq!(layout.flags.y, layout.selection.bottom());
                }
                assert_eq!(layout.selection.y, layout.system.bottom());
                if !layout.links.is_empty() {
                    assert_eq!(layout.links.y, layout.tip.bottom() + 2);
                }
            }
        }
    }

    #[test]
    fn dashboard_panels_fit_and_do_not_overlap_across_resizes() {
        for width in [0, 30, 89, 90, 100, 146, 147, 176, 194, 195, 200, 225, 250] {
            for height in [0, 10, 24, 25, 39, 40, 45, 48, 49, 50, 53] {
                let area = Rect::new(2, 3, width, height);
                let d = DashboardLayout::new(area, 12, 18, 3);
                let panels = [
                    d.commands,
                    d.system,
                    d.logo,
                    d.selection,
                    d.flags,
                    d.help,
                    d.tip,
                    d.links,
                ];
                for (i, panel) in panels.iter().enumerate() {
                    if panel.is_empty() {
                        continue;
                    }
                    assert_eq!(panel.intersection(area), *panel);
                    for other in panels.iter().skip(i + 1) {
                        assert!(!panel.intersects(*other));
                    }
                }
            }
        }
    }
}
