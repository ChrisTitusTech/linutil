use crate::theme::Theme;
use image::{imageops::FilterType, RgbaImage};
use ratatui::{prelude::*, widgets::Paragraph};

const LOGO_BLACK_CUTOFF: u8 = 48;

/// A fitted text logo. Rendering stays in the terminal buffer so its colors and
/// background behave like the rest of the dashboard, without protocol queries.
pub struct Logo {
    rgba: RgbaImage,
    cached_key: Option<(u16, u16, Color)>,
    cached_lines: Vec<Line<'static>>,
}

impl Logo {
    pub fn load() -> Option<Self> {
        let rgba = image::load_from_memory(include_bytes!("../assets/ctt_logo.png"))
            .ok()?
            .to_rgba8();
        Some(Self {
            rgba,
            cached_key: None,
            cached_lines: Vec::new(),
        })
    }

    pub fn draw(&mut self, frame: &mut Frame, area: Rect, theme: &Theme) {
        let area = area.intersection(frame.area());
        if area.is_empty() {
            return;
        }
        let (width, height) = self.draw_size(area.width, area.height.saturating_sub(1));
        if width > 0 && height > 0 {
            let key = (width, height, theme.bg());
            if self.cached_key != Some(key) {
                self.cached_lines = if let Color::Rgb(r, g, b) = theme.bg() {
                    self.sextant_lines(width, height, [r, g, b])
                } else {
                    self.ascii_lines(width, height, theme)
                };
                self.cached_key = Some(key);
            }
            let image_area = Rect::new(
                area.x + (area.width - width) / 2,
                area.y + area.height - height - 1,
                width,
                height,
            );
            frame.render_widget(
                Paragraph::new(Text::from(self.cached_lines.clone())),
                image_area,
            );
        }
        let caption = format!("Linutil v{}", env!("CARGO_PKG_VERSION"));
        let caption_area = if width as usize >= Line::from(caption.as_str()).width() {
            Rect::new(
                area.x + (area.width - width) / 2,
                area.bottom() - 1,
                width,
                1,
            )
        } else {
            Rect::new(area.x, area.bottom() - 1, area.width, 1)
        };
        frame.render_widget(
            Paragraph::new(Line::styled(
                caption,
                Style::default().fg(theme.tab_color()).bg(theme.bg()).bold(),
            ))
            .alignment(Alignment::Center),
            caption_area,
        );
    }

    // Terminal cells are approximately 8 by 16 pixels. Fit the complete logo
    // above the version caption, keeping its aspect ratio at all sizes.
    fn draw_size(&self, width: u16, max_height: u16) -> (u16, u16) {
        if width == 0 || max_height == 0 {
            return (0, 0);
        }
        let image_width = u64::from(self.rgba.width());
        let image_height = u64::from(self.rgba.height());
        let height = (image_height * u64::from(width)).div_ceil(image_width * 2);
        if height <= u64::from(max_height) {
            (width, height.max(1) as u16)
        } else {
            let fitted_width = (image_width * u64::from(max_height) * 2).div_ceil(image_height);
            (fitted_width.clamp(1, u64::from(width)) as u16, max_height)
        }
    }

