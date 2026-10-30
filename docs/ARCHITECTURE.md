# Arquitetura — Arqueiro Roguelite

**Versão:** Consolidação 0.2 — COD-012<br>
**Status:** MVP 0.1 com UI-001, GAME-001 e UI-002 implementados; Aventura e migração de modos pendentes<br>
**Referência de gameplay:** docs/GDD.md<br>
**Engine:** Godot 4.7.2, GDScript tipado

Este documento distingue **histórico**, **implementação existente**, **nova decisão aprovada**, **arquitetura proposta** e **funcionalidade futura**. Os contratos de gameplay e os valores numéricos vêm do GDD. Escolhas técnicas ainda não aprovadas estão marcadas como **proposta**, sem aprovação implícita. A auditoria de código usa `origin/develop` em `e6e3dd8`, de 30/10/2026; COD-012 altera somente documentação.

**Nova decisão aprovada:** a versão 0.2 terá somente Aventura e Infinito. Aventura substitui Ondas e usa um mapa manual com seis salas físicas em cinco etapas, dentro de uma única cena de mapa. Essa decisão ainda não está refletida nos enums, cenas ou scripts atuais. A seção 21 audita a migração e a seção 22 propõe sua arquitetura. O backlog está em [PLAN_MVP_0.2.md](PLAN_MVP_0.2.md).

## 1. Estado atual e estrutura de diretórios

A fundação COD-001/COD-002 já existe no repositório. COD-003 acrescentou o arqueiro controlável; COD-004/COD-005 acrescentaram flechas, vida, dano e um perseguidor. COD-006 acrescentou atirador, tanque e três ondas. COD-007 acrescentou XP, níveis e fila de escolhas pendentes. COD-008 acrescentou catálogo e seleção de cartas; COD-009 aplicou as oito melhorias; COD-010 completou HUD, resultados, pausa e reinício. UI-001 acrescentou atributos e cartas na pausa; GAME-001 acrescentou ondas infinitas; UI-002 acrescentou o menu e a seleção antecipada de modo. A entrada atual é `scenes/ui/main_menu.tscn`; `scenes/main.tscn` contém a partida. A arena atual é `scenes/arena_01.tscn` e instancia `scenes/player/player.tscn` no PlayerSpawn. `Cenas/cena01.tscn` preserva o caminho da antiga cena 1 como referência à arena. `assets/tiles/arena_floor.svg` fornece arte provisória; os testes smoke em `tests/` verificam a fundação, o combate, as ondas, a progressão, as cartas e o menu. Funplay MCP e GdUnit4 são addons existentes.

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

Criar diretórios e arquivos apenas quando uma tarefa precisar deles. Alguns caminhos do GDD são uma organização proposta e diferem dos caminhos atuais registrados acima.

## 2. Organização das cenas

| Cena | Papel atual |
| --- | --- |
| MainMenu | Entrada do projeto; navegação e seleção dos modos implementados em UI-002, ainda sem Aventura. |
| Main | Instancia a arena e coordena WaveDirector, UpgradeManager, HUD, UpgradeScreen e ResultScreen. |
| Arena | Contém piso, limites, obstáculos, pontos de spawn e raiz para entidades ordenadas por Y. |
| Player | CharacterBody2D com colisão, visuais, origem do arco, vida, hurtbox e câmera. |
| Arrow | Projétil com Area2D, movimento, duração máxima e resolução de colisão. |
| Chaser, RangedEnemy, Tank | Cenas de inimigo configuradas por EnemyData. |
| HUD, UpgradeScreen, ResultScreen | Apresentação; recebem eventos sem controlar diretamente atributos de entidades. |

Atualmente, Main contém fundo, Arena01, WaveDirector, UpgradeScreen, UpgradeManager, HUD e ResultScreen. Main reinicia o RunManager ao começar uma partida, conecta vitória e derrota e recarrega a cena ao reiniciar. A arena usa Floor como TileMapLayer, limites e pilares com StaticBody2D/CollisionPolygon2D, oito marcadores de spawn inimigo e Player. Player contém colisão, formas provisórias, BowOrigin, Camera2D, HealthComponent e Hurtbox. O arqueiro cria flechas em tempo de execução. WaveDirector instancia inimigos na arena a partir de WaveData e conecta suas recompensas de XP ao RunManager.

## 3. Scripts principais e responsabilidades

| Script ou componente | Responsabilidade atual |
| --- | --- |
| RunManager | Estado da partida, modo selecionado, XP, nível, vitória e derrota. |
| PlayerController | Movimento em oito direções, mira, ataque e dash. |
| HealthComponent | Vida, dano, cura e morte. |
| HurtboxComponent | Recepção de acertos e integração com vida. |
| Projectile | Movimento, colisão, aplicação de dano e remoção. |
| EnemyController | Movimento, comportamento e ataque de inimigos. |
| WaveDirector | Spawn das três ondas originais e geração progressiva do Infinito. |
| UpgradeManager | Elegibilidade, sorteio e aplicação de cartas. |
| HUD | Exibição de vida, XP, nível e onda. |
| UpgradeScreen | Exibição das três cartas e captura de uma escolha. |

