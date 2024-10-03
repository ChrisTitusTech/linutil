use std::borrow::Cow;

use ratatui::{
    style::{Style, Stylize},
    text::{Line, Span},
};

pub struct Shortcut {
    pub key_sequences: Vec<Span<'static>>,
    pub desc: &'static str,
}

fn add_spacing(list: Vec<Vec<Span>>) -> Line {
    list.into_iter()
        .flat_map(|mut s| {
            s.push(Span::default().content("    "));
            s
        })
        .collect()
}

pub fn span_vec_len(span_vec: &[Span]) -> usize {
    span_vec.iter().rfold(0, |init, s| init + s.width())
}

pub fn create_shortcut_list(
    shortcuts: impl IntoIterator<Item = Shortcut>,
    render_width: u16,
) -> Box<[Line<'static>]> {
    let hints = shortcuts.into_iter().collect::<Box<[Shortcut]>>();

    let mut shortcut_spans: Vec<Vec<Span<'static>>> = hints.iter().map(|h| h.to_spans()).collect();

    let mut lines: Vec<Line<'static>> = vec![];

    loop {
        let split_idx = shortcut_spans
            .iter()
            .scan(0usize, |total_len, s| {
                // take at least one so that we guarantee that we drain the list
                // otherwise, this might lock up if there's a shortcut that exceeds the window width
                if *total_len == 0 {
                    *total_len += span_vec_len(s) + 4;
                    Some(())
                } else {
                    *total_len += span_vec_len(s);
                    if *total_len > render_width as usize {
                        None
                    } else {
                        *total_len += 4;
                        Some(())
                    }
                }
            })
            .count();

        let rest = shortcut_spans.split_off(split_idx);
        lines.push(add_spacing(shortcut_spans));

        if rest.is_empty() {
            break;
        } else {
            shortcut_spans = rest;
        }
    }

    lines.into_boxed_slice()
}

impl Shortcut {
    pub fn new<const N: usize>(desc: &'static str, key_sequences: [&'static str; N]) -> Self {
        Self {
            key_sequences: key_sequences
                .iter()
                .map(|s| Span::styled(Cow::<'static, str>::Borrowed(s), Style::default().bold()))
                .collect(),
            desc,
        }
    }

    fn to_spans(&self) -> Vec<Span<'static>> {
        let mut ret: Vec<_> = self
            .key_sequences
            .iter()
            .flat_map(|seq| {
                [
                    Span::default().content("["),
                    seq.clone(),
                    Span::default().content("] "),
                ]
            })
            .collect();
        ret.push(Span::styled(self.desc, Style::default().italic()));
        ret
    }
}
