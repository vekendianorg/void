--[[
  configs/lang/it.lua — Italiano (Italian)

  Flat table of dotted keys -> strings, loaded by core/utils/lang.lua.
  Looked up at runtime via the global T(key, ...) function, e.g.:
      T("common.ok")                          -> "OK"
      T("settings.window_width_desc", 400, 650) -> "Larghezza del menu flottante (400 - 650 dp)"

  Conventions:
    - Keys are namespaced by file: "settings.*", "account.*", "cups.*", etc.
    - %s / %d / %X etc. are string.format placeholders — keep them in the
      same order when translating, but they don't need to keep the same
      letter (e.g. %s can become %d if the translated grammar needs it).
    - Entries that are Lua arrays (e.g. spinner option lists) are returned
      as-is, untouched by string.format.
    - LOG.*() calls, debug tags, and internal cache/state keys are NOT
      translated — only user-visible text (dialogs, toasts, buttons,
      module titles/descriptions) lives here.

  This file handles the Italian localization for the VOID script.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "OK",
["common.cancel"] = "Annulla",
["common.yes"] = "Sì",
["common.no"] = "No",
["common.failed"] = "Fallito",
["common.success"] = "Successo",
["common.later"] = "Più tardi",
["common.got_it"] = "Capito",
["common.retry"] = "Riprova",
["common.wait_safe"] = "Attendi (Sicuro)",
["common.waiting"] = "In attesa...",
["common.force_exit"] = "Esci Forzatamente",
["common.proceed_anyway"] = "Procedi Comunque",
["common.manual_mode"] = "Modalità Manuale",
["common.update_button"] = "AGGIORNA",
["common.launch_failed"] = "Avvio Fallito",
["common.confirm_exit_title"] = "Conferma Uscita",
["common.confirm_exit_msg"] = "Uscire dallo Script?",
["common.not_available"] = "Non Disponibile",
["common.warning"] = "Avviso",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "Avviso: Operazioni Attive",
["main.exit_active_ops_msg"] = "Ci sono %d attività in background.\nForzare l'uscita potrebbe corrompere lo stato del gioco.",
["main.initializing"] = "Inizializzazione...",
["main.no_app_found"] = "Nessuna app trovata",
["main.arch_64bit_required_title"] = "64-bit Richiesto",
["main.arch_64bit_required_msg"] = "ARMv8a è obbligatoria. x86_64 è parzialmente supportata.",

["main.update_available_title"] = "Aggiornamento Disponibile",
["main.update_available_msg"] = "v%s è disponibile (attuale: v%s)\n\n%s\n\nAggiornare ora?",
["main.no_changelog"] = "Nessun changelog.",
["main.downloading_version"] = "Download di v%s...",
["main.update_download_failed_msg"] = "Impossibile scaricare l'aggiornamento:\n%s",
["main.update_write_failed_msg"] = "Impossibile scrivere in:\n%s",
["main.update_done_title"] = "VOID Aggiornato a v%s",
["main.update_done_msg"] = "VOID è stato aggiornato con successo.\n\nIl nuovo script è stato salvato come:\nvoid_v%s.lua\n\nEseguilo da GameGuardian per applicare l'aggiornamento.",
["main.launching_version"] = "Avvio di v%s...",
["main.launch_failed_msg"] = "Scaricato ma non eseguibile:\n%s",

["main.multiple_spaces_title"] = "Spazi Multipli Rilevati",
["main.multiple_spaces_desc"] = "HCR2 è stato trovato in %d spazi virtuali.\nSeleziona lo spazio in cui stai giocando.",
["main.select_space_toast"] = "Seleziona uno spazio per continuare.",
["main.user_space_item"] = "Utente %s  —  %s",
["main.permission_error_title"] = "Errore di Permesso",
["main.permission_error_msg"] = "L'accesso alla shell è stato negato.\n\nVoid ne ha bisogno per localizzare HCR2 nel tuo spazio virtuale. Controlla il codice sorgente di Void per verificare quale comando viene eseguito.",
["main.hcr2_not_found_title"] = "Dati HCR2 Non Trovati",
["main.hcr2_not_found_msg"] = "Void non ha trovato i dati HCR2 nel tuo spazio virtuale. Questo può accadere se HCR2 non è stato ancora avviato, o se la tua app dello spazio virtuale usa una struttura di percorso insolita.\n\nLe funzionalità che dipendono dai file di gioco (Ricompense Eventi, ecc.) non funzioneranno senza un percorso valido.",
["main.manual_data_path_title"] = "Percorso Dati Manuale",
["main.manual_data_path_hint"] = "Inserisci il percorso dei dati HCR2",
["main.manual_path_cancelled"] = "Annullato — procedendo senza percorso.",
["main.waiting_for_lib"] = "In attesa di %s...",
["main.initialized"] = "Inizializzato",
["main.gamestatus_not_found"] = "GameStatus Non Trovato",
["main.dont_interrupt"] = "Non interrompere questo script",

-- ── ui/ui.lua (framework chrome: menu, cards, dialogs) ────────────────────────
["ui.size_saved_restart"] = "Dimensione salvata! Riavvia lo script",
["ui.category_error"] = "Errore: %s",
["ui.category_not_found"] = "Categoria Non Trovata",
["ui.na"] = "N/D",
["ui.spinner_select"] = "Seleziona",
["ui.slider_default_title"] = "Valore",
["ui.loading"] = "Caricamento",

-- ── core/engines/patches.lua (addArchModule patch engine) ────────────────────
["patches.requires_arch"] = "Richiede dispositivo %s (tuo dispositivo: %s)",
["patches.suffix_enabled"] = " Attivato",
["patches.suffix_disabled"] = " Disattivato",
["patches.pattern_not_found"] = "Fallito: %d pattern non trovati",

-- ── core/engines/arch.lua (architecture detection warnings) ──────────────────
["arch.warning_title"] = "Avviso Architettura",
["arch.unknown_arch_msg"] = "La tua architettura è sconosciuta. La libreria è caricata? Che sistema stai usando?",
["arch.non_primary_arch_msg"] = "Rilevato: %s\nAlcune o tutte le patch della libreria potrebbero non funzionare.",
["arch.unknown_version_msg"] = "Versione del gioco sconosciuta. Riprova dopo il caricamento del gioco.",
["arch.no_base_data_msg"] = "Errore interno: nessun dato base disponibile per questa architettura.",

-- ── core/engines/scheduler.lua ────────────────────────────────────────────────
["scheduler.task_crashed"] = "Avviso Scheduler: Attività crashata -> %s",

-- ── core/utils/paste.lua + catbox.lua (network error strings) ────────────────
["errors.http_error_code"] = "Codice Errore HTTP: %s",
["errors.crashed"] = "Crash: %s",
["errors.url_missing"] = "Il parametro URL è mancante o vuoto",
["errors.file_path_missing"] = "Il percorso del file è mancante",
["errors.download_url_missing"] = "L'URL è mancante",
["errors.dest_path_missing"] = "Il percorso di destinazione è mancante",

-- ── modules/registry.lua (sidebar tab labels + module-load error cards) ──────
["tabs.sep_game"] = "MENU GIOCO",
["tabs.account"] = "MENU ACCOUNT",
["tabs.vehicle"] = "MENU VEICOLO",
["tabs.player"] = "MENU GIOCATORE",
["tabs.adventure"] = "MENU AVVENTURA",
["tabs.cups"] = "MENU COPPE",
["tabs.team"] = "MENU SQUADRA",
["tabs.event"] = "MENU EVENTI",
["tabs.creative"] = "MENU CREATIVO",
["tabs.shop"] = "MENU NEGOZIO",
["tabs.other"] = "MENU ALTRO",
["tabs.sep_script"] = "MENU SCRIPT",
["tabs.settings"] = "IMPOSTAZIONI",
["tabs.about"] = "INFO",

["registry.module_load_failed"] = "Caricamento modulo fallito. Controlla i log per i dettagli.",
["registry.module_runtime_error"] = "Errore runtime: %s",
["registry.error"] = "Errore",

-- ── modules/tabs/settings.lua ─────────────────────────────────────────────────
["settings.section_updates"] = "Aggiornamenti",
["settings.auto_update.title"] = "Aggiornamento Automatico",
["settings.auto_update.desc"] = "Aggiorna VOID automaticamente all'avvio",
["settings.dev_mode_title"] = "Modalità Sviluppatore",
["settings.auto_update.dev_mode_msg"] = "L'aggiornamento automatico è disattivato per main.lua (build di sviluppo).",
["settings.check_updates.title"] = "Controlla Aggiornamenti",
["settings.check_updates.desc"] = "Controlla l'ultima versione di VOID su GitHub",
["settings.check_updates.dev_mode_msg"] = "Il controllo aggiornamenti è disattivato per main.lua (build di sviluppo).\n\nEsegui il pull manualmente dal repo.",
["settings.check_updates.checking"] = "Controllo aggiornamenti...",
["settings.check_updates.failed_title"] = "Controllo Aggiornamenti Fallito",
["settings.check_updates.failed_msg"] = "Impossibile raggiungere GitHub:\n%s",
["settings.check_updates.up_to_date_title"] = "Aggiornato",
["settings.check_updates.up_to_date_msg"] = "Sei già all'ultima versione (v%s).",
["settings.check_updates.no_changelog"] = "Nessun changelog disponibile.",
["settings.check_updates.available_msg"] = "v%s  (attuale: v%s)\n\n%s\n\nScaricare e sostituire questo script?",
["settings.check_updates.no_asset_msg"] = "Nessun asset .lua trovato nella release.",
["settings.check_updates.download_failed_title"] = "Download Fallito",
["settings.check_updates.write_failed_title"] = "Scrittura Fallita",
["settings.check_updates.done_title"] = "Fatto",
["settings.check_updates.done_msg"] = "Aggiornato a v%s. Riavvia lo script per applicare.",
["settings.check_updates.restart_button"] = "Riavvia",

["settings.section_language"] = "Lingua",
["settings.language.title"] = "Lingua",
["settings.language.desc"] = "Scegli la tua lingua preferita per il menu",
["settings.language.changed"] = "Lingua impostata su %s",
["settings.language.failed"] = "Caricamento di quella lingua fallito",
["settings.language.restart_msg"] = "Riavvia lo script per applicare completamente la lingua",

["settings.region.other"] = "A: Altro",
["settings.region.cpp_alloc"] = "Ca: alloc C++",
["settings.region.unknown"] = "S: Sconosciuto",
["settings.section_memory"] = "Memoria",
["settings.memory_range.title"] = "Intervallo di Memoria",
["settings.memory_range.desc"] = "Intervallo di memoria attualmente selezionato\n(scelto automaticamente dallo script)",
["settings.gamestatus.title"] = "GameStatus",
["settings.gamestatus.desc"] = "Indirizzo GameStatus attuale\n(scelto automaticamente dallo script)",
["settings.gamestatus_raw.title"] = "GameStatus (Raw)",
["settings.gamestatus_raw.desc"] = "Indirizzo GameStatus (raw) attuale\n(scelto automaticamente dallo script)",
["settings.clear_memory.title"] = "Cancella Memoria Salvata",
["settings.clear_memory.desc"] = "Cancella tutta la memoria salvata da VOID senza dover riavviare il gioco.",

["settings.section_ui_customizations"] = "Personalizzazioni UI",
["settings.theme_store.title"] = "Negozio Temi",
["settings.theme_store.desc"] = "Sfoglia e installa i temi della community Void",
["settings.theme_store.unreachable_msg"] = "Impossibile raggiungere il negozio temi:\n%s",
["settings.theme_store.parse_failed_msg"] = "Impossibile analizzare i dati del negozio temi.",
["settings.theme_store.list_title"] = "Negozio Temi Void",
["settings.theme_store.search_results_desc"] = "Risultati ricerca: %s trovati",
["settings.theme_store.available_desc"] = "%s temi disponibili",
["settings.theme_store.by_author"] = "di %s",
["settings.theme_store.search_item"] = "🔍 Cerca...",
["settings.theme_store.clear_search_item"] = "✕ Cancella ricerca",
["settings.theme_store.search_title"] = "Cerca Temi",
["settings.theme_store.search_hint"] = "Nome tema, autore o descrizione",
["settings.theme_store.no_results"] = "Nessun tema trovato per: %s",
["settings.theme_store.detail_msg"] = "Di %s\n\n%s\n\nID: %s",
["settings.theme_store.install_button"] = "Installa Tema",
["settings.theme_downloading_bg"] = "Download dell'immagine di sfondo...",
["settings.theme_imported"] = "Tema importato!",
["settings.theme_invalid_bundle"] = "Formato bundle non valido.",
["settings.theme_cloud_error"] = "Errore cloud: %s",
["settings.reset_theme.title"] = "Ripristina Tema",
["settings.reset_theme.desc"] = "Ripristina tema personalizzato e immagine di sfondo al default",
["settings.import_theme.title"] = "Importa Tema",
["settings.import_theme.desc"] = "Importa tema personalizzato dal cloud",
["settings.import_theme.hint"] = "Inserisci ID di Condivisione",
["settings.export_theme.title"] = "Esporta Tema",
["settings.export_theme.desc"] = "Esporta tema personalizzato e immagine di sfondo sul cloud",
["settings.export_theme.share_id_msg"] = "ID di Condivisione: %s\n\nCopiato negli appunti.",
["settings.export_theme.upload_failed_msg"] = "Upload fallito: %s",
["settings.export_theme.size_warning_title"] = "Avviso Dimensione Upload",
["settings.export_theme.size_warning_msg"] = "Includere l'immagine di sfondo personalizzata? Aumenterà la dimensione dell'upload a seconda della dimensione della tua immagine.",
["settings.export_theme.uploading_bg"] = "Caricamento immagine di sfondo su Catbox...",
["settings.export_theme.image_upload_failed_title"] = "Errore",
["settings.export_theme.image_upload_failed_msg"] = "Caricamento immagine fallito: %s",
["settings.tabs_icon.title"] = "Icona Schede",
["settings.tabs_icon.desc"] = "Cambia l'icona delle schede",
["settings.tabs_icon.hint"] = "Inserisci Icona",
["settings.tabs_icon.empty_error"] = "Non può essere vuoto",

["settings.bg_opacity.title"] = "Opacità Sfondo",
["settings.bg_opacity.desc"] = "Trasparenza di pannelli, schede e intestazione",
["settings.slider.alpha"] = "Alfa",
["settings.bg_image_opacity.title"] = "Opacità Immagine Sfondo",
["settings.bg_image_opacity.desc"] = "Regola le impostazioni alfa di visibilità direttamente usando canali interi puri.",
["settings.bg_image_picker.title"] = "Immagine Sfondo",
["settings.bg_image_picker.desc"] = "Tocca per modificare il percorso assoluto del file per l'immagine di sfondo personalizzata",
["settings.bg_image_picker.path_label"] = "Percorso Assoluto Immagine (.jpg o .png):",
["settings.bg_image_picker.remove_label"] = "Rimuovi Immagine Sfondo",
["settings.bg_image_picker.success_title"] = "Successo",
["settings.bg_image_picker.removed_msg"] = "Immagine Sfondo Rimossa",
["settings.bg_image_picker.added_msg"] = "Immagine sfondo aggiunta",
["settings.bg_image_picker.not_found_msg"] = "File non trovato o operazione di lettura negata:\n%s",

["settings.bg_rgb.title"] = "Sfondo RGB",
["settings.bg_rgb.desc"] = "Tonalità per gli sfondi dei pannelli (Intestazione e Scheda si adattano automaticamente)",
["settings.slider.r"] = "R",
["settings.slider.g"] = "G",
["settings.slider.b"] = "B",
["settings.accent_rgb.title"] = "Accento RGB",
["settings.accent_rgb.desc"] = "Tonalità per pulsanti, interruttori e schede attive (colore smorzato derivato automaticamente)",
["settings.logo_rgb.title"] = "Evidenziazione RGB",
["settings.logo_rgb.desc"] = "Colore per etichette, icone e testo interattivo (sempre completamente opaco)",
["settings.sub_rgb.title"] = "Sottotesto RGB",
["settings.sub_rgb.desc"] = "Colore per descrizioni ed etichette delle schede inattive",
["settings.text_rgb.title"] = "Testo RGB",
["settings.text_rgb.desc"] = "Colore per il testo del menu principale",

["settings.win_width.title"] = "Larghezza Menu",
["settings.win_width.desc"] = "Larghezza del menu flottante (%d – %d dp)",
["settings.slider.width"] = "Larghezza",
["settings.win_height.title"] = "Altezza Menu",
["settings.win_height.desc"] = "Altezza dell'area di contenuto scrollabile (%d – %d dp)",
["settings.slider.height"] = "Altezza",

-- ── modules/tabs/about.lua ────────────────────────────────────────────────────
["about.about_script.title"] = "Informazioni Script",
["about.about_script.desc"] = "Uno script di manipolazione della memoria potente e altamente ottimizzato costruito per Hill Climb Racing 2 sull'ambiente Pivot personalizzato.\n\nScarica Pivot:\nhttps://github.com/vekendianorg/pivot/releases/",
["about.script_owner.title"] = "Proprietario Script",
["about.script_owner.desc"] = "- Vekendian Organization (github: vekendianorg)",
["about.script_dev.title"] = "Sviluppatore Script",
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],
["about.script_translator.title"] = "Traduttore Script",
["about.script_translator.desc"] = [[
- English: Lazor (github: lazor-git)
- Bahasa Indonesia: Lazor (github: lazor-git)
- Español: Jayy2k (github: Jayy2k)
- Deutsch: Erik (github: eomthix)
- Русский: Winter Lotus(github: Ohranik1Pitorochki; discord:nikolaypg67)
- Thai: NaiArt777 (github: artphakkapol-hub)
- বাংলা: AMR (github: amr-gt)
- العربية: AMR (github: amr-gt)
- اردو: AMR (github: amr-gt)
- Français: AMR (github: amr-gt)
- Українська: AMR (github: amr-gt)
- Türkçe: AMR (github: amr-gt)
- Português (Brasil): AMR (github: amr-gt)
- हिन्दी: AMR (github: amr-gt)
- Italiano: AMR (github: amr-gt)
]],
["about.credits.title"] = "Crediti",
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
- Profinoobru
]],
["about.special_thanks.title"] = "Ringraziamenti Speciali",
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

