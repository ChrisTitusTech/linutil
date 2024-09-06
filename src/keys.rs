// A single key hint with the key name and a short description
pub struct KeyHint {
    key: &'static str,
    description: &'static str,
}

impl KeyHint {
    // Create a new KeyHint
    fn new(key: &'static str, description: &'static str) -> Self {
        Self { key, description }
    }

    // Get the key name for this hint
    pub fn get_key(&self) -> &'static str {
        self.key
    }

    // Get the description for this hint
    pub fn get_description(&self) -> &'static str {
        self.description
    }
}

// A set of KeyHints corresponding to each mode
pub enum KeyHintSet {
    Search,
    TabList,
    List,
    FloatingWindow,
}

impl KeyHintSet {
    // Get the key hints for this specific set
    pub fn get_key_hints(&self) -> Vec<KeyHint> {
        // Here all keys are defined
        match self {
            KeyHintSet::Search => {
                vec![KeyHint::new("Enter", "Search"), KeyHint::new("Esc", "Exit")]
            }

            KeyHintSet::TabList => vec![
                KeyHint::new("Enter/right/l/Tab", "Select"),
                KeyHint::new("down/j", "Down"),
                KeyHint::new("up/k", "Up"),
                KeyHint::new("/", "Search"),
                KeyHint::new("q", "Quit"),
                KeyHint::new("t", "Next theme"),
                KeyHint::new("T", "Prev theme"),
            ],

            KeyHintSet::List => vec![
                KeyHint::new("Enter/right/l", "Exec"),
                KeyHint::new("down/j", "Down"),
                KeyHint::new("up/k", "Up"),
                KeyHint::new("left/h", "Back"),
                KeyHint::new("up/k", "Up"),
                KeyHint::new("/", "Search"),
                KeyHint::new("q", "Quit"),
                KeyHint::new("t", "Next theme"),
                KeyHint::new("T", "Prev theme"),
            ],
            KeyHintSet::FloatingWindow => vec![
                KeyHint::new("Enter/Esc/p/q", "Close"),
                KeyHint::new("down/j", "Down"),
                KeyHint::new("up/k", "Up"),
            ],
        }
    }
}
