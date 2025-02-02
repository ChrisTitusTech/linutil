use ratatui::{
    style::{Style, Stylize},
    text::{Line, Span},
};
use std::borrow::Cow;

pub struct Shortcut {
    key_sequences: Vec<Span<'static>>,
    desc: &'static str,
}

fn add_spacing(list: Vec<Vec<Span>>) -> Line {
    list.into_iter()
        .flat_map(|mut s| {
            s.push(Span::default().content("    "));
            s
        })
        .collect()
}

fn span_vec_len(span_vec: &[Span]) -> usize {
    span_vec.iter().rfold(0, |init, s| init + s.width())
}

pub fn create_shortcut_list(
    shortcuts: impl IntoIterator<Item = Shortcut>,
    render_width: u16,
) -> Box<[Line<'static>]> {
    let shortcut_spans: Vec<Vec<Span<'static>>> =
        shortcuts.into_iter().map(|h| h.to_spans()).collect();

    let max_shortcut_width = shortcut_spans
        .iter()
        .map(|s| span_vec_len(s))
        .max()
        .unwrap_or(0);

    let columns = (render_width as usize / (max_shortcut_width + 4)).max(1);
    let rows = shortcut_spans.len().div_ceil(columns);

    let mut lines: Vec<Line<'static>> = Vec::with_capacity(rows);

    for row in 0..rows {
        let row_spans: Vec<_> = (0..columns)
            .filter_map(|col| {
                let index = row * columns + col;
                shortcut_spans.get(index).map(|span| {
                    let padding = max_shortcut_width - span_vec_len(span);
                    let mut span_clone = span.clone();
                    span_clone.push(Span::raw(" ".repeat(padding)));
                    span_clone
                })
            })
            .collect();
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
        let description = Span::styled(self.desc, Style::default().italic());
        self.key_sequences
            .iter()
            .flat_map(|seq| [Span::raw("["), seq.clone(), Span::raw("] ")])
            .chain(std::iter::once(description))
            .collect()
    }
}

#[macro_export]
macro_rules! shortcuts {
    ($(($name:literal,[$($key:literal),+ $(,)?])),* $(,)?) => {
        vec![
            $(
                Shortcut::new($name, [$($key),*])
            ),*
        ].into_boxed_slice()
    };
}
