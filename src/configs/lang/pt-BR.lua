--[[
  configs/lang/pt-BR.lua — Português (Brasil) [Brazilian Portuguese]

  Flat table of dotted keys -> strings, loaded by core/utils/lang.lua.
  Looked up at runtime via the global T(key, ...) function, e.g.:
      T("common.ok")                          -> "OK"
      T("settings.window_width_desc", 400, 650) -> "Largura do menu flutuante (400 - 650 dp)"

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

  This file handles the Brazilian Portuguese localization for the VOID script.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "OK",
["common.cancel"] = "Cancelar",
["common.yes"] = "Sim",
["common.no"] = "Não",
["common.failed"] = "Falhou",
["common.success"] = "Sucesso",
["common.later"] = "Depois",
["common.got_it"] = "Entendi",
["common.retry"] = "Tentar Novamente",
["common.wait_safe"] = "Aguardar (Seguro)",
["common.waiting"] = "Aguardando...",
["common.force_exit"] = "Forçar Saída",
["common.proceed_anyway"] = "Continuar Mesmo Assim",
["common.manual_mode"] = "Modo Manual",
["common.update_button"] = "ATUALIZAR",
["common.launch_failed"] = "Falha ao Iniciar",
["common.confirm_exit_title"] = "Confirmar Saída",
["common.confirm_exit_msg"] = "Sair do Script?",
["common.not_available"] = "Indisponível",
["common.warning"] = "Aviso",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "Aviso: Operações Ativas",
["main.exit_active_ops_msg"] = "Há %d tarefa(s) em segundo plano.\nForçar a saída pode corromper o estado do jogo.",
["main.initializing"] = "Inicializando...",
["main.no_app_found"] = "Nenhum aplicativo encontrado",
["main.arch_64bit_required_title"] = "64-bit Obrigatório",
["main.arch_64bit_required_msg"] = "ARMv8a é obrigatório. x86_64 é parcialmente suportado.",

["main.update_available_title"] = "Atualização Disponível",
["main.update_available_msg"] = "v%s está disponível (atual: v%s)\n\n%s\n\nAtualizar agora?",
["main.no_changelog"] = "Sem registro de alterações.",
["main.downloading_version"] = "Baixando v%s...",
["main.update_download_failed_msg"] = "Não foi possível baixar a atualização:\n%s",
["main.update_write_failed_msg"] = "Não foi possível escrever em:\n%s",
["main.update_done_title"] = "VOID Atualizado para v%s",
["main.update_done_msg"] = "VOID foi atualizado com sucesso.\n\nO novo script foi salvo como:\nvoid_v%s.lua\n\nExecute-o pelo GameGuardian para aplicar a atualização.",
["main.launching_version"] = "Iniciando v%s...",
["main.launch_failed_msg"] = "Baixado, mas não foi possível executar:\n%s",

["main.multiple_spaces_title"] = "Múltiplos Espaços Detectados",
["main.multiple_spaces_desc"] = "HCR2 foi encontrado em %d espaços virtuais.\nSelecione o espaço em que você está jogando atualmente.",
["main.select_space_toast"] = "Por favor, selecione um espaço para continuar.",
["main.user_space_item"] = "Usuário %s  —  %s",
["main.permission_error_title"] = "Erro de Permissão",
["main.permission_error_msg"] = "O acesso ao shell foi negado.\n\nO Void precisa disso para localizar o HCR2 no seu espaço virtual. Verifique o código fonte do Void se quiser verificar qual comando está sendo executado.",
["main.hcr2_not_found_title"] = "Dados do HCR2 Não Encontrados",
["main.hcr2_not_found_msg"] = "O Void não conseguiu localizar os dados do HCR2 no seu espaço virtual. Isso pode acontecer se o HCR2 ainda não foi iniciado, ou se o seu aplicativo de espaço virtual usa uma estrutura de caminho incomum.\n\nRecursos que dependem de arquivos do jogo (Recompensas de Eventos, etc.) não funcionarão sem um caminho válido.",
["main.manual_data_path_title"] = "Caminho de Dados Manual",
["main.manual_data_path_hint"] = "Digite o caminho dos dados do HCR2",
["main.manual_path_cancelled"] = "Cancelado — prosseguindo sem caminho.",
["main.waiting_for_lib"] = "Aguardando %s...",
["main.initialized"] = "Inicializado",
["main.gamestatus_not_found"] = "GameStatus Não Encontrado",
["main.dont_interrupt"] = "Não interrompa este script",

-- ── ui/ui.lua (framework chrome: menu, cards, dialogs) ────────────────────────
["ui.size_saved_restart"] = "Tamanho salvo! Reinicie o script",
["ui.category_error"] = "Erro: %s",
["ui.category_not_found"] = "Categoria Não Encontrada",
["ui.na"] = "N/D",
["ui.spinner_select"] = "Selecionar",
["ui.slider_default_title"] = "Valor",
["ui.loading"] = "Carregando",

-- ── core/engines/patches.lua (addArchModule patch engine) ────────────────────
["patches.requires_arch"] = "Requer dispositivo %s (seu dispositivo: %s)",
["patches.suffix_enabled"] = " Ativado",
["patches.suffix_disabled"] = " Desativado",
["patches.pattern_not_found"] = "Falhou: %d padrão(ões) não encontrado(s)",

-- ── core/engines/arch.lua (architecture detection warnings) ──────────────────
["arch.warning_title"] = "Aviso de Arquitetura",
["arch.unknown_arch_msg"] = "Sua arquitetura é desconhecida. A biblioteca está carregada? Qual sistema você está usando?",
["arch.non_primary_arch_msg"] = "Detectado: %s\nAlguns ou todos os patches de biblioteca podem não funcionar.",
["arch.unknown_version_msg"] = "Versão do jogo desconhecida. Tente novamente após o jogo carregar.",
["arch.no_base_data_msg"] = "Erro interno: não há dados base disponíveis para esta arquitetura.",

-- ── core/engines/scheduler.lua ────────────────────────────────────────────────
["scheduler.task_crashed"] = "Aviso do Agendador: Tarefa travou -> %s",

-- ── core/utils/paste.lua + catbox.lua (network error strings) ────────────────
["errors.http_error_code"] = "Código de Erro HTTP: %s",
["errors.crashed"] = "Travou: %s",
["errors.url_missing"] = "O parâmetro URL está ausente ou vazio",
["errors.file_path_missing"] = "O caminho do arquivo está ausente",
["errors.download_url_missing"] = "A URL está ausente",
["errors.dest_path_missing"] = "O caminho de destino está ausente",

-- ── modules/registry.lua (sidebar tab labels + module-load error cards) ──────
["tabs.sep_game"] = "MENU DO JOGO",
["tabs.account"] = "MENU DA CONTA",
["tabs.vehicle"] = "MENU DO VEÍCULO",
["tabs.player"] = "MENU DO JOGADOR",
["tabs.adventure"] = "MENU DE AVENTURA",
["tabs.cups"] = "MENU DE COPOS",
["tabs.team"] = "MENU DO TIME",
["tabs.event"] = "MENU DE EVENTOS",
["tabs.creative"] = "MENU CRIATIVO",
["tabs.shop"] = "MENU DA LOJA",
["tabs.other"] = "OUTRO MENU",
["tabs.sep_script"] = "MENU DO SCRIPT",
["tabs.settings"] = "CONFIGURAÇÕES",
["tabs.about"] = "SOBRE",

["registry.module_load_failed"] = "Falha ao carregar o módulo. Verifique os logs para mais detalhes.",
["registry.module_runtime_error"] = "Erro de execução: %s",
["registry.error"] = "Erro",

-- ── modules/tabs/settings.lua ─────────────────────────────────────────────────
["settings.section_updates"] = "Atualizações",
["settings.auto_update.title"] = "Atualização Automática",
["settings.auto_update.desc"] = "Atualizar VOID automaticamente na inicialização",
["settings.dev_mode_title"] = "Modo Dev",
["settings.auto_update.dev_mode_msg"] = "A atualização automática está desativada para main.lua (build de desenvolvimento).",
["settings.check_updates.title"] = "Verificar Atualizações",
["settings.check_updates.desc"] = "Verificar a versão mais recente do VOID no GitHub",
["settings.check_updates.dev_mode_msg"] = "A verificação de atualizações está desativada para main.lua (build de desenvolvimento).\n\nFaça o pull manualmente do repositório.",
["settings.check_updates.checking"] = "Verificando atualizações...",
["settings.check_updates.failed_title"] = "Falha na Verificação de Atualizações",
["settings.check_updates.failed_msg"] = "Não foi possível acessar o GitHub:\n%s",
["settings.check_updates.up_to_date_title"] = "Atualizado",
["settings.check_updates.up_to_date_msg"] = "Você já está na versão mais recente (v%s).",
["settings.check_updates.no_changelog"] = "Nenhum registro de alterações disponível.",
["settings.check_updates.available_msg"] = "v%s  (atual: v%s)\n\n%s\n\nBaixar e substituir este script?",
["settings.check_updates.no_asset_msg"] = "Nenhum arquivo .lua encontrado no release.",
["settings.check_updates.download_failed_title"] = "Falha no Download",
["settings.check_updates.write_failed_title"] = "Falha na Escrita",
["settings.check_updates.done_title"] = "Concluído",
["settings.check_updates.done_msg"] = "Atualizado para v%s. Reinicie o script para aplicar.",
["settings.check_updates.restart_button"] = "Reiniciar",

["settings.section_language"] = "Idioma",
["settings.language.title"] = "Idioma",
["settings.language.desc"] = "Escolha seu idioma preferido para o menu",
["settings.language.changed"] = "Idioma definido para %s",
["settings.language.failed"] = "Falha ao carregar esse idioma",
["settings.language.restart_msg"] = "Reinicie o script para aplicar o idioma completamente",

["settings.region.other"] = "O: Outro",
["settings.region.cpp_alloc"] = "Ca: alloc C++",
["settings.region.unknown"] = "D: Desconhecido",
["settings.section_memory"] = "Memória",
["settings.memory_range.title"] = "Intervalo de Memória",
["settings.memory_range.desc"] = "Intervalo de memória atualmente selecionado\n(escolhido automaticamente pelo script)",
["settings.gamestatus.title"] = "GameStatus",
["settings.gamestatus.desc"] = "Endereço GameStatus atual\n(escolhido automaticamente pelo script)",
["settings.gamestatus_raw.title"] = "GameStatus (Bruto)",
["settings.gamestatus_raw.desc"] = "Endereço GameStatus (bruto) atual\n(escolhido automaticamente pelo script)",
["settings.clear_memory.title"] = "Limpar Memória Salva",
["settings.clear_memory.desc"] = "Limpar toda a memória salva do VOID sem precisar reiniciar o jogo.",

["settings.section_ui_customizations"] = "Personalizações da UI",
["settings.theme_store.title"] = "Loja de Temas",
["settings.theme_store.desc"] = "Navegue e instale temas da comunidade Void",
["settings.theme_store.unreachable_msg"] = "Não foi possível acessar a loja de temas:\n%s",
["settings.theme_store.parse_failed_msg"] = "Não foi possível analisar os dados da loja de temas.",
["settings.theme_store.list_title"] = "Loja de Temas Void",
["settings.theme_store.search_results_desc"] = "Resultados da pesquisa: %s encontrado(s)",
["settings.theme_store.available_desc"] = "%s temas disponíveis",
["settings.theme_store.by_author"] = "por %s",
["settings.theme_store.search_item"] = "🔍 Pesquisar...",
["settings.theme_store.clear_search_item"] = "✕ Limpar pesquisa",
["settings.theme_store.search_title"] = "Pesquisar Temas",
["settings.theme_store.search_hint"] = "Nome do tema, autor ou descrição",
["settings.theme_store.no_results"] = "Nenhum tema encontrado para: %s",
["settings.theme_store.detail_msg"] = "Por %s\n\n%s\n\nID: %s",
["settings.theme_store.install_button"] = "Instalar Tema",
["settings.theme_downloading_bg"] = "Baixando imagem de fundo...",
["settings.theme_imported"] = "Tema importado!",
["settings.theme_invalid_bundle"] = "Formato de pacote inválido.",
["settings.theme_cloud_error"] = "Erro na nuvem: %s",
["settings.reset_theme.title"] = "Redefinir Tema",
["settings.reset_theme.desc"] = "Redefinir tema personalizado e imagem de fundo para o padrão",
["settings.import_theme.title"] = "Importar Tema",
["settings.import_theme.desc"] = "Importar tema personalizado da nuvem",
["settings.import_theme.hint"] = "Digite o ID de Compartilhamento",
["settings.export_theme.title"] = "Exportar Tema",
["settings.export_theme.desc"] = "Exportar tema personalizado e imagem de fundo para a nuvem",
["settings.export_theme.share_id_msg"] = "ID de Compartilhamento: %s\n\nCopiado para a área de transferência.",
["settings.export_theme.upload_failed_msg"] = "Falha no upload: %s",
["settings.export_theme.size_warning_title"] = "Aviso de Tamanho de Upload",
["settings.export_theme.size_warning_msg"] = "Incluir imagem de fundo personalizada? Isso aumentará o Tamanho do Upload dependendo do tamanho da sua imagem.",
["settings.export_theme.uploading_bg"] = "Enviando imagem de fundo para o Catbox...",
["settings.export_theme.image_upload_failed_title"] = "Erro",
["settings.export_theme.image_upload_failed_msg"] = "Falha no upload da imagem: %s",
["settings.tabs_icon.title"] = "Ícone das Abas",
["settings.tabs_icon.desc"] = "Alterar ícone das abas",
["settings.tabs_icon.hint"] = "Digite o Ícone",
["settings.tabs_icon.empty_error"] = "Não pode estar vazio",

["settings.bg_opacity.title"] = "Opacidade do Fundo",
["settings.bg_opacity.desc"] = "Transparência dos painéis, cartões e cabeçalho",
["settings.slider.alpha"] = "Alfa",
["settings.bg_image_opacity.title"] = "Opacidade da Imagem de Fundo",
["settings.bg_image_opacity.desc"] = "Ajustar as configurações alfa de visibilidade diretamente usando canais inteiros puros.",
["settings.bg_image_picker.title"] = "Imagem de Fundo",
["settings.bg_image_picker.desc"] = "Toque para modificar o caminho absoluto do arquivo para sua imagem de fundo personalizada",
["settings.bg_image_picker.path_label"] = "Caminho Absoluto da Imagem (.jpg ou .png):",
["settings.bg_image_picker.remove_label"] = "Remover Imagem de Fundo",
["settings.bg_image_picker.success_title"] = "Sucesso",
["settings.bg_image_picker.removed_msg"] = "Imagem de Fundo Removida",
["settings.bg_image_picker.added_msg"] = "Imagem de fundo adicionada",
["settings.bg_image_picker.not_found_msg"] = "Arquivo não encontrado ou operação de leitura recusada:\n%s",

["settings.bg_rgb.title"] = "Fundo RGB",
["settings.bg_rgb.desc"] = "Matiz para fundos de painel (Cabeçalho e Cartão escalam automaticamente)",
["settings.slider.r"] = "R",
["settings.slider.g"] = "G",
["settings.slider.b"] = "B",
["settings.accent_rgb.title"] = "Destaque RGB",
["settings.accent_rgb.desc"] = "Matiz para botões, alternadores e cartões ativos (cor suave derivada automaticamente)",
["settings.logo_rgb.title"] = "Realce RGB",
["settings.logo_rgb.desc"] = "Cor para rótulos, ícones e texto interativo (sempre totalmente opaco)",
["settings.sub_rgb.title"] = "Subtexto RGB",
["settings.sub_rgb.desc"] = "Cor para descrições e rótulos de abas inativas",
["settings.text_rgb.title"] = "Texto RGB",
["settings.text_rgb.desc"] = "Cor para o texto do menu principal",

["settings.win_width.title"] = "Largura do Menu",
["settings.win_width.desc"] = "Largura do menu flutuante (%d – %d dp)",
["settings.slider.width"] = "Largura",
["settings.win_height.title"] = "Altura do Menu",
["settings.win_height.desc"] = "Altura da área de conteúdo rolável (%d – %d dp)",
["settings.slider.height"] = "Altura",

-- ── modules/tabs/about.lua ────────────────────────────────────────────────────
["about.about_script.title"] = "Sobre o Script",
["about.about_script.desc"] = "Um poderoso e altamente otimizado script de manipulação de memória construído para Hill Climb Racing 2 no ambiente Pivot personalizado.\n\nBaixar Pivot:\nhttps://github.com/vekendianorg/pivot/releases/",
["about.script_owner.title"] = "Proprietário do Script",
["about.script_owner.desc"] = "- Vekendian Organization (github: vekendianorg)",
["about.script_dev.title"] = "Desenvolvedor do Script",
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],
["about.script_translator.title"] = "Tradutor do Script",
["about.script_translator.desc"] = [[
- English: Lazor (github: lazor-git)
- Bahasa Indonesia: Lazor (github: lazor-git)
- Español: Jayy2k (github: Jayy2k)
- Deutsch: Erik (github: eomthix)
- Русский: Winter Lotus(github: Ohranik1Pitorochki; discord:nikolaypg67), profinoobru (github: profinoobru)
- Thai: NaiArt777 (github: artphakkapol-hub)
- বাংলা: AMR (github: amr-gt)
- العربية: AMR (github: amr-gt)
- اردو: AMR (github: amr-gt)
- Français: AMR (github: amr-gt)
- Українська: AMR (github: amr-gt)
- Türkçe: AMR (github: amr-gt)
- Português (Brasil): AMR (github: amr-gt)
]],
["about.credits.title"] = "Créditos",
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
- Profinoobru
]],
["about.special_thanks.title"] = "Agradecimentos Especiais",
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

