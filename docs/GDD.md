# Projeto Arqueiro Roguelite

**Game Design Document — Especificação 0.2 em desenvolvimento**

**Status:** Especificação 0.2 em desenvolvimento; fundação COD-013 implementada, Aventura completa pendente<br>
**Base preservada:** MVP 0.1 e incrementos UI-001, GAME-001 e UI-002<br>
**Engine:** Godot 4.7.2<br>
**Linguagem:** GDScript<br>
**Gênero:** Action Roguelite 2D Isométrico<br>
**Plataforma inicial:** Windows

---

### Como ler este documento

- **Histórico:** escopo e ciclo originais do MVP 0.1, preservados para rastreabilidade.
- **Implementação existente:** COD-013 migra o menu e a identificação para Aventura (`ADVENTURE`) e Infinito (`ENDLESS`). Infinito continua jogável; Aventura tem apenas a fundação técnica e aguarda o mapa.
- **Nova decisão aprovada:** a especificação 0.2 oferece somente **Modo Aventura** e **Modo Infinito**, conforme seções 19 e 20. Aventura substitui Ondas; suas salas e o ciclo completo ainda não estão implementados.
- **Proposta:** detalhes de arquitetura ou balanceamento explicitamente marcados aguardam decisão; não alteram os parâmetros aprovados.
- **Futuro:** itens do roadmap ficam fora da entrega inicial do MVP 0.2.

As regras de atributos, controles, inimigos comuns, XP e oito cartas das seções 4 a 7 continuam válidas. [ARCHITECTURE.md](ARCHITECTURE.md) distingue os contratos atuais dos propostos; [PLAN_MVP_0.2.md](PLAN_MVP_0.2.md) organiza COD-013 a COD-021.

## 1. Visão geral

O jogador controla um arqueiro em um mundo de fantasia sombria. No Modo Aventura, percorre salas conectadas até um chefe final; no Modo Infinito, enfrenta ondas progressivas. Em ambos, ganha experiência, adquire habilidades por meio de cartas e enfrenta desafios cada vez mais difíceis.

A principal experiência deve ser a sensação de evolução constante: o personagem começa com um arco simples, mas termina uma partida utilizando combinações poderosas de habilidades.

### Pilares do design

1. **Combate responsivo:** movimentação rápida, boa precisão e ataques visualmente claros.
2. **Evolução perceptível:** cada carta deve mudar de maneira significativa algum aspecto da jogabilidade.
3. **Variedade de builds:** diferentes combinações de cartas devem produzir estilos distintos de combate.
4. **Alta rejogabilidade:** cada partida poderá ter habilidades, inimigos e desafios diferentes.

A inspiração em Hades será concentrada no ritmo do combate, na estrutura roguelite e na evolução das habilidades. Personagens, cenários, identidade visual, história e recursos artísticos serão originais.

## 2. Escopo histórico do MVP 0.1

A primeira versão foi especificada com os seguintes requisitos, preservados como base histórica:

- Uma arena isométrica com obstáculos e limites.
- Um arqueiro com movimentação em oito direções.
- Mira com mouse, disparo de flechas e esquiva (dash).
- Três tipos de inimigos.
- Três ondas progressivas de combate.
- Experiência, níveis e escolha de cartas.
- Oito upgrades disponíveis.
- Interface de vida, experiência e informações do combate.
- Tela de vitória, derrota e opção de reiniciar.

**Fora do escopo do MVP 0.1:** geração procedural, chefes, inventário, equipamentos, multiplayer, loja, progressão permanente, salvamento de partidas e narrativa avançada. O chefe final passa a integrar o MVP 0.2; as exclusões da entrega 0.2 estão na seção 20.

## 3. Ciclo histórico de gameplay do MVP 0.1

**Comportamento original:** este ciclo descreve a arena de três ondas, posteriormente selecionável como Modo Ondas em UI-002. Não define o fluxo do Modo Aventura. O fluxo aprovado da Aventura está na seção 20; a continuidade do Infinito está nas seções 18 e 19.

