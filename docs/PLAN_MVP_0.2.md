# Plano de implementação — MVP 0.2

**Status:** planejamento; nenhuma tarefa COD-013 a COD-021 implementada por COD-012.<br>
**Data e base auditada:** 30/10/2026, `origin/develop` em `e6e3dd8`.<br>
**Objetivo:** entregar Aventura em um mapa manual de seis salas conectadas, preservando o Infinito.<br>
**Especificação:** [GDD.md](GDD.md), especialmente seções 18 a 20.<br>
**Arquitetura proposta:** [ARCHITECTURE.md](ARCHITECTURE.md), seções 21 e 22.<br>
**Tecnologias:** Godot 4.7.2, GDScript tipado, TileMapLayer, Resources e addons existentes.

O escopo de gameplay aprovado vem do GDD. A decomposição, os nomes de arquivos e as interfaces abaixo são propostas técnicas para orientar a execução; não são código existente. Antes de executar cada tarefa, ler AGENTS.md, GDD e arquitetura, conferir Git e abrir sua branch a partir de `origin/develop`. Implementar uma tarefa por vez, com commits atômicos, testes proporcionais e Pull Request; não integrar diretamente em main/develop. O plano não autoriza implementar todas as tarefas dentro da branch documental COD-012.

## Restrições comuns

- Modalidades finais: somente Aventura e Infinito; remover Ondas como modalidade selecionável.
- Um mapa inicial manual, cinco etapas e seis salas físicas; bifurcação combate/descanso na segunda etapa.
- Todas as salas, portas e corredores existem em uma única cena de mapa. A passagem entre salas conserva a instância do jogador e a build/vida; não troca cena nem reinicia a tentativa.
- Reutilizar inimigos, XP, oito cartas, componentes de dano, pausa UI-001 e geração infinita GAME-001. RunManager continua responsável pelo estado global.
- Chefe final encerra Aventura; o mesmo chefe deve poder ser usado em outro contexto sem encerrar a partida por conta própria.
- Geração procedural, novos mapas completos, armadilhas funcionais, novas cartas, raridades e progressão permanente ficam fora da entrega inicial.
- Parâmetros de descanso, encontros, elite e chefe precisam de aprovação antes de sua implementação; não alterar os atributos básicos para preencher lacunas.

## Base confirmada e pendências de design

UI-001, GAME-001 e UI-002 já estão integrados em develop. O código usa `GameMode.WAVES`/`ENDLESS`, menu com Ondas/Infinito, referências `Arena01/Player` e estados legados de escolha pós-terceira onda. Aventura, MapDefinition, RoomDefinition, RoomDirector e RoomController ainda não existem. O relatório [VALIDATION_MVP_0.1.md](VALIDATION_MVP_0.1.md) é histórico; seus testes não certificam Aventura.

| Decisão pendente | Proposta ou limite já conhecido | Resolver antes de |
| --- | --- | --- |
| Distribuição física e tipos por etapa | Proposta: combate → combate/descanso → combate → elite → chefe. Contagem e bifurcação da etapa 2 são aprovadas. | COD-015 |
| Reentrada, retorno e ramo não escolhido | Não conceder de novo XP, encontros ou recompensa por gatilho repetido. Política de bloqueio do outro ramo ainda não aprovada. | COD-015 |
| Encontros comuns e limpeza local | Usar inimigos existentes; decidir composições e destino de projéteis ao concluir sala. | COD-016 |
| Descanso e recompensas | Definir benefício, magnitude, repetição e quais salas concedem ofertas. Proposta: níveis pendentes antes de recompensas. | COD-017 |
| Elite | Definir composição, escala e recompensa, sem modificar EnemyData compartilhado. | COD-018 |
| Chefe | Definir identidade, ataques, telegráficos, atributos e recompensa. Sem frequência de chefes no Infinito nesta entrega. | COD-019 |

## Dependências e resultado de cada tarefa

