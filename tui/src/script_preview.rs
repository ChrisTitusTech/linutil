use crate::{floating_text::wrapped_text, theme::Theme};
use linutil_core::Command;
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, MouseEvent, MouseEventKind},
    prelude::*,
    widgets::{Block, Clear, Paragraph},
};
use tree_sitter_bash as bash;
use tree_sitter_highlight::{HighlightConfiguration, HighlightEvent, Highlighter};

pub struct ScriptPreview {
    name: String,
    filename: String,
    lines: Vec<Line<'static>>,
    // Visual rows after wrapping: (source line index, text).
    rows: Vec<(usize, Line<'static>)>,
    wrapped_width: Option<u16>,
    scroll: usize,
    viewport: Size,
}

impl ScriptPreview {
    pub fn new(command: &Command, name: &str, theme: &Theme) -> Self {
        let (filename, source) = match command {
            Command::LocalFile { file, .. } => (
                file.file_name()
                    .unwrap_or(file.as_os_str())
                    .to_string_lossy()
                    .into_owned(),
                std::fs::read_to_string(file)
                    .unwrap_or_else(|error| format!("<preview unavailable: {error}>")),
            ),
            Command::Raw(source) => ("inline command".to_string(), source.clone()),
            Command::None => (
                "No script".to_string(),
                "<no preview available>".to_string(),
            ),
        };
        // Expand tabs for consistent cell widths in both rendering and scrolling.
        let source = source.replace('\t', "    ");
        let lines = highlighted_lines(&source, theme).unwrap_or_else(|| {
            source
                .lines()
                .map(|line| Line::styled(line.to_owned(), theme.cmd_color()))
                .collect()
        });

        Self {
            name: name.to_owned(),
            filename,
            lines: if lines.is_empty() {
                vec![Line::default()]
            } else {
                lines
            },
            rows: Vec::new(),
            wrapped_width: None,
            scroll: 0,
            viewport: Size::default(),
        }
    }

    pub fn draw(&mut self, frame: &mut Frame, area: Rect, theme: &Theme) {
        let block = Block::bordered()
            .border_set(crate::dashboard::border_set())
            .title(" Script Preview ")
            .title_style(Style::default().fg(theme.tab_color()).bold())
            .border_style(Style::default().fg(theme.focused_color()))
            .style(Style::default().bg(theme.bg()).fg(theme.cmd_color()));
        let inner = block.inner(area);
        frame.render_widget(Clear, area);
        frame.render_widget(block, area);
        let content = inner.inner(Margin::new(1, 0));
        let body = if content.height >= 5 {
            let header = Rect::new(
                content.x.saturating_add(1),
                content.y + 1,
                content.width.saturating_sub(2),
                1,
            );
            let hint = "j/k ↑/↓ scroll · p/esc close";
            let hint_width = Line::from(hint).width() as u16;
            // Keep the filename readable when the full hint cannot fit.
            let show_hint = header.width >= hint_width.saturating_add(16);
            let filename_width = if show_hint {
                header.width.saturating_sub(hint_width + 2)
            } else {
                header.width
            };
            frame.render_widget(
                Paragraph::new(self.filename.as_str()).style(theme.tab_color()),
                Rect::new(header.x, header.y, filename_width, 1),
            );
            if show_hint {
                frame.render_widget(
                    Paragraph::new(hint).style(theme.muted()),
                    Rect::new(header.right() - hint_width, header.y, hint_width, 1),
                );
            }
            frame.render_widget(
                Paragraph::new("─".repeat(header.width as usize)).style(theme.unfocused_color()),
                Rect::new(header.x, header.y + 1, header.width, 1),
            );
            Rect::new(
                content.x,
                content.y + 3,
                content.width,
                content.height.saturating_sub(4),
            )
        } else {
            content
        };
        let number_width = self.lines.len().to_string().len().max(3) as u16;
        let gutter_width = number_width.saturating_add(2).min(body.width);
        let code = Rect::new(
            body.x.saturating_add(gutter_width),
            body.y,
            body.width.saturating_sub(gutter_width),
            body.height,
        );
        self.viewport = code.as_size();
        if self.wrapped_width != Some(code.width) {
            self.rewrap(code.width);
        }
        self.clamp_scroll();

        let visible = self.rows.len().min(self.scroll + body.height as usize);
        for (row, index) in (self.scroll..visible).enumerate() {
            let y = body.y + row as u16;
            let (line, text) = &self.rows[index];
            // Number only the first row of a wrapped line.
            if index == 0 || self.rows[index - 1].0 != *line {
                frame.render_widget(
                    Paragraph::new(format!(
                        "{:>width$}",
                        line + 1,
                        width = number_width as usize
                    ))
                    .style(theme.muted()),
                    Rect::new(body.x, y, number_width.min(body.width), 1),
                );
            }
            frame.render_widget(
                Paragraph::new(text.clone()),
                Rect::new(code.x, y, code.width, 1),
            );
        }
        if content.height >= 5 {
            let first = self.rows.get(self.scroll).map_or(0, |row| row.0);
            let end = visible
                .checked_sub(1)
                .and_then(|last| self.rows.get(last))
                .map_or(0, |row| row.0 + 1);
            frame.render_widget(
                Paragraph::new(format!(
                    "Lines {}-{end} of {} · {}",
                    first + 1,
                    self.lines.len(),
                    self.name
                ))
                .right_aligned()
                .style(theme.muted()),
                Rect::new(content.x, content.bottom() - 1, content.width, 1),
            );
        }
    }