Os nomes acima seguem os contratos de responsabilidade do GDD. `PlayerRuntimeStats`, `BurnComponent` e `ResultScreen` são separações introduzidas para manter o estado da partida e a interface desacoplados.

## 4. Autoload e estados

**RunManager é o único Autoload definido pelo GDD.** Seu script usa `class_name RunProgress`, sem constituir um segundo gerenciador. Ele mantém nível, XP, evoluções pendentes e controla READY, COMBAT, UPGRADE_SELECTION, VICTORY e GAME_OVER, além do legado ENDLESS_CHOICE. Guarda `selected_mode` e dados transitórios da sessão. WaveDirector e UpgradeManager pertencem às cenas e se comunicam por referências explícitas e sinais. A seção 21 distingue os estados usados dos resíduos históricos; a seção 22 propõe continuidade entre salas.

Ao subir de nível, o combate pausa e a tela de cartas continua recebendo entrada. Se houver várias evoluções pendentes, cada escolha é apresentada em sequência; só depois o combate retoma. Vitória, derrota e reinício passam pelo controlador de estados, evitando que vários scripts alterem pausa ou término independentemente.

RunManager centraliza `set_state()` e a pausa da árvore. UpgradeScreen, UpgradeManager e ResultScreen usam `PROCESS_MODE_ALWAYS` para receber escolhas e botões durante a pausa. A seleção de cartas retorna ao estado COMBAT após a última escolha pendente, conclui a vitória aguardada ou ativa a continuação infinita pendente. Para Aventura, retornar ao contexto anterior de exploração ou combate é uma mudança proposta, ainda não implementada.

## 5. Comunicação por sinais

Os contratos principais são:

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

`PlayerStats`, `EnemyData`, `UpgradeDefinition` e `WaveData` possuem scripts Resource tipados e instâncias `.tres` em `data/`. Campos que não constam no GDD continuam identificados como propostas até avaliação de gameplay.

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

Esta arquitetura documenta o plano e o MVP 0.1 implementado. Os parâmetros marcados como provisórios aguardam avaliação de sensação de combate.

## 10. Implementação de combate para COD-004/COD-005

- O piso contém 110 tiles, com coordenadas de grade `x = -4..6` e `y = -5..4`. Os limites acompanham os vértices externos do piso. A câmera usa zoom 0,85 para mostrar a arena ampliada no início. `Cenas/cena01.tscn` herda o piso da arena base e conserva seus ajustes locais de posição.
- `PlayerStats` e `EnemyData` são recursos de configuração. `HealthComponent` guarda vida e invulnerabilidade em tempo de execução e emite `health_changed` e `died`. A hurtbox consulta o estado de dash do dono antes de aplicar dano.
- O arqueiro mantém o intervalo de ataque do GDD (0,60 s), cria `Projectile` em `BowOrigin` e usa `PlayerStats` para dano e velocidade. A flecha move-se em `Area2D`, resolve uma colisão por vez e se remove após impacto ou tempo máximo.
- `EnemyController` usa perseguição direta, colisão física e uma área de contato. Ao morrer, emite `enemy_defeated(xp_reward)` uma vez; COD-007 passou a encaminhar a recompensa ao RunManager.
- **Parâmetros provisórios que não constam no GDD:** duração máxima da flecha de 1,5 s e intervalo de contato do perseguidor de 0,8 s. São valores de teste, sujeitos a avaliação de gameplay.
- COD-005 usou um perseguidor fixo para teste; COD-006 substituiu essa instância pela criação de inimigos a cada onda. COD-007 conectou o XP ao RunManager.

## 11. Inimigos adicionais de COD-006

`EnemyController` concentra aquisição do alvo, vida e sinal de derrota. `ContactEnemyController` implementa perseguição e contato para perseguidor e tanque. `RangedEnemyController` tenta manter distância, move-se com colisão física e cria projéteis inimigos. O projétil reutiliza `Projectile`, com máscara para cenário e hurtbox do jogador. Esses scripts não alteram os recursos `.tres` durante a partida.

**Parâmetros provisórios para teste, não fixados pelo GDD:** velocidade do projétil inimigo de 430 px/s, distância preferida do atirador de 220 px com tolerância de 24 px e intervalo de contato do tanque de 1,0 s. O intervalo de disparo do atirador de 1,8 s e os atributos de vida, velocidade, dano e XP dos dois inimigos seguem a seção 5 do GDD.

## 12. Ondas de COD-006 — base histórica

`WaveData` guarda uma lista ordenada de cenas inimigas. Os arquivos `data/wave_01.tres` a `data/wave_03.tres` reproduzem exatamente as três composições do GDD. `WaveDirector` é um nó de Main, instancia inimigos na arena e acompanha `enemy_defeated`. Após a última derrota de uma onda, inicia a próxima por chamada diferida; após a terceira, emite `arena_completed()` uma vez. `wave_changed(number)` informa a onda ativa.

