--[[
  configs/lang/fr.lua — Français (French)

  Flat table of dotted keys -> strings, loaded by core/utils/lang.lua.
  Looked up at runtime via the global T(key, ...) function, e.g.:
      T("common.ok")                          -> "OK"
      T("settings.window_width_desc", 400, 650) -> "Largeur du menu flottant (400 - 650 dp)"

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

  This file handles the French localization for the VOID script.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "OK",
["common.cancel"] = "Annuler",
["common.yes"] = "Oui",
["common.no"] = "Non",
["common.failed"] = "Échec",
["common.success"] = "Succès",
["common.later"] = "Plus tard",
["common.got_it"] = "Compris",
["common.retry"] = "Réessayer",
["common.wait_safe"] = "Attendre (Sûr)",
["common.waiting"] = "Attente...",
["common.force_exit"] = "Quitter de force",
["common.proceed_anyway"] = "Continuer quand même",
["common.manual_mode"] = "Mode manuel",
["common.update_button"] = "METTRE À JOUR",
["common.launch_failed"] = "Échec du lancement",
["common.confirm_exit_title"] = "Confirmer la sortie",
["common.confirm_exit_msg"] = "Quitter le script ?",
["common.not_available"] = "Non disponible",
["common.warning"] = "Avertissement",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "Avertissement : Opérations actives",
["main.exit_active_ops_msg"] = "%d tâche(s) en arrière-plan.\nForcer la sortie peut corrompre l'état du jeu.",
["main.initializing"] = "Initialisation...",
["main.no_app_found"] = "Aucune application trouvée",
["main.arch_64bit_required_title"] = "64 bits requis",
["main.arch_64bit_required_msg"] = "ARMv8a est obligatoire. x86_64 est partiellement pris en charge.",

["main.update_available_title"] = "Mise à jour disponible",
["main.update_available_msg"] = "v%s est disponible (actuelle : v%s)\n\n%s\n\nMettre à jour maintenant ?",
["main.no_changelog"] = "Aucun journal des modifications.",
["main.downloading_version"] = "Téléchargement de v%s...",
["main.update_download_failed_msg"] = "Impossible de télécharger la mise à jour :\n%s",
["main.update_write_failed_msg"] = "Impossible d'écrire dans :\n%s",
["main.update_done_title"] = "VOID mis à jour vers v%s",
["main.update_done_msg"] = "VOID a été mis à jour avec succès.\n\nLe nouveau script a été enregistré sous :\nvoid_v%s.lua\n\nExécutez-le depuis GameGuardian pour appliquer la mise à jour.",
["main.launching_version"] = "Lancement de v%s...",
["main.launch_failed_msg"] = "Téléchargé mais impossible à exécuter :\n%s",

["main.multiple_spaces_title"] = "Espaces multiples détectés",
["main.multiple_spaces_desc"] = "HCR2 a été trouvé dans %d espaces virtuels.\nSélectionnez l'espace dans lequel vous jouez actuellement.",
["main.select_space_toast"] = "Veuillez sélectionner un espace pour continuer.",
["main.user_space_item"] = "Utilisateur %s  —  %s",
["main.permission_error_title"] = "Erreur de permission",
["main.permission_error_msg"] = "L'accès au shell a été refusé.\n\nVoid en a besoin pour localiser HCR2 dans votre espace virtuel. Vérifiez le code source de Void si vous voulez vérifier quelle commande est exécutée.",
["main.hcr2_not_found_title"] = "Données HCR2 introuvables",
["main.hcr2_not_found_msg"] = "Void n'a pas pu localiser les données HCR2 dans votre espace virtuel. Cela peut arriver si HCR2 n'a pas encore été lancé, ou si votre application d'espace virtuel utilise une structure de chemin inhabituelle.\n\nLes fonctionnalités qui reposent sur les fichiers du jeu (Récompenses d'événements, etc.) ne fonctionneront pas sans un chemin valide.",
["main.manual_data_path_title"] = "Chemin des données manuel",
["main.manual_data_path_hint"] = "Entrez le chemin des données HCR2",
["main.manual_path_cancelled"] = "Annulé — poursuite sans chemin.",
["main.waiting_for_lib"] = "Attente de %s...",
["main.initialized"] = "Initialisé",
["main.gamestatus_not_found"] = "GameStatus introuvable",
["main.dont_interrupt"] = "N'interrompez pas ce script",

-- ── ui/ui.lua (framework chrome: menu, cards, dialogs) ────────────────────────
["ui.size_saved_restart"] = "Taille enregistrée ! Redémarrez le script",
["ui.category_error"] = "Erreur : %s",
["ui.category_not_found"] = "Catégorie introuvable",
["ui.na"] = "N/D",
["ui.spinner_select"] = "Sélectionner",
["ui.slider_default_title"] = "Valeur",
["ui.loading"] = "Chargement",

-- ── core/engines/patches.lua (addArchModule patch engine) ────────────────────
["patches.requires_arch"] = "Nécessite un appareil %s (votre appareil : %s)",
["patches.suffix_enabled"] = " Activé",
["patches.suffix_disabled"] = " Désactivé",
["patches.pattern_not_found"] = "Échec : %d motif(s) introuvable(s)",

-- ── core/engines/arch.lua (architecture detection warnings) ──────────────────
["arch.warning_title"] = "Avertissement d'architecture",
["arch.unknown_arch_msg"] = "Votre architecture est inconnue. La bibliothèque est-elle chargée ? Quel système utilisez-vous ?",
["arch.non_primary_arch_msg"] = "Détecté : %s\nCertains ou tous les correctifs de bibliothèque peuvent ne pas fonctionner.",
["arch.unknown_version_msg"] = "Version du jeu inconnue. Réessayez après le chargement du jeu.",
["arch.no_base_data_msg"] = "Erreur interne : aucune donnée de base disponible pour cette architecture.",

-- ── core/engines/scheduler.lua ────────────────────────────────────────────────
["scheduler.task_crashed"] = "Avertissement du planificateur : La tâche a crashé -> %s",

-- ── core/utils/paste.lua + catbox.lua (network error strings) ────────────────
["errors.http_error_code"] = "Code d'erreur HTTP : %s",
["errors.crashed"] = "Crashé : %s",
["errors.url_missing"] = "Le paramètre URL est manquant ou vide",
["errors.file_path_missing"] = "Le chemin du fichier est manquant",
["errors.download_url_missing"] = "L'URL est manquante",
["errors.dest_path_missing"] = "Le chemin de destination est manquant",

-- ── modules/registry.lua (sidebar tab labels + module-load error cards) ──────
["tabs.sep_game"] = "MENU JEU",
["tabs.account"] = "MENU COMPTE",
["tabs.vehicle"] = "MENU VÉHICULE",
["tabs.player"] = "MENU JOUEUR",
["tabs.adventure"] = "MENU AVENTURE",
["tabs.cups"] = "MENU COUPES",
["tabs.team"] = "MENU ÉQUIPE",
["tabs.event"] = "MENU ÉVÉNEMENT",
["tabs.creative"] = "MENU CRÉATIF",
["tabs.shop"] = "MENU BOUTIQUE",
["tabs.other"] = "MENU AUTRE",
["tabs.sep_script"] = "MENU SCRIPT",
["tabs.settings"] = "PARAMÈTRES",
["tabs.about"] = "À PROPOS",

["registry.module_load_failed"] = "Le module n'a pas pu être chargé. Vérifiez les journaux pour plus de détails.",
["registry.module_runtime_error"] = "Erreur d'exécution : %s",
["registry.error"] = "Erreur",

-- ── modules/tabs/settings.lua ─────────────────────────────────────────────────
["settings.section_updates"] = "Mises à jour",
["settings.auto_update.title"] = "Mise à jour automatique",
["settings.auto_update.desc"] = "Mettre à jour VOID automatiquement au démarrage",
["settings.dev_mode_title"] = "Mode développeur",
["settings.auto_update.dev_mode_msg"] = "La mise à jour automatique est désactivée pour main.lua (version de développement).",
["settings.check_updates.title"] = "Vérifier les mises à jour",
["settings.check_updates.desc"] = "Vérifier la dernière version de VOID sur GitHub",
["settings.check_updates.dev_mode_msg"] = "La vérification des mises à jour est désactivée pour main.lua (version de développement).\n\nTirez manuellement depuis le dépôt.",
["settings.check_updates.checking"] = "Vérification des mises à jour...",
["settings.check_updates.failed_title"] = "Échec de la vérification",
["settings.check_updates.failed_msg"] = "Impossible de contacter GitHub :\n%s",
["settings.check_updates.up_to_date_title"] = "À jour",
["settings.check_updates.up_to_date_msg"] = "Vous êtes déjà sur la dernière version (v%s).",
["settings.check_updates.no_changelog"] = "Aucun journal des modifications disponible.",
["settings.check_updates.available_msg"] = "v%s  (actuelle : v%s)\n\n%s\n\nTélécharger et remplacer ce script ?",
["settings.check_updates.no_asset_msg"] = "Aucun fichier .lua trouvé dans la version.",
["settings.check_updates.download_failed_title"] = "Échec du téléchargement",
["settings.check_updates.write_failed_title"] = "Échec de l'écriture",
["settings.check_updates.done_title"] = "Terminé",
["settings.check_updates.done_msg"] = "Mis à jour vers v%s. Redémarrez le script pour appliquer.",
["settings.check_updates.restart_button"] = "Redémarrer",

["settings.section_language"] = "Langue",
["settings.language.title"] = "Langue",
["settings.language.desc"] = "Choisissez votre langue préférée pour le menu",
["settings.language.changed"] = "Langue définie sur %s",
["settings.language.failed"] = "Échec du chargement de cette langue",
["settings.language.restart_msg"] = "Redémarrez le script pour appliquer complètement la langue",

["settings.region.other"] = "A : Autre",
["settings.region.cpp_alloc"] = "Ca : alloc C++",
["settings.region.unknown"] = "I : Inconnu",
["settings.section_memory"] = "Mémoire",
["settings.memory_range.title"] = "Plage mémoire",
["settings.memory_range.desc"] = "Plage mémoire actuellement sélectionnée\n(choisie automatiquement par le script)",
["settings.gamestatus.title"] = "GameStatus",
["settings.gamestatus.desc"] = "Adresse GameStatus actuelle\n(choisie automatiquement par le script)",
["settings.gamestatus_raw.title"] = "GameStatus (Brut)",
["settings.gamestatus_raw.desc"] = "Adresse GameStatus (brute) actuelle\n(choisie automatiquement par le script)",
["settings.clear_memory.title"] = "Effacer la mémoire sauvegardée",
["settings.clear_memory.desc"] = "Effacer toute la mémoire sauvegardée par VOID sans avoir à redémarrer le jeu.",

["settings.section_ui_customizations"] = "Personnalisation de l'interface",
["settings.theme_store.title"] = "Magasin de thèmes",
["settings.theme_store.desc"] = "Parcourir et installer les thèmes Void de la communauté",
["settings.theme_store.unreachable_msg"] = "Impossible d'atteindre le magasin de thèmes :\n%s",
["settings.theme_store.parse_failed_msg"] = "Impossible d'analyser les données du magasin de thèmes.",
["settings.theme_store.list_title"] = "Magasin de thèmes Void",
["settings.theme_store.search_results_desc"] = "Résultats de recherche : %s trouvé(s)",
["settings.theme_store.available_desc"] = "%s thèmes disponibles",
["settings.theme_store.by_author"] = "par %s",
["settings.theme_store.search_item"] = "🔍 Rechercher...",
["settings.theme_store.clear_search_item"] = "✕ Effacer la recherche",
["settings.theme_store.search_title"] = "Rechercher des thèmes",
["settings.theme_store.search_hint"] = "Nom du thème, auteur ou description",
["settings.theme_store.no_results"] = "Aucun thème trouvé pour : %s",
["settings.theme_store.detail_msg"] = "Par %s\n\n%s\n\nID : %s",
["settings.theme_store.install_button"] = "Installer le thème",
["settings.theme_downloading_bg"] = "Téléchargement de l'image de fond...",
["settings.theme_imported"] = "Thème importé !",
["settings.theme_invalid_bundle"] = "Format de bundle invalide.",
["settings.theme_cloud_error"] = "Erreur cloud : %s",
["settings.reset_theme.title"] = "Réinitialiser le thème",
["settings.reset_theme.desc"] = "Réinitialiser le thème personnalisé et l'image de fond par défaut",
["settings.import_theme.title"] = "Importer un thème",
["settings.import_theme.desc"] = "Importer un thème personnalisé depuis le cloud",
["settings.import_theme.hint"] = "Entrez l'ID de partage",
["settings.export_theme.title"] = "Exporter un thème",
["settings.export_theme.desc"] = "Exporter un thème personnalisé et l'image de fond vers le cloud",
["settings.export_theme.share_id_msg"] = "ID de partage : %s\n\nCopié dans le presse-papiers.",
["settings.export_theme.upload_failed_msg"] = "Échec du téléversement : %s",
["settings.export_theme.size_warning_title"] = "Avertissement sur la taille du téléversement",
["settings.export_theme.size_warning_msg"] = "Inclure l'image de fond personnalisée ? Cela augmentera la taille du téléversement en fonction de la taille de votre image.",
["settings.export_theme.uploading_bg"] = "Téléversement de l'image de fond vers Catbox...",
["settings.export_theme.image_upload_failed_title"] = "Erreur",
["settings.export_theme.image_upload_failed_msg"] = "Échec du téléversement de l'image : %s",
["settings.tabs_icon.title"] = "Icône des onglets",
["settings.tabs_icon.desc"] = "Changer l'icône des onglets",
["settings.tabs_icon.hint"] = "Entrez l'icône",
["settings.tabs_icon.empty_error"] = "Ne peut pas être vide",

["settings.bg_opacity.title"] = "Opacité du fond",
["settings.bg_opacity.desc"] = "Transparence des panneaux, cartes et en-tête",
["settings.slider.alpha"] = "Alpha",
["settings.bg_image_opacity.title"] = "Opacité de l'image de fond",
["settings.bg_image_opacity.desc"] = "Ajuster directement les paramètres alpha de visibilité en utilisant des canaux entiers purs.",
["settings.bg_image_picker.title"] = "Image de fond",
["settings.bg_image_picker.desc"] = "Appuyez pour modifier le chemin absolu du fichier de votre image de fond personnalisée",
["settings.bg_image_picker.path_label"] = "Chemin absolu du fichier image (.jpg ou .png) :",
["settings.bg_image_picker.remove_label"] = "Supprimer l'image de fond",
["settings.bg_image_picker.success_title"] = "Succès",
["settings.bg_image_picker.removed_msg"] = "Image de fond supprimée",
["settings.bg_image_picker.added_msg"] = "Image de fond ajoutée",
["settings.bg_image_picker.not_found_msg"] = "Fichier introuvable ou opération de lecture refusée :\n%s",

["settings.bg_rgb.title"] = "RGB du fond",
["settings.bg_rgb.desc"] = "Teinte pour les fonds de panneau (l'en-tête et la carte s'adaptent automatiquement)",
["settings.slider.r"] = "R",
["settings.slider.g"] = "G",
["settings.slider.b"] = "B",
["settings.accent_rgb.title"] = "RGB d'accent",
["settings.accent_rgb.desc"] = "Teinte pour les boutons, les bascules et les cartes actives (couleur atténuée dérivée automatiquement)",
["settings.logo_rgb.title"] = "RGB de surbrillance",
["settings.logo_rgb.desc"] = "Couleur pour les étiquettes, les icônes et le texte interactif (toujours complètement opaque)",
["settings.sub_rgb.title"] = "RGB du sous-texte",
["settings.sub_rgb.desc"] = "Couleur pour les descriptions et les étiquettes d'onglets inactifs",
["settings.text_rgb.title"] = "RGB du texte",
["settings.text_rgb.desc"] = "Couleur pour le texte du menu principal",

["settings.win_width.title"] = "Largeur du menu",
["settings.win_width.desc"] = "Largeur du menu flottant (%d – %d dp)",
["settings.slider.width"] = "Largeur",
["settings.win_height.title"] = "Hauteur du menu",
["settings.win_height.desc"] = "Hauteur de la zone de contenu défilable (%d – %d dp)",
["settings.slider.height"] = "Hauteur",

-- ── modules/tabs/about.lua ────────────────────────────────────────────────────
["about.about_script.title"] = "À propos du script",
["about.about_script.desc"] = "Un script de manipulation de mémoire puissant et hautement optimisé construit pour Hill Climb Racing 2 sur l'environnement Pivot personnalisé.\n\nTélécharger Pivot :\nhttps://github.com/vekendianorg/pivot/releases/",
["about.script_owner.title"] = "Propriétaire du script",
["about.script_owner.desc"] = "- Vekendian Organization (github: vekendianorg)",
["about.script_dev.title"] = "Développeur du script",
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],
["about.script_translator.title"] = "Traducteur du script",
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
]],
["about.credits.title"] = "Crédits",
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
- Profinoobru
]],
["about.special_thanks.title"] = "Remerciements spéciaux",
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

