# Validação do MVP 0.1

**Data:** 25/10/2026<br>
**Engine:** Godot 4.7.2 stable oficial (`ed1daf0bf`)<br>
**Escopo:** COD-001 a COD-011, conforme `docs/GDD.md` v0.1.

## Verificações executadas

| Verificação | Resultado |
| --- | --- |
| Importação de recursos: `godot --headless --editor --import --path .` | Código de saída 0; nenhum erro de parse ou carregamento dos scripts do jogo. |
| Carregamento da cena principal: `godot --headless --path . --quit-after 3` | Código de saída 0; nenhum erro em runtime. |
| Doze testes smoke em `tests/` | Todos passaram, incluindo arena, movimento, flechas, colisões, três inimigos, três ondas, XP, cartas, efeitos, pausa, resultados e reinício. |
| Renderização da cena principal e das telas de cartas e vitória | Arena, HUD, cartas e resultado visíveis e legíveis em 1280 × 720. |
| Sequência das três ondas por teste de integração | Composição e ordem corretas; 175 XP totais, quatro evoluções resolvidas, vitória após a última onda. |
| Reinício pelo botão | Nova cena com primeira onda, nível 1, vida inicial, atributos sem melhorias e combate despausado. |

Os testes headless verificam as regras e a integração, mas não substituem uma partida controlada por uma pessoa no editor. **A sensação de movimento, mira e dificuldade ainda precisa de avaliação jogável.** Os parâmetros identificados como provisórios em `docs/ARCHITECTURE.md` continuam sujeitos a esse retorno.

Durante a importação headless, o addon existente Funplay MCP registrou erros de socket Winsock ao procurar o servidor local e avisos de recursos no encerramento do editor. A importação terminou com código 0 e sem erros de script; os testes e a execução da cena principal não registraram esses erros. O addon foi preservado.

## Roteiro de teste jogável

1. Abra a pasta no Godot 4.7.2 e pressione F5.
2. Mova com WASD, mire com o mouse, segure o clique esquerdo para atirar e use Espaço para dash; confira os limites e pilares.
3. Observe dano recebido, invulnerabilidade do dash, vida e recarga no HUD. Pressione Esc e retome pelo botão ou por Esc.
4. Termine as três ondas, escolhendo uma carta a cada evolução. Observe dano, velocidade, vida, perfuração, tiro triplo, fogo e recarga do dash nas partidas necessárias.
5. Confira a vitória, reinicie e verifique que a partida voltou ao nível 1 sem melhorias. Em outra partida, deixe a vida acabar para conferir derrota e reinício.
