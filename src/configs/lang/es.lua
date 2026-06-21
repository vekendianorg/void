--[[
  configs/lang/es.lua — Spanish

  Flat table of dotted keys -> strings, loaded by core/utils/lang.lua.
  Looked up at runtime via the global T(key, ...) function, e.g.:
      T("common.ok")                          -> "Aceptar"
      T("settings.window_width_desc", 400, "Ancho del menú flotante (400 - 650 dp)"

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

  This file handles the Spanish localization for the VOID script.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "Aceptar",
["common.cancel"] = "Cancelar",
["common.yes"] = "Sí",
["common.no"] = "No",
["common.failed"] = "Falló",
["common.success"] = "Éxito",
["common.later"] = "Más tarde",
["common.got_it"] = "Entendido",
["common.retry"] = "Reintentar",
["common.wait_safe"] = "Esperar (Seguro)",
["common.waiting"] = "Esperando...",
["common.force_exit"] = "Forzar Salida",
["common.proceed_anyway"] = "Continuar de todos modos",
["common.manual_mode"] = "Modo Manual",
["common.update_button"] = "ACTUALIZAR",
["common.launch_failed"] = "Error al Iniciar",
["common.confirm_exit_title"] = "Confirmar Salida",
["common.confirm_exit_msg"] = "¿Salir del script?",
["common.not_available"] = "No Disponible",
["common.warning"] = "Advertencia",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "Advertencia: Operaciones Activas",
["main.exit_active_ops_msg"] = "Hay %d tarea(s) en segundo plano ejecutándose.\nForzar la salida puede corromper el estado del juego.",
["main.initializing"] = "Inicializando...",
["main.no_app_found"] = "No se encontró la aplicación",
["main.arch_64bit_required_title"] = "Se requiere 64-bit",
["main.arch_64bit_required_msg"] = "ARMv8a es obligatorio. x86_64 tiene soporte parcial.",

["main.update_available_title"] = "Actualización Disponible",
["main.update_available_msg"] = "v%s está disponible (actual: v%s)\n\n%s\n\n¿Actualizar ahora?",
["main.no_changelog"] = "No hay registro de cambios.",
["main.downloading_version"] = "Descargando v%s...",
["main.update_download_failed_msg"] = "No se pudo descargar la actualización:\n%s",
["main.update_write_failed_msg"] = "No se pudo escribir en:\n%s",
["main.update_done_title"] = "VOID Actualizado a v%s",
["main.update_done_msg"] = "VOID se ha actualizado correctamente.\n\nEl nuevo script se guardó como:\nvoid_v%s.lua\n\nEjecútalo desde GameGuardian para aplicar la actualización.",
["main.launching_version"] = "Iniciando v%s...",
["main.launch_failed_msg"] = "Se descargó pero no se pudo ejecutar:\n%s",

["main.multiple_spaces_title"] = "Múltiples Espacios Detectados",
["main.multiple_spaces_desc"] = "Se encontró HCR2 en %d espacios virtuales.\nSelecciona el espacio en el que estás jugando actualmente.",
["main.select_space_toast"] = "Por favor selecciona un espacio para continuar.",
["main.user_space_item"] = "Usuario %s  —  %s",
["main.permission_error_title"] = "Error de Permisos",
["main.permission_error_msg"] = "Se denegó el acceso Shell.\n\nVoid lo necesita para localizar HCR2 en tu espacio virtual. Revisa el código fuente de Void si quieres verificar qué comando se ejecuta.",
["main.hcr2_not_found_title"] = "Datos de HCR2 No Encontrados",
["main.hcr2_not_found_msg"] = "Void no pudo localizar los datos de HCR2 en tu espacio virtual. Esto puede ocurrir si HCR2 no se ha iniciado aún, o si tu app de espacio virtual usa una estructura de rutas inusual.\n\nLas funciones que dependen de archivos del juego (Recompensas de Eventos, etc.) no funcionarán sin una ruta válida.",
["main.manual_data_path_title"] = "Ruta de Datos Manual",
["main.manual_data_path_hint"] = "Ingresa la ruta de datos de HCR2",
["main.manual_path_cancelled"] = "Cancelado — continuando sin ruta.",
["main.waiting_for_lib"] = "Esperando %s...",
["main.initialized"] = "Inicializado",
["main.gamestatus_not_found"] = "GameStatus No Encontrado",
["main.dont_interrupt"] = "No interrumpas este script",

-- ── ui/ui.lua (framework chrome: menu, cards, dialogs) ────────────────────────
["ui.size_saved_restart"] = "¡Tamaño guardado! Reinicia el script",
["ui.category_error"] = "Error: %s",
["ui.category_not_found"] = "Categoría No Encontrada",
["ui.na"] = "N/A",
["ui.spinner_select"] = "Seleccionar",
["ui.slider_default_title"] = "Valor",

-- ── core/engines/patches.lua ─────────────────────────────────────────────────
["patches.requires_arch"] = "Requiere dispositivo %s (tu dispositivo: %s)",
["patches.suffix_enabled"] = " Activado",
["patches.suffix_disabled"] = " Desactivado",
["patches.pattern_not_found"] = "Falló: %d patrón(es) no encontrado(s)",

-- ── core/engines/arch.lua ────────────────────────────────────────────────────
["arch.warning_title"] = "Advertencia de Arquitectura",
["arch.unknown_arch_msg"] = "Tu arquitectura es desconocida. ¿Está la librería cargada? ¿Qué sistema estás usando?",
["arch.non_primary_arch_msg"] = "Detectado: %s\nAlgunos o todos los parches de librería pueden no funcionar.",
["arch.unknown_version_msg"] = "Versión del juego desconocida. Inténtalo de nuevo después de que cargue el juego.",
["arch.no_base_data_msg"] = "Error interno: no hay datos base disponibles para esta arquitectura.",

-- ── core/engines/scheduler.lua ────────────────────────────────────────────────
["scheduler.task_crashed"] = "Advertencia del Planificador: La tarea falló -> %s",

-- ── core/utils/paste.lua + catbox.lua ────────────────────────────────────────
["errors.http_error_code"] = "Código de Error HTTP: %s",
["errors.crashed"] = "Falló: %s",
["errors.url_missing"] = "El parámetro URL falta o está vacío",
["errors.file_path_missing"] = "Falta la ruta del archivo",
["errors.download_url_missing"] = "Falta la URL",
["errors.dest_path_missing"] = "Falta la ruta de destino",

-- ── modules/registry.lua ─────────────────────────────────────────────────────
["tabs.sep_game"] = "MENÚ DEL JUEGO",
["tabs.account"] = "MENÚ DE CUENTA",
["tabs.vehicle"] = "MENÚ DE VEHÍCULOS",
["tabs.player"] = "MENÚ DEL JUGADOR",
["tabs.adventure"] = "MENÚ DE AVENTURA",
["tabs.cups"] = "MENÚ DE COPAS",
["tabs.team"] = "MENÚ DE EQUIPO",
["tabs.event"] = "MENÚ DE EVENTOS",
["tabs.creative"] = "MENÚ CREATIVO",
["tabs.shop"] = "MENÚ DE TIENDA",
["tabs.other"] = "OTROS MENÚS",
["tabs.sep_script"] = "MENÚ DEL SCRIPT",
["tabs.settings"] = "AJUSTES",
["tabs.about"] = "ACERCA DE",

["registry.module_load_failed"] = "El módulo no se pudo cargar. Revisa los logs para más detalles.",
["registry.module_runtime_error"] = "Error en tiempo de ejecución: %s",
["registry.error"] = "Error",

-- ── modules/tabs/settings.lua (part 1) ───────────────────────────────────────
["settings.section_updates"] = "Actualizaciones",
["settings.auto_update.title"] = "Actualización Automática",
["settings.auto_update.desc"] = "Actualizar VOID automáticamente al iniciar",
["settings.dev_mode_title"] = "Modo Desarrollador",
["settings.auto_update.dev_mode_msg"] = "La actualización automática está desactivada para main.lua (versión de desarrollo).",
["settings.check_updates.title"] = "Buscar Actualización",
["settings.check_updates.desc"] = "Buscar la última versión de VOID en GitHub",
["settings.check_updates.dev_mode_msg"] = "La búsqueda de actualizaciones está desactivada para main.lua (versión de desarrollo).\n\nActualiza manualmente desde el repositorio.",
["settings.check_updates.checking"] = "Buscando actualizaciones...",
["settings.check_updates.failed_title"] = "Error al Buscar Actualización",
["settings.check_updates.failed_msg"] = "No se pudo conectar con GitHub:\n%s",
["settings.check_updates.up_to_date_title"] = "Estás al día",
["settings.check_updates.up_to_date_msg"] = "Ya tienes la versión más reciente (v%s).",
["settings.check_updates.no_changelog"] = "No hay registro de cambios disponible.",
["settings.check_updates.available_msg"] = "v%s  (actual: v%s)\n\n%s\n\n¿Descargar y reemplazar este script?",
["settings.check_updates.no_asset_msg"] = "No se encontró un archivo .lua en la versión.",
["settings.check_updates.download_failed_title"] = "Descarga Fallida",
["settings.check_updates.write_failed_title"] = "Error al Escribir",
["settings.check_updates.done_title"] = "Listo",
["settings.check_updates.done_msg"] = "Actualizado a v%s. Reinicia el script para aplicar los cambios.",
["settings.check_updates.restart_button"] = "Reiniciar",

["settings.section_language"] = "Idioma",
["settings.language.title"] = "Idioma",
["settings.language.desc"] = "Elige tu idioma preferido para el menú",
["settings.language.changed"] = "Idioma establecido a %s",
["settings.language.failed"] = "Error al cargar ese idioma",
["settings.language.restart_msg"] = "Reinicia el script para aplicar completamente el idioma",

["settings.region.other"] = "O: Otro",
["settings.region.cpp_alloc"] = "Ca: C++ alloc",
["settings.region.unknown"] = "U: Desconocido",
["settings.section_memory"] = "Memoria",
["settings.memory_range.title"] = "Rango de Memoria",
["settings.memory_range.desc"] = "Rango de memoria seleccionado actualmente\n(elegido automáticamente por el script)",
["settings.gamestatus.title"] = "GameStatus",
["settings.gamestatus.desc"] = "Dirección actual de gamestatus\n(elegida automáticamente por el script)",
["settings.gamestatus_raw.title"] = "GameStatus (Raw)",
["settings.gamestatus_raw.desc"] = "Dirección actual de gamestatus (raw)\n(elegida automáticamente por el script)",
["settings.clear_memory.title"] = "Limpiar Memoria Guardada",
["settings.clear_memory.desc"] = "Limpiar toda la memoria guardada de VOID sin necesidad de reiniciar el juego completo.",
-- ── modules/tabs/settings.lua (continuation) ─────────────────────────────────
["settings.section_ui_customizations"] = "Personalización de la Interfaz",
["settings.theme_store.title"] = "Tienda de Temas",
["settings.theme_store.desc"] = "Explorar e instalar temas comunitarios de Void",
["settings.theme_store.unreachable_msg"] = "No se pudo acceder a la tienda de temas:\n%s",
["settings.theme_store.parse_failed_msg"] = "No se pudo analizar los datos de la tienda de temas.",
["settings.theme_store.list_title"] = "Tienda de Temas Void",
["settings.theme_store.search_results_desc"] = "Resultados de búsqueda: %s encontrados",
["settings.theme_store.available_desc"] = "%s temas disponibles",
["settings.theme_store.by_author"] = "por %s",
["settings.theme_store.search_item"] = "🔍 Buscar...",
["settings.theme_store.clear_search_item"] = "✕ Limpiar búsqueda",
["settings.theme_store.search_title"] = "Buscar Temas",
["settings.theme_store.search_hint"] = "Nombre del tema, autor o descripción",
["settings.theme_store.no_results"] = "No se encontraron temas para: %s",
["settings.theme_store.detail_msg"] = "Por %s\n\n%s\n\nID: %s",
["settings.theme_store.install_button"] = "Instalar Tema",
["settings.theme_downloading_bg"] = "Descargando imagen de fondo...",
["settings.theme_imported"] = "¡Tema importado!",
["settings.theme_invalid_bundle"] = "Formato de paquete inválido.",
["settings.theme_cloud_error"] = "Error de nube: %s",
["settings.reset_theme.title"] = "Restablecer Tema",
["settings.reset_theme.desc"] = "Restablecer tema personalizado e imagen de fondo al predeterminado",
["settings.import_theme.title"] = "Importar Tema",
["settings.import_theme.desc"] = "Importar tema personalizado desde la nube",
["settings.import_theme.hint"] = "Ingresa el Share ID",
["settings.export_theme.title"] = "Exportar Tema",
["settings.export_theme.desc"] = "Exportar tema personalizado e imagen de fondo a la nube",
["settings.export_theme.share_id_msg"] = "Share ID: %s\n\nCopiado al portapapeles.",
["settings.export_theme.upload_failed_msg"] = "Error al subir: %s",
["settings.export_theme.size_warning_title"] = "Advertencia de Tamaño de Subida",
["settings.export_theme.size_warning_msg"] = "¿Incluir imagen de fondo personalizada? Aumentará el tamaño de subida según el tamaño de tu imagen.",
["settings.export_theme.uploading_bg"] = "Subiendo imagen de fondo a Catbox...",
["settings.export_theme.image_upload_failed_title"] = "Error",
["settings.export_theme.image_upload_failed_msg"] = "Error al subir la imagen: %s",
["settings.tabs_icon.title"] = "Icono de Pestañas",
["settings.tabs_icon.desc"] = "Cambiar icono de pestañas",
["settings.tabs_icon.hint"] = "Ingresa Icono",
["settings.tabs_icon.empty_error"] = "No puede estar vacío",

["settings.bg_opacity.title"] = "Opacidad del Fondo",
["settings.bg_opacity.desc"] = "Transparencia de paneles, tarjetas y encabezado",
["settings.slider.alpha"] = "Alpha",
["settings.bg_image_opacity.title"] = "Opacidad de Imagen de Fondo",
["settings.bg_image_opacity.desc"] = "Ajustar visibilidad alpha directamente usando canales enteros puros.",
["settings.bg_image_picker.title"] = "Imagen de Fondo",
["settings.bg_image_picker.desc"] = "Toca para modificar la ruta absoluta del archivo de imagen de fondo personalizada",
["settings.bg_image_picker.path_label"] = "Ruta Absoluta del Archivo de Imagen (.jpg o .png):",
["settings.bg_image_picker.remove_label"] = "Eliminar Imagen de Fondo",
["settings.bg_image_picker.success_title"] = "Éxito",
["settings.bg_image_picker.removed_msg"] = "Imagen de Fondo Eliminada",
["settings.bg_image_picker.added_msg"] = "Imagen de fondo añadida",
["settings.bg_image_picker.not_found_msg"] = "Archivo no encontrado o operación de lectura denegada:\n%s",

["settings.bg_rgb.title"] = "RGB de Fondo",
["settings.bg_rgb.desc"] = "Tono para fondos de paneles (Encabezado y Tarjetas se escalan automáticamente)",
["settings.slider.r"] = "R",
["settings.slider.g"] = "G",
["settings.slider.b"] = "B",
["settings.accent_rgb.title"] = "RGB de Acento",
["settings.accent_rgb.desc"] = "Tinte para botones, interruptores y tarjetas activas (color atenuado derivado automáticamente)",
["settings.logo_rgb.title"] = "RGB de Resaltado",
["settings.logo_rgb.desc"] = "Color para etiquetas, iconos y texto interactivo (siempre completamente opaco)",
["settings.sub_rgb.title"] = "RGB de Sub-texto",
["settings.sub_rgb.desc"] = "Color para descripciones y etiquetas de pestañas inactivas",
["settings.text_rgb.title"] = "RGB de Texto",
["settings.text_rgb.desc"] = "Color para el texto principal del menú",

["settings.win_width.title"] = "Ancho del Menú",
["settings.win_width.desc"] = "Ancho del menú flotante (%d – %d dp)",
["settings.slider.width"] = "Ancho",
["settings.win_height.title"] = "Alto del Menú",
["settings.win_height.desc"] = "Alto del área de contenido desplazable (%d – %d dp)",
["settings.slider.height"] = "Alto",

-- ── modules/tabs/about.lua ────────────────────────────────────────────────────
["about.about_script.title"] = "Acerca del Script",
["about.about_script.desc"] = "Un script de manipulación de memoria potente y altamente optimizado para Hill Climb Racing 2 en el entorno Pivot personalizado.\n\nDescarga Pivot:\nhttps://github.com/vekendianorg/pivot/releases/",
["about.script_owner.title"] = "Propietario del Script",
["about.script_owner.desc"] = "- Vekendian Organization (github: vekendianorg)",
["about.script_dev.title"] = "Desarrolladores del Script",
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],
["about.script_translator.title"] = "Traductor del Script",
["about.script_translator.desc"] = [[
- English: Lazor (github: lazor-git)
- Bahasa Indonesia: Lazor (github: lazor-git)
- Español: Jayy2k (github: Jayy2k)
- Deutsch: Erik (github: eomthix)
- Thai: NaiArt777 (github: artphakkapol-hub)
]],
["about.credits.title"] = "Créditos",
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
]],
["about.special_thanks.title"] = "Agradecimientos Especiales",
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