-- ── modules/tabs/other.lua ────────────────────────────────────────────────────
["other.debug_mode.title"] = "Mode débogage",
["other.debug_mode.desc"] = "Activer/désactiver le mode débogage dans le jeu",
["other.debug_mode.enabled"] = "Mode débogage activé",
["other.debug_mode.disabled"] = "Mode débogage désactivé",
["other.hint.width"] = "Largeur",
["other.hint.height"] = "Hauteur",
["other.resolution.title"] = "Ajuster la résolution",
["other.resolution.desc"] = "Ajuster la largeur et la hauteur du jeu (par défaut 1280x720)",
["other.resolution.applied"] = "Résolution définie sur %dx%d",
["other.resolution_offset.title"] = "Ajuster le décalage de résolution",
["other.resolution_offset.desc"] = "Ajuster le décalage de largeur et de hauteur du jeu (par défaut 0x0), idéal pour une petite résolution sur un grand écran.",
["other.resolution_offset.applied"] = "Décalage de résolution défini sur %dx%d",
["other.glsurface_not_found"] = "GLSurfaceView introuvable",

-- ── modules/tabs/shop.lua ─────────────────────────────────────────────────────
["shop.free_chest.title"] = "Coffre gratuit",
["shop.free_chest.desc"] = "Rendre les coffres gratuits dans l'onglet Boutique",
["shop.free_chest.enabled"] = "Coffre gratuit activé",
["shop.free_chest.disabled"] = "Coffre gratuit désactivé",
["shop.free_purchases.title"] = "Achats gratuits",
["shop.free_purchases.desc"] = "Rendre certaines offres quotidiennes gratuites dans l'onglet Boutique (fonctionne également pour les offres spéciales sous forme de popups/badges)",
["shop.free_purchases.progress"] = "%d/%d",
["shop.free_purchases.success"] = "Achat gratuit réussi",
["shop.change_chest.title"] = "Changer de coffre",
["shop.change_chest.desc"] = "Changer le coffre légendaire en le coffre sélectionné",
["shop.change_chest.changed"] = "Coffre changé en %s",
["shop.change_chest.options"] = {
    "Coffre commun", "Coffre peu commun", "Coffre rare", "Coffre épique",
    "Coffre champion", "Coffre spécial 1", "Coffre de Noël", "Coffre légendaire",
    "Coffre bleu", "Coffre VIP 1", "Coffre VIP 2", "Coffre vidéo",
    "Coffre de départ", "Coffre spécial 2", "Coffre Fingersoft", "Méga coffre",
    "Coffre d'esprit d'équipe", "Coffre de style", "Coffre mythique"
},

