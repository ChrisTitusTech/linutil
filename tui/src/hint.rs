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
    pub key_sequenses: Vec<Span<'static>>,
    pub desc: &'static str,
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
        let mut shortcut_list: Vec<Vec<Span>> = self.hints.iter().map(|h| h.to_spans()).collect();

        let mut lines = vec![Line::default(); SHORTCUT_LINES];
        let mut idx = 0;

        while idx < SHORTCUT_LINES - 1 {
            let split_idx = shortcut_list
                .iter()
                .scan(0usize, |total_len, s| {
                    *total_len += span_vec_len(s);
                    if *total_len > inner_area.width as usize {
                        None
                    } else {
                        *total_len += 4;
                        Some(1)
                    }
                })
                .count();
            let new_shortcut_list = shortcut_list.split_off(split_idx);
            let line: Vec<_> = shortcut_list
                .into_iter()
                .flat_map(|mut s| {
                    s.push(Span::default().content("    "));
                    s
                })
                .collect();
            shortcut_list = new_shortcut_list;
            lines[idx] = line.into();
            idx += 1;
        }
        lines[idx] = shortcut_list
            .into_iter()
            .flat_map(|mut s| {
                s.push(Span::default().content("    "));
                s
            })
            .collect();

        let p = Paragraph::new(lines).block(block);
        frame.render_widget(p, area);
    }
}

impl Shortcut {
    pub fn new(key_sequences: Vec<&'static str>, desc: &'static str) -> Self {
        Self {
            key_sequenses: key_sequences
                .iter()
                .map(|s| Span::styled(*s, Style::default().bold()))
                .collect(),
            desc,
        }
    }

    fn to_spans(&self) -> Vec<Span> {
        let mut ret: Vec<_> = self
            .key_sequenses
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

fn get_list_item_shortcut(state: &AppState) -> Shortcut {
    if state.selected_item_is_dir() {
        Shortcut::new(vec!["l", "Right", "Enter"], "Go to selected dir")
    } else {
        Shortcut::new(vec!["l", "Right", "Enter"], "Run selected command")
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
                hints.push(Shortcut::new(vec!["h", "Left", "Tab"], "Focus tab list"));
                hints.push(get_list_item_shortcut(state));
            } else {
                if state.selected_item_is_up_dir() {
                    hints.push(Shortcut::new(
                        vec!["l", "Right", "Enter", "h", "Left"],
                        "Go to parrent directory",
                    ));
                } else {
                    hints.push(Shortcut::new(vec!["h", "Left"], "Go to parrent directory"));
                    hints.push(get_list_item_shortcut(state));
                    if state.selected_item_is_cmd() {
                        hints.push(Shortcut::new(vec!["p"], "Enable preview"));
                    }
                }
                hints.push(Shortcut::new(vec!["Tab"], "Focus tab list"));
            };
            hints.push(Shortcut::new(vec!["k", "Up"], "Select item above"));
            hints.push(Shortcut::new(vec!["j", "Down"], "Select item below"));
            hints.push(Shortcut::new(vec!["t"], "Next theme"));
            hints.push(Shortcut::new(vec!["T"], "Previous theme"));
            ShortcutList {
                scope_name: "Item list",
                hints,
            }
        }
        Focus::TabList => ShortcutList {
            scope_name: "Tab list",
            hints: vec![
                Shortcut::new(vec!["q", "CTRL-c"], "Exit linutil"),
                Shortcut::new(vec!["l", "Right", "Tab", "Enter"], "Focus action list"),
                Shortcut::new(vec!["k", "Up"], "Select item above"),
                Shortcut::new(vec!["j", "Down"], "Select item below"),
                Shortcut::new(vec!["t"], "Next theme"),
                Shortcut::new(vec!["T"], "Previous theme"),
            ],
        },
        Focus::FloatingWindow(ref float) => float.get_shortcut_list(),
    }
    .draw(frame, area);
}