-- ── modules/tabs/other.lua ────────────────────────────────────────────────────
["other.debug_mode.title"] = "Modo Depuración",
["other.debug_mode.desc"] = "Activar/desactivar el modo de depuración en el juego",
["other.debug_mode.enabled"] = "Modo Depuración Activado",
["other.debug_mode.disabled"] = "Modo Depuración Desactivado",
["other.hint.width"] = "Ancho",
["other.hint.height"] = "Alto",
["other.resolution.title"] = "Ajustar Resolución",
["other.resolution.desc"] = "Ajustar el ancho y alto del juego (predeterminado es 1280x720)",
["other.resolution.applied"] = "Resolución establecida en %dx%d",
["other.resolution_offset.title"] = "Ajustar Desplazamiento de Resolución",
["other.resolution_offset.desc"] = "Ajustar el desplazamiento de ancho y alto del juego (predeterminado 0x0), ideal para resoluciones pequeñas en pantallas grandes.",
["other.resolution_offset.applied"] = "Desplazamiento de resolución establecido en %dx%d",
["other.glsurface_not_found"] = "GLSurfaceView no encontrado",

-- ── modules/tabs/shop.lua ─────────────────────────────────────────────────────
["shop.free_chest.title"] = "Cofre Gratis",
["shop.free_chest.desc"] = "Hacer gratuitos los cofres en la pestaña de Tienda",
["shop.free_chest.enabled"] = "Cofre Gratis Activado",
["shop.free_chest.disabled"] = "Cofre Gratis Desactivado",
["shop.free_purchases.title"] = "Compras Gratis",
["shop.free_purchases.desc"] = "Hacer gratuitas algunas compras diarias en la pestaña de Tienda (también funciona para ofertas especiales como popups/insignias)",
["shop.free_purchases.progress"] = "%d/%d",
["shop.free_purchases.success"] = "Compra Gratis Exitosa",
["shop.change_chest.title"] = "Cambiar Cofre",
["shop.change_chest.desc"] = "Cambiar cofre legendario al cofre seleccionado",
["shop.change_chest.changed"] = "Cofre cambiado a %s",
["shop.change_chest.options"] = {
    "Cofre Común", "Cofre Poco Común", "Cofre Raro", "Cofre Épico",
    "Cofre Campeón", "Cofre Especial 1", "Cofre Navidad", "Cofre Legendario",
    "Cofre Azul", "Cofre VIP 1", "Cofre VIP 2", "Cofre de Video",
    "Cofre Inicial", "Cofre Especial 2", "Cofre Fingersoft", "Cofre Mega",
    "Cofre Espíritu de Equipo", "Cofre Estilo", "Cofre Mítico"
},