-- ── modules/tabs/player.lua ───────────────────────────────────────────────────
["player.auto_detach.title"] = "Détachement automatique",
["player.auto_detach.desc"] = "Détacher automatiquement des pièces comme le toit de la Rally Car",
["player.auto_die.title"] = "Mort automatique",
["player.auto_die.desc"] = "Provoquer automatiquement la mort (panne de carburant)",
["player.no_clip.title"] = "No-Clip",
["player.no_clip.desc"] = "Faire passer votre joueur à travers les objets sans mourir (vous pouvez passer au-dessus des lignes d'arrivée dans les coupes)",
["player.no_clip.enabled"] = "No-Clip activé",
["player.no_clip.disabled"] = "No-Clip désactivé",
["player.hide_name.title"] = "Masquer le nom",
["player.hide_name.desc"] = "Masquer votre nom de joueur en course",
["player.hide_name.enabled"] = "Masquage du nom activé",
["player.hide_name.disabled"] = "Masquage du nom désactivé",
["player.hide_flag.title"] = "Masquer le drapeau",
["player.hide_flag.desc"] = "Masquer votre drapeau de joueur en course",
["player.hide_flag.enabled"] = "Masquage du drapeau activé",
["player.hide_flag.disabled"] = "Masquage du drapeau désactivé",
["player.fuel.title"] = "Carburant",
["player.fuel.desc"] = "Verrouiller le carburant à une valeur constante pendant la course (0.0 – 100.0)",
["player.fuel.prompt_amount"] = "Quantité de carburant (0 – 100)",
["player.fuel.prompt_reset"] = "Réinitialiser",
["player.fuel.invalid"] = "Valeur invalide, doit être comprise entre 0 et 100",
["player.fuel.applied"] = "Carburant verrouillé à %s",
["player.fuel.reset"] = "Carburant restauré",
["player.fuel.not_applied"] = "Carburant inactif",
["player.zoom.title"] = "Ajuster le zoom",
["player.zoom.desc"] = "Ajuster la proximité ou l'éloignement de votre caméra",
["player.slider.min"] = "Min",
["player.slider.max"] = "Max",
["player.gravity.title"] = "Ajuster la gravité",
["player.gravity.desc"] = "Ajuster la force de la gravité",
["player.slider.x"] = "X",
["player.slider.y"] = "Y",

