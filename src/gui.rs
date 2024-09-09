use eframe::egui;
use eframe::App;
use egui::InnerResponse;
use egui_extras::{Column, TableBuilder};
use std::path::Path;
use std::process::exit;
use std::process::Command;
#[derive(Default)]
struct GuiFrontend;

impl GuiFrontend {
    fn new(cc: &eframe::CreationContext<'_>) -> Self {
        Self::default()
    }
}
fn info(ctx: &egui::Context, err_msg: &str) {
    egui::CentralPanel::default().show(ctx, |dialog| {
        dialog.centered_and_justified(|d| {
            d.heading(format!("Failed to finish the action: {err_msg}"));
        });
    });
}
impl App for GuiFrontend {
    fn update(&mut self, ctx: &eframe::egui::Context, frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |central| {
            central.horizontal_centered(|content| {
                let file = std::fs::read_to_string("src/commands/tabs.toml").unwrap();
                let toml: crate::tabs::TabList = toml::from_str(&file).unwrap();
                // We need this loop to access directories and execute scripts.
                // NOTE: This will not work if you are not in the root of the directory.
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
                                // This mess of spaghetti code is a result of having to have both
                                // row and col in the same loop.
                                for entry in cfg.data {
                                    body.row(20f32, |mut col| {
                                        col.col(|content| {
                                            if content
                                                .checkbox(&mut false, entry.name.to_string())
                                                .changed()
                                            {
                                                if let Some(script) = entry.script {
                                                    crate::running_command::Command::Raw(
                                                        script.display().to_string(),
                                                    );
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
    eframe::run_native(
        "CTT Linux toolkit",
        native_options,
        Box::new(|cc| Ok(Box::new(GuiFrontend::new(cc)))),
    )?;
    Ok(())
}
