--[[
  configs/lang/ru.lua — Русский 

  Flat table of dotted keys -> strings, loaded by core/utils/lang.lua.
  Looked up at runtime via the global T(key, ...) function, e.g.:
      T("common.ok")                          -> "OK"
      T("settings.window_width_desc", 400, 650) -> "Width of the floating menu (400 - 650 dp)"

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

    This file handles the Русский localization for the VOID script.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "OK",
["common.cancel"] = "Отмена",
["common.yes"] = "Да",
["common.no"] = "Нет",
["common.failed"] = "Ошибка",
["common.success"] = "Обработано",
["common.later"] = "Позже",
["common.got_it"] = "Получить это",
["common.retry"] = "Повторить",
["common.wait_safe"] = "Подождать (Безопаснее)",
["common.waiting"] = "Подождите...",
["common.force_exit"] = "Принудительный выход",
["common.proceed_anyway"] = "Всё равно начать",
["common.manual_mode"] = "Ручной режим",
["common.update_button"] = "Обновление",
["common.launch_failed"] = "Запуск не удался",
["common.confirm_exit_title"] = "Подтвердить выход",
["common.confirm_exit_msg"] = "Закрыть скрипт?",
["common.not_available"] = "Недоступен",
["common.warning"] = "ПРЕДУПРЕЖДЕНИЕ",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "Внимание: активные операции",
["main.exit_active_ops_msg"] = "Сейчас выполняется фоновых задач: %d.\nПринудительный выход может повредить состояние игры.",
["main.initializing"] = "Инициализация...",
["main.no_app_found"] = "Приложение не обнаружено",
["main.arch_64bit_required_title"] = "64-bit необходимо",
["main.arch_64bit_required_msg"] = "ARMv8a обязательна. x86_64 поддерживается частично.",

["main.update_available_title"] = "Доступно обновление!",
["main.update_available_msg"] = "v%s is available (current: v%s)\n\n%s\n\nОбновить сейчас?",
["main.no_changelog"] = "Список изменений отсутствует.",
["main.downloading_version"] = "Загружаем v%s...",
["main.update_download_failed_msg"] = "Не удалось скачать обновление:\n%s",
["main.update_write_failed_msg"] = "Не удалось записать в:\n%s",
["main.update_done_title"] = "VOID обновлён до v%s",
["main.update_done_msg"] = "VOID успешно обновлён.\n\nНовый скрипт сохранён как:\nvoid_v%s.lua\n\nЗапусти его через GameGuardian, чтобы применить обновление.",
["main.launching_version"] = "Запуск v%s...",
["main.launch_failed_msg"] = "Загружено, но не удалось запустить:\n%s",

["main.multiple_spaces_title"] = "Обнаружено несколько пространств",
["main.multiple_spaces_desc"] = "HCR2 найден в %d виртуальных пространствах.\nВыбери то, в котором сейчас играешь.",
["main.select_space_toast"] = "Выбери пространство, чтобы продолжить.",
["main.user_space_item"] = "Пользователь %s  —  %s",
["main.permission_error_title"] = "Ошибка доступа",
["main.permission_error_msg"] = "В доступе к Shell отказано.\n\nVoid нужен этот доступ, чтобы найти HCR2 в твоём виртуальном пространстве. Можешь проверить исходный код Void, чтобы убедиться, какая команда выполняется.",
["main.hcr2_not_found_title"] = "Данные HCR2 не найдены",
["main.hcr2_not_found_msg"] = "Void не смог найти данные HCR2 в твоём виртуальном пространстве. Это может произойти, если HCR2 ещё не запускался, либо твоё приложение для виртуального пространства использует нестандартную структуру путей.\n\nФункции, зависящие от файлов игры (Event Rewards и т.д.), не будут работать без корректного пути.",
["main.manual_data_path_title"] = "Путь к данным вручную",
["main.manual_data_path_hint"] = "Введи путь к данным HCR2",
["main.manual_path_cancelled"] = "Отменено — продолжаем без пути.",
["main.waiting_for_lib"] = "Ожидание %s...",
["main.initialized"] = "Инициализировано",
["main.gamestatus_not_found"] = "GameStatus не найден",
["main.dont_interrupt"] = "Не прерывай работу скрипта",

-- ── ui/ui.lua (framework chrome: menu, cards, dialogs) ────────────────────────
["ui.size_saved_restart"] = "Размер сохранён! Перезапусти скрипт",
["ui.category_error"] = "Ошибка: %s",
["ui.category_not_found"] = "Категория не найдена",
["ui.na"] = "N/A",
["ui.spinner_select"] = "Выбрать",
["ui.slider_default_title"] = "Значение",

-- ── core/engines/patches.lua (addArchModule patch engine) ────────────────────
["patches.requires_arch"] = "Требуется устройство %s (твоё устройство: %s)",
["patches.suffix_enabled"] = " включено",
["patches.suffix_disabled"] = " выключено",
["patches.pattern_not_found"] = "Ошибка: не найдено паттернов: %d",

-- ── core/engines/arch.lua (architecture detection warnings) ──────────────────
["arch.warning_title"] = "Предупреждение об архитектуре",
["arch.unknown_arch_msg"] = "Архитектура неизвестна. Библиотека загружена? Какая у тебя система?",
["arch.non_primary_arch_msg"] = "Обнаружено: %s\nНекоторые или все lib-патчи могут не работать.",
["arch.unknown_version_msg"] = "Версия игры неизвестна. Попробуй снова после загрузки игры.",
["arch.no_base_data_msg"] = "Внутренняя ошибка: нет базовых данных для этой архитектуры.",

-- ── core/engines/scheduler.lua ────────────────────────────────────────────────
["scheduler.task_crashed"] = "Предупреждение планировщика: задача упала -> %s",

-- ── core/utils/paste.lua + catbox.lua (network error strings) ────────────────
["errors.http_error_code"] = "Код HTTP-ошибки: %s",
["errors.crashed"] = "Сбой: %s",
["errors.url_missing"] = "Параметр URL отсутствует или пуст",
["errors.file_path_missing"] = "Путь к файлу отсутствует",
["errors.download_url_missing"] = "URL отсутствует",
["errors.dest_path_missing"] = "Путь назначения отсутствует",

-- ── modules/registry.lua (sidebar tab labels + module-load error cards) ──────
["tabs.sep_game"] = "ИГРОВОЕ МЕНЮ",
["tabs.account"] = "МЕНЮ АККАУНТА",
["tabs.vehicle"] = "МЕНЮ МАШИН",
["tabs.player"] = "МЕНЮ ИГРОКА",
["tabs.adventure"] = "МЕНЮ ПРИКЛЮЧЕНИЙ",
["tabs.cups"] = "МЕНЮ КУБКОВ",
["tabs.team"] = "МЕНЮ КОМАНДЫ",
["tabs.event"] = "МЕНЮ ИВЕНТОВ",
["tabs.creative"] = "МЕНЮ ТВОРЧЕСТВА",
["tabs.shop"] = "МЕНЮ МАГАЗИНА",
["tabs.other"] = "ДРУГОЕ МЕНЮ",
["tabs.sep_script"] = "МЕНЮ СКРИПТА",
["tabs.settings"] = "НАСТРОЙКИ",
["tabs.about"] = "О СКРИПТЕ",

["registry.module_load_failed"] = "Не удалось загрузить модуль. Подробности в логах.",
["registry.module_runtime_error"] = "Ошибка выполнения: %s",
["registry.error"] = "Ошибка",

-- ── modules/tabs/settings.lua ─────────────────────────────────────────────────
["settings.section_updates"] = "Updates",
["settings.auto_update.title"] = "Автообновление",
["settings.auto_update.desc"] = "Автоматически обновлять VOID при запуске",
["settings.dev_mode_title"] = "Режим разработчика",
["settings.auto_update.dev_mode_msg"] = "Автообновление отключено для main.lua (dev-сборка).",
["settings.check_updates.title"] = "Проверить обновления",
["settings.check_updates.desc"] = "Проверить наличие новой версии VOID на GitHub",
["settings.check_updates.dev_mode_msg"] = "Проверка обновлений отключена для main.lua (dev-сборка).\n\nОбновляй вручную через репозиторий.",
["settings.check_updates.checking"] = "Проверка обновлений...",
["settings.check_updates.failed_title"] = "Ошибка проверки обновлений",
["settings.check_updates.failed_msg"] = "Не удалось подключиться к GitHub:\n%s",
["settings.check_updates.up_to_date_title"] = "Установлена последняя версия",
["settings.check_updates.up_to_date_msg"] = "У тебя уже установлена последняя версия (v%s).",
["settings.check_updates.no_changelog"] = "Список изменений недоступен.",
["settings.check_updates.available_msg"] = "v%s  (текущая: v%s)\n\n%s\n\nСкачать и заменить этот скрипт?",
["settings.check_updates.no_asset_msg"] = "В релизе не найден файл .lua.",
["settings.check_updates.download_failed_title"] = "Ошибка загрузки",
["settings.check_updates.write_failed_title"] = "Ошибка записи",
["settings.check_updates.done_title"] = "Готово",
["settings.check_updates.done_msg"] = "Обновлено до v%s. Перезапусти скрипт, чтобы применить.",
["settings.check_updates.restart_button"] = "Перезапустить",

["settings.section_language"] = "Язык",
["settings.language.title"] = "Язык",
["settings.language.desc"] = "Выбери предпочитаемый язык меню",
["settings.language.changed"] = "Язык изменён на %s",
["settings.language.failed"] = "Не удалось загрузить этот язык",
["settings.language.restart_msg"] = "Перезапусти скрипт, чтобы язык применился полностью",

["settings.region.other"] = "O: Другое",
["settings.region.cpp_alloc"] = "Ca: выделение C++",
["settings.region.unknown"] = "U: Неизвестно",
["settings.section_memory"] = "Память",
["settings.memory_range.title"] = "Диапазон памяти",
["settings.memory_range.desc"] = "Текущий выбранный диапазон памяти\n(выбирается скриптом автоматически)",
["settings.gamestatus.title"] = "GameStatus",
["settings.gamestatus.desc"] = "Текущий адрес gamestatus\n(выбирается скриптом автоматически)",
["settings.gamestatus_raw.title"] = "GameStatus (Raw)",
["settings.gamestatus_raw.desc"] = "Текущий адрес gamestatus (raw)\n(выбирается скриптом автоматически)",
["settings.clear_memory.title"] = "Очистить сохранённую память",
["settings.clear_memory.desc"] = "Очищает всю сохранённую память VOID без необходимости перезапускать игру целиком.",

["settings.section_ui_customizations"] = "Настройка интерфейса",
["settings.theme_store.title"] = "Магазин тем",
["settings.theme_store.desc"] = "Просмотр и установка тем Void от сообщества",
["settings.theme_store.unreachable_msg"] = "Не удалось подключиться к магазину тем:\n%s",
["settings.theme_store.parse_failed_msg"] = "Не удалось обработать данные магазина тем.",
["settings.theme_store.list_title"] = "Магазин тем Void",
["settings.theme_store.search_results_desc"] = "Результаты поиска: найдено %s",
["settings.theme_store.available_desc"] = "Доступно тем: %s",
["settings.theme_store.by_author"] = "автор: %s",
["settings.theme_store.search_item"] = "🔍 Поиск...",
["settings.theme_store.clear_search_item"] = "✕ Очистить поиск",
["settings.theme_store.search_title"] = "Поиск тем",
["settings.theme_store.search_hint"] = "Название темы, автор или описание",
["settings.theme_store.no_results"] = "Темы не найдены по запросу: %s",
["settings.theme_store.detail_msg"] = "Автор: %s\n\n%s\n\nID: %s",
["settings.theme_store.install_button"] = "Установить тему",
["settings.theme_downloading_bg"] = "Загрузка фонового изображения...",
["settings.theme_imported"] = "Тема импортирована!",
["settings.theme_invalid_bundle"] = "Неверный формат пакета.",
["settings.theme_cloud_error"] = "Ошибка облака: %s",
["settings.reset_theme.title"] = "Сбросить тему",
["settings.reset_theme.desc"] = "Сбросить кастомную тему и фоновое изображение к стандартным",
["settings.import_theme.title"] = "Импортировать тему",
["settings.import_theme.desc"] = "Импортировать кастомную тему из облака",
["settings.import_theme.hint"] = "Введи Share ID",
["settings.export_theme.title"] = "Экспортировать тему",
["settings.export_theme.desc"] = "Экспортировать кастомную тему и фоновое изображение в облако",
["settings.export_theme.share_id_msg"] = "Share ID: %s\n\nСкопирован в буфер обмена.",
["settings.export_theme.upload_failed_msg"] = "Ошибка загрузки: %s",
["settings.export_theme.size_warning_title"] = "Предупреждение о размере загрузки",
["settings.export_theme.size_warning_msg"] = "Включить кастомное фоновое изображение? Это увеличит размер загрузки в зависимости от размера твоего изображения.",
["settings.export_theme.uploading_bg"] = "Загрузка фонового изображения на Catbox...",
["settings.export_theme.image_upload_failed_title"] = "Ошибка",
["settings.export_theme.image_upload_failed_msg"] = "Не удалось загрузить изображение: %s",
["settings.tabs_icon.title"] = "Иконка вкладок",
["settings.tabs_icon.desc"] = "Изменить иконку вкладок",
["settings.tabs_icon.hint"] = "Введи иконку",
["settings.tabs_icon.empty_error"] = "Не может быть пустым",

["settings.bg_opacity.title"] = "Прозрачность фона",
["settings.bg_opacity.desc"] = "Прозрачность панелей, карточек и шапки",
["settings.slider.alpha"] = "Alpha",
["settings.bg_image_opacity.title"] = "Прозрачность фонового изображения",
["settings.bg_image_opacity.desc"] = "Настрой прозрачность напрямую через целочисленные значения каналов.",
["settings.bg_image_picker.title"] = "Фоновое изображение",
["settings.bg_image_picker.desc"] = "Нажми, чтобы изменить абсолютный путь к файлу для кастомного фонового изображения",
["settings.bg_image_picker.path_label"] = "Абсолютный путь к файлу изображения (.jpg или .png):",
["settings.bg_image_picker.remove_label"] = "Удалить фоновое изображение",
["settings.bg_image_picker.success_title"] = "Успешно",
["settings.bg_image_picker.removed_msg"] = "Фоновое изображение удалено",
["settings.bg_image_picker.added_msg"] = "Фоновое изображение добавлено",
["settings.bg_image_picker.not_found_msg"] = "Файл не найден или операция чтения отклонена:\n%s",

["settings.bg_rgb.title"] = "RGB фона",
["settings.bg_rgb.desc"] = "Оттенок для фона панелей (шапка и карточки масштабируются автоматически)",
["settings.slider.r"] = "R",
["settings.slider.g"] = "G",
["settings.slider.b"] = "B",
["settings.accent_rgb.title"] = "RGB акцента",
["settings.accent_rgb.desc"] = "Оттенок для кнопок, переключателей и активных карточек (приглушённый цвет вычисляется автоматически)",
["settings.logo_rgb.title"] = "RGB подсветки",
["settings.logo_rgb.desc"] = "Цвет для меток, иконок и интерактивного текста (всегда полностью непрозрачный)",
["settings.sub_rgb.title"] = "RGB второстепенного текста",
["settings.sub_rgb.desc"] = "Цвет для описаний и неактивных меток вкладок",
["settings.text_rgb.title"] = "Text RGB",
["settings.text_rgb.desc"] = "Цвет основного текста меню",

["settings.win_width.title"] = "Ширина меню",
["settings.win_width.desc"] = "Ширина плавающего меню (%d – %d dp)",
["settings.slider.width"] = "Ширина",
["settings.win_height.title"] = "Высота меню",
["settings.win_height.desc"] = "Высота прокручиваемой области контента (%d – %d dp)",
["settings.slider.height"] = "Высота",

-- ── modules/tabs/about.lua ────────────────────────────────────────────────────
["about.about_script.title"] = "О скрипте",
["about.about_script.desc"] = "Мощный и сильно оптимизированный скрипт для манипуляции памятью, созданный для Hill Climb Racing 2 в кастомном окружении Pivot.\n\nСкачать Pivot:\nhttps://github.com/vekendianorg/pivot/releases/",
["about.script_owner.title"] = "Владелец скрипта",
["about.script_owner.desc"] = "- Vekendian Organization (github: vekendianorg)",
["about.script_dev.title"] = "Разработчик скрипта",
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],
["about.script_translator.title"] = "Переводчик скрипта",
["about.script_translator.desc"] = [[
- English: Lazor (github: lazor-git)
- Bahasa Indonesia: Lazor (github: lazor-git)
- Español: Jayy2k (github: Jayy2k)
- Deutsch: Erik (github: eomthix)
- Русский: NikolayPG (github: Ohranik1Pitorochki)
- Thai: NaiArt777 (github: artphakkapol-hub)
]],
["about.credits.title"] = "Credits",
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
]],
["about.special_thanks.title"] = "Особая благодарность",
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