-- ── modules/tabs/adventure.lua ────────────────────────────────────────────────
["adventure.auto_adventure_chests.title"] = "Coffres d'aventure automatiques (instable)",
["adventure.auto_adventure_chests.desc"] = "Augmenter automatiquement le niveau de vos coffres d'aventure",
["adventure.auto_adventure_chests.none_found"] = "Aucun coffre d'aventure trouvé",
["adventure.auto_adventure_chests.done"] = "Terminé",

["adventure.set_distance.title"] = "Définir la distance",
["adventure.set_distance.desc"] = "Définit la distance de votre course d'aventure à une valeur personnalisée. Doit être dans une course active. Une distance plus élevée peut rapporter plus d'étoiles. Maximum d'étoiles à 5000m. (Pas une fonction de téléportation)",
["adventure.set_distance.loop_active_title"] = "Définir la distance — Boucle active",
["adventure.set_distance.loop_active_msg"] = "La boucle de distance est actuellement en cours d'exécution.\nQue voulez-vous faire ?",
["adventure.set_distance.stop_loop"] = "Arrêter la boucle",
["adventure.set_distance.keep_running"] = "Continuer",
["adventure.set_distance.loop_will_stop"] = "La boucle s'arrêtera après la période en cours.",
["adventure.set_distance.prompt_target"] = "Distance cible (mètres)",
["adventure.set_distance.prompt_loop"] = "Boucle (réapplication automatique)",
["adventure.set_distance.prompt_interval"] = "Intervalle de boucle (ms, min 250)",
["adventure.set_distance.over_max_title"] = "Avertissement de distance",
["adventure.set_distance.over_max_msg"] = "Une distance supérieure à 5000m ne vous donnera aucune étoile.\n\nLa course enregistrera toujours la distance, mais aucune récompense d'étoile ne sera donnée. Continuer ?",
["adventure.set_distance.continue_button"] = "Continuer",
["adventure.set_distance.not_in_adventure"] = "Allez dans l'onglet Aventure et commencez d'abord une course",
["adventure.set_distance.start_race_first"] = "Commencez une course d'abord",
["adventure.set_distance.applied"] = "Distance définie : %sm",
["adventure.set_distance.loop_stopped"] = "Boucle de définition de distance arrêtée.",
["adventure.set_distance.loop_running"] = "Boucle de distance en cours — appuyez sur Définir la distance pour arrêter",
["adventure.set_distance.loop_warn_title"] = "Avertissement de boucle de distance",
["adventure.set_distance.loop_warn_msg"] = "Le mode boucle écrit dans la mémoire toutes les %s ms.\n\nUtiliser un intervalle court peut augmenter l'instabilité, les problèmes visuels ou les crashs du jeu.\n\nContinuer quand même ?",

