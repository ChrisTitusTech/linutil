use ratatui::{
    layout::{Margin, Rect},
    style::{Style, Stylize},
    text::{Line, Span},
    widgets::{Block, Borders, Paragraph},
    Frame,
};

use crate::state::{AppState, Focus};

pub const SHORTCUT_LINES: usize = 2;

pub struct ShortcutList {
    pub scope_name: &'static str,
    pub hints: Vec<Shortcut>,
}

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
impl ShortcutList {
    pub fn draw(&self, frame: &mut Frame, area: Rect) {
        let block = Block::default()
            .title(self.scope_name)
            .borders(Borders::all());
        let inner_area = area.inner(Margin::new(1, 1));
        let shortcut_spans: Vec<Vec<Span>> = self.hints.iter().map(|h| h.to_spans()).collect();

        let mut lines: Vec<Line> = Vec::with_capacity(SHORTCUT_LINES);

        let shortcut_list = (0..SHORTCUT_LINES - 1).fold(shortcut_spans, |mut acc, _| {
            let split_idx = acc
                .iter()
                .scan(0_usize, |total_len, s| {
                    *total_len += span_vec_len(s);
                    if *total_len > inner_area.width as usize {
                        None
                    } else {
                        *total_len += 4;
                        Some(1)
                    }
                })
                .count();

            let new_shortcut_list = acc.split_off(split_idx);
            lines.push(add_spacing(acc));

            new_shortcut_list
        });
        lines.push(add_spacing(shortcut_list));

        let p = Paragraph::new(lines).block(block);
        frame.render_widget(p, area);
    }
}

impl Shortcut {
    pub fn new(key_sequences: Vec<&'static str>, desc: &'static str) -> Self {
        Self {
            key_sequences: key_sequences
                .iter()
                .map(|s| Span::styled(*s, Style::default().bold()))
                .collect(),
            desc,
        }
    }

    fn to_spans(&self) -> Vec<Span> {
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

fn get_list_item_shortcut(state: &AppState) -> Vec<Shortcut> {
    if state.selected_item_is_dir() {
        vec![Shortcut::new(
            vec!["l", "Right", "Enter"],
            "Go to selected dir",
        )]
    } else {
        vec![
            Shortcut::new(vec!["l", "Right", "Enter"], "Run selected command"),
            Shortcut::new(vec!["p"], "Enable preview"),
            Shortcut::new(vec!["d"], "Command Description"),
        ]
    }
}

pub fn draw_shortcuts(state: &AppState, frame: &mut Frame, area: Rect) {
    match state.focus {
        Focus::Search => ShortcutList {
            scope_name: "Search bar",
            hints: vec![Shortcut::new(vec!["Enter"], "Finish search")],
        },

        Focus::List => {
            let mut hints = Vec::new();
            hints.push(Shortcut::new(vec!["q", "CTRL-c"], "Exit linutil"));

            if state.at_root() {
                hints.push(Shortcut::new(vec!["h", "Left"], "Focus tab list"));
                hints.extend(get_list_item_shortcut(state));
            } else if state.selected_item_is_up_dir() {
                hints.push(Shortcut::new(
                    vec!["l", "Right", "Enter", "h", "Left"],
                    "Go to parent directory",
                ));
            } else {
                hints.push(Shortcut::new(vec!["h", "Left"], "Go to parent directory"));
                hints.extend(get_list_item_shortcut(state));
            }
            hints.push(Shortcut::new(vec!["k", "Up"], "Select item above"));
            hints.push(Shortcut::new(vec!["j", "Down"], "Select item below"));
            hints.push(Shortcut::new(vec!["t"], "Next theme"));
            hints.push(Shortcut::new(vec!["T"], "Previous theme"));
            if state.is_current_tab_multi_selectable() {
                hints.push(Shortcut::new(vec!["v"], "Toggle multi-selection mode"));
                hints.push(Shortcut::new(vec!["Space"], "Select multiple commands"));
            }
            hints.push(Shortcut::new(vec!["Tab"], "Next tab"));
            hints.push(Shortcut::new(vec!["Shift-Tab"], "Previous tab"));
            ShortcutList {
                scope_name: "Item list",
                hints,
            }
        }

        Focus::TabList => ShortcutList {
            scope_name: "Tab list",
            hints: vec![
                Shortcut::new(vec!["q", "CTRL-c"], "Exit linutil"),
                Shortcut::new(vec!["l", "Right", "Enter"], "Focus action list"),
                Shortcut::new(vec!["k", "Up"], "Select item above"),
                Shortcut::new(vec!["j", "Down"], "Select item below"),
                Shortcut::new(vec!["t"], "Next theme"),
                Shortcut::new(vec!["T"], "Previous theme"),
                Shortcut::new(vec!["Tab"], "Next tab"),
                Shortcut::new(vec!["Shift-Tab"], "Previous tab"),
            ],
        },

        Focus::FloatingWindow(ref float) => float.get_shortcut_list(),
    }
    .draw(frame, area);
}