-- ── modules/tabs/other.lua ────────────────────────────────────────────────────
["other.debug_mode.title"] = "Modo de Depuração",
["other.debug_mode.desc"] = "Alternar o modo de depuração no jogo",
["other.debug_mode.enabled"] = "Modo de Depuração Ativado",
["other.debug_mode.disabled"] = "Modo de Depuração Desativado",
["other.hint.width"] = "Largura",
["other.hint.height"] = "Altura",
["other.resolution.title"] = "Ajustar Resolução",
["other.resolution.desc"] = "Ajustar a largura e altura do jogo (padrão é 1280x720)",
["other.resolution.applied"] = "Resolução definida para %dx%d",
["other.resolution_offset.title"] = "Ajustar Deslocamento da Resolução",
["other.resolution_offset.desc"] = "Ajustar o deslocamento de largura e altura do jogo (padrão é 0x0), melhor para resolução pequena em uma tela grande.",
["other.resolution_offset.applied"] = "Deslocamento da resolução definido para %dx%d",
["other.glsurface_not_found"] = "GLSurfaceView não encontrado",

-- ── modules/tabs/shop.lua ─────────────────────────────────────────────────────
["shop.free_chest.title"] = "Baú Grátis",
["shop.free_chest.desc"] = "Tornar os baús gratuitos na Aba Loja",
["shop.free_chest.enabled"] = "Baú Grátis Ativado",
["shop.free_chest.disabled"] = "Baú Grátis Desativado",
["shop.free_purchases.title"] = "Compras Grátis",
["shop.free_purchases.desc"] = "Tornar algumas ofertas diárias gratuitas na aba da loja (também funciona para ofertas especiais como popups/emblemas)",
["shop.free_purchases.progress"] = "%d/%d",
["shop.free_purchases.success"] = "Compra Grátis Bem-sucedida",
["shop.change_chest.title"] = "Alterar Baú",
["shop.change_chest.desc"] = "Alterar o baú lendário para o baú selecionado",
["shop.change_chest.changed"] = "Baú alterado para %s",
["shop.change_chest.options"] = {
    "Baú Comum", "Baú Incomum", "Baú Raro", "Baú Épico",
    "Baú do Campeão", "Baú Especial 1", "Baú de Natal", "Baú Lendário",
    "Baú Azul", "Baú VIP 1", "Baú VIP 2", "Baú de Vídeo",
    "Baú Inicial", "Baú Especial 2", "Baú Fingersoft", "Mega Baú",
    "Baú Espírito de Equipe", "Baú de Estilo", "Baú Mítico"
},