-- ── modules/tabs/cups.lua ─────────────────────────────────────────────────────
["cups.adjust_countdown.title"] = "Ajuster le compte à rebours",
["cups.adjust_countdown.desc"] = "Ajuster le compte à rebours avant le début de la course",
["cups.slider.seconds"] = "Secondes",
["cups.adjust_countdown.applied"] = "Compte à rebours ajusté à %ss",
["cups.auto_win.title"] = "Victoire automatique",
["cups.auto_win.desc"] = "Gagnez automatiquement quel que soit le résultat de votre course",
["cups.force_boss.title"] = "Forcer le boss",
["cups.force_boss.desc"] = "Forcer l'apparition du boss",
["cups.force_cup.title"] = "Forcer la coupe",
["cups.force_cup.desc"] = "Force une seule coupe",
["cups.force_cup.not_found"] = "Force Cup introuvable. Réessayez plus tard.",
["cups.force_cup.enabled"] = "Force Cup activé",
["cups.force_cup.disabled"] = "Force Cup désactivé",
["cups.set_time.title"] = "Définir le temps",
["cups.set_time.desc"] = "Définir votre temps de course (ne gèlera pas le temps pour des raisons de sécurité). Doit être dans une course de coupe active. (ex. 1:09.069, 7.284)",
["cups.set_time.hint"] = "Temps (1:09.069 ou 7.284)",
["cups.set_time.invalid_format"] = "Format invalide. Utilisez 1:09.069 ou 7.284",
["cups.set_time.no_negative"] = "Pas de valeurs négatives",
["cups.set_time.not_in_cup"] = "Allez dans l'onglet Coupes et commencez d'abord une course",
["cups.set_time.start_race_first"] = "Commencez une course d'abord",
["cups.set_time.applied"] = "Temps défini sur %s",
["cups.unlimited_tasks.title"] = "Tâches illimitées",
["cups.unlimited_tasks.desc"] = "Geler toutes les tâches comme terminées et toujours réclamables. Réclamez les récompenses plusieurs fois.",
["cups.unlimited_tasks.resolve_failed"] = "Échec de la résolution de la liste des tâches",
["cups.unlimited_tasks.none_found"] = "Aucune tâche trouvée",
["cups.unlimited_tasks.enabled"] = "Tâches illimitées activées",
["cups.unlimited_tasks.disabled"] = "Tâches illimitées désactivées",
["cups.unlimited_tasks.none_to_freeze"] = "Aucune tâche à geler",
["cups.rank_points_bonus.title"] = "+498 Points de classement",
["cups.rank_points_bonus.desc"] = "Faire en sorte que toutes les tâches de ligue vous donnent 498 points au lieu de 200, et supprime les autres récompenses.",
["cups.rank_points_bonus.none_found"] = "Aucune tâche de ligue trouvée",
["cups.rank_points_bonus.boosted"] = "Points de classement boostés : %s",
["cups.rank_points_bonus.no_match"] = "Aucune tâche de ligue correspondante trouvée",
["cups.rank_points_bonus.nothing_to_restore"] = "Rien à restaurer",
["cups.rank_points_bonus.restored"] = "Restauré : %s",