-- ── modules/tabs/other.lua ────────────────────────────────────────────────────
["other.debug_mode.title"] = "Режим отладки",
["other.debug_mode.desc"] = "Переключить внутриигровой режим отладки",
["other.debug_mode.enabled"] = "Режим отладки включён",
["other.debug_mode.disabled"] = "Режим отладки выключен",
["other.hint.width"] = "Ширина",
["other.hint.height"] = "Высота",
["other.resolution.title"] = "Настроить разрешение",
["other.resolution.desc"] = "Настрой ширину и высоту игры (по умолчанию 1280x720)",
["other.resolution.applied"] = "Разрешение установлено: %dx%d",
["other.resolution_offset.title"] = "Настроить смещение разрешения",
["other.resolution_offset.desc"] = "Настрой смещение по ширине и высоте игры (по умолчанию 0x0), лучше всего подходит для маленького разрешения на большом экране.",
["other.resolution_offset.applied"] = "Смещение разрешения установлено: %dx%d",
["other.glsurface_not_found"] = "GLSurfaceView не найден",

-- ── modules/tabs/shop.lua ─────────────────────────────────────────────────────
["shop.free_chest.title"] = "Бесплатные сундуки",
["shop.free_chest.desc"] = "Сделать сундуки бесплатными во вкладке магазина",
["shop.free_chest.enabled"] = "Бесплатные сундуки включены",
["shop.free_chest.disabled"] = "Бесплатные сундуки выключены",
["shop.free_purchases.title"] = "Бесплатные покупки",
["shop.free_purchases.desc"] = "Сделать некоторые ежедневные предложения в магазине бесплатными (также работает для специальных предложений в виде попапов/значков)",
["shop.free_purchases.progress"] = "%d/%d",
["shop.free_purchases.success"] = "Бесплатная покупка успешна",
["shop.change_chest.title"] = "Изменить сундук",
["shop.change_chest.desc"] = "Заменить легендарный сундук на выбранный",
["shop.change_chest.changed"] = "Сундук изменён на %s",
["shop.change_chest.options"] = {
    "Common Chest", "Uncommon Chest", "Rare Chest", "Epic Chest",
    "Champion Chest", "Special Chest 1", "Xmas Chest", "Legendary Chest",
    "Blue Chest", "VIP Chest 1", "VIP Chest 2", "Video Chest",
    "Starter Chest", "Special Chest 2", "Fingersoft Chest", "Mega Chest",
    "Team Spirit Chest", "Style Chest", "Mythic Chest"
},