-- ── modules/tabs/player.lua ───────────────────────────────────────────────────
["player.auto_detach.title"] = "Desanexação Automática",
["player.auto_detach.desc"] = "Desanexar automaticamente peças como o teto do Rally Car",
["player.auto_die.title"] = "Morte Automática",
["player.auto_die.desc"] = "Causar morte automaticamente (sem combustível)",
["player.no_clip.title"] = "No-Clip",
["player.no_clip.desc"] = "Faça seu jogador atravessar objetos sem morrer (Você pode passar sobre as linhas de chegada nos copos)",
["player.no_clip.enabled"] = "No-Clip Ativado",
["player.no_clip.disabled"] = "No-Clip Desativado",
["player.hide_name.title"] = "Ocultar Nome",
["player.hide_name.desc"] = "Ocultar seu nome de jogador na corrida",
["player.hide_name.enabled"] = "Ocultar Nome Ativado",
["player.hide_name.disabled"] = "Ocultar Nome Desativado",
["player.hide_flag.title"] = "Ocultar Bandeira",
["player.hide_flag.desc"] = "Ocultar sua bandeira de jogador na corrida",
["player.hide_flag.enabled"] = "Ocultar Bandeira Ativado",
["player.hide_flag.disabled"] = "Ocultar Bandeira Desativado",
["player.fuel.title"] = "Combustível",
["player.fuel.desc"] = "Travar o combustível em um valor constante durante a corrida (0.0 – 100.0)",
["player.fuel.prompt_amount"] = "Quantidade de combustível (0 – 100)",
["player.fuel.prompt_reset"] = "Redefinir",
["player.fuel.invalid"] = "Valor inválido, deve ser 0 – 100",
["player.fuel.applied"] = "Combustível travado em %s",
["player.fuel.reset"] = "Combustível restaurado",
["player.fuel.not_applied"] = "Combustível não ativo",
["player.zoom.title"] = "Ajustar Zoom",
["player.zoom.desc"] = "Ajustar o quão perto ou longe sua câmera está",
["player.slider.min"] = "Mín",
["player.slider.max"] = "Máx",
["player.gravity.title"] = "Ajustar Gravidade",
["player.gravity.desc"] = "Ajustar o quão forte é a gravidade",
["player.slider.x"] = "X",
["player.slider.y"] = "Y",