Os oito marcadores fixos da arena oferecem posições distintas. O diretor seleciona apenas marcadores a pelo menos 128 px da posição atual do jogador e a pelo menos 80 px entre si. Se não houver marcadores suficientes no momento, aguarda até existir uma seleção válida, sem criar uma onda parcial. Essas distâncias são parâmetros técnicos configuráveis, sujeitos a avaliação visual. No ciclo original, a terceira onda conduzia à vitória após cartas pendentes. UI-002 passou a encaminhar essa conclusão conforme o modo selecionado, como auditado na seção 21; isso não define encontros da futura Aventura.

## 13. Experiência e níveis de COD-007

`RunManager` é o Autoload registrado em `project.godot`; seu script tipado usa a classe `RunProgress`. Main chama `reset_run()` ao iniciar uma nova sessão. WaveDirector conecta o sinal `enemy_defeated(xp_reward)` de cada inimigo criado a `add_experience(amount)`, sem modificar EnemyData. O cálculo usa `20 + 10 × (nível atual − 1)` e subtrai cada limiar em sequência, preservando XP excedente.

Cada nível ganho incrementa `pending_level_ups` e emite `level_up_requested()` uma vez; `experience_changed(xp, required)` publica o progresso após a recompensa. `consume_pending_level_up()` remove uma escolha da fila sem apagar XP. UpgradeManager usa essa fila para mostrar as cartas e pausar o combate; PlayerRuntimeStats recebe os efeitos escolhidos.

## 14. Seleção de cartas de COD-008

As oito cartas são `UpgradeDefinition` imutáveis em `data/upgrades/`, com identificação, texto, ícone SVG original, efeito, magnitude e limite. `UpgradeManager` sorteia três definições distintas entre as elegíveis e mantém a contagem adquirida em estado de execução. Disparo Triplo e Flecha Flamejante têm limite de uma aquisição; as cartas de atributos básicos continuam elegíveis. `UpgradeScreen` apenas apresenta opções e emite a escolha feita pelo mouse.

UpgradeManager consome exatamente uma evolução pendente por escolha e apresenta outra oferta se necessário. RunManager pausa a árvore no estado UPGRADE_SELECTION; a tela e o gerenciador continuam processando. A próxima onda espera o término da seleção antes de criar novos inimigos. COD-009 conectou a escolha aos atributos efetivos do arqueiro.

## 15. Efeitos das cartas de COD-009

`PlayerRuntimeStats` contém bônus numéricos e habilidades adquiridas, separado do `PlayerStats` compartilhado. O dano e o movimento usam bônus percentuais acumulados; o intervalo entre ataques usa o divisor `1 + bônus de velocidade de ataque`. Vitalidade aumenta a vida máxima e atual de `HealthComponent`. O dash aplica uma redução multiplicativa de 15% à recarga efetiva por aquisição.

O arqueiro cria três flechas quando possui Disparo Triplo, mantendo o dano efetivo em cada uma. `Projectile` acompanha os inimigos já atingidos e atravessa um alvo adicional por carta de perfuração. `BurnComponent` aplica 3 de dano a cada segundo por 3 segundos. Novo acerto flamejante renova a duração sem criar efeitos paralelos; a contagem do próximo segundo é preservada. As três cenas inimigas recebem esse componente reutilizável.

**Parâmetros provisórios não fixados pelo GDD:** dispersão do tiro triplo de 12° para cada lado; reduções sucessivas da recarga do dash são multiplicativas; queimaduras repetidas renovam a duração sem acumular dano. São escolhas técnicas para o MVP, sujeitas a ajuste após teste de sensação de combate.

## 16. HUD, pausa e encerramento de COD-010

`GameHUD` observa os sinais de vida, experiência e onda e consulta a recarga atual do dash. O jogador recebe um breve flash de cor ao sofrer dano. `ResultScreen` permanece ativo durante a pausa e apresenta pausa normal, vitória ou derrota; somente a pausa normal pode ser retomada com Esc. Os botões de reinício recarregam Main, que recria entidades e atributos de execução e restaura o nível inicial.

RunManager é o único controlador da pausa e dos estados; COD-010 usava os cinco estados originais do GDD, e GAME-001 acrescentou o legado ENDLESS_CHOICE. A pausa normal é uma variável separada, atualmente válida apenas durante COMBAT. A conclusão da arena fica pendente até que todas as escolhas de cartas sejam feitas. A morte cancela essa conclusão pendente e bloqueia novas ondas. HUD e telas apenas apresentam eventos e emitem ações; não alteram diretamente atributos do arqueiro. A auditoria atual e a adaptação proposta à Aventura estão nas seções 21 e 22.

## 17. Estabilização de COD-011

A importação, os doze testes smoke originais, o carregamento headless da cena principal e as renderizações das interfaces estão registrados em [VALIDATION_MVP_0.1.md](VALIDATION_MVP_0.1.md). Esse relatório de 25/10/2026 cobre COD-001 a COD-011, não Aventura. O repositório agora contém quinze scripts smoke, incluindo pausa, Infinito e menu; sua existência não comprova validação do MVP 0.2. Uma partida jogada por uma pessoa permanece necessária para avaliar sensação de combate e os parâmetros provisórios.

## 18. Política de versionamento, GitFlow e GitHub

### 18.1. Papel das branches