-- ── modules/tabs/player.lua ───────────────────────────────────────────────────
["player.auto_detach.title"] = "Авто отстёгивание",
["player.auto_detach.desc"] = "Автоматически отстёгивать детали, например крышу Rally Car",
["player.no_clip.title"] = "Сквозь объекты",
["player.no_clip.desc"] = "Позволяет проходить сквозь объекты, не погибая (можно проезжать сквозь финишные линии в кубках)",
["player.no_clip.enabled"] = "Прохождение сквозь объекты включено",
["player.no_clip.disabled"] = "Прохождение сквозь объекты выключено",
["player.hide_name.title"] = "Скрыть имя",
["player.hide_name.desc"] = "Скрыть имя твоего игрока в заезде",
["player.hide_name.enabled"] = "Скрытие имени включено",
["player.hide_name.disabled"] = "Скрытие имени выключено",
["player.hide_flag.title"] = "Скрыть флаг",
["player.hide_flag.desc"] = "Скрыть флаг твоего игрока в заезде",
["player.hide_flag.enabled"] = "Скрытие флага включено",
["player.hide_flag.disabled"] = "Скрытие флага выключено",
["player.zoom.title"] = "Настроить зум",
["player.zoom.desc"] = "Настрой, насколько близко или далеко находится камера",
["player.slider.min"] = "Min",
["player.slider.max"] = "Max",
["player.gravity.title"] = "Настроить гравитацию",
["player.gravity.desc"] = "Настрой силу гравитации",
["player.slider.x"] = "X",
["player.slider.y"] = "Y",