-- ── modules/tabs/adventure.lua ────────────────────────────────────────────────
["adventure.auto_adventure_chests.title"] = "Baús de Aventura Automáticos (instável)",
["adventure.auto_adventure_chests.desc"] = "Aumentar automaticamente o nível dos seus baús de aventura",
["adventure.auto_adventure_chests.none_found"] = "Nenhum baú de aventura encontrado",
["adventure.auto_adventure_chests.done"] = "Concluído",

["adventure.set_distance.title"] = "Definir Distância",
["adventure.set_distance.desc"] = "Define a distância da sua corrida de aventura para um valor personalizado. Deve estar em uma corrida ativa. Uma distância maior pode render mais estrelas. Máximo de estrelas em 5000m. (Não é uma função de teletransporte)",
["adventure.set_distance.loop_active_title"] = "Definir Distância — Loop Ativo",
["adventure.set_distance.loop_active_msg"] = "O loop de distância está em execução.\nO que você quer fazer?",
["adventure.set_distance.stop_loop"] = "Parar Loop",
["adventure.set_distance.keep_running"] = "Manter Executando",
["adventure.set_distance.loop_will_stop"] = "O loop irá parar após o tick atual.",
["adventure.set_distance.prompt_target"] = "Distância alvo (metros)",
["adventure.set_distance.prompt_loop"] = "Loop (reaplicar automaticamente)",
["adventure.set_distance.prompt_interval"] = "Intervalo do loop (ms, mínimo 250)",
["adventure.set_distance.over_max_title"] = "Aviso de Distância",
["adventure.set_distance.over_max_msg"] = "Distância acima de 5000m não dará estrelas.\n\nA corrida ainda registrará a distância, mas nenhuma recompensa de estrela será dada. Continuar?",
["adventure.set_distance.continue_button"] = "Continuar",
["adventure.set_distance.not_in_adventure"] = "Vá para a aba Aventura e inicie uma corrida primeiro",
["adventure.set_distance.start_race_first"] = "Inicie uma corrida primeiro",
["adventure.set_distance.applied"] = "Distância definida: %sm",
["adventure.set_distance.loop_stopped"] = "Loop de Definir Distância parado.",
["adventure.set_distance.loop_running"] = "Loop de distância em execução — toque em Definir Distância para parar",
["adventure.set_distance.loop_warn_title"] = "Aviso de Loop de Distância",
["adventure.set_distance.loop_warn_msg"] = "O modo loop escreve na memória a cada %s ms.\n\nUsar um intervalo curto pode aumentar a instabilidade, falhas visuais ou travamentos do jogo.\n\nContinuar mesmo assim?",

