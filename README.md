# Arqueiro Roguelite

Jogo de ação roguelite 2D isométrico em desenvolvimento para Windows. O jogador controlará um arqueiro em arenas de fantasia sombria, enfrentará ondas de inimigos e escolherá cartas de evolução durante cada partida. O projeto busca combate responsivo, evolução perceptível, variedade de combinações e alta rejogabilidade, com personagens, cenários e identidade artística próprios.

O design oficial do MVP 0.1 está em [docs/GDD.md](docs/GDD.md). A organização técnica, o estado atual e as propostas ainda pendentes estão em [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). As instruções permanentes para colaboradores e Codex estão em [AGENTS.md](AGENTS.md).

## Tecnologias

- Godot 4.7.2.
- GDScript tipado para scripts do projeto.
- TileMapLayer e TileSet isométrico para o piso.
- Funplay MCP e GdUnit4, já presentes no repositório.
- Arte provisória original, sem dependência de assets comerciais.

## Estado atual

O MVP 0.1, de COD-001 a COD-011, está disponível para teste. A arena de 110 tiles isométricos (128 × 64 px) tem limites e pilares com colisão. O arqueiro move-se com WASD, mira com o mouse, dispara flechas ao manter o clique esquerdo e usa dash com Espaço. Perseguidor, atirador e tanque usam formas e cores provisórias originais. Três ondas configuradas em recursos `.tres` aparecem em sequência.

A cena de entrada está em `scenes/ui/main_menu.tscn`. Jogar permite escolher **Modo Aventura** ou **Modo Infinito**. COD-013 entrega somente a fundação da Aventura: sem mapa, ela mostra um aviso e permite voltar ao menu. O mapa, as salas e o chefe ainda serão implementados. Para jogar o combate atual, escolha Infinito: começa nas três ondas originais e continua automaticamente na onda 4. `scenes/main.tscn` compõe a sessão selecionada; `scenes/main/endless_session.tscn` usa a arena existente em `scenes/arena_01.tscn`. O controle, as oito cartas, o HUD, a pausa e o reinício do Infinito foram preservados.

## Começar a desenvolver

1. Abra a pasta do repositório no Godot 4.7.2 e aguarde a importação dos recursos.
2. Leia o GDD e a arquitetura antes de iniciar uma tarefa de implementação.
3. Execute a cena principal com F5. Para inspecionar somente a arena, abra scenes/arena_01.tscn e use F6.
4. Implemente uma tarefa COD por vez, preservando as regras já definidas e acrescentando testes proporcionais.
5. Quando uma decisão de gameplay ou arquitetura for aprovada, atualize o documento correspondente.

Na raiz do projeto, os comandos de verificação são:

    godot --headless --editor --import --path .
    godot --headless --path . --script res://tests/arena_smoke.gd
    godot --headless --path . --script res://tests/player_smoke.gd
    godot --headless --path . --script res://tests/projectile_smoke.gd
    godot --headless --path . --script res://tests/combat_smoke.gd
    godot --headless --path . --script res://tests/enemy_variants_smoke.gd
    godot --headless --path . --script res://tests/wave_smoke.gd
    godot --headless --path . --script res://tests/run_manager_smoke.gd
    godot --headless --path . --script res://tests/experience_integration_smoke.gd
    godot --headless --path . --script res://tests/upgrade_selection_smoke.gd
    godot --headless --path . --script res://tests/upgrade_effects_smoke.gd
    godot --headless --path . --script res://tests/projectile_effects_smoke.gd
    godot --headless --path . --script res://tests/run_flow_smoke.gd
    godot --headless --path . --script res://tests/main_menu_smoke.gd
    godot --headless --path . --script res://tests/game_mode_smoke.gd
    godot --headless --path . --script res://tests/endless_waves_smoke.gd
    godot --headless --path . --script res://tests/pause_menu_smoke.gd
    godot --headless --path . --quit-after 2

Substitua godot pelo caminho do executável instalado, se necessário. A última validação automatizada e seus limites estão em [docs/VALIDATION_MVP_0.1.md](docs/VALIDATION_MVP_0.1.md). Uma partida jogada no editor continua necessária para avaliar precisão da mira, colisões e sensação de combate.

### Testar o combate manualmente

1. Inicie a cena principal com F5. Clique em Jogar e escolha Modo Infinito. O arqueiro aparece no centro da arena ampliada; a primeira onda cria quatro perseguidores. Aventura ainda abre somente a preparação técnica sem mapa.
2. Use WASD para mover, aponte com o mouse e mantenha o clique esquerdo para disparar. Tente acertar o inimigo e os pilares; as flechas desaparecem no impacto.
3. Pressione Espaço para usar o dash. Teste o contato com o inimigo durante e após a esquiva, assim como as colisões com obstáculos e limites.
4. Derrote todos os inimigos de cada onda. A segunda traz atiradores; a terceira acrescenta um tanque. Ao subir de nível, clique em uma das três cartas. A arena permanece pausada até todas as escolhas pendentes terminarem. Compare dano, cadência, movimento, vida e as habilidades especiais depois de cada escolha.
5. Confira no HUD as alterações de vida, XP, nível, onda e recarga do dash. Pressione Esc durante o combate para pausar e retomar.
6. Termine as três ondas para avançar automaticamente à onda 4. Deixe a vida chegar a zero para ver a derrota. Use Reiniciar partida para começar do nível 1 no mesmo modo, sem cartas ou entidades da sessão anterior. Menu Principal volta à escolha de modo.

## Organização

| Caminho atual | Conteúdo |
| --- | --- |
| docs/ | GDD v0.1, arquitetura e relatório de validação. |
| scenes/ | Cena principal, arena, arqueiro, flechas e três tipos de inimigo. |
| scripts/ | Controladores, componentes de vida, projétil e dados tipados. |
| data/ | Recursos de atributos, ondas e oito definições de cartas. |
| assets/tiles/ e assets/icons/ | Atlas provisório do piso e ícones originais das cartas. |
| tests/ | Verificações da arena, combate, ondas, progressão, cartas, pausa, menu e reinício. |
| Cenas/cena01.tscn | Cena 1 preservada, que herda a arena atual. |
| addons/ | Funplay MCP e GdUnit4 já existentes. |

O backlog COD-001 a COD-011 e os critérios de conclusão do MVP estão no GDD. Após validar a sensação de combate manualmente, a próxima versão planejada é o MVP 0.2, com múltiplas salas, chefe e novas cartas.
