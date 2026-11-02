use crate::theme::Theme;
use ratatui::{
    crossterm::event::{KeyEvent, MouseEvent},
    layout::{Constraint, Layout, Margin, Position, Rect},
    style::{Color, Modifier},
    Frame,
};

pub trait FloatContent {
    fn draw(&mut self, frame: &mut Frame, area: Rect, theme: &Theme);
    fn handle_key_event(&mut self, key: &KeyEvent) -> bool;
    fn handle_mouse_event(&mut self, key: &MouseEvent) -> bool;
    fn is_finished(&self) -> bool;
    /// Whether a result has not been drawn yet. A command can end after its
    /// last output, which is what asks for a redraw, so this has to ask too.
    fn result_pending(&self) -> bool {
        false
    }
}

pub struct Float<Content: FloatContent + ?Sized> {
    pub content: Box<Content>,
    size: FloatSize,
    horizontal_inset: u16,
}

enum FloatSize {
    Percentage(u16, u16),
    Capped(u16, u16),
}

impl<Content: FloatContent + ?Sized> Float<Content> {
    pub fn new(content: Box<Content>, width_percent: u16, height_percent: u16) -> Self {
        Self {
            content,
            size: FloatSize::Percentage(width_percent, height_percent),
            horizontal_inset: 0,
        }
    }

    pub fn capped(content: Box<Content>, max_width: u16, max_height: u16) -> Self {
        Self {
            content,
            size: FloatSize::Capped(max_width, max_height),
            horizontal_inset: 0,
        }
    }

    pub fn with_horizontal_inset(mut self, columns: u16) -> Self {
        self.horizontal_inset = columns;
        self
    }

    fn floating_window(&self, size: Rect) -> Rect {
        let (width_percent, height_percent) = match self.size {
            FloatSize::Capped(max_width, max_height) => {
                let width = max_width.min(size.width.saturating_sub(6));
                let height = max_height.min(size.height.saturating_sub(4));
                return Rect::new(
                    size.x + (size.width - width) / 2,
                    size.y + (size.height - height) / 2,
                    width,
                    height,
                );
            }
            FloatSize::Percentage(width, height) => (width, height),
        };
        let hor_float = Layout::horizontal([
            Constraint::Percentage((100 - width_percent) / 2),
            Constraint::Percentage(width_percent),
            Constraint::Percentage((100 - width_percent) / 2),
        ])
        .split(size)[1];

        let popup = Layout::vertical([
            Constraint::Percentage((100 - height_percent) / 2),
            Constraint::Percentage(height_percent),
            Constraint::Percentage((100 - height_percent) / 2),
        ])
        .split(hor_float)[1];
        popup.inner(Margin::new(self.horizontal_inset.min(popup.width / 2), 0))
    }

    pub fn draw(&mut self, frame: &mut Frame, parent_area: Rect, theme: &Theme) {
        self.draw_with_undimmed_areas(frame, parent_area, theme, &[]);
    }

    pub fn draw_with_undimmed_areas(
        &mut self,
        frame: &mut Frame,
        parent_area: Rect,
        theme: &Theme,
        undimmed: &[Rect],
    ) {
        let popup_area = self.floating_window(parent_area);
        let buffer = frame.buffer_mut();
        let area = buffer.area;
        for y in area.y..area.bottom() {
            for x in area.x..area.right() {
                if !undimmed
                    .iter()
                    .any(|rect| rect.contains(Position::new(x, y)))
                {
                    dim_cell(&mut buffer[(x, y)], theme);
                }
            }
        }
        self.content.draw(frame, popup_area, theme);
    }

    pub fn handle_mouse_event(&mut self, event: &MouseEvent) {
        self.content.handle_mouse_event(event);
    }

    // Returns true if the floating window is finished.
    pub fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        self.content.handle_key_event(key)
    }
}

pub(crate) fn dim_cell(cell: &mut ratatui::buffer::Cell, theme: &Theme) {
    cell.fg = dim_color(cell.fg, theme.cmd_color(), *theme);
    cell.modifier.remove(Modifier::BOLD | Modifier::UNDERLINED);
}

