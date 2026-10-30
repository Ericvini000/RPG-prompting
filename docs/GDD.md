# Projeto Arqueiro Roguelite

**Game Design Document — Versão 0.1**

**Status:** Planejamento inicial<br>
**Engine:** Godot 4.7.2<br>
**Linguagem:** GDScript<br>
**Gênero:** Action Roguelite 2D Isométrico<br>
**Plataforma inicial:** Windows

---

## 1. Visão geral

O jogador controla um arqueiro em um mundo de fantasia sombria. Seu objetivo é enfrentar sucessivas ondas de inimigos, ganhar experiência, adquirir habilidades por meio de cartas e sobreviver a desafios cada vez mais difíceis.

A principal experiência deve ser a sensação de evolução constante: o personagem começa com um arco simples, mas termina uma partida utilizando combinações poderosas de habilidades.

### Pilares do design

1. **Combate responsivo:** movimentação rápida, boa precisão e ataques visualmente claros.
2. **Evolução perceptível:** cada carta deve mudar de maneira significativa algum aspecto da jogabilidade.
3. **Variedade de builds:** diferentes combinações de cartas devem produzir estilos distintos de combate.
4. **Alta rejogabilidade:** cada partida poderá ter habilidades, inimigos e desafios diferentes.

A inspiração em Hades será concentrada no ritmo do combate, na estrutura roguelite e na evolução das habilidades. Personagens, cenários, identidade visual, história e recursos artísticos serão originais.

## 2. Escopo do MVP 0.1

A primeira versão deve conter:

- Uma arena isométrica com obstáculos e limites.
- Um arqueiro com movimentação em oito direções.
- Mira com mouse, disparo de flechas e esquiva (dash).
- Três tipos de inimigos.
- Três ondas progressivas de combate.
- Experiência, níveis e escolha de cartas.
- Oito upgrades disponíveis.
- Interface de vida, experiência e informações do combate.
- Tela de vitória, derrota e opção de reiniciar.

**Fora do escopo inicial:** geração procedural, chefes, inventário, equipamentos, multiplayer, loja, progressão permanente, salvamento de partidas e narrativa avançada.

## 3. Ciclo de gameplay

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

Na versão 0.2, a conclusão da arena permitirá avançar para outras salas.

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

### Ondas de teste

| Onda | Composição |
| --- | --- |
| 1 | 4 perseguidores |
| 2 | 3 perseguidores e 2 atiradores |
| 3 | 2 perseguidores, 2 atiradores e 1 tanque |

Os inimigos aparecerão em pontos predeterminados, evitando posições muito próximas do jogador.

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

Quando uma carta aparecer, o jogo deverá pausar e apresentar três opções com nome, ícone, descrição, efeito numérico e quantidade de evoluções já adquiridas, quando aplicável. A seleção deverá funcionar com mouse.

A interface de cartas continuará processando entradas durante a pausa. Após uma escolha, outra seleção pendente será apresentada ou o combate será retomado.

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

## 13. Estados do jogo

O fluxo inicial terá cinco estados:

- **READY:** arena preparada, antes do início do combate.
- **COMBAT:** movimentação, ataques e inimigos ativos.
- **UPGRADE_SELECTION:** combate pausado aguardando escolha.
- **VICTORY:** todas as ondas concluídas.
- **GAME_OVER:** vida do jogador chegou a zero.

Mudanças de estado devem ter um controlador único, evitando múltiplos scripts tentando pausar ou finalizar o jogo simultaneamente.

## 14. Backlog de implementação para Codex

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

## 16. Critérios de conclusão do MVP

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

## 17. Próxima versão: MVP 0.2

Após estabilizar a versão 0.1, acrescentaremos:

- Transições entre diferentes salas.
- Seleção de caminhos ou recompensas.
- Aumento de dificuldade entre salas.
- Um chefe com padrões de ataque.
- Novas cartas e possíveis sinergias.
- Introdução de raridades.
- Identidade artística própria.
- Primeira estrutura de progressão permanente entre partidas.

## 18. Modo de ondas infinitas opcional — GAME-001

Após derrotar todos os inimigos das três ondas do MVP e concluir as escolhas de cartas pendentes, o jogador escolhe entre **Encerrar com Vitória** e **Continuar no Modo Infinito**. A primeira opção conserva o encerramento normal. A segunda inicia a onda 4 e mantém a mesma partida até a morte ou o reinício. A escolha aparece uma única vez; novas ondas não concedem vitória por conclusão.

As ondas 1 a 3 conservam as composições da seção 5. Da onda 4 em diante, as composições usam perseguidor, atirador e tanque, com um inimigo planejado adicional a cada onda: 6 na onda 4, 7 na onda 5 e assim por diante. Vida e dano dos inimigos recebem, respectivamente, bônus aditivos de 5% e 2% por onda após a terceira, aplicados sobre seus valores básicos e arredondados para inteiros. No máximo 12 inimigos permanecem ativos ao mesmo tempo; quantidades maiores entram em lotes. A onda seguinte só começa quando todos os inimigos planejados surgirem e forem derrotados.

Experiência, níveis e cartas seguem as regras existentes. A build continua entre ondas, e seleções de cartas interrompem spawns e transições até a escolha. A morte encerra a partida e cancela spawns pendentes. O reinício restaura o estado inicial, inclusive a opção de escolher o modo após a terceira onda. Intervalos e demais parâmetros operacionais são provisórios e configuráveis, conforme `docs/ARCHITECTURE.md`.