1. O jogador entra em uma arena.
2. Uma onda de inimigos aparece.
3. O arqueiro se movimenta, esquiva e dispara flechas.
4. Inimigos derrotados concedem experiência.
5. Ao atingir um novo nível, o combate é pausado.
6. São oferecidas três cartas diferentes e elegíveis.
7. O jogador escolhe uma carta e recebe sua melhoria.
8. O combate continua até terminar a onda.
9. Após três ondas, a arena é concluída.
10. O jogador vence a sessão de teste ou perde ao ficar sem vida.

O plano inicial previa avançar entre salas na versão 0.2. COD-012 concretiza essa intenção como um único mapa com salas fisicamente conectadas, sem exigir três ondas por sala.

## 4. Personagem: Arqueiro

### Atributos iniciais

| Atributo | Valor |
| --- | ---: |
| Vida máxima | 100 |
| Dano básico | 10 |
| Velocidade de movimento | 230 px/s |
| Intervalo entre ataques | 0,60 s |
| Velocidade da flecha | 700 px/s |
| Duração do dash | 0,14 s |
| Velocidade do dash | 600 px/s |
| Recarga do dash | 1,20 s |
| Invulnerabilidade após sofrer dano | 0,50 s |

Todos os valores devem ser configuráveis e centralizados, sem números mágicos espalhados pelos scripts.

### Controles

| Entrada | Ação |
| --- | --- |
| W, A, S, D | Movimento em oito direções |
| Mouse | Apontar a direção do arco |
| Clique esquerdo | Atacar continuamente enquanto pressionado |
| Espaço | Executar dash |
| Esc | Abrir/fechar pausa normal, quando disponível |

### Regras de combate

- Flechas devem nascer na posição visual do arco.
- A trajetória será calculada na direção da posição do mouse.
- Cada flecha terá velocidade, dano e tempo máximo de vida.
- Flechas comuns desaparecem ao atingir um inimigo ou obstáculo.
- Haverá proteção contra acertos múltiplos acidentais.
- Inicialmente, o dash concederá invulnerabilidade durante seu movimento.
- O ataque poderá ocorrer enquanto o arqueiro se movimenta.

### Perspectiva isométrica

O movimento será livre em coordenadas 2D da tela, com oito direções e velocidade diagonal normalizada.

O piso utilizará losangos isométricos com proporção 2:1, inicialmente de 128 × 64 pixels. Objetos e personagens serão ordenados pela posição vertical de seus pontos de contato com o chão.

O ponto de referência visual do personagem ficará próximo aos pés, enquanto a flecha nascerá na altura do arco. Isso permitirá manter o cenário isométrico sem criar um sistema tridimensional desnecessário.

## 5. Inimigos

| Tipo | HP | Velocidade | Ataque | XP |
| --- | ---: | ---: | --- | ---: |
| Perseguidor | 35 | 120 px/s | Contato, 10 dano | 10 |
| Atirador | 25 | 80 px/s | Projétil, 7 dano | 15 |
| Tanque | 100 | 65 px/s | Contato, 20 dano | 25 |

### Comportamentos

**Perseguidor:** identifica a posição do arqueiro e tenta alcançá-lo, com intervalo entre ataques de contato.

**Atirador:** procura manter distância e lança projéteis em direção à posição do jogador, com intervalo inicial de 1,8 segundo.

**Tanque:** possui muita vida, aproxima-se lentamente e pune o jogador que permanece parado.

Para o MVP, perseguidores e tanques usarão perseguição direta e colisões. Navegação avançada e desvio inteligente de obstáculos ficam para uma etapa posterior.

### Ondas de teste do MVP 0.1 e abertura do Infinito

| Onda | Composição |
| --- | --- |
| 1 | 4 perseguidores |
| 2 | 3 perseguidores e 2 atiradores |
| 3 | 2 perseguidores, 2 atiradores e 1 tanque |

Os inimigos aparecerão em pontos predeterminados, evitando posições muito próximas do jogador.

Essas três composições são mantidas na abertura do Modo Infinito. Não são uma regra de quantidade ou composição dos encontros da Aventura; esses encontros precisarão de configuração e validação próprias.

## 6. Experiência e níveis

Cada inimigo concede uma quantidade fixa de experiência ao morrer.

**XP para o próximo nível = 20 + 10 × (nível atual − 1)**