-- ── modules/tabs/other.lua ────────────────────────────────────────────────────
["other.debug_mode.title"] = "Modalità Debug",
["other.debug_mode.desc"] = "Attiva/disattiva la modalità debug nel gioco",
["other.debug_mode.enabled"] = "Modalità Debug Attivata",
["other.debug_mode.disabled"] = "Modalità Debug Disattivata",
["other.hint.width"] = "Larghezza",
["other.hint.height"] = "Altezza",
["other.resolution.title"] = "Regola Risoluzione",
["other.resolution.desc"] = "Regola la larghezza e l'altezza del gioco (default 1280x720)",
["other.resolution.applied"] = "Risoluzione impostata su %dx%d",
["other.resolution_offset.title"] = "Regola Offset Risoluzione",
["other.resolution_offset.desc"] = "Regola l'offset di larghezza e altezza del gioco (default 0x0), ideale per piccole risoluzioni su grandi schermi.",
["other.resolution_offset.applied"] = "Offset risoluzione impostato su %dx%d",
["other.glsurface_not_found"] = "GLSurfaceView non trovato",

-- ── modules/tabs/shop.lua ─────────────────────────────────────────────────────
["shop.free_chest.title"] = "Baule Gratuito",
["shop.free_chest.desc"] = "Rendi i bauli gratuiti nella scheda Negozio",
["shop.free_chest.enabled"] = "Baule Gratuito Attivato",
["shop.free_chest.disabled"] = "Baule Gratuito Disattivato",
["shop.free_purchases.title"] = "Acquisti Gratuiti",
["shop.free_purchases.desc"] = "Rendi alcuni affari giornalieri gratuiti nella scheda negozio (funziona anche per offerte speciali come popup/badge)",
["shop.free_purchases.progress"] = "%d/%d",
["shop.free_purchases.success"] = "Acquisto Gratuito Riuscito",
["shop.change_chest.title"] = "Cambia Baule",
["shop.change_chest.desc"] = "Cambia il baule leggendario con il baule selezionato",
["shop.change_chest.changed"] = "Baule cambiato in %s",
["shop.change_chest.options"] = {
    "Baule Comune", "Baule Non Comune", "Baule Raro", "Baule Epico",
    "Baule Campione", "Baule Speciale 1", "Baule di Natale", "Baule Leggendario",
    "Baule Blu", "Baule VIP 1", "Baule VIP 2", "Baule Video",
    "Baule Iniziale", "Baule Speciale 2", "Baule Fingersoft", "Mega Baule",
    "Baule Spirito di Squadra", "Baule Stile", "Baule Mitico"
},