| ID | Entrega | Dependências |
| --- | --- | --- |
| COD-013 | Migração de modos, remoção do fluxo legado e composição por modo | COD-012 integrada |
| COD-014 | Dados de mapa/sala e coordenação de progressão local | COD-013 |
| COD-015 | Mapa físico, seis salas, corredores, portas e bifurcação | COD-014 e decisões de topologia/retorno |
| COD-016 | Encontros finitos por sala com inimigos existentes e XP | COD-015 e composições aprovadas |
| COD-017 | Cartas de recompensa e descanso sem confundir níveis | COD-016 e regras de recompensa/descanso aprovadas |
| COD-018 | Sala de elite configurada | COD-016, COD-017 e parâmetros de elite aprovados |
| COD-019 | Chefe reutilizável e conclusão da Aventura | COD-016, COD-017 e design do chefe aprovado |
| COD-020 | Integração de HUD, pausa, resultados e ciclo completo | COD-015 a COD-019 |
| COD-021 | Revisão, regressão e validação do MVP 0.2 | COD-020 |

COD-018 e COD-019 não dependem do comportamento interno uma da outra; ambas são necessárias para integrar o mapa completo em COD-020. As entregas intermediárias são infraestrutura em develop; não declarar Aventura jogável nem publicar a versão 0.2 antes de COD-021.

## COD-013 — Migrar modos e separar composição da sessão

**Prioridade:** P0. **Arquivos previstos:** modificar `scripts/core/run_manager.gd`, `scripts/main/main_controller.gd`, `scenes/main.tscn`, `scripts/ui/main_menu.gd`, `scenes/ui/main_menu.tscn`, `scripts/ui/hud.gd`, `scripts/ui/result_screen.gd`, `scenes/ui/result_screen.tscn` e `scripts/systems/wave_director.gd`. Atualizar os nove testes que dependem de Main/arena ou do modo antigo, listados na arquitetura, seção 21.1; criar `tests/game_mode_smoke.gd`.

**Interfaces:** enum planejado `GameMode { ADVENTURE, ENDLESS }`; preservar `select_mode(mode: GameMode) -> void`, `reset_run() -> void` e `return_to_menu() -> void`. Main compõe o modo selecionado. A preparação da Aventura não inicia o WaveDirector automático nem simula a arena antiga com outro nome.

- [ ] Criar testes de seleção/padrão ADVENTURE, reinício no mesmo modo e limpeza de XP/cartas/pausa; confirmar falha com o enum atual.
- [ ] Migrar `WAVES`, os padrões e a apresentação; retirar ENDLESS_CHOICE, suas flags, métodos, sinais, botões e conexões legadas auditadas na arquitetura.
- [ ] Isolar a composição por modo. Manter arena e geração existentes no Infinito; deixar a preparação da Aventura pronta para o mapa de COD-014/COD-015, sem prometer uma aventura já jogável.
- [ ] Adaptar já nesta tarefa o bind mínimo de HUD/ResultScreen para a preparação da Aventura sem WaveDirector: nenhuma leitura/conexão de referência ausente. Testar carregamento e retorno ao menu nessa composição. O progresso real de sala/etapa fica para COD-020; não atrasar a correção dessa dependência estrutural até lá.
- [ ] Migrar os testes acoplados a Main para selecionar Infinito explicitamente quando verificam arena/ondas/cartas, ou para fixtures de componentes quando verificam vitória pendente. Trocar a expectativa automática de vitória na terceira onda por continuação no Infinito; não criar uma modalidade Ondas oculta para manter testes antigos.
- [ ] Importar e executar os testes de modo, arena e todos os smoke existentes afetados; pesquisar referências remanescentes a WAVES/ENDLESS_CHOICE em scripts, cenas e testes. Atualizar docs, revisar diff e fazer commit na branch da tarefa.

**Aceite:** enum e menu possuem só os dois modos aprovados; nenhuma seleção antiga após a terceira onda; reset preserva o modo e limpa a tentativa; Infinito ainda começa nas três ondas originais e avança à quarta. A migração de identificadores não é tratada como conclusão da Aventura.

## COD-014 — Modelar mapa, salas e progressão local

**Prioridade:** P0. **Arquivos propostos:** criar `scripts/data/map_definition.gd`, `scripts/data/room_definition.gd`, `scripts/systems/room_director.gd`, `scripts/rooms/room_controller.gd` e `tests/room_graph_smoke.gd`. Integrar a preparação de Aventura em Main/RunManager quando necessário.

