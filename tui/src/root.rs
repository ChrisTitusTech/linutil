use ratatui::{
    backend::CrosstermBackend,
    crossterm::event::{self, Event, KeyCode, KeyEvent},
    layout::{Alignment, Constraint, Layout},
    style::{Style, Stylize},
    widgets::{Paragraph, Wrap},
    Terminal,
};
use std::io;

const ROOT_WARNING: &str = r#"
!!!!!!!!!!!!!! YOU ARE ABOUT TO RUN LINUTIL AS ROOT !!!!!!!!!!!!!!
This utility prioritizes compatibility with non-root environments.
Some scripts may work without any issues, some may not.
You have been warned!
!!!!!!!!!!!!!!!!!!!!!! PROCEED WITH CAUTION !!!!!!!!!!!!!!!!!!!!!!
Press [y] to continue, [n] to abort
"#;

pub fn check_root(terminal: &mut Terminal<CrosstermBackend<io::Stdout>>) -> io::Result<bool> {
    if !nix::unistd::geteuid().is_root() {
        return Ok(true);
    }
    terminal.draw(|frame| {
        let root_warn = Paragraph::new(ROOT_WARNING)
            .white()
            .on_black()
            .alignment(Alignment::Center)
            .style(Style::default().bold())
            .wrap(Wrap { trim: true });

        let rects = Layout::vertical([
            Constraint::Fill(1),
            Constraint::Length(10),
            Constraint::Fill(1),
        ])
        .split(frame.area());

        let centered = rects[1];

        frame.render_widget(root_warn, centered);
    })?;

    loop {
        if let Event::Key(KeyEvent {
            code: KeyCode::Char(ch),
            ..
        }) = event::read()?
        {
            match ch.to_ascii_lowercase() {
                'y' => return Ok(true),
                'n' => return Ok(false),
                _ => {}
            }
        }
    }
}