-- ── modules/tabs/player.lua ───────────────────────────────────────────────────
["player.auto_detach.title"] = "Distacco Automatico",
["player.auto_detach.desc"] = "Distacca automaticamente parti come il tetto della Rally Car",
["player.auto_die.title"] = "Morte Automatica",
["player.auto_die.desc"] = "Provoca automaticamente la morte (carburante esaurito)",
["player.no_clip.title"] = "No-Clip",
["player.no_clip.desc"] = "Fai passare il tuo giocatore attraverso gli oggetti senza morire (puoi superare le linee di arrivo nelle coppe)",
["player.no_clip.enabled"] = "No-Clip Attivato",
["player.no_clip.disabled"] = "No-Clip Disattivato",
["player.hide_name.title"] = "Nascondi Nome",
["player.hide_name.desc"] = "Nascondi il nome del tuo giocatore in gara",
["player.hide_name.enabled"] = "Nascondi Nome Attivato",
["player.hide_name.disabled"] = "Nascondi Nome Disattivato",
["player.hide_flag.title"] = "Nascondi Bandiera",
["player.hide_flag.desc"] = "Nascondi la bandiera del tuo giocatore in gara",
["player.hide_flag.enabled"] = "Nascondi Bandiera Attivato",
["player.hide_flag.disabled"] = "Nascondi Bandiera Disattivato",
["player.fuel.title"] = "Carburante",
["player.fuel.desc"] = "Blocca il carburante a un valore costante durante la gara (0.0 – 100.0)",
["player.fuel.prompt_amount"] = "Quantità di carburante (0 – 100)",
["player.fuel.prompt_reset"] = "Ripristina",
["player.fuel.invalid"] = "Valore non valido, deve essere 0 – 100",
["player.fuel.applied"] = "Carburante bloccato a %s",
["player.fuel.reset"] = "Carburante ripristinato",
["player.fuel.not_applied"] = "Carburante non attivo",
["player.zoom.title"] = "Regola Zoom",
["player.zoom.desc"] = "Regola quanto è vicina o lontana la tua fotocamera",
["player.slider.min"] = "Min",
["player.slider.max"] = "Max",
["player.gravity.title"] = "Regola Gravità",
["player.gravity.desc"] = "Regola quanto è forte la gravità",
["player.slider.x"] = "X",
["player.slider.y"] = "Y",