-- ── modules/tabs/player.lua ───────────────────────────────────────────────────
["player.auto_detach.title"] = "Desprender Automáticamente",
["player.auto_detach.desc"] = "Desprender automáticamente partes como el techo del Rally Car",
["player.no_clip.title"] = "No-Clip",
["player.no_clip.desc"] = "Hacer que tu jugador atraviese objetos sin morir (Puedes pasar las líneas de meta en copas)",
["player.no_clip.enabled"] = "No-Clip Activado",
["player.no_clip.disabled"] = "No-Clip Desactivado",
["player.hide_name.title"] = "Ocultar Nombre",
["player.hide_name.desc"] = "Ocultar el nombre de tu jugador en la carrera",
["player.hide_name.enabled"] = "Ocultar Nombre Activado",
["player.hide_name.disabled"] = "Ocultar Nombre Desactivado",
["player.hide_flag.title"] = "Ocultar Bandera",
["player.hide_flag.desc"] = "Ocultar la bandera de tu jugador en la carrera",
["player.hide_flag.enabled"] = "Ocultar Bandera Activada",
["player.hide_flag.disabled"] = "Ocultar Bandera Desactivada",
["player.zoom.title"] = "Ajustar Zoom",
["player.zoom.desc"] = "Ajustar qué tan cerca o lejos está la cámara",
["player.slider.min"] = "Mín",
["player.slider.max"] = "Máx",
["player.gravity.title"] = "Ajustar Gravedad",
["player.gravity.desc"] = "Ajustar la fuerza de la gravedad",
["player.slider.x"] = "X",
["player.slider.y"] = "Y",