-- ── modules/tabs/event.lua ────────────────────────────────────────────────────
["event.patch_rewards.title"] = "Correctif des récompenses d'événement",
["event.patch_rewards.desc"] = "Appliquer le correctif des récompenses de l'événement public actuel avec celui fourni par VOID (nécessite un redémarrage du jeu)",
["event.restore_events.title"] = "Restaurer les récompenses d'événement",
["event.restore_events.desc"] = "Supprimer les JSON d'événements modifiés pour forcer la récupération du serveur de jeu (nécessite un redémarrage du jeu)",

["event.checking_permissions"] = "Vérification des permissions de l'environnement...",
["event.scanning_files"] = "Analyse des fichiers actifs...",
["event.decode_rewards_failed"] = "Échec du décodage du JSON des récompenses",
["event.workspace_creation_failed"] = "FATAL : Échec de la création de l'espace de travail : %s",
["event.workspace_creation_failed_dialog"] = "FATAL : Impossible de créer le répertoire de l'espace de travail.\n%s",
["event.file_inaccessible"] = "Fichier inaccessible au chemin : %s",
["event.predecrypt_not_found"] = "Pré-décryptage : source introuvable : %s",
["event.predecrypt_empty"] = "Pré-décryptage : la source est vide (0 octets) : %s",
["event.decode_active_failed"] = "Échec du décodage de active_events.json au chemin : %s",
["event.no_active_events"] = "Aucun événement actif trouvé au chemin : %s",
["event.cannot_open_active"] = "Impossible d'ouvrir active_events.json au chemin : %s",
["event.decrypt_active_failed"] = "Échec du décryptage de active_events.json au chemin : %s",
["event.root_copy_failed"] = "Échec de la copie root : %s",