-- ── modules/tabs/adventure.lua ────────────────────────────────────────────────
["adventure.auto_adventure_chests.title"] = "Bauli Avventura Automatici (instabile)",
["adventure.auto_adventure_chests.desc"] = "Aumenta automaticamente il livello dei tuoi bauli avventura",
["adventure.auto_adventure_chests.none_found"] = "Nessun baule avventura trovato",
["adventure.auto_adventure_chests.done"] = "Fatto",

["adventure.set_distance.title"] = "Imposta Distanza",
["adventure.set_distance.desc"] = "Imposta la distanza della tua gara avventura su un valore personalizzato. Devi essere in una gara attiva. Una distanza maggiore può dare più stelle. Massimo stelle a 5000m. (Non è una funzione di teletrasporto)",
["adventure.set_distance.loop_active_title"] = "Imposta Distanza — Ciclo Attivo",
["adventure.set_distance.loop_active_msg"] = "Il ciclo di distanza è attualmente in esecuzione.\nCosa vuoi fare?",
["adventure.set_distance.stop_loop"] = "Ferma Ciclo",
["adventure.set_distance.keep_running"] = "Continua",
["adventure.set_distance.loop_will_stop"] = "Il ciclo si fermerà dopo il tick corrente.",
["adventure.set_distance.prompt_target"] = "Distanza target (metri)",
["adventure.set_distance.prompt_loop"] = "Ciclo (riapplicazione automatica)",
["adventure.set_distance.prompt_interval"] = "Intervallo ciclo (ms, min 250)",
["adventure.set_distance.over_max_title"] = "Avviso Distanza",
["adventure.set_distance.over_max_msg"] = "Una distanza superiore a 5000m non ti darà stelle.\n\nLa gara registrerà comunque la distanza, ma non verranno date ricompense in stelle. Continuare?",
["adventure.set_distance.continue_button"] = "Continua",
["adventure.set_distance.not_in_adventure"] = "Vai alla scheda Avventura e inizia prima una gara",
["adventure.set_distance.start_race_first"] = "Inizia prima una gara",
["adventure.set_distance.applied"] = "Distanza impostata: %sm",
["adventure.set_distance.loop_stopped"] = "Ciclo Imposta Distanza fermato.",
["adventure.set_distance.loop_running"] = "Ciclo distanza in esecuzione — tocca Imposta Distanza per fermare",
["adventure.set_distance.loop_warn_title"] = "Avviso Ciclo Distanza",
["adventure.set_distance.loop_warn_msg"] = "La modalità ciclo scrive in memoria ogni %s ms.\n\nUsare un intervallo breve può aumentare instabilità, glitch visivi o crash del gioco.\n\nContinuare comunque?",

