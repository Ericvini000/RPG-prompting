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

COD-001 a COD-005 estão disponíveis para teste. A arena de 110 tiles isométricos (128 × 64 px) tem limites e pilares com colisão. O arqueiro move-se com WASD, mira com o mouse, dispara flechas ao manter o clique esquerdo e usa dash com Espaço. As flechas causam dano a um perseguidor de teste e desaparecem ao atingir inimigos ou obstáculos. O perseguidor persegue, causa dano de contato, morre ao perder toda a vida e emite o sinal de recompensa de 10 XP. As formas e cores são provisórias e originais.

A cena principal está em `scenes/main.tscn`; `scenes/arena_01.tscn` contém o teste e `Cenas/cena01.tscn` continua como referência herdada da arena. Ainda faltam o gerenciamento de XP, ondas, outros inimigos, cartas, HUD e resultados de partida. A cena usa um único perseguidor fixo para experimentar o combate.

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
    godot --headless --path . --script res://tests/combat_smoke.gd
    godot --headless --path . --quit-after 2

Substitua godot pelo caminho do executável instalado, se necessário. A verificação visual no editor continua necessária para alterações de controles, colisões ou apresentação.

### Testar o combate manualmente

1. Inicie a cena principal com F5. O arqueiro aparece no centro da arena ampliada, com um perseguidor na parte superior.
2. Use WASD para mover, aponte com o mouse e mantenha o clique esquerdo para disparar. Tente acertar o inimigo e os pilares; as flechas desaparecem no impacto.
3. Pressione Espaço para usar o dash. Teste o contato com o inimigo durante e após a esquiva, assim como as colisões com obstáculos e limites.
4. O perseguidor morre após receber dano suficiente. A recompensa é emitida por sinal; a interface e o sistema de experiência serão implementados em tarefas futuras.

Esc está mapeado para uma pausa futura, sem interface nesta etapa. Não há tela de derrota ou reinício; para repetir o teste, execute novamente a cena.

## Organização

| Caminho atual | Conteúdo |
| --- | --- |
| docs/ | GDD v0.1 e arquitetura do projeto. |
| scenes/ | Cena principal, arena, arqueiro, flecha e perseguidor. |
| scripts/ | Controladores, componentes de vida, projétil e dados tipados. |
| data/ | Recursos de atributos do arqueiro e do perseguidor. |
| assets/tiles/ | Atlas provisório do piso. |
| tests/ | Verificações da arena, personagem e combate. |
| Cenas/cena01.tscn | Cena 1 preservada, que herda a arena atual. |
| addons/ | Funplay MCP e GdUnit4 já existentes. |

O backlog COD-001 a COD-011 e os critérios de conclusão do MVP estão no GDD. A próxima etapa é COD-006: atirador, tanque e três ondas configuráveis.