| Branch | Origem | Integração | Finalidade |
| --- | --- | --- | --- |
| `main` | Versão publicada | Recebe Pull Requests de `release/*` e `hotfix/*` | Histórico estável e versões entregues. |
| `develop` | Inicialmente, a `main` estável do MVP 0.1 | Recebe Pull Requests de `feature/*`, `docs/*` e sincronizações de `main` | Integração da próxima versão. |
| `feature/<tarefa>-<resumo>` | `develop` | Pull Request para `develop` | Uma funcionalidade ou tarefa de gameplay por branch. |
| `docs/<tarefa>-<resumo>` | `develop` | Pull Request para `develop` | Documentação sem alteração de código do jogo. |
| `release/<versão>` | `develop` | Pull Request para `main`; depois, sincronização de `main` para `develop` por Pull Request | Estabilização, correções e preparação de uma versão. |
| `hotfix/<tarefa>-<resumo>` | `main` | Pull Request para `main`; depois, sincronização de `main` para `develop` por Pull Request | Correção urgente da versão publicada. |

As branches `main` e `develop` não recebem implementação nem commits diretos. Cada tarefa começa em uma branch própria, criada após verificar `git status`, a branch ativa e os refs remotos. Alterações de outra tarefa que ainda não tenham commit devem ser preservadas e isoladas antes de trocar de branch. Não usar force push para reescrever o histórico compartilhado.

### 18.2. Commits, Pull Requests e validação

- Criar commits atômicos, com mensagens descritivas sobre a função da mudança. Evitar misturar documentação, ajustes de editor e gameplay sem relação.
- Abrir Pull Request para toda integração em `develop` ou `main`. Descrever escopo, arquivos relevantes, testes executados, resultados, riscos e problemas conhecidos.
- Revisar o diff e executar testes proporcionais antes do merge. Para cenas ou recursos Godot, importar o projeto e executar as verificações headless pertinentes; alterações visuais ou de controle também exigem inspeção jogável.
- Resolver conflitos preservando trabalho existente e confirmar os testes após a resolução. Não fazer merge com verificações obrigatórias falhando.
- Manter `docs/GDD.md` e este documento alinhados quando uma decisão de gameplay ou arquitetura for aprovada. Propostas continuam identificadas como tal até a aprovação.

### 18.3. Proteções no GitHub

Após publicar a base estável do MVP 0.1 e criar `develop`, proteger `main` e `develop` no GitHub. Exigir Pull Request antes de integrar, bloquear force push e exclusão das branches e aplicar as regras também aos administradores, sem bypass rotineiro. Ativar resolução de conversas e revisão obrigatória conforme houver revisores disponíveis. Exigir um status check automatizado somente depois de o workflow correspondente existir e passar nas duas branches; exigir um check inexistente impediria qualquer merge.

O alvo dos Pull Requests é `develop` para `feature/*` e `docs/*`, e `main` para `release/*` e `hotfix/*`. Após integrar uma release ou hotfix em `main`, trazer os commits para `develop` por Pull Request para impedir divergência entre as linhas de desenvolvimento. Tags de versão seguem o commit aprovado em `main` após uma release ou hotfix; nenhuma tag faz parte da migração inicial GIT-001.

### 18.4. Migração inicial

A migração começa pela auditoria dos commits locais ainda não publicados e das alterações não commitadas. Preservar ambos antes de trocar de branch. A publicação única da `main` estável do MVP 0.1 é uma exceção de bootstrap, anterior à proteção e dependente de aprovação explícita; ela não autoriza novos pushes diretos. Criar `develop` exatamente a partir desse commit e publicá-la. Depois, configurar as proteções e criar `docs/gitflow-workflow` a partir de `develop` para integrar esta política e as instruções de `AGENTS.md` por Pull Request. Nenhuma branch, tag, proteção ou configuração remota deve ser criada ou alterada sem aprovação explícita da execução da migração.

**Estado histórico:** a migração GIT-001 foi concluída. `develop` foi criada a partir da `main` estável, a política entrou por Pull Request e os rulesets ativos protegem `main` e `develop` com Pull Request obrigatório, bloqueio de force push e de exclusão. O texto acima registra a sequência de bootstrap, não uma etapa pendente.

## 19. Interface de pausa de UI-001

`ResultScreen` continua responsável pelas telas de pausa normal, vitória e derrota. Apenas durante `COMBAT` com pausa normal ativa ele expande o painel e mostra `PauseDashboard`; vitória e derrota conservam o layout e os botões anteriores. `RunManager` permanece como único controlador de estado e pausa. A tela emite pedidos para continuar ou recomeçar, tratados por Main.

`PauseStatsPanel` apresenta vida de `HealthComponent` e atributos efetivos de `PlayerRuntimeStats`: dano, intervalo de ataque convertido em ataques por segundo, movimento, recarga do dash, flechas por disparo, perfuração e habilidade elemental. Não calcula bônus nem modifica recursos de configuração. `PauseCardsPanel` consulta `UpgradeManager.get_acquired_upgrades()` e `get_acquired_count()`; mostra ícone, nome, descrição, efeito e quantidade por definição, em lista com rolagem. Nenhuma carta exibe uma mensagem vazia.