-- ── modules/tabs/cups.lua ─────────────────────────────────────────────────────
["cups.adjust_countdown.title"] = "Regola Conto alla Rovescia",
["cups.adjust_countdown.desc"] = "Regola il conto alla rovescia prima di iniziare la gara",
["cups.slider.seconds"] = "Secondi",
["cups.adjust_countdown.applied"] = "Conto alla rovescia regolato a %ss",
["cups.auto_win.title"] = "Vittoria Automatica",
["cups.auto_win.desc"] = "Vinci automaticamente qualunque sia il risultato della tua gara",
["cups.force_boss.title"] = "Forza Boss",
["cups.force_boss.desc"] = "Il boss appare sempre",
["cups.force_cup.title"] = "Forza Coppa",
["cups.force_cup.desc"] = "Forza una singola coppa",
["cups.force_cup.not_found"] = "Forza Coppa non trovata. Riprova più tardi.",
["cups.force_cup.enabled"] = "Forza Coppa Attivato",
["cups.force_cup.disabled"] = "Forza Coppa Disattivato",
["cups.set_time.title"] = "Imposta Tempo",
["cups.set_time.desc"] = "Imposta il tempo della tua gara (non congelerà il tempo per sicurezza). Devi essere in una gara di coppa attiva. (es. 1:09.069, 7.284)",
["cups.set_time.hint"] = "Tempo (1:09.069 o 7.284)",
["cups.set_time.invalid_format"] = "Formato non valido. Usa 1:09.069 o 7.284",
["cups.set_time.no_negative"] = "Nessun valore negativo",
["cups.set_time.not_in_cup"] = "Vai alla scheda Coppe e inizia prima una gara",
["cups.set_time.start_race_first"] = "Inizia prima una gara",
["cups.set_time.applied"] = "Tempo impostato su %s",
["cups.unlimited_tasks.title"] = "Attività Illimitate",
["cups.unlimited_tasks.desc"] = "Blocca tutte le attività come completate e sempre richiedibili. Richiedi ricompense ripetutamente.",
["cups.unlimited_tasks.resolve_failed"] = "Impossibile risolvere l'elenco delle attività",
["cups.unlimited_tasks.none_found"] = "Nessuna attività trovata",
["cups.unlimited_tasks.enabled"] = "Attività Illimitate Attivate",
["cups.unlimited_tasks.disabled"] = "Attività Illimitate Disattivate",
["cups.unlimited_tasks.none_to_freeze"] = "Nessuna attività da bloccare",
["cups.rank_points_bonus.title"] = "+498 Punti Classifica",
["cups.rank_points_bonus.desc"] = "Fai in modo che tutte le attività della lega ti diano 498 punti invece di 200, e rimuovi anche altre ricompense.",
["cups.rank_points_bonus.none_found"] = "Nessuna attività lega trovata",
["cups.rank_points_bonus.boosted"] = "Punti classifica potenziati: %s",
["cups.rank_points_bonus.no_match"] = "Nessuna attività lega corrispondente trovata",
["cups.rank_points_bonus.nothing_to_restore"] = "Niente da ripristinare",
["cups.rank_points_bonus.restored"] = "Ripristinato: %s",