fn dim_color(color: Color, reset: Color, theme: Theme) -> Color {
    let color = if color == Color::Reset { reset } else { color };
    let (r, g, b) = match color {
        Color::Rgb(r, g, b) => (r, g, b),
        Color::Indexed(index @ 16..=231) => {
            let index = index - 16;
            let channel = |value| if value == 0 { 0 } else { 55 + 40 * value };
            (
                channel(index / 36),
                channel(index / 6 % 6),
                channel(index % 6),
            )
        }
        Color::Indexed(index @ 232..=255) => {
            let value = 8 + 10 * (index - 232);
            (value, value, value)
        }
        color => {
            let index = match color {
                Color::Black => 0,
                Color::Red => 1,
                Color::Green => 2,
                Color::Yellow => 3,
                Color::Blue => 4,
                Color::Magenta => 5,
                Color::Cyan => 6,
                Color::Gray => 7,
                Color::DarkGray => 8,
                Color::LightRed => 9,
                Color::LightGreen => 10,
                Color::LightYellow => 11,
                Color::LightBlue => 12,
                Color::LightMagenta => 13,
                Color::LightCyan => 14,
                Color::White => 15,
                Color::Indexed(index) => index as usize,
                _ => 0,
            };
            const ANSI: [(u8, u8, u8); 16] = [
                (0, 0, 0),
                (128, 0, 0),
                (0, 128, 0),
                (128, 128, 0),
                (0, 0, 128),
                (128, 0, 128),
                (0, 128, 128),
                (192, 192, 192),
                (128, 128, 128),
                (255, 0, 0),
                (0, 255, 0),
                (255, 255, 0),
                (0, 0, 255),
                (255, 0, 255),
                (0, 255, 255),
                (255, 255, 255),
            ];
            ANSI[index]
        }
    };
    let gray = ((0.2126 * r as f64 + 0.7152 * g as f64 + 0.0722 * b as f64) * 0.35).round() as u8;
    if matches!(color, Color::Rgb(..)) && theme != Theme::Compatible {
        match theme.bg() {
            // Fade towards the background: a fixed gray can be as bright as a
            // lighter background and vanish.
            Color::Rgb(bg_r, bg_g, bg_b) if theme != Theme::Default => {
                let fade = |color: u8, bg: u8| {
                    (f64::from(bg) + (f64::from(color) - f64::from(bg)) * 0.35).round() as u8
                };
                Color::Rgb(fade(r, bg_r), fade(g, bg_g), fade(b, bg_b))
            }
            _ => Color::Rgb(gray, gray, gray),
        }
    } else if (r, g, b) == (0, 0, 0) {
        Color::Black
    } else {
        // With 16 colours, anything darker would be black, and borders
        // would vanish behind a popup while their text stayed visible.
        Color::DarkGray
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ratatui::{backend::TestBackend, style::Style, widgets::Paragraph, Terminal};

    struct SampleContent;

    impl FloatContent for SampleContent {
        fn draw(&mut self, frame: &mut Frame, area: Rect, _theme: &Theme) {
            frame.render_widget(Paragraph::new("popup").style(Color::Green), area);
        }
        fn handle_key_event(&mut self, _key: &KeyEvent) -> bool {
            false
        }
        fn handle_mouse_event(&mut self, _event: &MouseEvent) -> bool {
            false
        }
        fn is_finished(&self) -> bool {
            true
        }
    }

    #[test]
    fn command_inset_removes_six_columns_without_changing_height() {
        let original = Float::new(Box::new(SampleContent), 95, 95);
        let narrowed = Float::new(Box::new(SampleContent), 95, 95).with_horizontal_inset(3);
        for width in [4, 30, 90, 198, 250] {
            let area = Rect::new(0, 0, width, 45);
            let before = original.floating_window(area);
            let after = narrowed.floating_window(area);
            let inset = 3.min(before.width / 2);
            assert_eq!(after.width, before.width - 2 * inset);
            assert_eq!(after.x, before.x + inset);
            assert_eq!(after.y, before.y);
            assert_eq!(after.height, before.height);
        }
    }

    #[test]
    fn capped_geometry_centers_in_parent_and_handles_tiny_areas() {
        let float = Float::capped(Box::new(SampleContent), 94, 44);
        assert_eq!(
            float.floating_window(Rect::new(10, 20, 198, 53)),
            Rect::new(62, 24, 94, 44)
        );
        assert_eq!(
            float.floating_window(Rect::new(0, 0, 90, 40)),
            Rect::new(3, 2, 84, 36)
        );
        for width in 0..8 {
            for height in 0..8 {
                let area = float.floating_window(Rect::new(0, 0, width, height));
                assert!(area.right() <= width && area.bottom() <= height);
            }
        }
    }

    #[test]
    fn all_floats_dim_background_and_preserve_exempt_areas_and_popup_colors() {
        for capped in [false, true] {
            let mut float = if capped {
                Float::capped(Box::new(SampleContent), 20, 8)
            } else {
                Float::new(Box::new(SampleContent), 50, 50)
            };
            let mut terminal = Terminal::new(TestBackend::new(50, 20)).unwrap();
            terminal
                .draw(|frame| {
                    let area = frame.area();
                    frame.render_widget(
                        Paragraph::new("background").style(
                            Style::default()
                                .fg(Color::Rgb(100, 150, 200))
                                .bg(Color::Rgb(20, 20, 20))
                                .add_modifier(Modifier::BOLD | Modifier::UNDERLINED),
                        ),
                        area,
                    );
                    float.draw_with_undimmed_areas(
                        frame,
                        area,
                        &Theme::Default,
                        &[Rect::new(1, 0, 1, 1)],
                    );
                })
                .unwrap();
            let buffer = terminal.backend().buffer();
            let cell = &buffer[(0, 0)];
            assert_eq!(cell.fg, Color::Rgb(50, 50, 50));
            assert_eq!(cell.bg, Color::Rgb(20, 20, 20));
            assert!(!cell
                .modifier
                .intersects(Modifier::BOLD | Modifier::UNDERLINED));
            assert_eq!(buffer[(1, 0)].fg, Color::Rgb(100, 150, 200));
            assert!(buffer[(1, 0)].modifier.contains(Modifier::BOLD));
            let popup = float.floating_window(Rect::new(0, 0, 50, 20));
            assert_eq!(buffer[(popup.x, popup.y)].fg, Color::Green);
        }
    }

    #[test]
    fn compatible_dimming_never_emits_truecolor() {
        for color in [
            Color::Reset,
            Color::Red,
            Color::White,
            Color::Rgb(255, 255, 255),
            Color::Indexed(15),
            Color::Indexed(200),
            Color::Indexed(255),
        ] {
            assert!(matches!(
                dim_color(color, Color::White, Theme::Compatible),
                Color::Black | Color::DarkGray
            ));
        }
    }

    #[test]
    fn compatible_dimming_keeps_dark_colours_visible() {
        for color in [Color::Blue, Color::DarkGray, Color::Indexed(17)] {
            assert_eq!(
                dim_color(color, Color::White, Theme::Compatible),
                Color::DarkGray,
                "{color:?}"
            );
        }
        assert_eq!(
            dim_color(Color::Black, Color::White, Theme::Compatible),
            Color::Black
        );
        assert_eq!(
            dim_color(Color::Reset, Color::Black, Theme::Compatible),
            Color::Black
        );
    }
}