-- ── modules/tabs/cups.lua ─────────────────────────────────────────────────────
["cups.adjust_countdown.title"] = "Ajustar Contagem Regressiva",
["cups.adjust_countdown.desc"] = "Ajustar a contagem regressiva antes de iniciar a corrida",
["cups.slider.seconds"] = "Segundos",
["cups.adjust_countdown.applied"] = "Contagem regressiva ajustada para %ss",
["cups.auto_win.title"] = "Vitória Automática",
["cups.auto_win.desc"] = "Vença automaticamente, não importa qual seja o resultado da sua corrida",
["cups.force_boss.title"] = "Forçar Chefão",
["cups.force_boss.desc"] = "Forçar o chefão a sempre aparecer",
["cups.force_cup.title"] = "Forçar Copo",
["cups.force_cup.desc"] = "Força um único copo",
["cups.force_cup.not_found"] = "Forçar Copo não encontrado. Tente novamente mais tarde.",
["cups.force_cup.enabled"] = "Forçar Copo Ativado",
["cups.force_cup.disabled"] = "Forçar Copo Desativado",
["cups.set_time.title"] = "Definir Tempo",
["cups.set_time.desc"] = "Defina o tempo da sua corrida (não irá congelar o tempo por razões de segurança). Deve estar em uma corrida de copo ativa. (ex: 1:09.069, 7.284)",
["cups.set_time.hint"] = "Tempo (1:09.069 ou 7.284)",
["cups.set_time.invalid_format"] = "Formato inválido. Use 1:09.069 ou 7.284",
["cups.set_time.no_negative"] = "Sem valores negativos",
["cups.set_time.not_in_cup"] = "Vá para a aba Copos e inicie uma corrida primeiro",
["cups.set_time.start_race_first"] = "Inicie uma corrida primeiro",
["cups.set_time.applied"] = "Tempo definido para %s",
["cups.unlimited_tasks.title"] = "Tarefas Ilimitadas",
["cups.unlimited_tasks.desc"] = "Congelar todas as tarefas como concluídas e sempre reivindicáveis. Reivindique recompensas repetidamente.",
["cups.unlimited_tasks.resolve_failed"] = "Falha ao resolver lista de tarefas",
["cups.unlimited_tasks.none_found"] = "Nenhuma tarefa encontrada",
["cups.unlimited_tasks.enabled"] = "Tarefas Ilimitadas Ativadas",
["cups.unlimited_tasks.disabled"] = "Tarefas Ilimitadas Desativadas",
["cups.unlimited_tasks.none_to_freeze"] = "Nenhuma tarefa para congelar",
["cups.rank_points_bonus.title"] = "+498 Pontos de Rank",
["cups.rank_points_bonus.desc"] = "Faça com que todas as tarefas da liga lhe dêem 498 pontos em vez de 200 pontos, e também remova outras recompensas.",
["cups.rank_points_bonus.none_found"] = "Nenhuma tarefa de liga encontrada",
["cups.rank_points_bonus.boosted"] = "Pontos de rank impulsionados: %s",
["cups.rank_points_bonus.no_match"] = "Nenhuma tarefa de liga correspondente encontrada",
["cups.rank_points_bonus.nothing_to_restore"] = "Nada para restaurar",
["cups.rank_points_bonus.restored"] = "Restaurado: %s",

