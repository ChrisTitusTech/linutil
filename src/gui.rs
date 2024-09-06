use eframe::egui;
use eframe::App;
use egui_extras::{Column, TableBuilder};
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
        egui::CentralPanel::default().show(ctx, |central| {
            central.horizontal_centered(|content| {
                let file = std::fs::read_to_string("src/commands/tabs.toml").unwrap();
                let toml: crate::tabs::TabList = toml::from_str(&file).unwrap();
                for dir in toml.directories {
                    let dirname = std::fs::read_to_string(
                        Path::new("src/commands")
                            .join(dir.clone())
                            .join("tab_data.toml"),
                    )
                    .unwrap();
                    content.push_id(&dir.display().to_string(), |table| {
                        TableBuilder::new(table)
                            .column(Column::auto().resizable(true))
                            .column(Column::remainder().clip(true))
                            .header(21.0, |mut header| {
                                header.col(|col| {
                                    col.push_id(&dir.display().to_string(), |data| {
                                        data.heading(&dir.display().to_string());
                                    });
                                });
                            })
                            .body(|mut body| {
                                let cfg: crate::tabs::TabEntry = toml::from_str(&dirname).unwrap();
                                for entry in cfg.data {
                                    body.row(20f32, |mut col| {
                                        col.col(|content| {
                                            if content
                                                .checkbox(&mut false, entry.name.to_string())
                                                .changed()
                                            {
                                                if let Some(script) = entry.script {
                                                    std::process::Command::new(script)
                                                        .output()
                                                        .unwrap()
                                                        .stdout;
                                                }
                                            }
                                        });
                                    });
                                }
                            });
                    });
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
