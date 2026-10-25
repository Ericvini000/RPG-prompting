<!-- FUNPLAY_MCP_SKILL_BEGIN -->
# Funplay MCP for Godot

- Local MCP endpoint: `http://127.0.0.1:8766/`
- Project skill: `res://.funplay/skills/funplay-godot-project.md`
- Start Godot editor with the Funplay MCP addon enabled before using these tools.
<!-- FUNPLAY_MCP_SKILL_END -->

## Projeto

### Antes de implementar

- Leia `docs/GDD.md` e `docs/ARCHITECTURE.md` antes de implementar qualquer funcionalidade.
- Trate o GDD v0.1 como fonte das regras e dos parâmetros de gameplay. Propostas identificadas na arquitetura não são decisões aprovadas.
- Confirme o escopo da tarefa e não implemente funcionalidades fora dele.
- Preserve o trabalho e as funcionalidades existentes. Não altere mecânicas definidas sem informar o usuário e registrar a decisão aprovada na documentação.

### Implementação

- Use Godot 4.7.2, APIs compatíveis com essa versão e GDScript tipado em scripts próprios.
- Mantenha código modular, organizado e documentado onde a explicação ajudar a manutenção.
- Separe configuração de estado em execução, prefira `TileMapLayer` para novos mapas e siga os contratos de sinais do GDD.
- Preserve `addons/funplay_mcp/` e `addons/gdUnit4/`; evite dependências novas sem necessidade.
- A cena principal atual é `res://scenes/main.tscn`; a arena atual é `res://scenes/arena_01.tscn`. A reorganização proposta no GDD ainda não foi aplicada.

### Validação e entrega

- Crie testes ou verificações adequados às modificações. Após editar cenas ou recursos, importe o projeto e execute `res://tests/arena_smoke.gd` em modo headless; verifique também o carregamento e os scripts afetados.
- Ao concluir cada tarefa, apresente os arquivos alterados, testes executados, resultados e problemas encontrados.
- Atualize `docs/GDD.md` ou `docs/ARCHITECTURE.md` quando uma decisão de gameplay ou arquitetura for aprovada; identifique claramente propostas ainda pendentes.
