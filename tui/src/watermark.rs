//! A dim, fixed CTT logo in the blank space of the command list.
//!
//! The outline uses faint Braille dots, with partial edge coverage faded out. Only blank background
//! cells are used, so it can never hide or break up the text in front of it.

use crate::theme::Theme;
use ratatui::{buffer::Buffer, layout::Rect, style::Color};
use unicode_width::UnicodeWidthStr;

const OUTLINE_WIDTH: f64 = 1188.0;
const OUTLINE_HEIGHT: f64 = 1145.0;
/// The two wings and the U, as x, y pairs.
const OUTLINE: [&[u16]; 3] = [
    &[
        2, 0, 9, 0, 16, 3, 17, 5, 48, 20, 60, 28, 110, 53, 111, 55, 189, 95, 205, 105, 223, 113,
        239, 123, 257, 131, 258, 133, 315, 162, 316, 164, 340, 175, 354, 184, 449, 233, 450, 235,
        503, 262, 504, 264, 525, 274, 535, 281, 549, 287, 565, 301, 568, 309, 568, 808, 566, 811,
        561, 812, 554, 809, 531, 793, 518, 787, 493, 770, 489, 769, 482, 763, 467, 756, 436, 735,
        413, 723, 392, 708, 372, 698, 351, 683, 333, 665, 323, 647, 318, 629, 317, 383, 314, 377,
        307, 370, 296, 365, 295, 363, 64, 244, 40, 227, 26, 212, 10, 185, 4, 168, 0, 147, 0, 2,
    ],
    &[
        1179, 0, 1186, 0, 1188, 2, 1188, 147, 1180, 180, 1172, 197, 1162, 212, 1148, 227, 1124,
        244, 893, 363, 892, 365, 881, 370, 874, 377, 871, 383, 870, 629, 865, 647, 855, 665, 837,
        683, 816, 698, 796, 708, 775, 723, 752, 735, 721, 756, 706, 763, 699, 769, 695, 770, 670,
        787, 657, 793, 634, 809, 627, 812, 622, 811, 620, 808, 620, 309, 623, 301, 639, 287, 653,
        281, 654, 279, 684, 264, 685, 262, 699, 256, 700, 254, 770, 218, 771, 216, 783, 211, 797,
        202, 872, 164, 873, 162, 919, 139, 931, 131, 949, 123, 950, 121, 983, 105, 984, 103, 998,
        97, 999, 95, 1015, 88, 1016, 86, 1030, 80, 1031, 78, 1047, 71, 1048, 69, 1064, 62, 1065,
        60,
    ],
    &[
        25, 379, 23, 381, 23, 650, 25, 672, 35, 720, 44, 746, 60, 780, 67, 789, 78, 809, 102, 837,
        102, 839, 136, 873, 176, 903, 192, 911, 224, 932, 238, 938, 279, 964, 293, 970, 327, 992,
        339, 997, 363, 1013, 374, 1018, 378, 1022, 392, 1028, 426, 1050, 450, 1062, 477, 1080, 491,
        1086, 525, 1108, 537, 1113, 574, 1137, 591, 1145, 600, 1144, 614, 1137, 651, 1113, 663,
        1108, 697, 1086, 711, 1080, 738, 1062, 792, 1032, 796, 1028, 810, 1022, 814, 1018, 830,
        1010, 849, 997, 861, 992, 887, 975, 891, 974, 895, 970, 909, 964, 950, 938, 964, 932, 996,
        911, 1012, 903, 1034, 887, 1038, 882, 1052, 873, 1086, 839, 1086, 837, 1110, 809, 1134,
        768, 1134, 765, 1144, 746, 1153, 720, 1161, 685, 1165, 650, 1165, 381, 1163, 379, 1153,
        380, 1152, 382, 1054, 435, 1053, 437, 1031, 448, 976, 481, 977, 645, 973, 674, 970, 684,
        972, 683, 964, 697, 966, 698, 961, 707, 937, 739, 920, 754, 876, 781, 861, 788, 825, 810,
        809, 818, 772, 841, 760, 846, 723, 870, 709, 876, 675, 898, 654, 909, 622, 929, 594, 944,
        566, 929, 534, 909, 513, 898, 479, 876, 465, 870, 428, 846, 416, 841, 379, 818, 363, 810,
        327, 788, 312, 781, 268, 754, 251, 739, 227, 707, 222, 698, 224, 697, 216, 683, 218, 684,
        215, 674, 211, 645, 212, 481, 157, 448, 135, 437, 134, 435, 36, 382, 35, 380,
    ],
];
const TINT: [u8; 3] = [161, 167, 178];
const OPACITY: f64 = 0.05;
// Alacritty takes Braille from a font instead of drawing it itself. Its dots are larger and
// soft-edged, which makes the logo about twice as bright for the same color.
const FONT_BRAILLE_OPACITY: f64 = 0.025;
const MAX_WIDTH: u16 = 44;
const MIN_WIDTH: u16 = 14;
const LIST_SHARE: u16 = 50; // Percent of the list's width.
const DOT_BITS: [[u8; 4]; 2] = [[1, 2, 4, 64], [8, 16, 32, 128]];