    fn ascii_lines(&self, width: u16, height: u16, theme: &Theme) -> Vec<Line<'static>> {
        let image = image::imageops::resize(
            &self.rgba,
            u32::from(width),
            u32::from(height),
            FilterType::Triangle,
        );
        (0..height)
            .map(|y| {
                Line::from(
                    (0..width)
                        .map(|x| {
                            let pixel = image.get_pixel(u32::from(x), u32::from(y)).0;
                            let visible = pixel[3] >= 10
                                && pixel[..3].iter().copied().max().unwrap_or(0)
                                    >= LOGO_BLACK_CUTOFF;
                            let color = if pixel[2] > pixel[0].saturating_add(20) {
                                theme.focused_color()
                            } else {
                                theme.cmd_color()
                            };
                            Span::styled(
                                if visible { "#" } else { " " },
                                Style::default().fg(color).bg(theme.bg()),
                            )
                        })
                        .collect::<Vec<_>>(),
                )
            })
            .collect()
    }

    fn sextant_lines(&self, width: u16, height: u16, bg: [u8; 3]) -> Vec<Line<'static>> {
        let mut source = self.rgba.clone();
        for pixel in source.pixels_mut() {
            let peak = pixel.0[..3].iter().copied().max().unwrap_or(0);
            if peak <= 36 {
                pixel.0[3] = 0;
            } else if peak < 68 {
                pixel.0[3] = (u16::from(pixel.0[3]) * u16::from(peak - 36) / 32) as u8;
            }
        }
        // The approved study fits the two wings independently. The source is
        // the same embedded asset; these crops remove its outer black margins.
        let left = image::imageops::crop_imm(&source, 35, 25, 357, 838).to_image();
        let right = image::imageops::crop_imm(&source, 430, 25, 357, 838).to_image();
        let left = image::imageops::resize(
            &left,
            u32::from(width),
            u32::from(height) * 3,
            FilterType::CatmullRom,
        );
        let right = image::imageops::resize(
            &right,
            u32::from(width),
            u32::from(height) * 3,
            FilterType::CatmullRom,
        );
        let sample = |x: u16, y: u16| -> [[u8; 3]; 6] {
            std::array::from_fn(|i| {
                let sub_x = u32::from(x) * 2 + (i % 2) as u32;
                let sub_y = u32::from(y) * 3 + (i / 2) as u32;
                let pixel = if sub_x < u32::from(width) {
                    left.get_pixel(sub_x, sub_y)
                } else {
                    right.get_pixel(sub_x - u32::from(width), sub_y)
                };
                std::array::from_fn(|channel| {
                    let alpha = u32::from(pixel.0[3]);
                    ((u32::from(pixel.0[channel]) * alpha
                        + u32::from(bg[channel]) * (255 - alpha)
                        + 127)
                        / 255) as u8
                })
            })
        };
        (0..height)
            .map(|y| {
                let mut row = vec![Span::raw(" "); usize::from(width)];
                for x in 0..width / 2 {
                    let mirror_x = width - 1 - x;
                    let points = sample(x, y);
                    let (mut mask, mut foreground, mut background) = best_partition(&points, bg);
                    let carve = width.is_multiple_of(2) && x == width / 2 - 1 && y + 2 < height;
                    if carve {
                        mask &= 0b010101;
                        foreground = mean(&points, mask, true, bg);
                        background = bg;
                    }
                    row[usize::from(x)] = sextant_span(mask, foreground, background);
                    let mirror_mask = ((mask & 0b010101) << 1) | ((mask & 0b101010) >> 1);
                    let mirror_points = sample(mirror_x, y);
                    let mirror_fg = mean(&mirror_points, mirror_mask, true, bg);
                    let mirror_bg = if carve || mirror_mask == 0 || mirror_mask == 63 {
                        bg
                    } else {
                        mean(&mirror_points, mirror_mask, false, bg)
                    };
                    row[usize::from(mirror_x)] = sextant_span(mirror_mask, mirror_fg, mirror_bg);
                }
                if !width.is_multiple_of(2) {
                    let x = width / 2;
                    let (mut mask, foreground, background) = best_partition(&sample(x, y), bg);
                    if y + 2 < height {
                        row[usize::from(x)] = sextant_span(0, bg, bg);
                    } else {
                        for bit in (0..6).step_by(2) {
                            if mask & (3 << bit) != 0 {
                                mask |= 3 << bit;
                            }
                        }
                        row[usize::from(x)] = sextant_span(mask, foreground, background);
                    }
                }
                Line::from(row)
            })
            .collect()
    }
}

fn mean(points: &[[u8; 3]; 6], mask: u8, selected: bool, bg: [u8; 3]) -> [u8; 3] {
    let count = (0..6)
        .filter(|i| (mask & (1 << i) != 0) == selected)
        .count() as u32;
    if count == 0 {
        return bg;
    }
    std::array::from_fn(|channel| {
        let total: u32 = points
            .iter()
            .enumerate()
            .filter(|(i, _)| (mask & (1 << i) != 0) == selected)
            .map(|(_, point)| u32::from(point[channel]))
            .sum();
        ((total + count / 2) / count) as u8
    })
}

