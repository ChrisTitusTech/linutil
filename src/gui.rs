use eframe::egui;
use eframe::App;
use std::fs::read_dir;
use std::path::Path;
use std::process::exit;
#[derive(Default)]
struct GuiFrontend;

impl GuiFrontend {
    fn new(cc: &eframe::CreationContext<'_>) -> Self {
        Self::default()
    }
}

impl App for GuiFrontend {
    fn update(&mut self, ctx: &eframe::egui::Context, frame: &mut eframe::Frame) {
        // egui::SidePanel::new(egui::panel::Side::Left, "categories").show_animated(
        //     ctx,
        //     true,
        //     |side| {
        //         side.heading("Categories");
        //         side.separator();
        //         let file = std::fs::read_to_string("src/commands/tabs.toml").unwrap();
        //         let toml: crate::tabs::TabList = toml::from_str(&file).unwrap();
        //         for dir in toml.directories {
        //             if side.button(dir.to_str().unwrap()).clicked() {}
        //         }
        //     },
        // );
        egui::CentralPanel::default().show(ctx, |central| {
            central.horizontal_centered(|stuff| {
                let file = std::fs::read_to_string("src/commands/tabs.toml").unwrap();
                let toml: crate::tabs::TabList = toml::from_str(&file).unwrap();
                for dir in toml.directories {
                    let dirname = std::fs::read_to_string(
                        Path::new("src/commands").join(dir).join("tab_data.toml"),
                    )
                    .unwrap();
                    let cfg: crate::tabs::TabEntry = toml::from_str(&dirname).unwrap();
                    for entry in cfg.data {
                        stuff.button(entry.name.to_string());
                    }
                }
            });
        });
    }
}

pub(crate) fn start_gui() -> eframe::Result<(), eframe::Error> {
    let native_options = eframe::NativeOptions::default();
    match eframe::run_native(
        "CTT Linux toolkit",
        native_options,
        Box::new(|cc| Ok(Box::new(GuiFrontend::new(cc)))),
    ) {
        Ok(ok) => ok,
        Err(_) => exit(1),
    };
    Ok(())
}