Exemplos:

- Nível 1 → 2: 20 XP.
- Nível 2 → 3: 30 XP.
- Nível 3 → 4: 40 XP.
- Nível 4 → 5: 50 XP.

A experiência excedente é preservada. Caso o jogador acumule experiência suficiente para subir vários níveis simultaneamente, todas as escolhas deverão ser realizadas em sequência, uma por nível.

## 7. Sistema de cartas

Este sistema será construído de forma extensível, permitindo criar novas cartas sem reescrever a lógica central.

### Cartas iniciais

| ID | Carta | Efeito |
| --- | --- | --- |
| UPG-001 | Força do Arqueiro | +20% de dano |
| UPG-002 | Tiro Rápido | +15% de velocidade de ataque |
| UPG-003 | Agilidade | +12% de velocidade de movimento |
| UPG-004 | Vitalidade | +25 de vida máxima e atual |
| UPG-005 | Flecha Perfurante | A flecha atravessa 1 inimigo adicional |
| UPG-006 | Disparo Triplo | Dispara 3 flechas, com dispersão angular |
| UPG-007 | Flecha Flamejante | Aplica queimadura de 3 dano/s por 3 segundos |
| UPG-008 | Esquiva Aprimorada | Reduz em 15% a recarga do dash |

### Regras iniciais

- Três cartas diferentes aparecerão a cada subida de nível.
- Apenas uma poderá ser escolhida.
- Cartas de atributos básicos poderão aparecer repetidamente.
- Disparo Triplo e Flecha Flamejante serão inicialmente habilidades únicas.
- Cartas no limite de evolução não poderão ser oferecidas novamente.
- Cartas de atributos básicos permanecerão elegíveis no MVP, garantindo opções suficientes.
- As melhorias acumuladas serão perdidas ao finalizar a partida.
- Raridade e probabilidades especiais serão introduzidas depois.

### Cálculo dos atributos

As cartas devem modificar os atributos efetivos do personagem, sem sobrescrever seus valores básicos:

- Dano efetivo = dano base × (1 + bônus acumulado).
- Intervalo de ataque = intervalo base ÷ (1 + bônus acumulado de velocidade de ataque).
- Velocidade de movimento = velocidade base × (1 + bônus acumulado).

Modificadores especiais, como perfuração, disparo triplo e efeitos elementais, devem possuir lógica própria desacoplada da interface.

## 8. Interface

A interface principal terá:

- Barra de vida.
- Barra de experiência.
- Nível atual.
- Número da onda.
- Indicador da recarga do dash.

Essa lista descreve o HUD existente. Para a Aventura, o progresso deverá identificar etapa e sala; para o Infinito, continuará identificando a onda. A adaptação visual é trabalho planejado em COD-020.

Quando uma carta aparecer, o jogo deverá pausar e apresentar três opções com nome, ícone, descrição, efeito numérico e quantidade de evoluções já adquiridas, quando aplicável. A seleção deverá funcionar com mouse.

A interface de cartas continua processando entradas durante a pausa. Na implementação existente, após uma escolha, outra seleção pendente é apresentada ou o combate é retomado, podendo concluir um resultado pendente. Na Aventura planejada, a última escolha deverá devolver o controle ao contexto de exploração ou combate pertinente, ou concluir a vitória pendente, conforme a proposta de estados em ARCHITECTURE.md, seção 22.

## 9. Arquitetura de software

### Princípios

1. Separar dados de configuração e comportamento.
2. Compor personagens a partir de componentes reutilizáveis.
3. Utilizar sinais para comunicar eventos entre sistemas.
4. Evitar dependências diretas entre interfaces e inimigos.
5. Manter o código orientado à extensão de habilidades e inimigos.
6. Preferir scripts pequenos e tipados.
7. Garantir que o projeto possa ser testado sem recursos artísticos definitivos.

### Sistemas principais

| Sistema | Responsabilidade |
| --- | --- |
| RunManager | Estado da partida, XP, nível, conclusão e derrota |
| PlayerController | Movimento, direção, ataque e dash |
| HealthComponent | Vida, dano, cura e morte |
| Projectile | Movimento, colisão e aplicação de dano |
| EnemyController | Comportamento e ataques dos inimigos |
| WaveDirector | Criação e acompanhamento das ondas |
| UpgradeManager | Sorteio, elegibilidade e aplicação de cartas |
| HUD | Exibição de vida, XP, nível e onda |
| UpgradeScreen | Exibição das cartas e captura da escolha |

