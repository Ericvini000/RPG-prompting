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

A cena de entrada está em `scenes/ui/main_menu.tscn`. Jogar permite escolher **Modo Aventura** ou **Modo Infinito**. Aventura percorre um mapa de seis salas em cinco etapas: combate inicial, escolha exclusiva entre combate e descanso, combate avançado, elite e chefe final. A vida e a build persistem entre salas; combates concedem cartas de recompensa além das evoluções por XP. Descanso cura 30 uma vez. O Infinito conserva suas três ondas iniciais e continua com dificuldade crescente; nas ondas 5, 10, 15… enfrenta a mesma Sentinela do Umbral, recebe uma carta e continua sobrevivendo.

`scenes/main.tscn` compõe a sessão selecionada. Aventura usa `scenes/maps/map_01.tscn`, com corredores e portas físicas; Infinito usa `scenes/arena_01.tscn`. Recursos básicos de combate e as oito cartas foram preservados. A validação automatizada está em [docs/VALIDATION_MVP_0.2.md](docs/VALIDATION_MVP_0.2.md); avaliação humana de dificuldade e sensação de combate continua pendente.

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
    godot --headless --path . --script res://tests/adventure_flow_smoke.gd
    godot --headless --path . --script res://tests/adventure_traversal_smoke.gd --fixed-fps 120
    godot --headless --path . --script res://tests/endless_boss_smoke.gd
    godot --headless --path . --script res://tests/endless_waves_smoke.gd
    godot --headless --path . --script res://tests/pause_menu_smoke.gd
    godot --headless --path . --quit-after 2

Substitua godot pelo caminho do executável instalado, se necessário. A validação atual e seus limites estão em [docs/VALIDATION_MVP_0.2.md](docs/VALIDATION_MVP_0.2.md); o relatório 0.1 permanece como histórico. Uma partida humana no editor continua necessária para avaliar precisão da mira, dificuldade e sensação de combate.

### Testar o combate manualmente

1. Inicie a cena principal com F5. Escolha Aventura para percorrer salas ou Infinito para ondas. A primeira sala da Aventura cria três perseguidores; a primeira onda do Infinito cria quatro.
2. Use WASD para mover, aponte com o mouse e mantenha o clique esquerdo para disparar. Tente acertar o inimigo e os pilares; as flechas desaparecem no impacto.
3. Pressione Espaço para usar o dash. Teste o contato com o inimigo durante e após a esquiva, assim como as colisões com obstáculos e limites.
4. Derrote os inimigos do encontro ou onda. Ao subir de nível e receber recompensas, clique em uma das três cartas; o jogo aguarda todas as escolhas pendentes. Compare dano, cadência, movimento, vida e habilidades especiais depois de cada escolha.
5. Confira no HUD as alterações de vida, XP, nível, onda e recarga do dash. Pressione Esc durante o combate para pausar e retomar.
6. Na Aventura, conclua combates e escolhas de cartas para liberar as portas. Escolha apenas um ramo da bifurcação; o descanso cura uma vez, e o combate oferece outra recompensa. A derrota do chefe final conclui a aventura. No Infinito, conclua as três ondas para continuar automaticamente, enfrentando chefes a cada cinco ondas. Use Reiniciar partida para começar do nível 1 no mesmo modo; Menu Principal volta à seleção.

## Organização

| Caminho atual | Conteúdo |
| --- | --- |
| docs/ | GDD 0.2 com histórico 0.1, arquitetura, plano e relatórios de validação. |
| scenes/ | Cena principal, arena, arqueiro, flechas e três tipos de inimigo. |
| scripts/ | Controladores, componentes de vida, projétil e dados tipados. |
| data/ | Recursos de atributos, ondas e oito definições de cartas. |
| assets/tiles/ e assets/icons/ | Atlas provisório do piso e ícones originais das cartas. |
| tests/ | Verificações da arena, combate, ondas, progressão, cartas, pausa, menu e reinício. |
| Cenas/cena01.tscn | Cena 1 preservada, que herda a arena atual. |
| addons/ | Funplay MCP e GdUnit4 já existentes. |

O GDD registra as regras e o histórico; PLAN_MVP_0.2.md e IMPLEMENTATION_MVP_0.2.md registram COD-014 a COD-022. Próximos passos sugeridos: avaliação humana de dificuldade, revisão dos parâmetros provisórios e, depois, novos mapas/conteúdos do roadmap.