-- ── modules/tabs/adventure.lua ────────────────────────────────────────────────
["adventure.auto_adventure_chests.title"] = "Cofres de Aventura Automáticos (inestable)",
["adventure.auto_adventure_chests.desc"] = "Subir automáticamente de nivel tus cofres de aventura",
["adventure.auto_adventure_chests.none_found"] = "No se encontraron cofres de aventura",
["adventure.auto_adventure_chests.done"] = "Listo",

["adventure.set_distance.title"] = "Establecer Distancia",
["adventure.set_distance.desc"] = "Establece la distancia de tu carrera de Aventura a un valor personalizado. Debe estar en una carrera activa. Mayor distancia puede dar más estrellas. Máx estrellas a 5000m. (No es una función de teletransporte)",
["adventure.set_distance.loop_active_title"] = "Establecer Distancia — Bucle Activo",
["adventure.set_distance.loop_active_msg"] = "El bucle de distancia está en ejecución.\n¿Qué quieres hacer?",
["adventure.set_distance.stop_loop"] = "Detener Bucle",
["adventure.set_distance.keep_running"] = "Mantener Ejecutando",
["adventure.set_distance.loop_will_stop"] = "El bucle se detendrá después del tick actual.",
["adventure.set_distance.prompt_target"] = "Distancia objetivo (metros)",
["adventure.set_distance.prompt_loop"] = "Bucle (re-aplicar automáticamente)",
["adventure.set_distance.prompt_interval"] = "Intervalo del bucle (ms, mín 250)",
["adventure.set_distance.over_max_title"] = "Advertencia de Distancia",
["adventure.set_distance.over_max_msg"] = "La distancia mayor a 5000m no te dará estrellas.\n\nLa carrera registrará la distancia, pero no se darán recompensas de estrellas. ¿Continuar?",
["adventure.set_distance.continue_button"] = "Continuar",
["adventure.set_distance.not_in_adventure"] = "Ve a la pestaña Aventura e inicia una carrera primero",
["adventure.set_distance.start_race_first"] = "Inicia una carrera primero",
["adventure.set_distance.applied"] = "Distancia establecida: %sm",
["adventure.set_distance.loop_stopped"] = "Bucle de Establecer Distancia detenido.",
["adventure.set_distance.loop_running"] = "Bucle de distancia en ejecución — toca Establecer Distancia para detener",