Ao receber `pause_changed(true)`, `ResultScreen` lê o jogador, `UpgradeManager`, `RunManager` e `WaveDirector`, atualiza os dois painéis e o progresso (nível, XP e onda) e só então exibe o menu. Os componentes visuais recebem essas referências por `bind()` em Main. Fechar e reabrir a pausa provoca uma nova leitura; nenhuma consulta altera o estado da partida. A recriação de Main em Recomeçar restaura os atributos e a lista de cartas da sessão inicial.

## 20. GAME-001 — histórico de seleção e geração vigente do Infinito

**Histórico substituído por UI-002:** depois da terceira onda, `arena_completed()` conduzia a `ENDLESS_CHOICE`, após cartas pendentes. `ResultScreen` apresentava duas ações e Main conectava seus sinais a `choose_endless_mode()` ou `choose_victory()`. Hoje `complete_initial_waves()` trata a conclusão pelo modo já selecionado no menu. O enum legado, seus métodos, flags, sinais e botões ainda existem no código, mas a partida normal não solicita essa escolha. A seção 21 detalha os pontos a migrar; não se deve reintroduzir esse estado como fluxo da Aventura.

**Implementação vigente da geração:** `WaveDirector` conserva os três `WaveData` originais. No Infinito, avança automaticamente para a onda 4 após as escolhas de cartas pendentes. As regras abaixo permanecem, independentemente da substituição de Ondas por Aventura no menu.

No modo infinito, o diretor monta cada composição em memória a partir das três cenas inimigas já configuradas nas ondas iniciais, sem criar novos arquivos `WaveData`. O total planejado é o total da terceira onda mais um por onda posterior. A ordem dos tipos é embaralhada por onda e repetida até atingir o total. O diretor controla uma fila de spawns, aguarda o intervalo configurado, respeita o limite ativo e só avança quando a fila e a lista de inimigos ativos estão vazias. A busca de marcadores evita proximidade do jogador e sobreposição com inimigos ativos; se nenhum ponto ideal estiver disponível, tenta novamente e, após um tempo limite, usa o marcador livre mais distante que esteja a pelo menos 64 px do jogador. Quando todos os marcadores estão ocupados, aguarda espaço liberado por derrotas. Seleção de cartas ou pausa normal suspendem os temporizadores e spawns.

`EnemyController` recebe multiplicadores por instância antes de entrar na árvore. `HealthComponent` recebe vida máxima escalada, e controladores de contato e distância consultam dano efetivo escalado. Os recursos `EnemyData` compartilhados permanecem imutáveis. Para a onda `n ≥ 4`, os multiplicadores são `1 + 0,05 × (n − 3)` para vida e `1 + 0,02 × (n − 3)` para dano; o resultado é arredondado ao inteiro mais próximo. XP e demais atributos do inimigo conservam os dados originais. `GameHUD` mostra a numeração sem limite de três a partir da onda 4.

**Parâmetros provisórios exportados em `WaveDirector`:** máximo de 12 inimigos ativos; 0,3 s entre spawns; 1,5 s entre ondas; nova tentativa após 0,5 s sem ponto válido; recuperação após 3,0 s sem ponto ideal; distância mínima normal de 128 px do jogador e 80 px entre inimigos; distância mínima de recuperação de 64 px. Esses valores, a composição embaralhada e o arredondamento aditivo precisam de avaliação jogável antes de serem fixados para balanceamento.

## 21. Menu, auditoria de modos e migração para Aventura

### 21.1. Nova decisão aprovada e diferença para o código

A seleção vigente no **design 0.2** é somente **Aventura** e **Infinito**, mais Voltar como navegação. Aventura é a modalidade principal e substitui Ondas. O menu continua sendo uma cena específica, separada da partida. Essa é uma decisão aprovada de design, não uma declaração de implementação.

**Implementação existente de UI-002:** `project.godot` inicia `res://scenes/ui/main_menu.tscn`; `scripts/ui/main_menu.gd` controla Jogar, opções e Voltar, solicita `select_mode()` e carrega `res://scenes/main.tscn`. O código ainda usa os seguintes identificadores:

