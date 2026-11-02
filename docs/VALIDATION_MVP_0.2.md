# Validação do MVP 0.2

**Data:** 01/11/2026. **Engine:** Godot 4.7.2 stable oficial (`ed1daf0bf`).

## Escopo

COD-014 a COD-021: mapa único com seis salas, bifurcação exclusiva, encontros, XP, recompensas, descanso, elite, chefe, HUD, pausa, resultado, reinício e menu. COD-022 acrescenta chefes periódicos no Infinito e recebe sua verificação específica ao final desta sequência.

## Evidências

- Importação headless do projeto: saída 0, sem erros de parse dos scripts próprios. O ambiente registra avisos de escrita em user://, certificados, cache e sockets do Funplay; addons preservados.
- Suíte smoke ampliada com grafo, mapa, encontros, recompensas, elite, chefe e ciclo da Aventura. Cada novo comportamento teve uma verificação que falhou antes de sua implementação/correção.
- Ao concluir COD-021: 25/25 scripts smoke com saída 0, mensagem de sucesso e ausência de SCRIPT ERROR.
- Duas rotas da Aventura concluídas por integração: ramo de combate e descanso, com vitória final, derrota, reinício e retorno ao menu.
- `adventure_traversal_smoke.gd`: percorre fisicamente as duas rotas usando ações de movimento e CharacterBody2D, sem teleporte entre salas; verifica portas/corredores e colisão do ramo não escolhido. Inimigos são removidos e cartas resolvidas pela fixture para isolar a navegação, portanto esse teste não avalia dificuldade.
- Renderização não headless em 1280 × 720: combate inicial, pausa com atributos/cartas/progresso e chefe com aviso visual e indicador de vida inspecionados.
- Identidade do Player, vida atual/máxima, XP e build preservados durante a progressão; Resources básicos de atributos, inimigos e cartas não são alterados em runtime.
- Revisão de bugs: retomada da quarta onda após cartas, escolha tardia após derrota e mira do chefe a partir da origem do projétil cobertas por regressão.

## Comandos

```powershell
godot --headless --editor --import --path .
godot --headless --path . --script res://tests/arena_smoke.gd
godot --headless --path . --script res://tests/adventure_flow_smoke.gd
godot --headless --path . --script res://tests/adventure_traversal_smoke.gd --fixed-fps 120
godot --headless --path . --script res://tests/endless_waves_smoke.gd
godot --headless --path . --quit-after 120
git diff --check
```

Além dos comandos exemplificados, todos os scripts `tests/*_smoke.gd` são executados. A verificação exige mensagem de sucesso e ausência de SCRIPT ERROR, além do código de saída: uma asserção de GDScript isolada pode não produzir saída diferente de zero se o motor receber `--quit-after`.

## Limites e aceite

Não foi realizada uma partida humana completa para avaliar dificuldade, precisão da mira e sensação de combate. Os percursos automatizados e a inspeção visual não substituem esse aceite. A implementação pode ser testada a partir do menu, mas o aceite integral do MVP, incluindo sensação de combate, permanece pendente dessa avaliação humana.

Não há segundo mapa, armadilhas funcionais, novas cartas, raridades, salvamento ou progressão permanente. Inimigos comuns mantêm perseguição direta; o layout usa corredores amplos e encontros locais, sem navegação avançada.