-- ── modules/tabs/event.lua ────────────────────────────────────────────────────
["event.patch_rewards.title"] = "Patch Ricompense Eventi",
["event.patch_rewards.desc"] = "Applica patch alle ricompense dell'evento pubblico attuale con quelle personalizzate fornite da VOID (richiede riavvio del gioco)",
["event.restore_events.title"] = "Ripristina Ricompense Eventi",
["event.restore_events.desc"] = "Elimina i JSON degli eventi modificati per forzare il ripristino del server di gioco (richiede riavvio del gioco)",

["event.checking_permissions"] = "Controllo permessi ambiente...",
["event.scanning_files"] = "Scansione file attivi...",
["event.decode_rewards_failed"] = "Decodifica del JSON delle ricompense fallita",
["event.workspace_creation_failed"] = "FATALE: Creazione workspace fallita: %s",
["event.workspace_creation_failed_dialog"] = "FATALE: Impossibile creare la directory del workspace.\n%s",
["event.file_inaccessible"] = "File inaccessibile al percorso: %s",
["event.predecrypt_not_found"] = "Pre-decrypt: sorgente non trovata: %s",
["event.predecrypt_empty"] = "Pre-decrypt: la sorgente è vuota (0 byte): %s",
["event.decode_active_failed"] = "Decodifica di active_events.json fallita al percorso: %s",
["event.no_active_events"] = "Nessun evento attivo trovato al percorso: %s",
["event.cannot_open_active"] = "Impossibile aprire active_events.json al percorso: %s",
["event.decrypt_active_failed"] = "Decrypt di active_events.json fallito al percorso: %s",
["event.root_copy_failed"] = "Copia root fallita: %s",