-- ── modules/tabs/event.lua ────────────────────────────────────────────────────
["event.patch_rewards.title"] = "Patch de Recompensas de Evento",
["event.patch_rewards.desc"] = "Aplicar patch nas recompensas do evento público atual com as personalizadas fornecidas pelo VOID (requer reinicialização do jogo)",
["event.restore_events.title"] = "Restaurar Recompensas de Evento",
["event.restore_events.desc"] = "Excluir JSONs de eventos modificados para forçar a recuperação do servidor do jogo (requer reinicialização do jogo)",

["event.checking_permissions"] = "Verificando permissões do ambiente...",
["event.scanning_files"] = "Escaneando arquivos ativos...",
["event.decode_rewards_failed"] = "Falha ao decodificar JSON de recompensas",
["event.workspace_creation_failed"] = "FATAL: Falha na criação do espaço de trabalho: %s",
["event.workspace_creation_failed_dialog"] = "FATAL: Não foi possível criar o diretório do espaço de trabalho.\n%s",
["event.file_inaccessible"] = "Arquivo inacessível no caminho: %s",
["event.predecrypt_not_found"] = "Pré-descriptografia: fonte não encontrada: %s",
["event.predecrypt_empty"] = "Pré-descriptografia: fonte está vazia (0 bytes): %s",
["event.decode_active_failed"] = "Falha ao decodificar active_events.json no caminho: %s",
["event.no_active_events"] = "Nenhum evento ativo encontrado no caminho: %s",
["event.cannot_open_active"] = "Não foi possível abrir active_events.json no caminho: %s",
["event.decrypt_active_failed"] = "Falha ao descriptografar active_events.json no caminho: %s",
["event.root_copy_failed"] = "Falha na cópia raiz: %s",