O RunManager será um Autoload, pois futuramente poderá preservar o estado de uma partida entre diferentes salas. Os demais sistemas serão instanciados dentro das cenas e se comunicarão por referências explícitas e sinais.

### Dados configuráveis

Usaremos recursos customizados (Resource) armazenados em arquivos .tres:

- **PlayerStats:** valores básicos do arqueiro.
- **EnemyData:** vida, velocidade, dano, intervalo de ataque e experiência concedida.
- **UpgradeDefinition:** identificação, nome, descrição, ícone, tipo de efeito, magnitude e limites.
- **WaveData:** composição e quantidade de inimigos de uma onda.

Recursos de configuração não deverão ser alterados durante a partida. Os atributos modificados existirão em uma instância separada de estado.

## 10. Organização do repositório

Estrutura proposta pelo GDD para o MVP, a ser criada conforme cada tarefa:

- project.godot — configurações principais.
- scenes/ — cenas do jogo:
  - main/main.tscn
  - arena/arena_01.tscn
  - player/player.tscn
  - combat/arrow.tscn
  - enemies/chaser.tscn
  - enemies/ranged_enemy.tscn
  - enemies/tank.tscn
  - ui/hud.tscn
  - ui/upgrade_screen.tscn
  - ui/result_screen.tscn
- scripts/ — lógica e controladores:
  - core/run_manager.gd
  - player/player_controller.gd
  - combat/projectile.gd
  - enemies/enemy_controller.gd
  - systems/wave_director.gd
  - systems/upgrade_manager.gd
  - components/health_component.gd
  - components/hurtbox_component.gd
  - data/player_stats.gd
  - data/enemy_data.gd
  - data/upgrade_definition.gd
- data/ — recursos .tres de personagens, inimigos, ondas e cartas.
- assets/ — imagens, fontes, áudios e recursos temporários.
- tests/ — testes automatizados e verificações.
- docs/ — documentação e decisões de arquitetura.

O repositório também terá README.md, .gitignore e AGENTS.md com as instruções permanentes para o Codex. A estrutura acima é uma proposta para o MVP; os caminhos reais da fundação já existente são registrados em ARCHITECTURE.md.

## 11. Estrutura das cenas

### main.tscn — estrutura planejada

- **Main — Node2D**
  - Arena — Node2D
  - WaveDirector — Node
  - UpgradeManager — Node
  - HUD — CanvasLayer
  - UpgradeScreen — CanvasLayer
  - ResultScreen — CanvasLayer

### arena_01.tscn — estrutura planejada

- **Arena — Node2D**
  - Floor — TileMapLayer
  - SortingRoot — Node2D com Y-sort
    - Walls — TileMapLayer com Y-sort
    - Player — CharacterBody2D
    - Inimigos e projéteis instanciados dinamicamente
  - SpawnPoints — Node2D

### player.tscn — estrutura planejada

- **Player — CharacterBody2D**
  - CollisionShape2D
  - Visuals — Node2D
    - Shadow — Sprite2D ou Polygon2D
    - CharacterSprite — Sprite2D
    - BowOrigin — Marker2D
  - HealthComponent — Node
  - Hurtbox — Area2D
  - Camera2D

A organização visual deve usar os pés dos personagens como referência para a ordenação isométrica.

## 12. Eventos e sinais

| Origem | Sinal | Consumidor |
| --- | --- | --- |
| HealthComponent | health_changed(current, maximum) | HUD |
| HealthComponent | died() | Inimigo ou jogador |
| Inimigo | enemy_defeated(xp_reward) | RunManager |
| RunManager | experience_changed(xp, required) | HUD |
| RunManager | level_up_requested() | UpgradeManager |
| UpgradeManager | upgrade_selected(upgrade_id) | RunManager e jogador |
| WaveDirector | wave_changed(number) | HUD |
| WaveDirector | arena_completed() | RunManager |

