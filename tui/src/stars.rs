use crate::theme::{supports_truecolor, Theme};
use ratatui::{buffer::Buffer, layout::Rect, style::Color};
use std::time::{Duration, Instant};

const FRAME_INTERVAL: Duration = Duration::from_millis(70);
const TINY: [char; 8] = ['⠁', '⠂', '⠄', '⡀', '⠈', '⠐', '⠠', '⢀'];
const MEDIUM: [char; 3] = ['·', '∙', '•'];
const LARGE: [char; 2] = ['⋆', '✶'];
const TINTS: [(u8, u8, u8); 3] = [(174, 180, 210), (121, 124, 144), (255, 255, 255)];

struct Star {
    x: u16,
    y: u16,
    hash: u32,
    glyph: char,
    px: f64,
    py: f64,
}

pub struct Starfield {
    supported: bool,
    enabled: bool,
    started: Instant,
    last_frame: Instant,
    geometry: Option<(Rect, Rect)>,
    stars: Vec<Star>,
}

impl Starfield {
    pub fn new() -> Self {
        Self::for_terminal(
            &std::env::var("TERM").unwrap_or_default(),
            &std::env::var("COLORTERM").unwrap_or_default(),
            linux_console(),
        )
    }

    pub fn for_terminal(term: &str, colorterm: &str, console: bool) -> Self {
        let now = Instant::now();
        Self {
            supported: !basic_terminal(term, console) && supports_truecolor(term, colorterm),
            enabled: true,
            started: now,
            last_frame: now,
            geometry: None,
            stars: Vec::new(),
        }
    }

    pub fn toggle(&mut self) {
        if self.supported {
            self.enabled = !self.enabled;
        }
    }

    pub fn active(&self, theme: &Theme) -> bool {
        self.supported && self.enabled && *theme != Theme::Compatible
    }

    pub fn frame_due(&self, theme: &Theme) -> bool {
        self.active(theme) && !self.stars.is_empty() && self.last_frame.elapsed() >= FRAME_INTERVAL
    }

    pub fn draw(&mut self, buffer: &mut Buffer, area: Rect, logo: Rect, theme: &Theme) {
        if !self.active(theme) {
            return;
        }
        let Color::Rgb(r, g, b) = theme.bg() else {
            return;
        };
        self.draw_at(
            buffer,
            area,
            logo,
            (r, g, b),
            self.started.elapsed().as_secs_f64(),
        );
        self.last_frame = Instant::now();
    }

    fn draw_at(
        &mut self,
        buffer: &mut Buffer,
        area: Rect,
        logo: Rect,
        background: (u8, u8, u8),
        seconds: f64,
    ) {
        let area = area.intersection(buffer.area);
        if self.geometry != Some((area, logo)) {
            self.stars = place_stars(area, logo);
            self.geometry = Some((area, logo));
        }
        for star in &self.stars {
            let cell = &mut buffer[(star.x, star.y)];
            if cell.symbol() != " "
                || cell.bg != Color::Rgb(background.0, background.1, background.2)
            {
                continue;
            }
            let period = 4.0 + f64::from(star.hash % 31) / 10.0;
            let offset = f64::from((star.hash >> 5) % 997) / 997.0;
            let age = (seconds / period + offset).fract();
            let glow = (std::f64::consts::PI * age).sin().powi(6) * 0.98;
            if glow < 0.04 {
                continue;
            }
            let tint = TINTS[((star.hash >> 11) % 3) as usize];
            let blend =
                |a: u8, b: u8| (f64::from(a) + (f64::from(b) - f64::from(a)) * glow).round() as u8;
            cell.set_char(star.glyph).set_fg(Color::Rgb(
                blend(background.0, tint.0),
                blend(background.1, tint.1),
                blend(background.2, tint.2),
            ));
        }
    }
}

fn place_stars(area: Rect, logo: Rect) -> Vec<Star> {
    let mut candidates = Vec::new();
    for y in area.y..area.bottom() {
        for x in area.x..area.right() {
            if logo.contains((x, y).into()) {
                continue;
            }
            let x32 = u32::from(x);
            let y32 = u32::from(y);
            let mut h = (x32 + 101).wrapping_mul(0x9e3779b1)
                ^ (y32 + 313).wrapping_mul(0x85ebca6b)
                ^ (x32 * 37 + y32 * 97).wrapping_mul(0xc2b2ae35);
            h = (h ^ (h >> 16)).wrapping_mul(0x85ebca6b);
            h = (h ^ (h >> 13)).wrapping_mul(0xc2b2ae35);
            h ^= h >> 16;
            if h % 1000 >= 360 {
                continue;
            }
            let mut hash =
                (x32 + 503).wrapping_mul(0x7f4a7c15) ^ (y32 + 709).wrapping_mul(0x27d4eb2d) ^ h;
            hash = (hash ^ (hash >> 16)).wrapping_mul(0x045d9f3b);
            hash = (hash ^ (hash >> 16)).wrapping_mul(0x045d9f3b);
            hash ^= hash >> 16;
            let index = (hash & 7) as usize;
            let glyph = match (hash >> 3) % 20 {
                0..12 => TINY[index],
                12..17 => MEDIUM[((hash >> 8) % 3) as usize],
                _ => LARGE[((hash >> 8) % 2) as usize],
            };
            candidates.push((
                h,
                Star {
                    x,
                    y,
                    hash,
                    glyph,
                    px: f64::from(x) + (index >> 2) as f64 * 0.5,
                    py: f64::from(y) * 4.0 + (index & 3) as f64,
                },
            ));
        }
    }
    candidates.sort_by_key(|(priority, _)| *priority);
    let mut stars: Vec<Star> = Vec::new();
    for (_, candidate) in candidates {
        if !stars.iter().any(|other| {
            (candidate.px - other.px).abs() < 1.8 && (candidate.py - other.py).abs() < 2.6
        }) {
            stars.push(candidate);
        }
    }
    stars
}