["event.select_events_patch"] = "Selecione eventos para aplicar patch:\nCaminho: %s",
["event.user_cancelled"] = "Usuário cancelou a seleção para o caminho: %s",
["event.rewards_unavailable"] = "Recompensas incorporadas não disponíveis, pulando patches para o caminho: %s",
["event.skipped_unreadable"] = "Evento ilegível ignorado: %s",
["event.predecrypt_event_not_found"] = "Pré-descriptografia: evento não encontrado: %s",
["event.predecrypt_event_empty"] = "Pré-descriptografia: evento está vazio (0 bytes): %s",
["event.processing_failed"] = "Falha ao processar %s: %s",
["event.cannot_open_decrypted"] = "Não foi possível abrir o arquivo descriptografado: %s",
["event.decrypt_event_failed"] = "Falha ao descriptografar evento: %s",
["event.loop_crash"] = "Loop crítico de processamento de arquivo travou: %s",

["event.success_header"] = "Com sucesso:",
["event.success_removed_header"] = "Removido com sucesso (Será Restaurado na Reinicialização):",
["event.success_item"] = "- %s",
["event.success_item_json"] = "- %s.json",
["event.failed_header"] = "Falhou:",
["event.failed_item"] = "- %s",

["event.patch_results_title"] = "Resultados do Patch",
["event.restore_results_title"] = "Resultados da Restauração",
["event.restart_required_title"] = "Reinicialização Necessária",
["event.patch_restart_msg"] = "O jogo foi encerrado e este script vai sair, inicie-o novamente para ver os efeitos do patch",
["event.restore_restart_msg"] = "O jogo agora será fechado para permitir a sincronização dos arquivos do servidor.",
["event.finishing_tasks_patch"] = "Finalizando tarefas pendentes em segundo plano... Por favor, aguarde.",
["event.finishing_tasks_restore"] = "Finalizando tarefas pendentes em segundo plano...",
["event.patch_failed_msg"] = "Falha ao aplicar patch, tente novamente.",

["event.select_events_restore"] = "Selecione arquivos para restaurar (excluir):\nCaminho: %s",
["event.delete_failed"] = "Falha ao excluir %s: %s",

-- ── modules/tabs/account.lua ──────────────────────────────────────────────────
["account.change_name.title"] = "Alterar Nome",
["account.change_name.desc"] = "Alterar o nome do seu jogador",
["account.change_name.hint"] = "Digite o Nome",
["account.change_name.empty"] = "Digite um nome primeiro",
["account.change_name.too_long_title"] = "Nome Muito Longo",
["account.change_name.too_long_msg"] = "Seu nome é muito longo, por favor, encurte-o",
["account.change_name.resolve_failed"] = "Falha ao resolver ponteiro do nome",
["account.change_name.applied"] = "Nome alterado para %s",

["account.change_gp.title"] = "Alterar Potência da Garagem",
["account.change_gp.desc"] = "Altera a potência da garagem do perfil (persiste se for maior). Defina para 8 para redefinir se ultrapassar o máximo, mas apenas se o seu GP real já estiver fixado abaixo do limite.",
["account.change_gp.hint"] = "Digite a Potência da Garagem",
["account.change_gp.max_int_title"] = "Máximo de 32 bits atingido",
["account.change_gp.lower_value"] = "Por favor, diminua seu valor",
["account.change_gp.too_low_title"] = "Muito Baixo",
["account.change_gp.higher_value"] = "Por favor, aumente seu valor",
["account.change_gp.applied"] = "A Potência da Garagem foi alterada para %s",