-- ── modules/tabs/cups.lua ─────────────────────────────────────────────────────
["cups.adjust_countdown.title"] = "Ajustar Cuenta Atrás",
["cups.adjust_countdown.desc"] = "Ajustar la cuenta atrás antes de iniciar la carrera",
["cups.slider.seconds"] = "Segundos",
["cups.adjust_countdown.applied"] = "Cuenta atrás ajustada a %ss",
["cups.auto_win.title"] = "Victoria Automática",
["cups.auto_win.desc"] = "Ganar automáticamente sin importar tus resultados de carrera",
["cups.force_boss.title"] = "Forzar Jefe",
["cups.force_boss.desc"] = "Forzar que el jefe siempre aparezca",
["cups.force_cup.title"] = "Forzar Copa",
["cups.force_cup.desc"] = "Forzar una sola copa",
["cups.force_cup.not_found"] = "Copa forzada no encontrada. Inténtalo más tarde.",
["cups.force_cup.enabled"] = "Forzar Copa Activado",
["cups.force_cup.disabled"] = "Forzar Copa Desactivado",
["cups.unlimited_tasks.title"] = "Tareas Ilimitadas",
["cups.unlimited_tasks.desc"] = "Congelar todas las tareas como completadas y siempre reclamables. Reclama recompensas repetidamente.",
["cups.unlimited_tasks.resolve_failed"] = "Error al resolver lista de tareas",
["cups.unlimited_tasks.none_found"] = "No se encontraron tareas",
["cups.unlimited_tasks.enabled"] = "Tareas Ilimitadas Activadas",
["cups.unlimited_tasks.disabled"] = "Tareas Ilimitadas Desactivadas",
["cups.unlimited_tasks.none_to_freeze"] = "No hay tareas para congelar",
["cups.rank_points_bonus.title"] = "+498 Puntos de Rango",
["cups.rank_points_bonus.desc"] = "Hacer que todas las tareas de liga den 498 puntos en lugar de 200, y eliminar otras recompensas.",
["cups.rank_points_bonus.none_found"] = "No se encontraron tareas de liga",
["cups.rank_points_bonus.boosted"] = "Puntos de rango aumentados: %s",
["cups.rank_points_bonus.no_match"] = "No se encontraron tareas de liga coincidentes",
["cups.rank_points_bonus.nothing_to_restore"] = "Nada que restaurar",
["cups.rank_points_bonus.restored"] = "Restaurado: %s",