| Ponto auditado | Código existente | Migração planejada, ainda não executada |
| --- | --- | --- |
| `scripts/core/run_manager.gd` | `enum GameMode { WAVES, ENDLESS }`; `selected_mode` e `return_to_menu()` usam `WAVES` como padrão. | Substituir `WAVES` por `ADVENTURE`, manter `ENDLESS` e tornar Aventura o padrão. |
| `scripts/ui/main_menu.gd` e `scenes/ui/main_menu.tscn` | Botão `Waves`, texto MODO ONDAS e ligação a `GameMode.WAVES`. | Apresentar Aventura e Infinito; encaminhar cada modo a sua composição de partida. |
| `scripts/main/main_controller.gd` e `scenes/main.tscn` | Referências fixas a `Arena01/Player` e `WaveDirector`, com `reset_run()` em `_ready()`. | Compor uma sessão por modo e executar reset somente no início/reinício da tentativa, nunca na entrada de sala. |
| `RunManager.complete_initial_waves()` | `WAVES` pede vitória; `ENDLESS` ativa `endless_mode_started()` após cartas pendentes. | A terceira onda pertence apenas à abertura do Infinito; Aventura conclui salas e só pede vitória pelo chefe final. |
| `scripts/systems/wave_director.gd` | Inicia ondas automaticamente, usa `endless_mode` para gerar ondas posteriores e ainda reconhece a retomada legada. | Manter geração do Infinito; impedir ativação automática desse diretor em Aventura. Reutilizar apenas código de encontro necessário. |
| `scripts/ui/hud.gd`, `result_screen.gd` e painéis de pausa | HUD e pausa recebem `WaveDirector`; texto de vitória menciona três ondas. | COD-013 adapta o bind mínimo para composição sem WaveDirector; COD-020 integra progresso de sala/etapa e resultado pelo chefe, preservando UI-001. |
| `tests/main_menu_smoke.gd`, `arena_smoke.gd`, `endless_waves_smoke.gd`, `experience_integration_smoke.gd`, `pause_menu_smoke.gd`, `run_flow_smoke.gd`, `upgrade_effects_smoke.gd`, `upgrade_selection_smoke.gd` e `wave_smoke.gd` | Instanciam Main e/ou dependem de `WAVES`, Arena01, WaveDirector, três ondas ou vitória do ciclo antigo. | Já em COD-013, preparar fixtures com modo explícito ou testar componentes isolados, sem perder cobertura. Adaptar vitória de três ondas e completar a cobertura da Aventura em COD-020. |

`reset_run()` atualmente preserva o modo selecionado e limpa XP, nível, flags e pausa. Main recria o jogador e UpgradeManager ao recarregar a partida; o modo permanece no Autoload. `return_to_menu()` limpa o estado e volta ao padrão `WAVES`. A migração deve conservar a semântica de reinício e troca de modo, alterando o padrão para `ADVENTURE`. Não existe salvamento de partidas que exija conversão persistida do enum; ainda assim, todas as referências em cenas, scripts e testes devem ser auditadas em COD-013.

### 21.2. Auditoria de estados de RunManager/RunProgress

| Estado ou variável atual | Uso confirmado | Tratamento planejado |
| --- | --- | --- |
| `READY` | Após reset, antes de `begin_combat()`; também durante o menu. | Manter preparação da tentativa; menu continua separado da cena da partida. |
| `COMBAT` | Processamento da partida e único contexto atual da pausa normal. | Manter para encontros; avaliar exploração separada conforme seção 22. |
| `UPGRADE_SELECTION` | Pausa global enquanto cartas pendentes são escolhidas. | Conservar, ampliando a origem das ofertas e o contexto de retorno. |
| `VICTORY` | Conclusão das três ondas no modo legado. | Na Aventura, somente chefe final; nunca concluir o Infinito por onda ou chefe. |
| `GAME_OVER` | Morte do jogador; cancela transições e spawns. | Preservar prioridade sobre recompensa, entrada de sala e conclusão. |
| `ENDLESS_CHOICE` | Enum, branch de pausa e apresentação ainda presentes; sem solicitação no fluxo normal de UI-002. | Remover o caminho legado após migrar referências e testes; não reutilizar para Aventura. |
| `normal_paused` | Flag separada dos estados; Esc alterna durante COMBAT. | Preservar comportamento existente e permitir pausa na exploração proposta. |
| `endless_mode` | Flag de execução ativada após a terceira onda; distinta do modo escolhido no menu. | Manter essa distinção; não usar como identificação da Aventura. |

**Resíduos auditados:** `_endless_choice_pending`, `request_endless_choice()`, `choose_endless_mode()` e `choose_victory()` em RunProgress; sinais `endless_requested`/`victory_requested`, nós Endless/Finish e tratamento de ENDLESS_CHOICE em ResultScreen; conexões correspondentes em Main. COD-012 apenas registra esses resíduos. Remoção e testes de regressão pertencem a COD-013.

### 21.3. Navegação e validação existente

ResultScreen atualmente emite `main_menu_requested` em vitória/derrota. Main retira a pausa e carrega o menu, cujo `_ready()` limpa a tentativa. Recomeçar recarrega Main e conserva o modo. O design aprovado mantém esse contrato para Aventura e Infinito; a implementação precisa limpar também progresso de mapa/salas e recompensas pendentes.

`tests/main_menu_smoke.gd` cobre o fluxo UI-002 existente, não Aventura. A validação documental COD-012 não substitui executar os testes da futura migração. O estilo e os textos visuais continuam provisórios.

## 22. Arquitetura proposta do Modo Aventura — não implementada

### 22.1. Limites e alternativas avaliadas

**Requisito aprovado:** todas as seis salas e seus corredores/portas pertencem a uma única cena do primeiro mapa. Uma sala pode instanciar componentes reutilizáveis como filhos dessa cena; entrar nela não chama `change_scene_to_file()` nem recarrega Main. Mapa e sala são unidades diferentes: um mapa contém várias salas; etapa é a posição na progressão e pode conter duas salas alternativas.

**Proposta recomendada:** manter Main como dono da sessão, um mapa como filho substituível e um RoomDirector por tentativa. Isso permite preservar Player, UpgradeManager, HUD e suas referências. Trocar a cena inteira por sala violaria o requisito de continuidade física. Colocar progressão, portas, encontros e recompensas em um único script do mapa concentraria responsabilidades; por isso propõem-se dados e controladores pequenos. Não é necessário outro Autoload nem uma estrutura genérica de grafo procedural.