/// A Linux virtual console or a terminal type with no Unicode or colour
/// guarantees: its font may lack braille and other symbols.
pub(crate) fn basic_terminal(term: &str, console: bool) -> bool {
    console || matches!(term, "" | "linux" | "dumb" | "vt100" | "ansi")
}

pub(crate) fn linux_console() -> bool {
    #[cfg(target_os = "linux")]
    for fd in [0, 1] {
        if let Ok(path) = std::fs::read_link(format!("/proc/self/fd/{fd}")) {
            let path = path.to_string_lossy();
            if path == "/dev/console"
                || path.strip_prefix("/dev/tty").is_some_and(|suffix| {
                    !suffix.is_empty() && suffix.bytes().all(|c| c.is_ascii_digit())
                })
            {
                return true;
            }
        }
    }
    false
}

#[cfg(test)]
mod tests {
    use super::*;
    use ratatui::style::Style;

    #[test]
    fn basic_terminals_are_the_console_and_limited_term_types() {
        assert!(basic_terminal("xterm-256color", true));
        for term in ["", "linux", "dumb", "vt100", "ansi"] {
            assert!(basic_terminal(term, false), "{term}");
        }
        assert!(!basic_terminal("xterm-256color", false));
        assert!(!basic_terminal("xterm-kitty", false));
    }

    #[test]
    fn console_and_limited_terminals_never_animate_even_after_toggle() {
        for (term, colorterm, console) in [
            ("linux", "truecolor", false),
            ("dumb", "truecolor", false),
            ("", "truecolor", false),
            ("vt100", "truecolor", false),
            ("xterm-256color", "", false),
            ("xterm-256color", "truecolor", true),
        ] {
            let mut stars = Starfield::for_terminal(term, colorterm, console);
            stars.toggle();
            assert!(!stars.active(&Theme::Default));
            assert!(!stars.frame_due(&Theme::Default));
            let mut buffer = Buffer::empty(Rect::new(0, 0, 100, 3));
            let before = buffer.clone();
            stars.draw(&mut buffer, before.area, Rect::default(), &Theme::Default);
            assert_eq!(buffer, before);
            assert!(stars.geometry.is_none());
        }
        let mut stars = Starfield::for_terminal("xterm-256color", "truecolor", false);
        assert!(stars.active(&Theme::Default));
        assert!(!stars.active(&Theme::Compatible));
        stars.stars = place_stars(Rect::new(80, 0, 100, 3), Rect::default());
        stars.last_frame = Instant::now() - FRAME_INTERVAL;
        assert!(stars.frame_due(&Theme::Default));
        assert!(!stars.frame_due(&Theme::Compatible));
        stars.toggle();
        assert!(!stars.active(&Theme::Default));
        assert!(!stars.frame_due(&Theme::Default));
    }

    #[test]
    fn animation_preserves_text_backgrounds_and_logo_and_handles_resizing() {
        let mut stars = Starfield::for_terminal("xterm-256color", "truecolor", false);
        for area in [
            Rect::new(0, 0, 198, 3),
            Rect::new(5, 2, 90, 3),
            Rect::default(),
        ] {
            let mut background = Buffer::empty(Rect::new(0, 0, 220, 8));
            background.set_style(background.area, Style::default().bg(Color::Rgb(22, 22, 22)));
            let logo = Rect::new(170, 0, 28, 8);
            let occupied = place_stars(area, logo).first().map(|s| (s.x, s.y));
            if let Some(pos) = occupied {
                background[pos].set_symbol("X");
            }
            let mut saw_stars = false;
            let mut saw_change = false;
            let mut previous = background.clone();
            for tick in 0..20 {
                let mut buffer = background.clone();
                stars.draw_at(
                    &mut buffer,
                    area,
                    logo,
                    (22, 22, 22),
                    f64::from(tick) * 0.35,
                );
                for y in buffer.area.y..buffer.area.bottom() {
                    for x in buffer.area.x..buffer.area.right() {
                        let cell = &buffer[(x, y)];
                        assert_eq!(cell.bg, background[(x, y)].bg);
                        if !area.contains((x, y).into())
                            || logo.contains((x, y).into())
                            || Some((x, y)) == occupied
                        {
                            assert_eq!(cell, &background[(x, y)]);
                        } else if cell.symbol() != " " {
                            saw_stars = true;
                        }
                    }
                }
                saw_change |= buffer != previous;
                previous = buffer;
            }
            if !area.is_empty() {
                assert!(saw_stars && saw_change);
            }
        }
    }
}