["event.select_events_patch"] = "Seleziona eventi da patchare:\nPercorso: %s",
["event.user_cancelled"] = "Utente ha annullato la selezione per il percorso: %s",
["event.rewards_unavailable"] = "Ricompense incorporate non disponibili, salto patch per il percorso: %s",
["event.skipped_unreadable"] = "Evento illeggibile saltato: %s",
["event.predecrypt_event_not_found"] = "Pre-decrypt: evento non trovato: %s",
["event.predecrypt_event_empty"] = "Pre-decrypt: l'evento è vuoto (0 byte): %s",
["event.processing_failed"] = "Elaborazione di %s fallita: %s",
["event.cannot_open_decrypted"] = "Impossibile aprire il file decriptato: %s",
["event.decrypt_event_failed"] = "Decrypt dell'evento fallito: %s",
["event.loop_crash"] = "Ciclo critico di elaborazione file crashato: %s",

["event.success_header"] = "Con successo:",
["event.success_removed_header"] = "Rimosso con successo (Verrà Ripristinato al Riavvio):",
["event.success_item"] = "- %s",
["event.success_item_json"] = "- %s.json",
["event.failed_header"] = "Fallito:",
["event.failed_item"] = "- %s",

["event.patch_results_title"] = "Risultati Patch",
["event.restore_results_title"] = "Risultati Ripristino",
["event.restart_required_title"] = "Riavvio Richiesto",
["event.patch_restart_msg"] = "Il gioco è stato chiuso e questo script uscirà, riavvialo per vedere gli effetti della patch",
["event.restore_restart_msg"] = "Il gioco ora si chiuderà per consentire la sincronizzazione dei file del server.",
["event.finishing_tasks_patch"] = "Completamento attività in background in sospeso... Attendere prego.",
["event.finishing_tasks_restore"] = "Completamento attività in background in sospeso...",
["event.patch_failed_msg"] = "Patch fallita, riprova.",

["event.select_events_restore"] = "Seleziona file da ripristinare (eliminare):\nPercorso: %s",
["event.delete_failed"] = "Eliminazione di %s fallita: %s",

-- ── modules/tabs/account.lua ──────────────────────────────────────────────────
["account.change_name.title"] = "Cambia Nome",
["account.change_name.desc"] = "Cambia il nome del tuo giocatore",
["account.change_name.hint"] = "Inserisci Nome",
["account.change_name.empty"] = "Inserisci prima un nome",
["account.change_name.too_long_title"] = "Nome Troppo Lungo",
["account.change_name.too_long_msg"] = "Il tuo nome è troppo lungo, accorcialo",
["account.change_name.resolve_failed"] = "Impossibile risolvere il puntatore del nome",
["account.change_name.applied"] = "Nome cambiato in %s",

["account.change_gp.title"] = "Cambia Potenza Garage",
["account.change_gp.desc"] = "Cambia la potenza del garage del profilo (persiste se più alta). Imposta a 8 per ripristinare se supera il massimo, ma solo se il tuo GP effettivo è già fissato sotto il limite.",
["account.change_gp.hint"] = "Inserisci Potenza Garage",
["account.change_gp.max_int_title"] = "Raggiunto il massimo int a 32 bit",
["account.change_gp.lower_value"] = "Abbassa il valore",
["account.change_gp.too_low_title"] = "Troppo Basso",
["account.change_gp.higher_value"] = "Aumenta il valore",
["account.change_gp.applied"] = "La Potenza del Garage è stata cambiata in %s",