["event.select_events_patch"] = "Sélectionnez les événements à corriger :\nChemin : %s",
["event.user_cancelled"] = "L'utilisateur a annulé la sélection pour le chemin : %s",
["event.rewards_unavailable"] = "Récompenses intégrées non disponibles, correction ignorée pour le chemin : %s",
["event.skipped_unreadable"] = "Événement illisible ignoré : %s",
["event.predecrypt_event_not_found"] = "Pré-décryptage : événement introuvable : %s",
["event.predecrypt_event_empty"] = "Pré-décryptage : l'événement est vide (0 octets) : %s",
["event.processing_failed"] = "Échec du traitement de %s : %s",
["event.cannot_open_decrypted"] = "Impossible d'ouvrir le fichier décrypté : %s",
["event.decrypt_event_failed"] = "Échec du décryptage de l'événement : %s",
["event.loop_crash"] = "Crash de la boucle de traitement critique des fichiers : %s",

["event.success_header"] = "Avec succès :",
["event.success_removed_header"] = "Supprimé avec succès (sera restauré au redémarrage) :",
["event.success_item"] = "- %s",
["event.success_item_json"] = "- %s.json",
["event.failed_header"] = "Échec :",
["event.failed_item"] = "- %s",

["event.patch_results_title"] = "Résultats du correctif",
["event.restore_results_title"] = "Résultats de la restauration",
["event.restart_required_title"] = "Redémarrage requis",
["event.patch_restart_msg"] = "Le jeu est fermé et ce script va quitter, relancez-le pour voir les effets du correctif",
["event.restore_restart_msg"] = "Le jeu va maintenant se fermer pour permettre la synchronisation des fichiers du serveur.",
["event.finishing_tasks_patch"] = "Fin des tâches en arrière-plan en attente... Veuillez patienter.",
["event.finishing_tasks_restore"] = "Fin des tâches en arrière-plan en attente...",
["event.patch_failed_msg"] = "Échec du correctif, réessayez.",

["event.select_events_restore"] = "Sélectionnez les fichiers à restaurer (supprimer) :\nChemin : %s",
["event.delete_failed"] = "Échec de la suppression de %s : %s",

-- ── modules/tabs/account.lua ──────────────────────────────────────────────────
["account.change_name.title"] = "Changer le nom",
["account.change_name.desc"] = "Changer le nom de votre joueur",
["account.change_name.hint"] = "Entrez le nom",
["account.change_name.empty"] = "Entrez d'abord un nom",
["account.change_name.too_long_title"] = "Nom trop long",
["account.change_name.too_long_msg"] = "Votre nom est trop long, veuillez le raccourcir",
["account.change_name.resolve_failed"] = "Échec de la résolution du pointeur de nom",
["account.change_name.applied"] = "Nom changé en %s",

["account.change_gp.title"] = "Changer la puissance du garage",
["account.change_gp.desc"] = "Modifie la puissance du garage du profil (persiste si plus élevée). Mettez à 8 pour réinitialiser si au-dessus du maximum, mais seulement si votre GP réel est déjà fixé sous la limite.",
["account.change_gp.hint"] = "Entrez la puissance du garage",
["account.change_gp.max_int_title"] = "Maximum 32 bits atteint",
["account.change_gp.lower_value"] = "Veuillez réduire votre valeur",
["account.change_gp.too_low_title"] = "Trop bas",
["account.change_gp.higher_value"] = "Veuillez augmenter votre valeur",
["account.change_gp.applied"] = "La puissance du garage a été changée en %s",