A tela de cartas não poderá modificar diretamente o dano ou a velocidade do jogador. Ela informará qual carta foi escolhida e o sistema de evolução aplicará a mudança.

## 13. Estados do jogo: base histórica e continuidade

O fluxo original do MVP 0.1 definiu cinco estados:

- **READY:** arena preparada, antes do início do combate.
- **COMBAT:** movimentação, ataques e inimigos ativos.
- **UPGRADE_SELECTION:** combate pausado aguardando escolha.
- **VICTORY:** todas as ondas concluídas no ciclo original. No design 0.2, representa a derrota do chefe final da Aventura; não ocorre ao concluir uma onda do Infinito.
- **GAME_OVER:** vida do jogador chegou a zero.

Mudanças de estado devem ter um controlador único, evitando múltiplos scripts tentando pausar ou finalizar o jogo simultaneamente.

GAME-001 acrescentou `ENDLESS_CHOICE`; UI-002 deixou de utilizá-lo no fluxo normal e COD-013 removeu esse legado. A fundação de Aventura aguarda mapa em READY; exploração e estados locais de sala continuam planejados. A auditoria histórica e os contratos implementados estão em ARCHITECTURE.md, seções 21 a 23.

## 14. Backlog histórico de implementação para Codex — MVP 0.1

COD-001 a COD-011 registram a sequência original. O backlog da versão 0.2 está em [PLAN_MVP_0.2.md](PLAN_MVP_0.2.md), sem declarar essas novas tarefas implementadas.

### COD-001 — Fundação do projeto

**Prioridade:** P0<br>
**Dependências:** Nenhuma

Implementar projeto Godot 4.7.2, resolução 1280 × 720, Input Map, estrutura de pastas, .gitignore, README.md, AGENTS.md, cena principal executável e Git.

**Aceite:** projeto abre no editor e executa uma cena vazia sem erros.

### COD-002 — Arena isométrica

**Prioridade:** P0<br>
**Dependências:** COD-001

Implementar arena com piso isométrico, TileSet 128 × 64, limites físicos, obstáculos, Y-sort e pontos de spawn. Usar formas geométricas provisórias ou recursos livres adequadamente licenciados.

**Aceite:** arena aparece corretamente, obstáculos têm colisão e a estrutura visual não depende de arte definitiva.

### COD-003 — Controle do arqueiro

**Prioridade:** P0<br>
**Dependências:** COD-002

Implementar cena Player, movimento WASD em oito direções com diagonal normalizada, mira com mouse, dash com cooldown, câmera que acompanha o personagem e animações visuais provisórias.

**Aceite:** personagem se move, aponta, esquiva e não atravessa paredes.

### COD-004 — Flechas e sistema de dano

**Prioridade:** P0<br>
**Dependências:** COD-003

Implementar projéteis com Area2D, disparo na direção do mouse, intervalo entre ataques, colisões de flechas com cenário e inimigos, HealthComponent, HurtboxComponent e remoção segura de projéteis.

**Aceite:** flechas podem causar dano a alvos de teste e não atingem o próprio arqueiro.

### COD-005 — Primeiro inimigo

**Prioridade:** P0<br>
**Dependências:** COD-004

Criar perseguidor que persegue o jogador, aplica dano de contato, recebe dano de flechas, morre e emite evento de derrota.

**Aceite:** o jogador consegue enfrentar e eliminar um inimigo funcional.

### COD-006 — Inimigos adicionais e ondas

**Prioridade:** P1<br>
**Dependências:** COD-005

Implementar atirador, tanque, WaveDirector, três ondas configuráveis, spawn em pontos predefinidos, contagem e conclusão de ondas.

**Aceite:** três ondas são executadas na ordem correta, sem sobreposição acidental ou surgimento sobre o jogador.

### COD-007 — Experiência e níveis

**Prioridade:** P1<br>
**Dependências:** COD-005

Implementar experiência por inimigo derrotado, fórmula de progressão, aumento de nível, preservação de XP excedente, fila de níveis pendentes e sinais para interface e evolução.

**Aceite:** jogador sobe de nível corretamente, inclusive quando recebe XP suficiente para várias evoluções.