**Interfaces propostas:** `MapDefinition` e `RoomDefinition` com os campos da arquitetura, seção 22.2; `RoomDirector.configure(definition: MapDefinition, map_root: Node2D, player: PlayerController) -> void`; `try_enter_room(room_id: StringName) -> bool`; sinais `room_entered(room_id: StringName)` e `room_completed(room_id: StringName)`. Estado de sala pertence ao diretor e não aos Resources.

- [ ] Criar teste com seis IDs, cinco etapas, duas salas na etapa 2 e caminho das duas alternativas até o chefe. Testar ID duplicado, ligação inexistente, entrada inválida e chefe inacessível; confirmar falha antes da implementação.
- [ ] Implementar os dados, validação da definição e transições locais com referências explícitas; não construir um gerador procedural ou Autoload por sala.
- [ ] Propor EXPLORATION como contexto ativo separado de COMBAT; garantir que RoomDirector não altera diretamente a pausa global. Preservar prioridade de GAME_OVER e impedir reativação de salas concluídas.
- [ ] Executar `room_graph_smoke.gd` e os testes de RunManager/modo; revisar recursos imutáveis e estado limpo ao iniciar nova tentativa; atualizar docs e fazer commit.

**Aceite:** uma definição válida pode ser carregada em teste; definições inválidas são diagnosticadas; cada entrada/conclusão ocorre uma vez; concluir sala não emite vitória global; reiniciar limpa o progresso local sem modificar a configuração.

## COD-015 — Construir mapa físico e passagem entre salas

**Prioridade:** P0. **Arquivos propostos:** criar `scenes/maps/map_01.tscn`, `data/maps/map_01.tres`, `data/rooms/map_01/`, `scripts/rooms/room_door.gd`, `scenes/rooms/room_door.tscn` e `tests/adventure_map_smoke.gd`. Ajustar composição de Main e RoomController. Não criar uma cena de jogo separada para cada sala.

**Interfaces:** consumir MapDefinition/RoomDefinition e `try_enter_room()` de COD-014. Main instancia Map01 e Player uma vez por tentativa, fornece as referências e mantém Player fora do ciclo de criação/remoção local de salas.

- [ ] Registrar aprovação da distribuição de salas e das regras de retorno/bifurcação antes de fixar o mapa e o acesso às portas.
- [ ] Criar teste de contagem e conectividade física. Guardar `player.get_instance_id()`, vida 90/100 após dano de 10 e um upgrade UPG-001; atravessar uma porta e exigir a mesma instância, vida 90/100 e dano efetivo 12.
- [ ] Construir piso 128 × 64, paredes, obstáculos, corredores, seis áreas de sala e portas no mesmo mapa; usar formas originais provisórias, TileMapLayer e Y-sort. Fazer gatilhos aceitarem somente o Player e tratarem entradas repetidas sem duplicação.
- [ ] Importar e executar `adventure_map_smoke.gd` e `arena_smoke.gd`; inspecionar visualmente câmera, pés/Y-sort, paredes e travessia de ambas as alternativas em 1280 × 720. Documentar e fazer commit.

**Aceite:** cinco etapas e seis salas físicas navegáveis, bifurcação na segunda, nenhuma troca de cena por sala, colisões utilizáveis e jogador/vida/build preservados. Arte provisória é suficiente; encontros completos ainda dependem de COD-016.

## COD-016 — Implementar encontros finitos por sala

**Prioridade:** P0. **Arquivos previstos:** modificar `scripts/rooms/room_controller.gd`, `scripts/systems/room_director.gd` e dados dos encontros em `data/rooms/map_01/`; criar `tests/room_encounter_smoke.gd`. Extrair uma rotina pequena de spawn de WaveDirector somente se isso reduzir duplicação, mantendo seus testes.

**Interfaces:** `RoomController.begin_encounter(player: PlayerController) -> void`, `room_completed(room_id: StringName)` e o sinal existente `EnemyController.enemy_defeated(xp_reward: int)`. RunManager recebe `add_experience(amount)` exatamente uma vez por derrota. Configurações de encontro podem reutilizar WaveData sem ativar a geração infinita.