["account.fake_unlock.title"] = "Sblocco Falso",
["account.fake_unlock.desc"] = "Sblocca tutte le personalizzazioni temporaneamente",
["account.fake_vip.title"] = "VIP Falso",
["account.fake_vip.desc"] = "Attiva/disattiva lo stato di abbonamento VIP localmente",

["account.fake_rank.title"] = "Classifica Falsa",
["account.fake_rank.desc"] = "Imposta la tua classifica a leggendaria falsa istantaneamente",
["account.fake_rank.race_warn_title"] = "Gara Richiesta",
["account.fake_rank.race_warn_msg"] = "La Classifica Falsa dovrebbe essere applicata solo mentre una gara di Coppe è attivamente in esecuzione.\n\nApplicarla al di fuori di una gara potrebbe comportare un shadow ban.\n\nAssicurati di essere già all'interno di una gara di Coppe prima di continuare.\n\nContinuare comunque?",
["account.fake_rank.continue_button"] = "Continua",
["account.fake_rank.applied"] = "Classifica falsa iniettata",
["account.fake_rank.not_in_cups"] = "Inizia prima una gara",

-- ── modules/tabs/vehicle.lua ──────────────────────────────────────────────────
["vehicle.parts_slot.title"] = "Regola Slot Parti",
["vehicle.parts_slot.desc"] = "Regola lo slot delle parti per tutti i veicoli",
["vehicle.parts_slot.slider_title"] = "Slot",
["vehicle.parts_slot.no_vehicles"] = "Nessun veicolo trovato",
["vehicle.parts_slot.applied"] = "Slot parti regolato: %d veicoli",

["vehicle.parts_modifier.title"] = "Modificatore Parti",
["vehicle.parts_modifier.desc"] = "Modifica i livelli delle parti di tuning in gara attiva",
["vehicle.parts_modifier.select"] = "Seleziona una parte",
["vehicle.parts_modifier.prompt_level"] = "Livello: ",
["vehicle.parts_modifier.prompt_digit0"] = "Cifra: ",
["vehicle.parts_modifier.prompt_digit1"] = "Coda: ",
["vehicle.parts_modifier.prompt_reset"] = "Ripristina",
["vehicle.parts_modifier.invalid"] = "Valore livello non valido",
["vehicle.parts_modifier.not_found"] = "Parte non trovata in memoria",
["vehicle.parts_modifier.applied"] = "%s impostato al livello %s",
["vehicle.parts_modifier.reset"] = "%s ripristinato",

["vehicle.unlock_vehicles.title"] = "Sblocca Veicoli",
["vehicle.unlock_vehicles.desc"] = "Sblocca tutti i veicoli per l'acquisto con monete",
["vehicle.unlock_vehicles.no_vehicles"] = "Nessun veicolo trovato",
["vehicle.unlock_vehicles.unlocked"] = "Veicoli sbloccati: %d",
["vehicle.unlock_vehicles.none_to_unlock"] = "Nessun veicolo da sbloccare",

["vehicle.max_vehicles.title"] = "Veicoli Massimi",
["vehicle.max_vehicles.desc"] = "Massimizza istantaneamente i livelli di potenziamento di tutti i veicoli sbloccati",
["vehicle.max_vehicles.no_vehicles"] = "Impossibile risolvere l'elenco veicoli",
["vehicle.max_vehicles.all_maxed"] = "Tutti i veicoli massimizzati",
["vehicle.max_vehicles.failed"] = "Massimizzazione veicoli fallita",

["vehicle.max_mastery.title"] = "Maestria Massima",
["vehicle.max_mastery.desc"] = "Massimizza istantaneamente le maestrie di tutti i veicoli sbloccati e massimizzati.",
["vehicle.max_mastery.all_maxed"] = "Tutte le maestrie massimizzate",
["vehicle.max_mastery.failed"] = "Massimizzazione maestrie fallita",

["vehicle.max_parts.title"] = "Parti Massime",
["vehicle.max_parts.desc"] = "Massimizza istantaneamente i livelli di tutte le parti sbloccate per tutti i veicoli.",
["vehicle.max_parts.no_vehicles"] = "Impossibile risolvere l'elenco veicoli",
["vehicle.max_parts.all_maxed"] = "Tutte le parti massimizzate",
["vehicle.max_parts.failed"] = "Massimizzazione parti fallita",

["vehicle.common.no_vehicles"] = "Nessun veicolo trovato",
["vehicle.common.progress"] = "%d/%d",
["vehicle.common.resolve_list_failed"] = "Impossibile risolvere l'elenco veicoli",
["vehicle.common.no_zero_region"] = "Nessuna regione zero trovata",

}