-- ── modules/tabs/adventure.lua ────────────────────────────────────────────────
["adventure.auto_adventure_chests.title"] = "Авто сундуки приключений (нестабильно)",
["adventure.auto_adventure_chests.desc"] = "Автоматически повышать уровень твоих сундуков приключений",
["adventure.auto_adventure_chests.none_found"] = "Сундуки приключений не найдены",
["adventure.auto_adventure_chests.done"] = "Готово",

["adventure.set_distance.title"] = "Установить дистанцию",
["adventure.set_distance.desc"] = "Устанавливает дистанцию твоего заезда в режиме Adventure на заданное значение. Нужно быть в активном заезде. Чем больше дистанция, тем больше звёзд можно получить. Максимум звёзд на 5000м. (Это не телепорт)",
["adventure.set_distance.loop_active_title"] = "Установка дистанции — цикл активен",
["adventure.set_distance.loop_active_msg"] = "Цикл установки дистанции сейчас работает.\nЧто делать дальше?",
["adventure.set_distance.stop_loop"] = "Остановить цикл",
["adventure.set_distance.keep_running"] = "Продолжить работу",
["adventure.set_distance.loop_will_stop"] = "Цикл остановится после текущего тика.",
["adventure.set_distance.prompt_target"] = "Целевая дистанция (в метрах)",
["adventure.set_distance.prompt_loop"] = "Цикл (авто-повтор)",
["adventure.set_distance.prompt_interval"] = "Интервал цикла (мс, минимум 250)",
["adventure.set_distance.over_max_title"] = "Предупреждение о дистанции",
["adventure.set_distance.over_max_msg"] = "Дистанция свыше 5000м не даст дополнительных звёзд.\n\nЗаезд всё равно зафиксирует дистанцию, но звёзды за неё не начислятся. Продолжить?",
["adventure.set_distance.continue_button"] = "Продолжить",
["adventure.set_distance.not_in_adventure"] = "Перейди во вкладку Adventure и начни заезд",
["adventure.set_distance.start_race_first"] = "Сначала начни заезд",
["adventure.set_distance.applied"] = "Дистанция установлена: %sm",
["adventure.set_distance.loop_stopped"] = "Цикл установки дистанции остановлен.",
["adventure.set_distance.loop_running"] = "Цикл дистанции работает — нажми Set Distance, чтобы остановить",