### COD-008 — Sistema de seleção de cartas

**Prioridade:** P1<br>
**Dependências:** COD-007

Implementar UpgradeDefinition como Resource, UpgradeManager, sorteio de três cartas diferentes, interface de seleção, pausa do combate, elegibilidade e retomada do jogo após a escolha.

**Aceite:** o jogador seleciona uma única carta, a interface desaparece e o combate continua sem perder níveis pendentes.

### COD-009 — Aplicação das oito melhorias

**Prioridade:** P1<br>
**Dependências:** COD-008

Implementar todas as cartas da seção 7, separando modificadores numéricos de efeitos especiais e incluindo regras de acumulação.

**Aceite:** cada carta altera efetivamente o combate, sem modificar os dados básicos compartilhados entre partidas.

### COD-010 — HUD e resultado da partida

**Prioridade:** P1<br>
**Dependências:** COD-006, COD-007 e COD-009

Implementar barra de vida, barra de experiência, nível, indicador de onda, feedback visual ao tomar dano, telas de vitória e derrota e reinicialização.

**Aceite:** uma partida pode começar, evoluir, terminar e reiniciar sem manter melhorias ou entidades da sessão anterior.

### COD-011 — Validação e estabilização

**Prioridade:** P1<br>
**Dependências:** COD-010

Implementar verificações automatizadas e revisar carregamento das cenas, erros de scripts, colisões, fórmulas de atributos, sorteio de cartas, ganho de experiência, pausa e retomada e reinicialização da partida.

**Aceite:** todos os testes automatizados passam e a sequência completa pode ser jogada manualmente sem erros conhecidos que impeçam a conclusão.

## 15. Estratégia de testes

Os sistemas de cálculo serão testados separadamente da interface visual. Casos mínimos:

- Aumento de dano por upgrade.
- Velocidade de ataque após múltiplas cartas.
- Cálculo de experiência e níveis.
- Preservação de XP excedente.
- Ausência de duplicação de cartas na mesma seleção.
- Exclusão de habilidades únicas já adquiridas.
- Tratamento de múltiplas evoluções pendentes.
- Reset dos atributos após reiniciar.

Cada tarefa do Codex deverá incluir testes ou verificações proporcionais à funcionalidade implementada. Além dos testes automatizados, será necessário executar o jogo visualmente para avaliar controles, precisão da mira, colisões, perspectiva e sensação de combate.

## 16. Critérios históricos de conclusão do MVP 0.1

O MVP 0.1 será considerado concluído somente quando:

1. O projeto abrir sem erros.
2. O arqueiro puder se movimentar, atirar e executar dash.
3. Os três inimigos funcionarem.
4. As três ondas puderem ser concluídas.
5. Experiência e níveis funcionarem.
6. Todas as oito cartas produzirem seus efeitos.
7. Vitória, derrota e reinício funcionarem.
8. O sistema suportar futuras arenas e novas cartas sem grandes reescritas.

**Resultado esperado:** uma arena isométrica jogável com um ciclo completo de combate e progressão de personagem.

---

## 17. Roadmap e revisão de escopo para a versão 0.2

O planejamento original agrupava transições entre salas, caminhos e recompensas, dificuldade crescente, chefe, novas cartas, raridades, identidade artística e progressão permanente na próxima versão. COD-012 substitui esse agrupamento pelo escopo delimitado na seção 20.

**Entrega inicial aprovada:** Modo Aventura, um mapa manual com seis salas em cinco etapas, combate e descanso, elite, recompensas e chefe final. Modo Infinito permanece independente com sua progressão existente.

**Roadmap futuro, sem compromisso de entrega nesta etapa:** novos mapas completos, tipos adicionais de sala, armadilhas funcionais, inimigos, chefes, novas cartas e sinergias, raridades, acabamento artístico e progressão permanente. Chefes periódicos no Infinito ficam como proposta COD-022 e não encerram a partida ao morrer. Geração procedural continua fora da entrega inicial e sem requisito de implementação aprovado.

## 18. Modo Infinito — regras vigentes e histórico GAME-001

### Histórico substituído