- [ ] Registrar composições e política de encerramento de projéteis locais; criar testes de encontro vazio/inválido diagnosticado, spawns válidos, múltiplos inimigos, última derrota e reentrada.
- [ ] Implementar encontros com perseguidor, atirador e tanque existentes, alvo explícito e contagem local. Bloquear progressão durante encontro conforme política de portas aprovada.
- [ ] Testar que uma derrota concede XP configurado uma vez, cartas pausam encontro/spawn e portas só liberam após conclusão válida. Morte do jogador cancela spawns e impede conclusão tardia de sala.
- [ ] Executar `room_encounter_smoke.gd`, testes de inimigos/XP/Infinito e `arena_smoke.gd` após importação; revisar colisões e fazer commit com documentação atualizada.

**Aceite:** sala completa somente após todos os inimigos planejados serem derrotados; não reinicia ao cruzar o mesmo gatilho; recompensa de XP não duplica; finalizar combate comum não causa VICTORY e não altera o Infinito.

## COD-017 — Integrar recompensas de cartas e descanso

**Prioridade:** P0. **Arquivos previstos:** modificar `scripts/systems/upgrade_manager.gd`, `scripts/core/run_manager.gd`, `scripts/systems/room_director.gd`, `scripts/rooms/room_controller.gd`, Main e dados de sala; criar `tests/room_rewards_smoke.gd`. Reutilizar UpgradeScreen e HealthComponent.

**Interfaces propostas:** `UpgradeManager.request_reward_choice(source_id: StringName) -> void`, `reward_choice_resolved(source_id: StringName)` e `has_pending_choices() -> bool`. Distinguir origem nível/recompensa; usar identificador de mapa/sala para impedir concessão repetida.

- [ ] Aprovar benefício de descanso, magnitude, repetição, salas que recompensam, quantidade de ofertas e ordem da fila; registrar no GDD sem apresentar valores provisórios como aprovados.
- [ ] Criar testes com nível pendente e recompensa simultânea: uma tela por vez, três cartas distintas/elegíveis, uma escolha por oferta e nenhuma perda de pedidos. Uma recompensa isolada não altera nível/XP nem consome uma evolução pendente.
- [ ] Ampliar a fila de ofertas mantendo elegibilidade/aplicação únicas. Conceder descanso pelo componente de vida apenas se cura for a decisão aprovada; limitar ao máximo de vida e impedir repetição indevida conforme regra definida.
- [ ] Testar portas/transições bloqueadas durante ofertas, retorno ao contexto correto após a fila, vitória pendente aguardando também recompensas e GAME_OVER cancelando todas as escolhas. Reinício/menu limpam fila e fontes já recebidas.
- [ ] Executar `room_rewards_smoke.gd`, testes de seleção/efeitos/XP e pausa, importar se houver recursos/cenas alterados, atualizar docs e fazer commit.

**Aceite:** cartas por XP e recompensa usam os mesmos efeitos sem confundir contadores; descanso aplica somente o benefício aprovado; não há recompensa duplicada por reentrada; build persiste até o fim da tentativa.

## COD-018 — Configurar sala de elite

**Prioridade:** P1. **Arquivos previstos:** dados da sala de elite em `data/rooms/map_01/`, configuração de encontro em RoomController se necessária e `tests/elite_room_smoke.gd`. Usar EnemyData/cenas existentes e multiplicadores por instância, sem inventar um quarto inimigo comum.

- [ ] Aprovar posição definitiva da elite, composição, atributos e recompensa; criar testes com os valores aprovados e falha inicial.
- [ ] Configurar o encontro de elite, reutilizando vida/dano por instância e a fila de recompensa de COD-017; manter os Resources básicos inalterados.
- [ ] Testar dano/vida efetivos, conclusão única, recompensa única, morte do jogador e avanço permitido sem vitória global. Inspecionar clareza visual da elite com formas provisórias.
- [ ] Executar `elite_room_smoke.gd`, testes de encontro/recompensa e Infinito; atualizar docs e fazer commit.

**Aceite:** a elite oferece o desafio e a recompensa aprovados, preserva os inimigos básicos e não conclui a Aventura.

## COD-019 — Criar chefe reutilizável e conclusão da Aventura

**Prioridade:** P1. **Arquivos propostos:** `scripts/enemies/boss_controller.gd`, `scenes/enemies/boss.tscn`, `data/boss.tres` e `tests/boss_encounter_smoke.gd`; modificar dados da sala final e integração de RoomDirector/RunManager. Estender EnemyData apenas quando o design aprovado exigir novos campos.

