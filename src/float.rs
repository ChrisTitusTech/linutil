use ratatui::layout::{Constraint, Direction, Layout, Rect};

/// This function just makes a given area smaller by 20 % in each direction, creating a kind of
/// "floating window". And you don't actually need all the constraints, and layouts to do that, its
/// very easy to calculate it directly, but I chose to use the ratatui API
pub fn floating_window(size: Rect) -> Rect {
    // If the terminal window is small enough, just take up all the space for the command
    if size.width < 85 || size.height < 25 {
        return size;
    }
    let hor_float = Layout::default()
        .constraints([
            Constraint::Percentage(20),
            Constraint::Percentage(60),
            Constraint::Percentage(20),
        ])
        .direction(Direction::Horizontal)
        .split(size)[1];
    Layout::default()
        .constraints([
            Constraint::Percentage(20),
            Constraint::Percentage(60),
            Constraint::Percentage(20),
        ])
        .direction(Direction::Vertical)
        .split(hor_float)[1]
}

/// Here is how would a purely math based function look like:
/// But it might break on smaller numbers
fn _unused_manual_floating_window(size: Rect) -> Rect {
    // If the terminal window is small enough, just take up all the space for the command
    if size.width < 85 || size.height < 25 {
        return size;
    }
    let new_width = size.width * 60 / 100;
    let new_height = size.height * 60 / 100;
    let new_x = size.x + size.width * 20 / 100;
    let new_y = size.y + size.height * 20 / 100;
    Rect {
        width: new_width,
        height: new_height,
        x: new_x,
        y: new_y,
    }
}

#[test]
fn test_floating() {
    let rect = Rect {
        x: 10,
        y: 2,
        width: 100,
        height: 200,
    };
    let res1 = floating_window(rect);
    let res2 = floating_window(rect);
    assert_eq!(res1, res2);
}
