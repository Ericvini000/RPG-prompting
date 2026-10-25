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

A fundação COD-001/COD-002 contém uma cena principal e uma arena de testes com piso isométrico de 128 × 64 pixels, limites, obstáculos com colisão e marcadores de spawn. COD-003 acrescenta um arqueiro controlável com câmera, mira pelo mouse, dash e visual geométrico provisório. Ainda não há flechas, dano, inimigos, ondas, cartas ou progressão; o clique esquerdo está configurado, mas o ataque pertence à COD-004.

Os arquivos existentes continuam em scenes/main.tscn e scenes/arena_01.tscn. O GDD propõe subdiretórios para o MVP; essa reorganização ainda não foi executada.

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
    godot --headless --path . --quit-after 2

Substitua godot pelo caminho do executável instalado, se necessário. A verificação visual no editor continua necessária para alterações de controles, colisões ou apresentação.

### Testar o arqueiro manualmente

1. Inicie a cena principal com F5. O arqueiro aparece no marcador central da arena.
2. Use WASD, inclusive duas teclas ao mesmo tempo, para verificar o movimento em oito direções. Mova o mouse para mudar a direção do arco.
3. Pressione Espaço durante o movimento para usar dash. Espere a recarga antes de repetir; parado, o dash usa a direção da mira.
4. Tente mover e usar dash contra os pilares e as paredes. O personagem deve parar na colisão enquanto a câmera o acompanha.

Esc está mapeado para a pausa futura, mas a interface de pausa ainda não foi implementada.

## Organização

| Caminho atual | Conteúdo |
| --- | --- |
| docs/ | GDD v0.1 e arquitetura do projeto. |
| scenes/ | Cena principal e arena inicial. |
| scenes/player/ | Cena do arqueiro com visual geométrico e câmera. |
| scripts/player/ e scripts/data/ | Controlador tipado e classe de atributos. |
| data/ | Valores iniciais do arqueiro em Resource. |
| assets/tiles/ | Atlas provisório do piso. |
| tests/ | Verificações da arena e do arqueiro. |
| Cenas/cena01.tscn | Referência preservada da antiga cena 1 para a arena atual. |
| addons/ | Funplay MCP e GdUnit4 já existentes. |

O backlog COD-001 a COD-011 e os critérios de conclusão do MVP estão no GDD. A próxima etapa de implementação é COD-004, flechas e sistema de dano.
