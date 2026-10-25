# Arquitetura — Arqueiro Roguelite

**Versão:** 0.1<br>
**Status:** Planejamento técnico alinhado ao GDD v0.1<br>
**Referência de gameplay:** docs/GDD.md<br>
**Engine:** Godot 4.7.2, GDScript tipado

Este documento descreve a arquitetura pretendida para o MVP 0.1. Os contratos de gameplay e os valores numéricos vêm do GDD. Escolhas técnicas ainda não definidas no GDD estão marcadas como **proposta**, sem aprovação implícita. Criar ou alterar código depende da tarefa de implementação correspondente.

## 1. Estado atual e estrutura de diretórios

A fundação COD-001/COD-002 já existe no repositório. COD-003 acrescentou o arqueiro controlável; COD-004/COD-005 acrescentaram flechas, vida, dano e um perseguidor de teste. A cena principal atual é scenes/main.tscn; a arena atual é scenes/arena_01.tscn e instancia scenes/player/player.tscn no PlayerSpawn. Cenas/cena01.tscn preserva o caminho da antiga cena 1 como referência à arena. assets/tiles/arena_floor.svg fornece arte provisória; tests/arena_smoke.gd, tests/player_smoke.gd e tests/combat_smoke.gd verificam a fundação, o personagem e o combate. Funplay MCP e GdUnit4 são addons existentes.

O GDD propõe esta organização para o MVP:

| Diretório | Responsabilidade |
| --- | --- |
| scenes/main, scenes/arena | Orquestração da partida e arenas |
| scenes/player, scenes/combat, scenes/enemies, scenes/ui | Entidades e interfaces instanciáveis |
| scripts/core | Estado da partida |
| scripts/player, scripts/combat, scripts/enemies | Comportamento de entidades |
| scripts/systems | Ondas e cartas |
| scripts/components | Vida e detecção de dano reutilizáveis |
| scripts/data e data | Classes Resource e seus arquivos .tres |
| assets | Arte, áudio, fontes e materiais provisórios |
| tests | Testes automatizados e verificações de carregamento |
| docs | GDD, arquitetura e decisões aprovadas |

**Diferença ainda não resolvida:** o GDD propõe scenes/main/main.tscn e scenes/arena/arena_01.tscn, mas a fundação existente usa cenas diretamente em scenes/. A migração desses caminhos é uma **proposta**, não uma decisão aprovada. Até haver uma tarefa para isso, os caminhos atuais permanecem como estão.

Criar diretórios e arquivos apenas quando uma tarefa precisar deles. A estrutura listada no GDD não significa que essas cenas e scripts já existam.

## 2. Organização das cenas

| Cena | Papel planejado |
| --- | --- |
| Main | Instancia a arena e coordena WaveDirector, UpgradeManager, HUD, UpgradeScreen e ResultScreen. |
| Arena | Contém piso, limites, obstáculos, pontos de spawn e raiz para entidades ordenadas por Y. |
| Player | CharacterBody2D com colisão, visuais, origem do arco, vida, hurtbox e câmera. |
| Arrow | Projétil com Area2D, movimento, duração máxima e resolução de colisão. |
| Chaser, RangedEnemy, Tank | Cenas de inimigo configuradas por EnemyData. |
| HUD, UpgradeScreen, ResultScreen | Apresentação; recebem eventos sem controlar diretamente atributos de entidades. |

Atualmente, Main contém fundo e Arena01. A arena usa Floor como TileMapLayer, limites e pilares com StaticBody2D/CollisionPolygon2D, marcadores de spawn, Player e um perseguidor de teste. Player contém colisão, formas provisórias, BowOrigin, Camera2D, HealthComponent e Hurtbox. O arqueiro cria flechas em tempo de execução. WaveDirector, outros inimigos e interfaces ainda pertencem a tarefas futuras.

## 3. Scripts principais e responsabilidades

| Script ou componente | Responsabilidade definida no GDD |
| --- | --- |
| RunManager | Estado da partida, XP, nível, vitória e derrota. |
| PlayerController | Movimento em oito direções, mira, ataque e dash. |
| HealthComponent | Vida, dano, cura e morte. |
| HurtboxComponent | Recepção de acertos e integração com vida. |
| Projectile | Movimento, colisão, aplicação de dano e remoção. |
| EnemyController | Movimento, comportamento e ataque de inimigos. |
| WaveDirector | Spawn e acompanhamento das três ondas. |
| UpgradeManager | Elegibilidade, sorteio e aplicação de cartas. |
| HUD | Exibição de vida, XP, nível e onda. |
| UpgradeScreen | Exibição das três cartas e captura de uma escolha. |