    pub fn handle_key(&mut self, key: &KeyEvent) -> bool {
        match key.code {
            KeyCode::Char('p') | KeyCode::Esc => {
                return true;
            }
            KeyCode::Char('j') | KeyCode::Down => self.scroll = self.scroll.saturating_add(1),
            KeyCode::Char('k') | KeyCode::Up => self.scroll = self.scroll.saturating_sub(1),
            KeyCode::PageDown => self.scroll = self.scroll.saturating_add(10),
            KeyCode::PageUp => self.scroll = self.scroll.saturating_sub(10),
            KeyCode::Home => self.scroll = 0,
            KeyCode::End => self.scroll = self.rows.len(),
            _ => {}
        }
        self.clamp_scroll();
        false
    }

    pub fn handle_mouse(&mut self, event: &MouseEvent) {
        match event.kind {
            MouseEventKind::ScrollDown => self.scroll = self.scroll.saturating_add(1),
            MouseEventKind::ScrollUp => self.scroll = self.scroll.saturating_sub(1),
            _ => {}
        }
        self.clamp_scroll();
    }

    // Wrap every line to the code width, keeping the same source line at
    // the top across resizes.
    fn rewrap(&mut self, width: u16) {
        let top = self.rows.get(self.scroll).map_or(0, |row| row.0);
        self.rows = self
            .lines
            .iter()
            .enumerate()
            .flat_map(|(index, line)| {
                let wrapped = wrapped_text(&Text::from(line.clone()), width).lines;
                let wrapped = if wrapped.is_empty() {
                    vec![Line::default()]
                } else {
                    wrapped
                };
                wrapped.into_iter().map(move |row| (index, row))
            })
            .collect();
        self.wrapped_width = Some(width);
        self.scroll = self.rows.iter().position(|row| row.0 == top).unwrap_or(0);
    }

    fn clamp_scroll(&mut self) {
        self.scroll = self.scroll.min(
            self.rows
                .len()
                .saturating_sub(self.viewport.height.max(1) as usize),
        );
    }
}

fn highlighted_lines(source: &str, theme: &Theme) -> Option<Vec<Line<'static>>> {
    let styles = [
        ("function", theme.focused_color()),
        ("string", theme.green()),
        ("property", theme.tab_color()),
        ("comment", theme.muted()),
        ("embedded", theme.tab_color()),
        ("constant", theme.cyan()),
        ("keyword", theme.purple()),
        ("number", theme.tab_color()),
        ("operator", theme.cyan()),
    ];
    let mut configuration =
        HighlightConfiguration::new(bash::LANGUAGE.into(), "bash", bash::HIGHLIGHT_QUERY, "", "")
            .ok()?;
    configuration.configure(&styles.iter().map(|(name, _)| *name).collect::<Vec<_>>());
    let mut highlighter = Highlighter::new();
    let events = highlighter
        .highlight(&configuration, source.as_bytes(), None, |_| None)
        .ok()?;
    let mut lines = Vec::new();
    let mut spans = Vec::new();
    let mut stack = vec![Style::default().fg(theme.cmd_color())];
    for event in events {
        match event.ok()? {
            HighlightEvent::HighlightStart(highlight) => {
                stack.push(Style::default().fg(styles.get(highlight.0)?.1));
            }
            HighlightEvent::HighlightEnd => {
                stack.pop()?;
            }
            HighlightEvent::Source { start, end } => {
                let style = *stack.last()?;
                for part in source.get(start..end)?.split_inclusive('\n') {
                    if let Some(content) = part.strip_suffix('\n') {
                        spans.push(Span::styled(content.to_owned(), style));
                        lines.push(Line::from(std::mem::take(&mut spans)));
                    } else {
                        spans.push(Span::styled(part.to_owned(), style));
                    }
                }
            }
        }
    }
    if !spans.is_empty() {
        lines.push(Line::from(spans));
    }
    if source.starts_with("#!") {
        if let Some(line) = lines.first_mut() {
            for span in &mut line.spans {
                span.style = Style::default().fg(theme.purple());
            }
        }
    }
    Some(lines)
}

#[cfg(test)]
mod tests {
    use super::*;
    use ratatui::{backend::TestBackend, Terminal};

    fn draw(preview: &mut ScriptPreview, width: u16, height: u16) -> Buffer {
        let mut terminal = Terminal::new(TestBackend::new(width, height)).unwrap();
        terminal
            .draw(|frame| {
                let area = frame.area();
                preview.draw(frame, area, &Theme::Default);
            })
            .unwrap();
        terminal.backend().buffer().clone()
    }