-- ── modules/tabs/cups.lua ─────────────────────────────────────────────────────
["cups.adjust_countdown.title"] = "Настроить отсчёт",
["cups.adjust_countdown.desc"] = "Настрой отсчёт перед началом заезда",
["cups.slider.seconds"] = "Секунды",
["cups.adjust_countdown.applied"] = "Отсчёт изменён на %ss",
["cups.auto_win.title"] = "Авто победа",
["cups.auto_win.desc"] = "Автоматически побеждать вне зависимости от результата заезда",
["cups.force_boss.title"] = "Принудительный босс",
["cups.force_boss.desc"] = "Босс будет появляться всегда",
["cups.force_cup.title"] = "Выбрать кубок",
["cups.force_cup.desc"] = "Принудительно установить один кубок",
["cups.force_cup.not_found"] = "Force Cup не найден. Попробуй позже.",
["cups.force_cup.enabled"] = "Force Cup включён",
["cups.force_cup.disabled"] = "Force Cup выключен",
["cups.unlimited_tasks.title"] = "Безлимитные задания",
["cups.unlimited_tasks.desc"] = "Заморозить все задания как выполненные и доступные для получения. Забирай награды многократно.",
["cups.unlimited_tasks.resolve_failed"] = "Не удалось получить список заданий",
["cups.unlimited_tasks.none_found"] = "Задания не найдены",
["cups.unlimited_tasks.enabled"] = "Безлимитные задания включены",
["cups.unlimited_tasks.disabled"] = "Безлимитные задания выключены",
["cups.unlimited_tasks.none_to_freeze"] = "Нет заданий для заморозки",
["cups.rank_points_bonus.title"] = "+498 очков ранга",
["cups.rank_points_bonus.desc"] = "Все лиговые задания дают 498 очков вместо 200, остальные награды убираются.",
["cups.rank_points_bonus.none_found"] = "Лиговые задания не найдены",
["cups.rank_points_bonus.boosted"] = "Очки ранга увеличены: %s",
["cups.rank_points_bonus.no_match"] = "Подходящие лиговые задания не найдены",
["cups.rank_points_bonus.nothing_to_restore"] = "Нечего восстанавливать",
["cups.rank_points_bonus.restored"] = "Восстановлено: %s",