Os nomes acima são contratos de responsabilidade do GDD. Separações adicionais em scripts menores só devem ser introduzidas quando a implementação demonstrar necessidade.

## 4. Autoload e estados

**RunManager é o único Autoload definido pelo GDD.** Ele será o controlador único dos estados READY, COMBAT, UPGRADE_SELECTION, VICTORY e GAME_OVER. Deve armazenar os dados transitórios da sessão e, no futuro, permitir continuidade entre salas. WaveDirector e UpgradeManager pertencem às cenas e se comunicam por referências explícitas e sinais.

Ao subir de nível, o combate pausa e a tela de cartas continua recebendo entrada. Se houver várias evoluções pendentes, cada escolha é apresentada em sequência; só depois o combate retoma. Vitória, derrota e reinício passam pelo controlador de estados, evitando que vários scripts alterem pausa ou término independentemente.

**Proposta técnica:** centralizar a mudança de estado em um método do RunManager e configurar o processamento da interface de cartas durante a pausa. A forma exata do método e o modo de processamento serão decididos na tarefa de implementação e testados contra o fluxo do GDD.

## 5. Comunicação por sinais

Os contratos previstos são:

| Emissor | Sinal | Receptor previsto |
| --- | --- | --- |
| HealthComponent | health_changed(current, maximum) | HUD |
| HealthComponent | died() | Jogador ou inimigo |
| Inimigo | enemy_defeated(xp_reward) | RunManager |
| RunManager | experience_changed(xp, required) | HUD |
| RunManager | level_up_requested() | UpgradeManager |
| UpgradeManager | upgrade_selected(upgrade_id) | RunManager e jogador |
| WaveDirector | wave_changed(number) | HUD |
| WaveDirector | arena_completed() | RunManager |

As conexões ficam no dono da cena ou em um ponto de composição explícito. A UpgradeScreen informa a escolha; não altera dano, velocidade ou dados Resource diretamente. A interface observa o estado e emite intenções, evitando dependência direta entre HUD e inimigos.

## 6. Recursos customizados e estado de execução

| Resource | Dados previstos |
| --- | --- |
| PlayerStats | Vida máxima, dano, movimento, ataque, flecha, dash e invulnerabilidade iniciais da seção 4 do GDD. |
| EnemyData | HP, velocidade, dano, intervalo de ataque e XP dos três tipos da seção 5. |
| UpgradeDefinition | ID, nome, descrição, ícone, tipo de efeito, magnitude e limite das oito cartas da seção 7. |
| WaveData | Composição e quantidade de inimigos de cada onda da seção 5. |

Arquivos .tres são configuração imutável durante uma partida. Os atributos efetivos, bônus acumulados, vida atual, experiência e cartas adquiridas ficam em estado de execução separado. Isso evita que uma partida modifique dados compartilhados ou contamine o reinício.

`PlayerStats` e `EnemyData` já possuem scripts Resource tipados em `scripts/data/` e instâncias em `data/`. `UpgradeDefinition` e `WaveData` serão acrescentados nas tarefas correspondentes. Campos que não constam no GDD devem ser registrados como propostas até avaliação de gameplay.

## 7. Combate, dano e colisões

- Player usa CharacterBody2D para movimentação e colisão com limites e obstáculos.
- Flechas usam Area2D. Nascem em BowOrigin, seguem a direção do mouse, carregam velocidade, dano e tempo máximo de vida e desaparecem após acertar inimigo ou obstáculo, salvo efeito de perfuração.
- HealthComponent é responsável pela vida; HurtboxComponent recebe impactos. A resolução do ataque deve impedir múltiplos acertos acidentais e evitar que o arqueiro seja atingido por sua própria flecha.
- Dash respeita recarga, duração e velocidade configuráveis e concede invulnerabilidade durante o movimento. A proteção de 0,50 s após dano também vem dos atributos iniciais do GDD.
- Perseguidor e tanque usam perseguição direta e colisões no MVP. Navegação avançada fica para depois.