- [ ] Aprovar identidade original, ataques/avisos visuais, atributos, XP e recompensa do chefe. Criar testes de dano, vida e derrota única de acordo com essa especificação.
- [ ] Implementar o chefe com componentes existentes e referência explícita ao alvo. O chefe informa sua derrota; não chama RunManager para finalizar um modo.
- [ ] Conectar a conclusão da sala final ao pedido de vitória da Aventura. Testar que cartas/recompensas pendentes são resolvidas antes do resultado e que morte do jogador prevalece sobre conclusão tardia.
- [ ] Instanciar o chefe em um teste isolado de contexto Infinito e confirmar que sua derrota não causa VICTORY. Esse teste verifica reutilização; não adiciona agendamento periódico ao WaveDirector.
- [ ] Importar, executar `boss_encounter_smoke.gd`, testes de dano/recompensa/estado e `arena_smoke.gd`; inspecionar ataques e colisões visualmente, atualizar docs e fazer commit.

**Aceite:** um chefe funcional conclui Aventura pelo dono do encontro; não existe acoplamento do controlador do chefe à vitória global e não há chefes periódicos no Infinito nesta tarefa.

## COD-020 — Integrar interface e ciclo completo dos dois modos

**Prioridade:** P1. **Arquivos previstos:** Main, menu, `scripts/ui/hud.gd`, `scripts/ui/result_screen.gd`, painéis de pausa e cenas correspondentes; modificar `tests/main_menu_smoke.gd` e `tests/pause_menu_smoke.gd`; criar `tests/adventure_flow_smoke.gd`.

**Interfaces:** UI recebe Player/UpgradeManager/RunManager e progresso de sala/etapa ou de onda por referências e sinais. Preservar `restart_requested`, `main_menu_requested` e controle de pausa no RunManager; não duplicar regras de progressão na interface.

- [ ] Criar teste de ponta a ponta com as duas alternativas da segunda etapa, preservação de vida/build, elite e chefe final; testar HUD de sala/etapa na Aventura e onda no Infinito.
- [ ] Integrar seleção exclusiva Aventura/Infinito, resultado pelo chefe e navegação. Remover dependência obrigatória de WaveDirector no HUD/dashboard quando a sessão for Aventura.
- [ ] Testar pausa na exploração e combate, cartas com árvore pausada, reinício de ambos os modos e retorno ao menu. Alternar de modo após adquirir upgrades; exigir XP/vida/cartas/entidades/mapa/filas iniciais na nova tentativa.
- [ ] Verificar visualmente 1280 × 720: menu, portas, cartas, pausa, progresso e resultados. Executar `adventure_flow_smoke.gd`, testes de menu/pausa/Infinito e `arena_smoke.gd`, atualizar README/AGENTS para o estado implementado e fazer commit.

**Aceite:** ciclo completo jogável do menu ao chefe/vitória ou derrota, com reinício limpo no mesmo modo; Infinito preserva suas regras e não exibe a escolha antiga.

## COD-021 — Revisar e validar o MVP 0.2

**Prioridade:** P1. **Arquivos previstos:** criar `docs/VALIDATION_MVP_0.2.md`, atualizar GDD, arquitetura e README. Correções de código devem responder a falhas comprovadas e receber testes de regressão; não adicionar conteúdo de roadmap.

- [ ] Revisar diff e requisitos de todas as tarefas; conferir que nenhum item proposto foi declarado aprovado ou entregue sem evidência. Auditar referências antigas a Ondas/WAVES/ENDLESS_CHOICE fora dos registros históricos.
- [ ] Executar importação, scripts smoke e execução headless da entrada. Registrar versão do Godot, comandos, códigos de saída e avisos do ambiente; confirmar que a migração dos testes antigos em COD-013 não deixou expectativa de vitória na terceira onda em Aventura.
- [ ] Completar manualmente ambas as rotas da bifurcação e uma partida no Infinito além da terceira onda; testar morte em combate/elite/chefe, pausa, recompensas, reinício e troca de modo. Conferir portas, projéteis, colisões, Y-sort e câmera.
- [ ] Corrigir bloqueios reproduzidos, repetir somente verificações afetadas e registrar resultados/limites. Se a validação manual não for possível, registrá-la como pendente e não declarar aceite integral.
- [ ] Atualizar o relatório com requisitos atendidos, riscos restantes e sugestões futuras. Fazer commits atômicos e Pull Request com revisão antes de eventual release.