-- ── modules/tabs/event.lua ────────────────────────────────────────────────────
["event.patch_rewards.title"] = "Патч наград ивента",
["event.patch_rewards.desc"] = "Заменить награды текущего публичного ивента на кастомные от VOID (нужен перезапуск игры)",
["event.restore_events.title"] = "Восстановить награды ивента",
["event.restore_events.desc"] = "Удалить изменённые JSON-файлы ивентов, чтобы сервер игры восстановил их (нужен перезапуск игры)",

["event.checking_permissions"] = "Проверка прав доступа окружения...",
["event.scanning_files"] = "Сканирование активных файлов...",
["event.decode_rewards_failed"] = "Не удалось декодировать JSON наград",
["event.workspace_creation_failed"] = "ФАТАЛЬНО: не удалось создать рабочую директорию: %s",
["event.workspace_creation_failed_dialog"] = "ФАТАЛЬНО: не удалось создать рабочую директорию.\n%s",
["event.file_inaccessible"] = "Файл недоступен по пути: %s",
["event.predecrypt_not_found"] = "Pre-decrypt: источник не найден: %s",
["event.predecrypt_empty"] = "Pre-decrypt: источник пуст (0 байт): %s",
["event.decode_active_failed"] = "Не удалось декодировать active_events.json по пути: %s",
["event.no_active_events"] = "Активные ивенты не найдены по пути: %s",
["event.cannot_open_active"] = "Не удалось открыть active_events.json по пути: %s",
["event.decrypt_active_failed"] = "Не удалось расшифровать active_events.json по пути: %s",
["event.root_copy_failed"] = "Ошибка root-копирования: %s",