### 22.2. Dados e responsabilidades propostas

Todos os nomes, caminhos e contratos desta seção são propostas para as próximas tarefas; os arquivos ainda não existem. Dados Resource continuam imutáveis durante a partida.

| Unidade proposta | Caminho proposto | Responsabilidade e dados |
| --- | --- | --- |
| `MapDefinition : Resource` | `scripts/data/map_definition.gd`; `data/maps/map_01.tres` | `map_id: StringName`, `scene: PackedScene`, `entry_room_id: StringName`, `rooms: Array[RoomDefinition]`. Identifica a cena completa e valida IDs/conexões, sem gerar geometria. |
| `RoomDefinition : Resource` | `scripts/data/room_definition.gd`; `data/rooms/` | `room_id: StringName`, `stage: int`, `room_type` tipado (COMBAT, REST, ELITE, BOSS), `next_room_ids: Array[StringName]`, `encounters: Array[WaveData]` e configuração de recompensa. Valores de descanso/elite/chefe aguardam design. |
| `RoomDirector : Node` | `scripts/systems/room_director.gd` | Sala ativa, salas iniciadas/concluídas, rota escolhida e recebimento de recompensas em estado local da tentativa. Valida acesso, coordena encontros e encaminha término final ao RunManager. |
| `RoomController : Node2D` | `scripts/rooms/room_controller.gd` | Referência à definição, área de entrada, portas, marcadores de inimigos e vida do encontro local. Emite entrada e conclusão uma vez; não decide vitória da partida. |
| Porta e área de entrada | `scripts/rooms/room_door.gd`, `scenes/rooms/room_door.tscn` | Porta física com colisão e gatilho Area2D; permite passagem e solicita entrada, sem teleporte ou troca de cena. |
| Primeiro mapa | `scenes/maps/map_01.tscn` | Geometria manual, TileMapLayer isométrico, colisões e seis RoomController nos locais físicos definidos em COD-015. |

IDs devem ser únicos; conexões só podem apontar para salas existentes. O validador proposto verifica cinco etapas, seis salas, bifurcação na segunda e caminho até o chefe, sem codificar essas quantidades no controlador reutilizável de todos os mapas. Estado de conclusão, inimigos vivos e recompensa recebida não deve ser gravado em `.tres`.

### 22.3. Composição da sessão e preservação do jogador

Estrutura conceitual proposta, não uma cena já criada:

```text
Main — sessão e composição por modo
├── GameplayRoot — Node2D com Y-sort
│   ├── Player — uma instância por tentativa
│   └── MapRoot
│       └── Map01 — cena única do mapa, com Y-sort nos ramos pertinentes
│           ├── Floor / Walls / Corridors
│           └── Rooms — seis salas físicas, portas e gatilhos
├── RoomDirector — somente na Aventura
├── UpgradeManager / UpgradeScreen
└── HUD / ResultScreen
```

O Infinito continua compondo a arena e WaveDirector existentes, sem RoomDirector concorrente. O atual Player filho de Arena01 exige adaptação na composição da Aventura; os caminhos fixos `Arena01/Player` não devem ser propagados. Main fornece referências explícitas aos sistemas.

Cruzar portas conserva a mesma instância de Player, HealthComponent e PlayerRuntimeStats, assim como o UpgradeManager, XP e nível do RunManager. Não chama `reset_run()`, `HealthComponent.configure()` nem recria o jogador. Projéteis e efeitos locais do encontro têm política de encerramento própria, a definir em COD-016, sem apagar melhorias ou conceder cura implícita. Y-sort usa os pés; piso, portas, personagens e objetos mantêm colisões e ordem visual consistentes entre os ramos da cena.

### 22.4. Entrada, encontro, portas e término

**Contratos propostos:** `RoomDirector.try_enter_room(room_id: StringName) -> bool`; `RoomController.begin_encounter(player: PlayerController) -> void`; sinais `room_entered(room_id: StringName)` e `room_completed(room_id: StringName)`. O diretor valida transição e registra a sala antes de iniciar seu conteúdo. Gatilhos repetidos, múltiplos shapes do jogador e retorno a sala concluída não podem reiniciar encontro, XP ou recompensa.

**Proposta de portas:** manter saídas de progressão bloqueadas durante encontros e escolhas de recompensa; abri-las depois da conclusão local. A política de retorno à sala anterior e de acesso ao ramo não escolhido precisa de aprovação em COD-015. A implementação deve distinguir fechamento de acesso e gatilho de início para não prender o jogador na colisão da porta. Gatilhos monitoram o corpo do Player e não projéteis/inimigos; novas camadas só serão atribuídas quando necessárias.

RoomController reutiliza EnemyController, suas cenas e WaveData para encontros finitos, mantendo contagem de inimigos e fila de spawns separadas da geração infinita. Pode-se extrair uma rotina pequena de spawn compartilhada se houver duplicação comprovada; não se deve instanciar o WaveDirector atual sem desativar seu início automático e sua progressão global. Cada derrota concede XP exatamente uma vez ao RunManager, usando o mesmo sinal existente.