-- ── modules/tabs/event.lua ────────────────────────────────────────────────────
["event.patch_rewards.title"] = "Parche de Recompensas de Evento",
["event.patch_rewards.desc"] = "Parchear las recompensas del evento público actual a las personalizadas proporcionadas por VOID (requiere reiniciar el juego)",
["event.restore_events.title"] = "Restaurar Recompensas de Evento",
["event.restore_events.desc"] = "Eliminar JSONs de eventos modificados para forzar la recuperación del servidor del juego (requiere reiniciar el juego)",

["event.checking_permissions"] = "Verificando permisos del entorno...",
["event.scanning_files"] = "Escaneando archivos activos...",
["event.decode_rewards_failed"] = "Error al decodificar JSON de recompensas",
["event.workspace_creation_failed"] = "FATAL: Error al crear espacio de trabajo: %s",
["event.workspace_creation_failed_dialog"] = "FATAL: No se pudo crear el directorio de espacio de trabajo.\n%s",
["event.file_inaccessible"] = "Archivo inaccesible en la ruta: %s",
["event.predecrypt_not_found"] = "Pre-desencriptar: fuente no encontrada: %s",
["event.predecrypt_empty"] = "Pre-desencriptar: fuente vacía (0 bytes): %s",
["event.decode_active_failed"] = "Error al decodificar active_events.json en la ruta: %s",
["event.no_active_events"] = "No se encontraron eventos activos en la ruta: %s",
["event.cannot_open_active"] = "No se puede abrir active_events.json en la ruta: %s",
["event.decrypt_active_failed"] = "Error al desencriptar active_events.json en la ruta: %s",
["event.root_copy_failed"] = "Error al copiar con root: %s",