["event.select_events_patch"] = "Выбери ивенты для патча:\nПуть: %s",
["event.user_cancelled"] = "Пользователь отменил выбор для пути: %s",
["event.rewards_unavailable"] = "Встроенные награды недоступны, патч пропущен для пути: %s",
["event.skipped_unreadable"] = "Пропущен нечитаемый ивент: %s",
["event.predecrypt_event_not_found"] = "Pre-decrypt: ивент не найден: %s",
["event.predecrypt_event_empty"] = "Pre-decrypt: ивент пуст (0 байт): %s",
["event.processing_failed"] = "Ошибка обработки %s: %s",
["event.cannot_open_decrypted"] = "Не удалось открыть расшифрованный файл: %s",
["event.decrypt_event_failed"] = "Не удалось расшифровать ивент: %s",
["event.loop_crash"] = "Критический сбой цикла обработки файлов: %s",

["event.success_header"] = "Успешно:",
["event.success_removed_header"] = "Успешно удалено (восстановится при перезапуске):",
["event.success_item"] = "- %s",
["event.success_item_json"] = "- %s.json",
["event.failed_header"] = "Ошибка:",
["event.failed_item"] = "- %s",

["event.patch_results_title"] = "Результаты патча",
["event.restore_results_title"] = "Результаты восстановления",
["event.restart_required_title"] = "Требуется перезапуск",
["event.patch_restart_msg"] = "Игра закрывается, скрипт сейчас тоже выйдет — запусти заново, чтобы увидеть результат патча",
["event.restore_restart_msg"] = "Игра сейчас закроется для синхронизации файлов с сервером.",
["event.finishing_tasks_patch"] = "Завершение фоновых задач... Подожди.",
["event.finishing_tasks_restore"] = "Завершение фоновых задач...",
["event.patch_failed_msg"] = "Не удалось применить патч, попробуй ещё раз.",

["event.select_events_restore"] = "Выбери файлы для восстановления (удаления):\nПуть: %s",
["event.delete_failed"] = "Не удалось удалить %s: %s",

