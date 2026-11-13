use ratatui::buffer::Buffer;
use std::time::Duration;
use unicode_width::UnicodeWidthStr;

pub const DURATION: Duration = Duration::from_millis(1500);

/// Scramble the rendered interface until its original characters are revealed.
pub fn apply(buffer: &mut Buffer, elapsed: Duration) {
    if elapsed >= DURATION {
        return;
    }
    let progress = elapsed.as_secs_f32() / DURATION.as_secs_f32();
    const CIPHER: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%&*";
    let tick = (elapsed.as_millis() / 55) as u32;
    for (index, cell) in buffer.content.iter_mut().enumerate() {
        if cell.symbol().trim().is_empty() {
            continue;
        }
        let seed = hash(index as u32);
        let reveal_at = (seed % 1000) as f32 / 1000.0;
        if progress < reveal_at {
            // Preserve wide glyph geometry; scramble only single cells.
            if cell.symbol().width() == 1 {
                let glyph = CIPHER[hash(seed.wrapping_add(tick)) as usize % CIPHER.len()];
                cell.set_char(char::from(glyph));
            } else {
                cell.set_symbol(" ");
            }
        }
    }
}

fn hash(mut value: u32) -> u32 {
    value = (value ^ (value >> 16)).wrapping_mul(0x7feb352d);
    value = (value ^ (value >> 15)).wrapping_mul(0x846ca68b);
    value ^ (value >> 16)
}

#[cfg(test)]
mod tests {
    use super::*;
    use ratatui::{layout::Rect, style::Color};

    #[test]
    fn decrypt_finishes_with_the_exact_original_buffer() {
        let mut original = Buffer::empty(Rect::new(3, 2, 12, 4));
        original.set_string(3, 3, "Linutil 界", Color::Cyan);
        for elapsed in [DURATION, DURATION + Duration::from_secs(1)] {
            let mut buffer = original.clone();
            apply(&mut buffer, elapsed);
            assert_eq!(buffer, original);
        }
    }

    #[test]
    fn decrypt_changes_text_without_changing_its_style_or_area() {
        let mut original = Buffer::empty(Rect::new(0, 0, 30, 1));
        original.set_string(0, 0, "Linutil startup preview", Color::Cyan);
        let mut buffer = original.clone();
        apply(&mut buffer, Duration::from_millis(100));
        assert_ne!(buffer, original);
        assert_eq!(buffer.area, original.area);
        for (before, after) in original.content.iter().zip(&buffer.content) {
            assert_eq!(before.style(), after.style());
            if before.symbol() == " " {
                assert_eq!(after.symbol(), " ");
            }
        }
    }
}
