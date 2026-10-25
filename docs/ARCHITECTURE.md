# Arquitetura — Arqueiro Roguelite

**Versão:** 0.1<br>
**Status:** MVP 0.1 implementado, com parâmetros provisórios pendentes de avaliação jogável<br>
**Referência de gameplay:** docs/GDD.md<br>
**Engine:** Godot 4.7.2, GDScript tipado

Este documento descreve a arquitetura implementada no MVP 0.1 e as propostas ainda abertas. Os contratos de gameplay e os valores numéricos vêm do GDD. Escolhas técnicas ainda não definidas no GDD estão marcadas como **proposta**, sem aprovação implícita.

## 1. Estado atual e estrutura de diretórios

A fundação COD-001/COD-002 já existe no repositório. COD-003 acrescentou o arqueiro controlável; COD-004/COD-005 acrescentaram flechas, vida, dano e um perseguidor. COD-006 acrescentou atirador, tanque e três ondas. COD-007 acrescentou XP, níveis e fila de escolhas pendentes. COD-008 acrescentou catálogo e seleção de cartas; COD-009 aplicou as oito melhorias; COD-010 completou HUD, resultados, pausa e reinício. A cena principal atual é scenes/main.tscn; a arena atual é scenes/arena_01.tscn e instancia scenes/player/player.tscn no PlayerSpawn. Cenas/cena01.tscn preserva o caminho da antiga cena 1 como referência à arena. assets/tiles/arena_floor.svg fornece arte provisória; os testes smoke em tests/ verificam a fundação, o combate, as ondas, a progressão e as cartas. Funplay MCP e GdUnit4 são addons existentes.

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

Os nomes acima seguem os contratos de responsabilidade do GDD. `PlayerRuntimeStats`, `BurnComponent` e `ResultScreen` são separações introduzidas para manter o estado da partida e a interface desacoplados.

## 4. Autoload e estados

**RunManager é o único Autoload definido pelo GDD.** Ele mantém nível, XP, evoluções pendentes e controla os estados READY, COMBAT, UPGRADE_SELECTION, VICTORY e GAME_OVER. Guarda dados transitórios da sessão e poderá futuramente permitir continuidade entre salas. WaveDirector e UpgradeManager pertencem às cenas e se comunicam por referências explícitas e sinais.

Ao subir de nível, o combate pausa e a tela de cartas continua recebendo entrada. Se houver várias evoluções pendentes, cada escolha é apresentada em sequência; só depois o combate retoma. Vitória, derrota e reinício passam pelo controlador de estados, evitando que vários scripts alterem pausa ou término independentemente.

RunManager centraliza `set_state()` e a pausa da árvore. UpgradeScreen, UpgradeManager e ResultScreen usam `PROCESS_MODE_ALWAYS` para receber escolhas e botões durante a pausa. A seleção de cartas retorna ao estado COMBAT após a última escolha pendente ou conclui a vitória aguardada.

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

## 12. Ondas de COD-006

`WaveData` guarda uma lista ordenada de cenas inimigas. Os arquivos `data/wave_01.tres` a `data/wave_03.tres` reproduzem exatamente as três composições do GDD. `WaveDirector` é um nó de Main, instancia inimigos na arena e acompanha `enemy_defeated`. Após a última derrota de uma onda, inicia a próxima por chamada diferida; após a terceira, emite `arena_completed()` uma vez. `wave_changed(number)` informa a onda ativa.

Os oito marcadores fixos da arena oferecem posições distintas. O diretor seleciona apenas marcadores a pelo menos 128 px da posição atual do jogador e a pelo menos 80 px entre si. Se não houver marcadores suficientes no momento, aguarda até existir uma seleção válida, sem criar uma onda parcial. Essas distâncias são parâmetros técnicos configuráveis, sujeitos a avaliação visual. Após a terceira onda, sinaliza a conclusão; RunManager apresenta a vitória após qualquer escolha de carta ainda pendente.

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

RunManager é o único controlador da pausa e dos cinco estados do GDD. A pausa normal é uma variável separada, válida apenas durante COMBAT. A conclusão da arena fica pendente até que todas as escolhas de cartas sejam feitas. A morte cancela essa conclusão pendente e bloqueia novas ondas. HUD e telas apenas apresentam eventos e emitem ações; não alteram diretamente atributos do arqueiro.

## 17. Estabilização de COD-011

A importação, os doze testes smoke, o carregamento headless da cena principal e as renderizações das interfaces estão registrados em [VALIDATION_MVP_0.1.md](VALIDATION_MVP_0.1.md). Uma partida jogada por uma pessoa permanece necessária para avaliar sensação de combate e os parâmetros provisórios, sem alterar as regras do GDD até haver decisão aprovada.

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