GAME-001 apresentava **Encerrar com Vitória** ou **Continuar no Modo Infinito** após três ondas e depois das cartas pendentes. UI-002 substituiu essa escolha pela seleção do modo antes da partida. Essa escolha antiga é apenas histórico; não deve reaparecer no fluxo aprovado da versão 0.2.

### Continuidade e escalonamento vigentes

Ao selecionar o Infinito no menu, o jogador começa nas três ondas originais e continua automaticamente na onda 4 após resolver cartas pendentes. Não há vitória pela conclusão de ondas.

As ondas 1 a 3 conservam as composições da seção 5. Da onda 4 em diante, as composições usam perseguidor, atirador e tanque, com um inimigo planejado adicional a cada onda: 6 na onda 4, 7 na onda 5 e assim por diante. Vida e dano dos inimigos recebem, respectivamente, bônus aditivos de 5% e 2% por onda após a terceira, aplicados sobre seus valores básicos e arredondados para inteiros. No máximo 12 inimigos permanecem ativos ao mesmo tempo; quantidades maiores entram em lotes. A onda seguinte só começa quando todos os inimigos planejados surgirem e forem derrotados.

Experiência, níveis e cartas seguem as regras existentes. A build continua entre ondas, e seleções de cartas interrompem spawns e transições até a escolha. A morte encerra a partida e cancela spawns pendentes. O reinício restaura a onda 1 e limpa a build, preservando o Modo Infinito selecionado; não reapresenta a escolha histórica. Intervalos e demais parâmetros operacionais são provisórios e configuráveis, conforme `docs/ARCHITECTURE.md`.

**Funcionalidade futura:** chefes reutilizáveis poderão aparecer periodicamente no Infinito. A derrota de um chefe não encerra esse modo. Frequência, escalonamento e recompensas de chefes serão definidos em outra tarefa, proposta como COD-022.

## 19. Menu principal e modalidades aprovadas — MVP 0.2

**Seleção de modos implementada em COD-013; ciclo da Aventura pendente.** O jogo abre no menu principal, com o título provisório **ARQUEIRO ROGUELITE** e o botão **Jogar**. Jogar apresenta somente **Modo Aventura**, **Modo Infinito** e **Voltar**. A modalidade é escolhida antes de começar; Voltar retorna à tela inicial do menu.

| Modalidade | Progressão | Conclusão |
| --- | --- | --- |
| Modo Aventura | Mapa manual com salas ligadas por corredores e portas, cartas e recompensas. | Derrotar o chefe final conclui a aventura; vida zero causa derrota. |
| Modo Infinito | Três ondas originais, depois ondas geradas com dificuldade crescente, conforme seção 18. | Vida zero causa derrota; reiniciar inicia outra partida. Ondas e futuros chefes não concedem vitória final. |

O antigo Modo Ondas foi retirado da seleção em COD-013, com a migração de `WAVES` para `ADVENTURE`. **Limite atual:** selecionar Aventura abre uma preparação que informa a ausência do mapa e permite retornar ao menu; não inicia ondas nem simula a aventura completa. A entrega das salas depende das próximas tarefas.

Nas telas de vitória da Aventura e derrota de ambos os modos, **Recomeçar** deverá iniciar uma partida limpa no modo selecionado, sem conservar XP, cartas ou atributos adquiridos. **Menu Principal** encerra a partida, retira a pausa e permite escolher novamente. UI-002 já fornece essa navegação para suas modalidades atuais; a adaptação à Aventura é planejada. A interface de pausa de UI-001 e a seleção de cartas devem ser preservadas.

## 20. Escopo aprovado do MVP 0.2 — Modo Aventura

### 20.1. Requisitos da entrega inicial

- Modo Aventura como modalidade principal, independente do Infinito.
- Um mapa inicial construído manualmente, com todas as salas na mesma cena de mapa.
- Várias salas fisicamente conectadas, com deslocamento por corredores e portas; sem troca de cena a cada sala.
- Cinco etapas de progressão; a segunda bifurca entre combate e descanso. São seis salas físicas no total.
- Combates que reutilizam perseguidor, atirador e tanque; cartas oferecidas por experiência e por recompensas.
- Preservação da build, vida atual e máxima, XP e nível ao avançar. Cruzar uma porta não reinicia nem cura o jogador automaticamente.
- Uma sala de elite e um chefe final cuja derrota conclui a aventura.
- Estrutura capaz de receber outros mapas, tipos de sala, armadilhas, inimigos e chefes no futuro, sem exigir a implementação desses conteúdos agora.