#[derive(Clone, Copy, Debug, PartialEq)]
struct Glyph {
    symbol: char,
    strength: f64,
}

pub struct Watermark {
    opacity: f64,
    size: Option<(u16, u16)>,
    glyphs: Vec<Glyph>,
}

impl Watermark {
    pub fn new() -> Self {
        let term = std::env::var("TERM").unwrap_or_default();
        Self {
            opacity: opacity_for(&term, std::env::var_os("ALACRITTY_WINDOW_ID").is_some()),
            size: None,
            glyphs: Vec::new(),
        }
    }

    /// Size from `list` and center in `panel`, painting only within `clip`.
    /// Keeping the layout separate from clipping anchors the logo across preview mode.
    /// Text must already be drawn. Glyphs are only rebuilt when the size changes.
    pub fn draw(
        &mut self,
        buffer: &mut Buffer,
        panel: Rect,
        list: Rect,
        clip: Rect,
        theme: &Theme,
    ) {
        let background = theme.bg();
        let Color::Rgb(r, g, b) = background else {
            return;
        };
        let Some(stage) = stage(panel, list.intersection(buffer.area)) else {
            return;
        };
        if self.size != Some((stage.width, stage.height)) {
            self.glyphs = braille(stage.width, stage.height);
            self.size = Some((stage.width, stage.height));
        }
        let clip = clip.intersection(buffer.area);
        // Nord's lighter background needs a little more contrast to retain the faint outline.
        let opacity = self.opacity * if *theme == Theme::Nord { 1.4 } else { 1.0 };
        for y in stage.y..stage.bottom() {
            let mut occupied_until = buffer.area.x;
            // Scan from the row's start: a grapheme may begin outside the logo or clip.
            for x in buffer.area.x..stage.right() {
                let cell = &mut buffer[(x, y)];
                let covered = x < occupied_until;
                if !covered {
                    let width = u16::try_from(cell.symbol().width()).unwrap_or(u16::MAX);
                    occupied_until = x.saturating_add(width);
                }
                if covered || x < stage.x || !clip.contains((x, y).into()) {
                    continue;
                }
                let index =
                    usize::from(y - stage.y) * usize::from(stage.width) + usize::from(x - stage.x);
                let glyph = self.glyphs[index];
                if glyph.symbol != ' ' && cell.symbol() == " " && cell.bg == background {
                    cell.set_char(glyph.symbol)
                        .set_fg(tint([r, g, b], opacity * glyph.strength));
                }
            }
        }
    }
}

/// `TERM` is the reliable answer. The window variable only counts inside a multiplexer,
/// which replaces `TERM`: any other terminal started from Alacritty inherits it too.
fn opacity_for(term: &str, alacritty_window: bool) -> f64 {
    let multiplexer = term.starts_with("tmux") || term.starts_with("screen");
    if term.starts_with("alacritty") || (multiplexer && alacritty_window) {
        FONT_BRAILLE_OPACITY
    } else {
        OPACITY
    }
}

fn tint(background: [u8; 3], opacity: f64) -> Color {
    let mix = |index: usize| {
        let (front, back) = (f64::from(TINT[index]), f64::from(background[index]));
        (back + (front - back) * opacity).round() as u8
    };
    Color::Rgb(mix(0), mix(1), mix(2))
}