["account.fake_unlock.title"] = "Desbloqueio Falso",
["account.fake_unlock.desc"] = "Desbloquear todas as personalizações temporariamente",
["account.fake_vip.title"] = "VIP Falso",
["account.fake_vip.desc"] = "Alternar o estado de assinatura VIP localmente",
  
["account.fake_rank.title"] = "Rank Falso",
["account.fake_rank.desc"] = "Definir seu rank para lendário falso instantaneamente",
["account.fake_rank.race_warn_title"] = "Corrida Necessária",
["account.fake_rank.race_warn_msg"] = "O Rank Falso só deve ser aplicado enquanto uma corrida de Copos estiver ativa.\n\nAplicá-lo fora de uma corrida pode resultar em um banimento oculto.\n\nCertifique-se de que você já está dentro de uma corrida de Copos antes de continuar.\n\nContinuar mesmo assim?",
["account.fake_rank.continue_button"] = "Continuar",
["account.fake_rank.applied"] = "Rank falso injetado",
["account.fake_rank.not_in_cups"] = "Inicie uma corrida primeiro",

-- ── modules/tabs/vehicle.lua ──────────────────────────────────────────────────
["vehicle.parts_slot.title"] = "Ajustar Slot de Peças",
["vehicle.parts_slot.desc"] = "Ajustar o slot de peças para todos os veículos",
["vehicle.parts_slot.slider_title"] = "Slots",
["vehicle.parts_slot.no_vehicles"] = "Nenhum veículo encontrado",
["vehicle.parts_slot.applied"] = "Slot de peças ajustado: %d veículos",

["vehicle.parts_modifier.title"] = "Modificador de Peças",
["vehicle.parts_modifier.desc"] = "Modificar os níveis das peças de ajuste na corrida ativa",
["vehicle.parts_modifier.select"] = "Selecione uma peça",
["vehicle.parts_modifier.prompt_level"] = "Nível: ",
["vehicle.parts_modifier.prompt_digit0"] = "Dígito: ",
["vehicle.parts_modifier.prompt_digit1"] = "Cauda: ",
["vehicle.parts_modifier.prompt_reset"] = "Redefinir",
["vehicle.parts_modifier.invalid"] = "Valor de nível inválido",
["vehicle.parts_modifier.not_found"] = "Peça não encontrada na memória",
["vehicle.parts_modifier.applied"] = "%s definido para nível %s",
["vehicle.parts_modifier.reset"] = "%s redefinido",

["vehicle.unlock_vehicles.title"] = "Desbloquear Veículos",
["vehicle.unlock_vehicles.desc"] = "Desbloquear todos os veículos para estarem disponíveis para compra com moedas",
["vehicle.unlock_vehicles.no_vehicles"] = "Nenhum veículo encontrado",
["vehicle.unlock_vehicles.unlocked"] = "Veículos desbloqueados: %d",
["vehicle.unlock_vehicles.none_to_unlock"] = "Nenhum veículo para desbloquear",

["vehicle.max_vehicles.title"] = "Máximo de Veículos",
["vehicle.max_vehicles.desc"] = "Maximizar instantaneamente os níveis de upgrade de todos os veículos desbloqueados",
["vehicle.max_vehicles.no_vehicles"] = "Falha ao resolver lista de veículos",
["vehicle.max_vehicles.all_maxed"] = "Todos os veículos maximizados",
["vehicle.max_vehicles.failed"] = "Falha ao maximizar veículos",

["vehicle.max_mastery.title"] = "Máximo de Maestria",
["vehicle.max_mastery.desc"] = "Maximizar instantaneamente as maestrias de todos os veículos desbloqueados e maximizados.",
["vehicle.max_mastery.all_maxed"] = "Todas as maestrias maximizadas",
["vehicle.max_mastery.failed"] = "Falha ao maximizar maestrias",

["vehicle.max_parts.title"] = "Máximo de Peças",
["vehicle.max_parts.desc"] = "Maximizar instantaneamente os níveis de todas as peças desbloqueadas para todos os veículos.",
["vehicle.max_parts.no_vehicles"] = "Falha ao resolver lista de veículos",
["vehicle.max_parts.all_maxed"] = "Todas as peças maximizadas",
["vehicle.max_parts.failed"] = "Falha ao maximizar peças",

["vehicle.common.no_vehicles"] = "Nenhum veículo encontrado",
["vehicle.common.progress"] = "%d/%d",
["vehicle.common.resolve_list_failed"] = "Falha ao resolver lista de veículos",
["vehicle.common.no_zero_region"] = "Nenhuma região zero encontrada",

}
