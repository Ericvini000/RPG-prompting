# Execução do MVP 0.2 — COD-014 a COD-022

**Início:** 01/11/2026. Dependência: COD-013 em `237c65e`, ainda em PR. As branches são empilhadas por tarefa; não há merge automático em develop/main. O PR final cumulativo inclui as dependências ainda não integradas.

## Configuração inicial aprovada pelo usuário

- Descanso: cura 30 uma vez por tentativa; salas concluídas podem ser revisitadas sem repetir encontros ou benefícios. O outro ramo da etapa 2 permanece bloqueado.
- Combate e elite: uma escolha entre três cartas elegíveis após resolver XP; descanso concede apenas cura.
- Inicial: 3 perseguidores. Ramo de combate: 2 perseguidores e 1 atirador. Avançado: 3 perseguidores, 2 atiradores e 1 tanque.
- Elite: 1 tanque e 2 atiradores, vida ×1,6 e dano ×1,2, aplicados por instância.
- Chefe original: Sentinela do Umbral, 450 HP, contato 15, projéteis 9, 50 XP; alterna leque e rajada radial, com aviso de 0,6 s.
- Infinito: chefe nas ondas 5, 10, 15… substitui a onda comum, usa escala de vida/dano existente e oferece uma carta. Sua derrota não encerra a sobrevivência.

## Registro de entregas

- COD-014: Resources MapDefinition/RoomDefinition, validação de grafo e primeiro mapa, RoomController, RoomDirector e estado EXPLORATION. `room_graph_smoke.gd` passou após falhar pela ausência dos componentes. Nenhuma geometria ou encontro entregue nesta etapa.
- COD-015: cena única Map01 com seis salas, seis portas, corredores, piso TileMapLayer 128×64 e colisão no contorno. Layout fixo autoral em coordenadas de tiles, sem geração aleatória. `adventure_map_smoke.gd` verifica passagem, bifurcação e identidade/vida/build; a montagem permanece explícita até a integração COD-020.
- COD-016: encontros finitos com inimigos existentes e XP único, espera por cartas, portas bloqueadas e cancelamento após morte. Projéteis remanescentes são removidos ao concluir a sala. Distância operacional mínima de spawn: 80 px, configurável por código de encontro para o mapa compacto; parâmetros comuns do Infinito foram preservados. Testes de encontro, mapa, grafo, arena e Infinito passaram.
- COD-017: fila única de apresentação com origem nível/recompensa separada; IDs de origem impedem concessão repetida. Cartas de nível precedem recompensa de sala, morte cancela ofertas e descanso cura 30 uma vez. A sala só libera portas após todas as escolhas. Suíte: 20/20 smoke passaram.
- COD-018: elite com tanque e dois atiradores, vida ×1,6/dano ×1,2 por instância, destaque âmbar e recompensa única. `elite_room_smoke.gd` passou; Resources básicos permanecem inalterados. Regressões de recompensas, arena e Infinito passaram.
- COD-019: Sentinela do Umbral reutilizável, 450 HP, contato 15, projétil 9 e 50 XP, leque de três e radial de oito projéteis com aviso de 0,6 s. Somente RoomDirector solicita vitória após concluir a sala final e suas escolhas. Teste isolado preserva COMBAT no Infinito; integração completa da rota de combate passou. Parâmetros operacionais provisórios: chefe estacionário, intervalo 2,4 s, projétil 360 px/s e dispersão do leque 0,25 rad.

## Decisões de implementação

- Resources são configuração imutável; salas concluídas e ramo bloqueado pertencem à tentativa.
- Cada tarefa usa uma branch específica derivada da dependência anterior, para preservar a sequência sem integrar PRs automaticamente.
- COD-022 foi incluída explicitamente no escopo desta execução pelo usuário; deixa de ser apenas proposta futura nesta sequência.