["event.select_events_patch"] = "Seleccionar eventos para parchear:\nRuta: %s",
["event.user_cancelled"] = "Usuario canceló la selección para la ruta: %s",
["event.rewards_unavailable"] = "Recompensas embebidas no disponibles, saltando parches para la ruta: %s",
["event.skipped_unreadable"] = "Evento ilegible saltado: %s",
["event.predecrypt_event_not_found"] = "Pre-desencriptar: evento no encontrado: %s",
["event.predecrypt_event_empty"] = "Pre-desencriptar: evento vacío (0 bytes): %s",
["event.processing_failed"] = "Error al procesar %s: %s",
["event.cannot_open_decrypted"] = "No se puede abrir el archivo desencriptado: %s",
["event.decrypt_event_failed"] = "Error al desencriptar evento: %s",
["event.loop_crash"] = "Error crítico en el bucle de procesamiento de archivos: %s",

["event.success_header"] = "Éxito:",
["event.success_removed_header"] = "Eliminado Exitosamente (Se Restaurará al Reiniciar):",
["event.success_item"] = "- %s",
["event.success_item_json"] = "- %s.json",
["event.failed_header"] = "Fallido:",
["event.failed_item"] = "- %s",

["event.patch_results_title"] = "Resultados del Parche",
["event.restore_results_title"] = "Resultados de Restauración",
["event.restart_required_title"] = "Reinicio Requerido",
["event.patch_restart_msg"] = "El juego se cerrará y este script saldrá. Inícialo de nuevo para ver los efectos del parche.",
["event.restore_restart_msg"] = "El juego se cerrará ahora para permitir la sincronización de archivos del servidor.",
["event.finishing_tasks_patch"] = "Finalizando tareas pendientes en segundo plano... Por favor espera.",
["event.finishing_tasks_restore"] = "Finalizando tareas pendientes en segundo plano...",
["event.patch_failed_msg"] = "Error al parchear, inténtalo de nuevo.",

["event.select_events_restore"] = "Seleccionar archivos para restaurar (eliminar):\nRuta: %s",
["event.delete_failed"] = "Error al eliminar %s: %s",