### 20.2. Topologia e ciclo da aventura

As duas alternativas da segunda etapa deverão existir fisicamente e voltar a conectar-se à terceira. **Decisão aprovada no prompt de implementação do MVP 0.2:** somente um dos caminhos dessa etapa pode ser escolhido por partida; não é permitido obter recompensas das duas alternativas. O posicionamento isométrico, as distâncias e a política de retornar às salas já visitadas ainda precisam de definição. O mapa ainda não foi criado em COD-013.

| Etapa | Salas físicas | Papel |
| --- | --- | --- |
| 1 | R01 | Sala de combate inicial. |
| 2 | R02A e R02B | Bifurcação aprovada: combate ou descanso. |
| 3 | R03 | Sala de combate avançado após a bifurcação. |
| 4 | R04 | Sala de elite. |
| 5 | R05 | Chefe final e conclusão da aventura. |

**Distribuição aprovada no prompt de implementação do MVP 0.2:** combate inicial → combate ou descanso → combate avançado → elite → chefe. A topologia lógica é aprovada; sua construção física pertence às tarefas seguintes.

O fluxo aprovado é entrar no mapa, atravessar salas conectadas, enfrentar encontros, receber XP/cartas/recompensas, escolher entre combate e descanso e avançar até o chefe final. Concluir uma sala permite progressão local; não conclui a partida. Vida e build persistem entre salas. A derrota encerra a tentativa; Recomeçar limpa toda a tentativa e mantém Aventura selecionada.

### 20.3. Recompensas, descanso e elite

A progressão por experiência conserva a fórmula e as oito cartas existentes. Recompensas de sala, quando configuradas, oferecem três cartas elegíveis para escolher uma, sem consumir evoluções pendentes. **Decisão aprovada no prompt de implementação:** concluir o combate, resolver evoluções por XP pendentes e então oferecer a recompensa configurada. O catálogo e a aplicação de efeitos devem ser reutilizados. Essa extensão ainda depende de COD-017.

**Descanso aprovado no prompt de implementação:** recuperar vida por valor configurável. Quantidade e repetição da cura, composição dos encontros, atributos da elite, recompensas por tipo de sala e identidade/padrões/atributos do chefe continuam pendentes. Nenhum valor numérico adicional foi aprovado. Esses parâmetros deverão ser registrados antes de implementar suas tarefas; os atributos básicos existentes não serão sobrescritos.

### 20.4. Exclusões e critérios de aceite

Geração procedural, novos mapas completos, armadilhas funcionais e progressão permanente não integram a entrega inicial. Novas cartas e raridades permanecem no roadmap futuro. Inventário, equipamentos, multiplayer, loja, salvamento de partidas e narrativa avançada continuam fora deste escopo. Arte provisória original é suficiente.

O MVP 0.2 só poderá ser declarado concluído quando:

1. O menu oferecer somente Aventura e Infinito, com reinício no mesmo modo e retorno funcional ao menu.
2. O primeiro mapa manual tiver seis salas físicas em cinco etapas, com a bifurcação de combate/descanso na segunda, corredores e portas utilizáveis.
3. Toda a travessia entre salas acontecer dentro da mesma cena de mapa e conservar a instância do jogador, sua vida e build.
4. Os três inimigos existentes, XP, cartas por nível e recompensas funcionarem sem duplicações ao reentrar em gatilhos ou salas.
5. Descanso e elite produzirem os efeitos posteriormente aprovados; somente o chefe final concluir a Aventura.
6. Pausa, cartas, derrota, vitória, reinício e menu funcionarem sem perder escolhas pendentes ou conservar dados da tentativa anterior.
7. O Infinito conservar as regras da seção 18, sem escolha extra na terceira onda e sem vitória por chefe.
8. Testes automatizados e uma travessia manual completa validarem colisões, portas, Y-sort, câmera, persistência e conclusão, conforme PLAN_MVP_0.2.md.
