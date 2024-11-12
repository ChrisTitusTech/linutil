use rand::Rng;

const TIPS: &str = include_str!("../cool_tips.txt");

pub fn get_random_tip() -> &'static str {
    let tips: Vec<&str> = TIPS.lines().collect();
    if tips.is_empty() {
        return "";
    }

    let mut rng = rand::thread_rng();
    let random_index = rng.gen_range(0..tips.len());
    tips[random_index]
}