-- ── modules/tabs/account.lua ──────────────────────────────────────────────────
["account.change_name.title"] = "Изменить имя",
["account.change_name.desc"] = "Измени имя своего игрока",
["account.change_name.hint"] = "Введи имя",
["account.change_name.empty"] = "Сначала введи имя",
["account.change_name.too_long_title"] = "Имя слишком длинное",
["account.change_name.too_long_msg"] = "Твоё имя слишком длинное, сократи его",
["account.change_name.resolve_failed"] = "Не удалось получить указатель на имя",
["account.change_name.applied"] = "Имя изменено на %s",

["account.change_gp.title"] = "Изменить Garage Power",
["account.change_gp.desc"] = "Меняет Garage Power профиля (сохраняется, если значение выше). Поставь 8 для сброса при превышении лимита, но только если твой реальный GP уже зафиксирован ниже лимита.",
["account.change_gp.hint"] = "Введи Garage Power",
["account.change_gp.max_int_title"] = "Достигнут максимум 32-битного int",
["account.change_gp.lower_value"] = "Уменьши значение",
["account.change_gp.too_low_title"] = "Слишком низко",
["account.change_gp.higher_value"] = "Увеличь значение",
["account.change_gp.applied"] = "Garage Power изменён на %s",

["account.fake_unlock.title"] = "Фейковая разблокировка",
["account.fake_unlock.desc"] = "Временно разблокировать все кастомизации",
["account.fake_vip.title"] = "Фейковый VIP",
["account.fake_vip.desc"] = "Переключить статус VIP-подписки локально",
["account.fake_rank.title"] = "Фейковый ранг",
["account.fake_rank.desc"] = "Автоматически установить фейковый легендарный ранг",
["account.fake_rank.applied"] = "Фейковый ранг применён.",


-- ── modules/tabs/vehicle.lua ──────────────────────────────────────────────────
["vehicle.parts_slot.title"] = "Настроить слоты деталей",
["vehicle.parts_slot.desc"] = "Настрой слоты деталей для всех машин",
["vehicle.parts_slot.slider_title"] = "Слоты",
["vehicle.parts_slot.no_vehicles"] = "Машины не найдены",
["vehicle.parts_slot.applied"] = "Слоты деталей изменены: %d машин",

["vehicle.unlock_vehicles.title"] = "Разблокировать машины",
["vehicle.unlock_vehicles.desc"] = "Разблокировать все машины для покупки за монеты",
["vehicle.unlock_vehicles.no_vehicles"] = "Машины не найдены",
["vehicle.unlock_vehicles.unlocked"] = "Машин разблокировано: %d",
["vehicle.unlock_vehicles.none_to_unlock"] = "Нет машин для разблокировки",

["vehicle.max_vehicles.title"] = "Макс. машины",
["vehicle.max_vehicles.desc"] = "Мгновенно прокачать уровни всех разблокированных машин до максимума",
["vehicle.max_vehicles.no_vehicles"] = "Не удалось получить список машин",
["vehicle.max_vehicles.all_maxed"] = "Все машины прокачаны до максимума",
["vehicle.max_vehicles.failed"] = "Не удалось прокачать машины",

["vehicle.max_mastery.title"] = "Макс. мастерство",
["vehicle.max_mastery.desc"] = "Мгновенно прокачать мастерство всех разблокированных и прокачанных машин до максимума.",
["vehicle.max_mastery.all_maxed"] = "Всё мастерство прокачано до максимума",
["vehicle.max_mastery.failed"] = "Не удалось прокачать мастерство",

["vehicle.max_parts.title"] = "Макс. детали",
["vehicle.max_parts.desc"] = "Мгновенно прокачать все разблокированные детали для всех машин до максимума.",
["vehicle.max_parts.no_vehicles"] = "Не удалось получить список машин",
["vehicle.max_parts.all_maxed"] = "Все детали прокачаны до максимума",
["vehicle.max_parts.failed"] = "Не удалось прокачать детали",

["vehicle.common.no_vehicles"] = "Машины не найдены",
["vehicle.common.progress"] = "%d/%d",
["vehicle.common.resolve_list_failed"] = "Не удалось получить список машин",
["vehicle.common.no_zero_region"] = "Нулевой регион не найден",

}