/// The logo's cells: centered in `panel` and kept inside `list`. Each cell is 2 by 4
/// dots, and the dots are taken as square.
fn stage(panel: Rect, list: Rect) -> Option<Rect> {
    let rows_for =
        |width: u16| (f64::from(width) * OUTLINE_HEIGHT / OUTLINE_WIDTH / 2.0).ceil() as u16;
    let mut width = (list.width.saturating_mul(LIST_SHARE) / 100).min(MAX_WIDTH);
    if rows_for(width) > list.height {
        width = (f64::from(list.height) * 2.0 * OUTLINE_WIDTH / OUTLINE_HEIGHT) as u16;
    }
    // A width with the panel's parity centers exactly.
    width = width.saturating_sub(panel.width.abs_diff(width) % 2);
    if width < MIN_WIDTH {
        return None;
    }
    let height = rows_for(width);
    let x = panel.x + (panel.width - width) / 2;
    let y = panel.y + (panel.height - height) / 2;
    Some(Rect::new(
        x,
        y.clamp(list.y, list.bottom() - height),
        width,
        height,
    ))
}

/// Sample four scanlines per dot and integrate horizontal coverage. Majority-covered
/// dots form the silhouette. Feather the inner two dots of the boundary so the fade
/// survives the very low opacity and terminal color rounding.
/// Braille has one foreground per cell, so average only the dots that are actually drawn.
/// This is deterministic and cached on resize: no random sparkle or animation.
fn braille(width: u16, height: u16) -> Vec<Glyph> {
    const SAMPLES: usize = 4;
    let (columns, rows) = (usize::from(width) * 2, usize::from(height) * 4);
    let scale = columns as f64 / OUTLINE_WIDTH;
    let top = (rows as f64 - OUTLINE_HEIGHT * scale) / 2.0;
    let cells = usize::from(width) * usize::from(height);
    let mut dots = vec![0u8; cells];
    let mut strengths = vec![0.0; cells];
    let mut coverage = vec![0.0_f64; columns * rows];
    for row in 0..rows {
        let coverage = &mut coverage[row * columns..(row + 1) * columns];
        for sample in 0..SAMPLES {
            let y = (row as f64 + (sample as f64 + 0.5) / SAMPLES as f64 - top) / scale;
            for part in OUTLINE {
                let mut crossings = crossings(part, y);
                crossings.sort_by(f64::total_cmp);
                let mut edges = crossings.into_iter();
                while let (Some(start), Some(stop)) = (edges.next(), edges.next()) {
                    let start = (start * scale).clamp(0.0, columns as f64);
                    let stop = (stop * scale).clamp(0.0, columns as f64);
                    for (column, covered) in coverage
                        .iter_mut()
                        .enumerate()
                        .take(stop.ceil() as usize)
                        .skip(start.floor() as usize)
                    {
                        let overlap = stop.min(column as f64 + 1.0) - start.max(column as f64);
                        *covered += overlap / SAMPLES as f64;
                    }
                }
            }
        }
    }
    for row in 0..rows {
        for column in 0..columns {
            let covered = coverage[row * columns + column];
            if covered < 0.5 {
                continue;
            }
            let cell = row / 4 * usize::from(width) + column / 2;
            dots[cell] |= DOT_BITS[column % 2][row % 4];
            // Distance to the nearest outside dot, including outside the stage.
            // A two-dot inward fade leaves the silhouette and its gaps intact.
            let mut distance = 2.5_f64;
            for dy in -2_isize..=2 {
                for dx in -2_isize..=2 {
                    let x = column as isize + dx;
                    let y = row as isize + dy;
                    let outside = x < 0
                        || y < 0
                        || x >= columns as isize
                        || y >= rows as isize
                        || coverage[y as usize * columns + x as usize] < 0.5;
                    if outside {
                        distance = distance.min((dx as f64).hypot(dy as f64));
                    }
                }
            }
            let feather = ((distance - 0.5) / 2.0).clamp(0.0, 1.0);
            strengths[cell] += covered.min(1.0) * feather;
        }
    }
    dots.into_iter()
        .zip(strengths)
        .map(|(dots, strength)| Glyph {
            symbol: if dots == 0 {
                ' '
            } else {
                char::from_u32(0x2800 + u32::from(dots)).unwrap_or(' ')
            },
            strength: if dots == 0 {
                0.0
            } else {
                strength / f64::from(dots.count_ones())
            },
        })
        .collect()
}

