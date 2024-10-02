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
    let shortcut_spans: Vec<Vec<Span<'static>>> = shortcuts
        .into_iter()
        .map(|h| h.to_spans())
        .collect();

    let max_shortcut_width = shortcut_spans
        .iter()
        .map(|s| span_vec_len(s))
        .max()
        .unwrap_or(0);

    let columns = (render_width as usize / (max_shortcut_width + 4)).max(1);
    let rows = (shortcut_spans.len() + columns - 1) / columns;

    let mut lines: Vec<Line<'static>> = Vec::new();

    for row in 0..rows {
        let mut row_spans = Vec::new();
        for col in 0..columns {
            let index = row * columns + col;
            if index < shortcut_spans.len() {
                let mut span = shortcut_spans[index].clone();
                let padding = max_shortcut_width - span_vec_len(&span);
                span.push(Span::raw(" ".repeat(padding)));
                row_spans.push(span);
            }
        }
        lines.push(add_spacing(row_spans));
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