Concluir o encontro produz `room_completed`, não VICTORY. RoomDirector autoriza o avanço e solicita recompensa uma única vez. Apenas a conclusão da sala final pelo chefe pode pedir `RunManager.request_victory()` na Aventura; a vitória espera as escolhas de cartas/recompensas pendentes. GAME_OVER tem prioridade e cancela spawns, entradas e conclusões pendentes.

### 22.5. Cartas por nível e por recompensa

**Limitação existente:** UpgradeManager oferece cartas apenas por `pending_level_ups`, e `select_upgrade()` consome uma evolução a cada escolha. Usá-lo diretamente para recompensa de sala consumiria a fila errada. A extensão deverá separar a origem da oferta e preservar o cálculo de nível.

**Proposta para COD-017:** adicionar `request_reward_choice(source_id: StringName) -> void` e sinal `reward_choice_resolved(source_id: StringName)`, usando a mesma elegibilidade, oferta de três cartas distintas, aplicação e contagem. Uma fila distingue pedidos de nível e recompensa; a escolha de recompensa não aumenta nível, não cria XP artificial e não consome `pending_level_ups`. O identificador de origem impede concessão duplicada da mesma recompensa de sala.

Proposta de ordenação: resolver evoluções já pendentes e depois recompensas de sala, sem abrir duas telas simultâneas. RunManager permanece dono de UPGRADE_SELECTION e restaura o contexto anterior depois de toda a fila; RoomDirector só libera progressão após o pedido resolvido. Antes de implementar, aprovar quantidade de ofertas por sala, quais salas recompensam e benefício do descanso. O descanso pode usar `HealthComponent.heal()` se a cura for aprovada; valores e repetição não estão definidos.

### 22.6. Estados, reinício e conclusão da tentativa

**Proposta:** acrescentar EXPLORATION ao RunState para deslocamento entre encontros e descanso, mantendo COMBAT, UPGRADE_SELECTION e estados terminais. RunManager continua único dono da pausa; `finish_upgrade_selection()` precisará restaurar exploração ou combate e priorizar derrota/vitória pendente. Estado de sala (não iniciada, ativa, concluída) fica no RoomDirector, separado do estado global. A pausa normal deverá funcionar nos contextos ativos, preservando o dashboard de UI-001.

Nova tentativa ou Recomeçar: limpar RunManager, RoomDirector, filas de recompensa, entidades, vida e build; preservar `selected_mode`. Retorno ao menu: descartar sessão/mapa e todas as referências, limpar filas e retirar pausa. Entrada de sala não é nova tentativa. `ResultScreen` precisa de texto de vitória pelo chefe, e HUD/dashboard devem receber progresso de sala/etapa sem depender obrigatoriamente de WaveDirector.

### 22.7. Elite, chefes e extensões futuras

A sala de elite reutilizará os inimigos existentes e configuração própria do encontro; composição, multiplicadores e recompensa estão pendentes. O chefe final requer comportamento e dados próprios, com vida, dano e sinal de derrota compatíveis com os componentes de combate existentes. Seu controlador não deve chamar vitória global: o dono do encontro decide o efeito da derrota.

**Requisito arquitetural aprovado:** o chefe deve ser reutilizável em Aventura e Infinito. Na Aventura, RoomDirector encerra a tentativa pelo chefe final; no Infinito, um futuro agendador de encontros retomará as ondas. Chefes periódicos no Infinito são proposta COD-022, fora do MVP 0.2 inicial; frequência e escala ainda não foram definidas.

Um mapa futuro poderá ser outra PackedScene selecionada por MapDefinition e carregada dentro de MapRoot, separadamente do primeiro mapa. Main e os sistemas de sessão poderão persistir, removendo encontros antigos e religando referências de mapa/diretor, sem reset de vida/build. Essa possibilidade não exige entregar um segundo mapa ou transições entre mapas agora.

Novos tipos de sala podem ampliar RoomDefinition e fornecer componentes locais de encontro/recompensa. Armadilhas futuras poderão usar colisão e HealthComponent/HurtboxComponent com origem de dano própria. Não criar agora um framework de plugins de sala, armadilhas funcionais, gerador procedural ou progressão permanente.

### 22.8. Validação proposta e decisões pendentes

COD-013 a COD-021 devem cobrir modo selecionado, grafo de salas, passagem física, identidade do jogador, vida/build, uma ativação por sala, XP e recompensa únicos, seleção de cartas na pausa, prioridade da morte, elite, chefe e limpeza de reinício. A matriz de testes e os critérios por tarefa estão em PLAN_MVP_0.2.md.

Antes de suas respectivas implementações, decidir e registrar: distribuição final de salas e política de retorno/bifurcação (COD-015); composições e limpeza de projéteis (COD-016); benefícios de descanso, ofertas e valores de recompensa (COD-017); composição/escala de elite (COD-018); identidade, padrões, atributos e recompensas do chefe (COD-019). Os contratos e caminhos propostos podem ser ajustados ao implementar, mantendo GDD e plano coerentes.