/// Where a loop of x, y pairs crosses the row at `y`.
fn crossings(part: &[u16], y: f64) -> Vec<f64> {
    let points: Vec<(f64, f64)> = part
        .iter()
        .step_by(2)
        .zip(part[1..].iter().step_by(2))
        .map(|(x, y)| (f64::from(*x), f64::from(*y)))
        .collect();
    (0..points.len())
        .filter_map(|index| {
            let (a, b) = (points[index], points[(index + 1) % points.len()]);
            ((a.1 <= y) != (b.1 <= y)).then(|| a.0 + (y - a.1) / (b.1 - a.1) * (b.0 - a.0))
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoothing_keeps_full_interior_and_fades_edges_without_flicker() {
        for width in [14, 33, 44] {
            let height = (f64::from(width) * OUTLINE_HEIGHT / OUTLINE_WIDTH / 2.0).ceil() as u16;
            let glyphs = braille(width, height);
            assert_eq!(glyphs, braille(width, height));
            if width == 44 {
                assert!(glyphs.iter().any(|g| g.strength == 1.0));
            }
            assert!(glyphs.iter().any(|g| g.strength > 0.0 && g.strength < 0.5));
            assert!(glyphs.iter().all(|g| (0.0..=1.0).contains(&g.strength)));
        }
    }

    #[test]
    fn smoothing_preserves_text_and_selection_backgrounds() {
        let area = Rect::new(0, 0, 100, 40);
        let theme = Theme::Default;
        let mut buffer = Buffer::empty(area);
        for cell in &mut buffer.content {
            cell.set_bg(theme.bg());
        }
        let mut watermark = Watermark::new();
        let original = buffer.clone();
        watermark.draw(&mut buffer, area, area, area, &theme);
        if !matches!(theme.bg(), Color::Rgb(..)) {
            assert_eq!(buffer, original);
            return;
        }
        let painted: Vec<_> = buffer
            .content
            .iter()
            .enumerate()
            .filter_map(|(i, cell)| (cell.symbol() != " ").then_some(i))
            .collect();
        assert!(painted.len() > 2);
        let text = painted[0];
        let selection = painted[1];
        buffer.content[text].set_char('X').set_fg(Color::Red);
        buffer.content[selection].set_char(' ').set_bg(Color::Blue);
        let before = buffer.clone();
        watermark.draw(&mut buffer, area, area, area, &theme);
        assert_eq!(buffer, before);
    }

    #[test]
    fn wide_grapheme_trailing_columns_never_emit_watermark_cells() {
        use ratatui::widgets::{Paragraph, Widget};

        let area = Rect::new(3, 2, 100, 40);
        let theme = Theme::Default;
        if !matches!(theme.bg(), Color::Rgb(..)) {
            return; // Exercise this rendering path with TERM/COLORTERM set to truecolor.
        }
        let mut blank = Buffer::empty(area);
        for cell in &mut blank.content {
            cell.set_bg(theme.bg());
        }
        let mut watermark = Watermark::new();
        let mut painted = blank.clone();
        watermark.draw(&mut painted, area, area, area, &theme);
        let (x, y) = (area.y..area.bottom())
            .flat_map(|y| (area.x + 1..area.right()).map(move |x| (x, y)))
            .find(|&position| painted[position].symbol() != " ")
            .expect("logo contains a painted cell");

        for text in ["⚠️", "界", "👩‍💻"] {
            let mut previous = blank.clone();
            previous[(x, y)].set_char('X');
            let mut next = blank.clone();
            Paragraph::new(text).render(Rect::new(x - 1, y, 2, 1), &mut next);
            assert_eq!(next[(x - 1, y)].symbol(), text);
            assert_eq!(next[(x, y)].symbol(), " ");
            let expected = previous
                .diff(&next)
                .into_iter()
                .filter(|&(cx, cy, _)| cy == y && (cx == x - 1 || cx == x))
                .map(|(cx, cy, cell)| (cx, cy, cell.clone()))
                .collect::<Vec<_>>();
            // The leading grapheme is outside the clip, but still covers its next column.
            watermark.draw(&mut next, area, area, Rect::new(x, y, 1, 1), &theme);
            assert_eq!(next[(x, y)].symbol(), " ");
            let emitted = previous
                .diff(&next)
                .into_iter()
                .filter(|&(cx, cy, _)| cy == y && (cx == x - 1 || cx == x))
                .map(|(cx, cy, cell)| (cx, cy, cell.clone()))
                .collect::<Vec<_>>();
            assert_eq!(emitted, expected, "watermark changed updates for {text}");
        }
    }

    fn dot_mirror(dots: u32) -> u32 {
        (dots & 0b0000_0111) << 3
            | (dots & 0b0011_1000) >> 3
            | (dots & 0b0100_0000) << 1
            | (dots & 0b1000_0000) >> 1
    }

    #[test]
    fn logo_is_mirrored_and_keeps_its_gaps() {
        let (width, height) = (33, 16);
        let glyphs = braille(width, height);
        let dots = |glyph: char| glyph as u32 - if glyph == ' ' { 32 } else { 0x2800 };
        let (mut different, mut total) = (0, 0);
        for row in glyphs.chunks(usize::from(width)) {
            for (left, right) in row.iter().zip(row.iter().rev()) {
                different += (dots(left.symbol) ^ dot_mirror(dots(right.symbol))).count_ones();
                total += dots(left.symbol).count_ones();
            }
        }
        // Tracing rounds each side a little differently.
        assert!(
            different * 100 < total * 2,
            "{different} of {total} dots differ"
        );
        // The gap between the wings runs down the middle of the upper half.
        let middle = usize::from(width) / 2;
        for row in glyphs.chunks(usize::from(width)).skip(6).take(4) {
            assert_eq!(row[middle].symbol, ' ');
        }
    }

    #[test]
    fn stage_is_centered_in_the_panel_and_stays_in_the_list() {
        for (width, height) in [(42, 22), (52, 33), (104, 47), (105, 47), (200, 80)] {
            let panel = Rect::new(3, 2, width, height);
            let list = Rect::new(panel.x + 2, panel.y + 4, width - 4, height - 6);
            let stage = stage(panel, list).unwrap();
            assert_eq!(list.intersection(stage), stage);
            assert_eq!(
                stage.x * 2 + stage.width,
                panel.x * 2 + panel.width,
                "horizontal center of {width}x{height}"
            );
            let middle = i32::from(stage.y * 2 + stage.height);
            let target = i32::from(panel.y * 2 + panel.height);
            assert!(
                (middle - target).abs() <= 1,
                "vertical center of {width}x{height}"
            );
            assert!(stage.width <= MAX_WIDTH);
        }
        // A list too short to center in still keeps the logo inside it.
        let (panel, list) = (Rect::new(0, 0, 64, 18), Rect::new(2, 4, 60, 12));
        let short = stage(panel, list).unwrap();
        assert_eq!(list.intersection(short), short);

        let panel = Rect::new(0, 0, 200, 40);
        assert_eq!(stage(panel, Rect::new(2, 4, 20, 30)), None);
        assert_eq!(stage(panel, Rect::new(2, 4, 196, 5)), None);
        // A preview's code viewport may collapse on a tiny terminal.
        for width in 0..MIN_WIDTH {
            let code = Rect::new(8, 4, width, 3);
            assert_eq!(stage(code, code), None);
        }
    }

    #[test]
    fn color_is_a_faint_blend_into_the_background() {
        assert_eq!(tint([22, 22, 22], OPACITY), Color::Rgb(29, 29, 30));
        assert_eq!(
            tint([22, 22, 22], FONT_BRAILLE_OPACITY),
            Color::Rgb(25, 26, 26)
        );
    }

    #[test]
    fn alacritty_gets_a_lower_opacity_wherever_it_runs() {
        assert_eq!(opacity_for("xterm-256color", false), OPACITY);
        assert_eq!(opacity_for("xterm-kitty", false), OPACITY);
        assert_eq!(opacity_for("xterm-ghostty", false), OPACITY);
        assert_eq!(opacity_for("alacritty", false), FONT_BRAILLE_OPACITY);
        assert_eq!(opacity_for("alacritty-direct", false), FONT_BRAILLE_OPACITY);
        assert_eq!(opacity_for("tmux-256color", true), FONT_BRAILLE_OPACITY);
        assert_eq!(opacity_for("screen-256color", true), FONT_BRAILLE_OPACITY);
        assert_eq!(opacity_for("tmux-256color", false), OPACITY);
        // Started from Alacritty, so the variable is inherited.
        assert_eq!(opacity_for("xterm-kitty", true), OPACITY);
        assert_eq!(opacity_for("xterm-ghostty", true), OPACITY);
    }
}