**Aceite:** critérios da seção 20.4 do GDD demonstrados; verificações automatizadas passam, ambas as rotas são concluídas manualmente e não há erro conhecido que impeça avanço ou encerramento. A validação histórica 0.1 não é reutilizada como evidência de 0.2.

## Estratégia de testes e riscos

| Risco ou condição | Evidência necessária | Tarefa responsável |
| --- | --- | --- |
| Gatilho repetido, reentrada ou múltiplos shapes | Uma entrada válida, um encontro e uma recompensa; sem XP adicional após morte já contabilizada. | COD-014 a COD-017 |
| Identidade do Player perdida entre salas | Mesmo instance_id, vida 90/100 e dano 12 após UPG-001, XP/nível/cartas conservados ao cruzar portas. | COD-015 e COD-020 |
| Referência fixa de arena ou diretor inicia modo errado | Aventura não inicia ondas automáticas; Infinito conserva 1–3 e avança à quarta sem escolha extra. | COD-013 e COD-020 |
| Nível/recompensa/conclusão ocorrem juntos | Uma fila determinística; nenhuma oferta perdida; portas e vitória aguardam resolução. | COD-017 e COD-019 |
| Morte simultânea a entrada ou última derrota | GAME_OVER prevalece; sem spawn, cura, recompensa ou vitória tardia. | COD-016 a COD-019 |
| Porta bloqueia corredor ou ramo fica inacessível | Travessia física das duas rotas, inclusive com dash; retorno conforme regra aprovada. | COD-015 e COD-021 |
| Chefe encerra Infinito por acoplamento | Derrota em fixture independente sem pedido global de vitória. | COD-019 |
| Reinício/troca de modo conserva flags e filas | Estado inicial e somente modo preservado no reinício; menu limpa a sessão e retira pausa. | COD-017 e COD-020 |
| Recurso compartilhado recebe bônus em runtime | EnemyData, PlayerStats e definições de sala/cartas idênticos antes/depois de combate e reinício. | COD-014, COD-018 e COD-021 |
| Navegação direta e câmera não servem ao mapa maior | Layout testado manualmente para reduzir travamentos dos inimigos, colisões e perda de visão; melhorias só se falha concreta exigir. | COD-015, COD-016 e COD-021 |

Os testes de cálculo existentes continuam verificando atributos, XP e cartas. Testes de integração novos verificam salas e seus sinais. Casos de dados inválidos devem falhar com diagnóstico em vez de produzir uma tentativa impossível de concluir. Não criar infraestrutura de testes nova quando os scripts smoke/GdUnit4 existentes bastarem.

Comandos base (substituir `godot` pelo executável local 4.7.2):

```powershell
godot --headless --editor --import --path .
godot --headless --path . --script res://tests/arena_smoke.gd
godot --headless --path . --script res://tests/main_menu_smoke.gd
godot --headless --path . --script res://tests/endless_waves_smoke.gd
godot --headless --path . --quit-after 120
git diff --check
```

Cada novo script de teste listado nas tarefas só poderá ser executado depois de criado. Rodar todos os smoke existentes em COD-021; durante uma tarefa, executar o teste novo e as regressões pertinentes, além da importação e arena_smoke exigidos por AGENTS.md ao alterar cenas/recursos. Saída esperada: exit 0 e a mensagem de sucesso do teste, sem erros de script/carregamento. Avaliação manual não é substituída por esses comandos.

## COD-022 — Proposta futura: chefes periódicos no Infinito

**Fora da entrega inicial do MVP 0.2.** Dependências propostas: COD-019, COD-021 e aprovação de frequência, progressão e recompensas dos chefes no Infinito. Reutilizar o chefe e componentes de encontro, retomando ondas após a derrota dele; não causar VICTORY, recriar jogador ou apagar a build. A tarefa exigirá testes de agendamento, pausa/cartas, morte, reinício e continuidade das ondas. Nenhum intervalo ou algoritmo de agendamento foi aprovado por COD-012.