-- ── modules/tabs/account.lua ──────────────────────────────────────────────────
["account.change_name.title"] = "Cambiar Nombre",
["account.change_name.desc"] = "Cambiar el nombre de tu jugador",
["account.change_name.hint"] = "Ingresa Nombre",
["account.change_name.empty"] = "Ingresa un nombre primero",
["account.change_name.too_long_title"] = "Nombre Demasiado Largo",
["account.change_name.too_long_msg"] = "Tu nombre es demasiado largo, por favor acórtalo",
["account.change_name.resolve_failed"] = "Error al resolver puntero de nombre",
["account.change_name.applied"] = "Nombre cambiado a %s",

["account.change_gp.title"] = "Cambiar Potencia de Garaje",
["account.change_gp.desc"] = "Cambia la potencia de garaje del perfil (persiste si es mayor). Pon 8 para restablecer si está por encima del máximo, solo si tu GP real ya está fijado por debajo del límite.",
["account.change_gp.hint"] = "Ingresa Potencia de Garaje",
["account.change_gp.max_int_title"] = "Máximo entero de 32 bits Alcanzado",
["account.change_gp.lower_value"] = "Por favor baja tu valor",
["account.change_gp.too_low_title"] = "Demasiado Bajo",
["account.change_gp.higher_value"] = "Por favor sube tu valor",
["account.change_gp.applied"] = "Potencia de Garaje cambiada a %s",

["account.fake_unlock.title"] = "Desbloqueo Falso",
["account.fake_unlock.desc"] = "Desbloquear todas las personalizaciones temporalmente",
["account.fake_vip.title"] = "VIP Falso",
["account.fake_vip.desc"] = "Cambiar el estado de suscripción VIP localmente",
["account.fake_rank.title"] = "Rango Falso",
["account.fake_rank.desc"] = "Establecer tu rango a legendario falso automáticamente",
["account.fake_rank.applied"] = "Rango Falso inyectado.",

-- ── modules/tabs/vehicle.lua ──────────────────────────────────────────────────
["vehicle.parts_slot.title"] = "Ajustar Ranura de Partes",
["vehicle.parts_slot.desc"] = "Ajustar la ranura de partes para todos los vehículos",
["vehicle.parts_slot.slider_title"] = "Ranuras",
["vehicle.parts_slot.no_vehicles"] = "No se encontraron vehículos",
["vehicle.parts_slot.applied"] = "Ranura de partes ajustada: %d vehículos",

["vehicle.unlock_vehicles.title"] = "Desbloquear Vehículos",
["vehicle.unlock_vehicles.desc"] = "Desbloquear todos los vehículos para que estén disponibles para comprar con monedas",
["vehicle.unlock_vehicles.no_vehicles"] = "No se encontraron vehículos",
["vehicle.unlock_vehicles.unlocked"] = "Vehículos desbloqueados: %d",
["vehicle.unlock_vehicles.none_to_unlock"] = "No hay vehículos para desbloquear",

["vehicle.max_vehicles.title"] = "Máx Vehículos",
["vehicle.max_vehicles.desc"] = "Maximizar instantáneamente todos los niveles de mejora de vehículos desbloqueados",
["vehicle.max_vehicles.no_vehicles"] = "Error al resolver lista de vehículos",
["vehicle.max_vehicles.all_maxed"] = "Todos los vehículos maximizados",
["vehicle.max_vehicles.failed"] = "Error al maximizar vehículos",

["vehicle.max_mastery.title"] = "Máx Maestría",
["vehicle.max_mastery.desc"] = "Maximizar instantáneamente todas las maestrías de vehículos desbloqueados y maximizados.",
["vehicle.max_mastery.all_maxed"] = "Todas las maestrías maximizadas",
["vehicle.max_mastery.failed"] = "Error al maximizar maestrías",

["vehicle.max_parts.title"] = "Máx Partes",
["vehicle.max_parts.desc"] = "Maximizar instantáneamente todos los niveles de partes desbloqueadas para todos los vehículos.",
["vehicle.max_parts.no_vehicles"] = "Error al resolver lista de vehículos",
["vehicle.max_parts.all_maxed"] = "Todas las partes maximizadas",
["vehicle.max_parts.failed"] = "Error al maximizar partes",

["vehicle.common.no_vehicles"] = "No se encontraron vehículos",
["vehicle.common.progress"] = "%d/%d",
["vehicle.common.resolve_list_failed"] = "Error al resolver lista de vehículos",
["vehicle.common.no_zero_region"] = "No se encontró región cero",

}