**Implementação atual:** o cenário permanece na camada física 1, e Player usa camada 2 com máscara 1. O corpo do perseguidor usa camada 4 e máscara 3; sua hurtbox usa camada 8. A hurtbox do jogador usa camada 16. Flechas usam camada 32 e monitoram cenário (1) e hurtbox inimiga (8). A área de contato do perseguidor monitora a hurtbox do jogador (16). Os números das camadas são escolhas técnicas desta implementação, sem alterar as regras do GDD.

O controlador atual usa os valores de data/player_stats.tres, sem modificar esse recurso durante o jogo. Ele normaliza a diagonal, move o CharacterBody2D pela física, gira BowPivot na direção do mouse e expõe BowOrigin para a próxima etapa. O dash usa a direção de movimento ou, quando parado, a direção da mira. Esse comportamento parado é uma **proposta de implementação**, pois o GDD não especifica a direção do dash sem entrada de movimento.

## 8. Perspectiva isométrica e ordenação por Y

O piso usa losangos 2:1 de 128 × 64 pixels em TileMapLayer. O movimento do arqueiro é livre nas coordenadas 2D da tela, com oito direções e diagonal normalizada; não depende de converter WASD em coordenadas de grade. Objetos e personagens usam o ponto de contato dos pés com o chão para a ordem visual. BowOrigin fica na altura do arco, separado da referência dos pés.

A arena atual habilita Y-sort e mantém o piso em z_index inferior. Uma futura SortingRoot poderá reunir as entidades quando a composição da arena exigir. Qualquer reorganização dos nós atuais deverá preservar a aparência e as colisões existentes.

## 9. Padrões de desenvolvimento e testes

- Usar apenas APIs compatíveis com Godot 4.7.2 e GDScript tipado; centralizar valores configuráveis em recursos, evitando números mágicos.
- Implementar somente o escopo da tarefa corrente. Não antecipar chefes, procedural, inventário, multiplayer ou progressão permanente no MVP 0.1.
- Preservar sinais, cenas e comportamento existentes. Mudanças de regras ou parâmetros do GDD exigem registro e comunicação antes da implementação.
- Manter a lógica de cálculo separada da interface para testar atributos, XP, elegibilidade e efeitos de cartas.
- Usar testes proporcionais à mudança; GdUnit4 está disponível para testes de comportamento, tests/arena_smoke.gd verifica a fundação e tests/player_smoke.gd verifica movimento, mira, dash, câmera e colisão do arqueiro.
- Para alterações de cenas e recursos, importar o projeto, validar scripts e carregamento em Godot 4.7.2 e executar a cena visualmente quando controles, colisões ou apresentação forem afetados.
- Cobrir os casos mínimos do GDD: dano e cadência acumulados, XP excedente, múltiplos níveis pendentes, cartas diferentes por oferta, exclusão de habilidades únicas e reset da partida.

Esta arquitetura documenta o plano e o estado atual. Os sistemas restantes dependem das tarefas COD-006 a COD-011.

## 10. Implementação de combate para COD-004/COD-005

- O piso contém 110 tiles, com coordenadas de grade `x = -4..6` e `y = -5..4`. Os limites acompanham os vértices externos do piso. A câmera usa zoom 0,85 para mostrar a arena ampliada no início. `Cenas/cena01.tscn` herda o piso da arena base e conserva seus ajustes locais de posição.
- `PlayerStats` e `EnemyData` são recursos de configuração. `HealthComponent` guarda vida e invulnerabilidade em tempo de execução e emite `health_changed` e `died`. A hurtbox consulta o estado de dash do dono antes de aplicar dano.
- O arqueiro mantém o intervalo de ataque do GDD (0,60 s), cria `Projectile` em `BowOrigin` e usa `PlayerStats` para dano e velocidade. A flecha move-se em `Area2D`, resolve uma colisão por vez e se remove após impacto ou tempo máximo.
- `EnemyController` usa perseguição direta, colisão física e uma área de contato. Ao morrer, emite `enemy_defeated(xp_reward)` uma vez; nenhum gerenciador consome XP nesta etapa.
- **Parâmetros provisórios que não constam no GDD:** duração máxima da flecha de 1,5 s e intervalo de contato do perseguidor de 0,8 s. São valores de teste, sujeitos a avaliação de gameplay.
- Um único perseguidor é instanciado no primeiro marcador de inimigo. As ondas e a progressão permanecem para COD-006/COD-007.