    #[test]
    fn loads_real_script_and_shows_basename() {
        let file = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("../core/tabs/applications-setup/communication-apps/discord-setup.sh");
        let source = std::fs::read_to_string(&file).unwrap();
        let command = Command::LocalFile {
            executable: "/bin/sh".to_string(),
            args: Vec::new(),
            file,
        };
        let mut preview = ScriptPreview::new(&command, "Discord", &Theme::Default);
        assert_eq!(preview.filename, "discord-setup.sh");
        assert_eq!(preview.lines.len(), source.lines().count());
        assert!(preview
            .lines
            .iter()
            .any(|line| line.to_string().contains("checkEnv")));
        let buffer = draw(&mut preview, 90, 20);
        let content: String = buffer.content.iter().map(|cell| cell.symbol()).collect();
        assert!(content.contains("Script Preview"));
        assert!(content.contains("discord-setup.sh"));
        assert!(content.contains("Lines 1-"));
        assert!(!content.contains("communication-apps/"));
    }

    #[test]
    fn wraps_long_lines_and_numbers_only_their_first_row() {
        let source = (1..=50)
            .map(|index| format!("echo line {index}: {} END{index}", "x ".repeat(50)))
            .collect::<Vec<_>>()
            .join("\n");
        let mut preview = ScriptPreview::new(&Command::Raw(source), "Inline", &Theme::Default);
        let buffer = draw(&mut preview, 60, 15);
        assert!(preview.rows.len() > 50);
        assert!(preview
            .rows
            .iter()
            .all(|(_, row)| row.width() <= preview.viewport.width as usize));
        let rows: Vec<String> = buffer
            .content
            .chunks(60)
            .map(|row| row.iter().map(|cell| cell.symbol()).collect())
            .collect();
        assert!(rows.iter().any(|row| row.contains("  1  echo line 1:")));
        assert!(rows.iter().any(|row| row.contains("END1")));
        assert!(preview.rows.iter().filter(|row| row.0 == 0).count() > 1);
        let continuation = rows.iter().position(|row| row.contains("END1")).unwrap();
        assert!(!rows[continuation]
            .trim_start_matches(['│', ' '])
            .starts_with('1'));

        preview.handle_key(&KeyEvent::from(KeyCode::End));
        assert_eq!(
            preview.scroll + preview.viewport.height as usize,
            preview.rows.len()
        );
        let content: String = draw(&mut preview, 60, 15)
            .content
            .iter()
            .map(|cell| cell.symbol())
            .collect();
        assert!(content.contains("END50"));
        assert!(content.contains("of 50"));
        draw(&mut preview, 180, 60);
        assert_eq!(preview.rows.len(), 50);
        assert_eq!(preview.scroll, 0);
    }

    #[test]
    fn closes_on_preview_keys_and_handles_empty_or_missing_sources() {
        let mut preview =
            ScriptPreview::new(&Command::Raw(String::new()), "Empty", &Theme::Default);
        assert_eq!(preview.filename, "inline command");
        assert_eq!(preview.lines.len(), 1);
        for key in [KeyCode::Char('p'), KeyCode::Esc] {
            assert!(preview.handle_key(&KeyEvent::from(key)));
        }
        for key in [
            KeyCode::Char('P'),
            KeyCode::Char('q'),
            KeyCode::Enter,
            KeyCode::Char('h'),
            KeyCode::Left,
        ] {
            assert!(!preview.handle_key(&KeyEvent::from(key)));
        }
        for width in 0..8 {
            for height in 0..8 {
                draw(&mut preview, width, height);
            }
        }
        let preview = ScriptPreview::new(&Command::None, "Directory", &Theme::Default);
        assert_eq!(preview.lines[0].to_string(), "<no preview available>");
        let preview = ScriptPreview::new(
            &Command::LocalFile {
                executable: "/bin/sh".to_string(),
                args: Vec::new(),
                file: "/dev/null/missing.sh".into(),
            },
            "Missing",
            &Theme::Default,
        );
        assert_eq!(preview.filename, "missing.sh");
        assert!(preview.lines[0].to_string().contains("preview unavailable"));
    }

    #[test]
    fn highlighting_preserves_source_and_applies_dashboard_palette() {
        let source = "#!/bin/sh\n# comment\nif true; then\n  printf '%s' \"$VALUE\"\nfi\n";
        let lines = highlighted_lines(source, &Theme::Default).unwrap();
        assert_eq!(
            lines.iter().map(Line::to_string).collect::<Vec<_>>(),
            source.lines().collect::<Vec<_>>()
        );
        assert!(lines[0]
            .spans
            .iter()
            .all(|span| span.style.fg == Some(Theme::Default.purple())));
        assert!(lines[1]
            .spans
            .iter()
            .any(|span| span.content.contains("# comment")
                && span.style.fg == Some(Theme::Default.muted())));
        assert!(lines[3].spans.iter().any(|span| span.content == "printf"
            && span.style.fg == Some(Theme::Default.focused_color())));
    }
}