fn best_partition(points: &[[u8; 3]; 6], bg: [u8; 3]) -> (u8, [u8; 3], [u8; 3]) {
    let low_contrast = (0..3).all(|channel| {
        let min = points.iter().map(|p| p[channel]).min().unwrap_or(0);
        let max = points.iter().map(|p| p[channel]).max().unwrap_or(0);
        max - min <= 18
    });
    if low_contrast {
        let average = mean(points, 63, true, bg);
        if average.iter().zip(bg).all(|(a, b)| a.abs_diff(b) <= 3) {
            return (0, bg, bg);
        }
        return (63, average, bg);
    }
    let mut best = (u64::MAX, 0, bg, bg);
    for mask in 1..32 {
        let foreground = mean(points, mask, true, bg);
        let background = mean(points, mask, false, bg);
        let error = points
            .iter()
            .enumerate()
            .map(|(i, point)| {
                let color = if mask & (1 << i) != 0 {
                    foreground
                } else {
                    background
                };
                point
                    .iter()
                    .zip(color)
                    .map(|(a, b)| i64::from(*a).abs_diff(i64::from(b)).pow(2))
                    .sum::<u64>()
            })
            .sum();
        if error < best.0 {
            best = (error, mask, foreground, background);
        }
    }
    let (_, mut mask, mut foreground, mut background) = best;
    if background.iter().map(|c| u16::from(*c)).sum::<u16>()
        > foreground.iter().map(|c| u16::from(*c)).sum::<u16>()
    {
        mask = !mask & 63;
        std::mem::swap(&mut foreground, &mut background);
    }
    (mask, foreground, background)
}

fn sextant_span(mask: u8, foreground: [u8; 3], background: [u8; 3]) -> Span<'static> {
    let symbol = match mask {
        0 => ' ',
        21 => '▌',
        42 => '▐',
        63 => '█',
        _ => char::from_u32(
            0x1fb00 + u32::from(mask - 1 - u8::from(mask > 21) - u8::from(mask > 42)),
        )
        .unwrap_or(' '),
    };
    Span::styled(
        symbol.to_string(),
        Style::default()
            .fg(Color::Rgb(foreground[0], foreground[1], foreground[2]))
            .bg(Color::Rgb(background[0], background[1], background[2])),
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use ratatui::{backend::TestBackend, Terminal};

    #[test]
    fn fits_odd_even_and_tiny_areas_without_overwriting_neighbors() {
        let mut logo = Logo::load().unwrap();
        for (width, height) in [(29, 11), (28, 10), (3, 2), (1, 1), (0, 0)] {
            let mut terminal = Terminal::new(TestBackend::new(40, 16)).unwrap();
            let area = Rect::new(2, 2, width, height);
            terminal
                .draw(|frame| logo.draw(frame, area, &Theme::Compatible))
                .unwrap();
            let buffer = terminal.backend().buffer();
            for y in 0..16 {
                for x in 0..40 {
                    if !area.contains(Position::new(x, y)) {
                        assert_eq!(buffer[(x, y)].symbol(), " ");
                    }
                }
            }
            if width > 0 && height > 1 {
                assert!(logo
                    .cached_lines
                    .iter()
                    .all(|line| line.width() <= usize::from(width)));
            }
        }
    }

    #[test]
    fn logo_blends_into_the_theme_background() {
        let logo = Logo::load().unwrap();
        let lines = logo.sextant_lines(28, 10, [0x2e, 0x34, 0x40]);
        let spans = || lines.iter().flat_map(|line| &line.spans);
        assert!(spans().all(|span| span.style.bg != Some(Color::Rgb(0x16, 0x16, 0x16))));
        assert!(spans().any(|span| span.style.bg == Some(Color::Rgb(0x2e, 0x34, 0x40))));
    }

    #[test]
    fn sextants_have_mirrored_center_channel() {
        let logo = Logo::load().unwrap();
        for width in [27, 28] {
            let lines = logo.sextant_lines(width, 10, [0x16, 0x16, 0x16]);
            assert_eq!(lines.len(), 10);
            assert!(lines.iter().all(|line| line.width() == usize::from(width)));
            if width % 2 == 1 {
                assert!(lines[..8]
                    .iter()
                    .all(|line| line.spans[usize::from(width / 2)].content == " "));
            }
        }
    }
}