["account.fake_unlock.title"] = "Déverrouillage factice",
["account.fake_unlock.desc"] = "Déverrouiller toutes les personnalisations temporairement",
["account.fake_vip.title"] = "VIP factice",
["account.fake_vip.desc"] = "Basculer l'état de l'abonnement VIP localement",

["account.fake_rank.title"] = "Classement factice",
["account.fake_rank.desc"] = "Définir votre classement sur légendaire factice automatiquement",
["account.fake_rank.race_warn_title"] = "Course requise",
["account.fake_rank.race_warn_msg"] = "Le classement factice ne doit être appliqué que pendant qu'une course de coupe est active.\n\nL'appliquer en dehors d'une course peut entraîner un bannissement caché.\n\nAssurez-vous d'être déjà dans une course de coupe avant de continuer.\n\nContinuer quand même ?",
["account.fake_rank.continue_button"] = "Continuer",

-- ── modules/tabs/vehicle.lua ──────────────────────────────────────────────────
["vehicle.parts_slot.title"] = "Ajuster l'emplacement des pièces",
["vehicle.parts_slot.desc"] = "Ajuster l'emplacement des pièces pour tous les véhicules",
["vehicle.parts_slot.slider_title"] = "Emplacements",
["vehicle.parts_slot.no_vehicles"] = "Aucun véhicule trouvé",
["vehicle.parts_slot.applied"] = "Emplacement des pièces ajusté : %d véhicules",

["vehicle.parts_modifier.title"] = "Modificateur de pièces",
["vehicle.parts_modifier.desc"] = "Modifier les niveaux des pièces de réglage en course active",
["vehicle.parts_modifier.select"] = "Sélectionnez une pièce",
["vehicle.parts_modifier.prompt_level"] = "Niveau : ",
["vehicle.parts_modifier.prompt_digit0"] = "Chiffre : ",
["vehicle.parts_modifier.prompt_digit1"] = "Queue : ",
["vehicle.parts_modifier.prompt_reset"] = "Réinitialiser",
["vehicle.parts_modifier.invalid"] = "Niveau invalide",
["vehicle.parts_modifier.not_found"] = "Pièce introuvable en mémoire",
["vehicle.parts_modifier.applied"] = "%s défini au niveau %s",
["vehicle.parts_modifier.reset"] = "%s réinitialisé",

["vehicle.unlock_vehicles.title"] = "Déverrouiller les véhicules",
["vehicle.unlock_vehicles.desc"] = "Déverrouiller tous les véhicules pour les acheter avec des pièces",
["vehicle.unlock_vehicles.no_vehicles"] = "Aucun véhicule trouvé",
["vehicle.unlock_vehicles.unlocked"] = "Véhicules déverrouillés : %d",
["vehicle.unlock_vehicles.none_to_unlock"] = "Aucun véhicule à déverrouiller",

["vehicle.max_vehicles.title"] = "Véhicules max",
["vehicle.max_vehicles.desc"] = "Maximiser instantanément les niveaux de mise à niveau de tous les véhicules déverrouillés",
["vehicle.max_vehicles.no_vehicles"] = "Échec de la résolution de la liste des véhicules",
["vehicle.max_vehicles.all_maxed"] = "Tous les véhicules maximisés",
["vehicle.max_vehicles.failed"] = "Échec de la maximisation des véhicules",

["vehicle.max_mastery.title"] = "Maîtrise max",
["vehicle.max_mastery.desc"] = "Maximiser instantanément les maîtrises de tous les véhicules déverrouillés et maximisés.",
["vehicle.max_mastery.all_maxed"] = "Toutes les maîtrises maximisées",
["vehicle.max_mastery.failed"] = "Échec de la maximisation des maîtrises",

["vehicle.max_parts.title"] = "Pièces max",
["vehicle.max_parts.desc"] = "Maximiser instantanément les niveaux de toutes les pièces déverrouillées pour tous les véhicules.",
["vehicle.max_parts.no_vehicles"] = "Échec de la résolution de la liste des véhicules",
["vehicle.max_parts.all_maxed"] = "Toutes les pièces maximisées",
["vehicle.max_parts.failed"] = "Échec de la maximisation des pièces",

["vehicle.common.no_vehicles"] = "Aucun véhicule trouvé",
["vehicle.common.progress"] = "%d/%d",
["vehicle.common.resolve_list_failed"] = "Échec de la résolution de la liste des véhicules",
["vehicle.common.no_zero_region"] = "Aucune région zéro trouvée",

}
