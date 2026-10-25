# Funplay MCP for Godot Project Skill

Use this project through the local Funplay MCP for Godot editor server.

## Connection

- Endpoint: `http://127.0.0.1:8766/`
- Active tool profile: `core`
- Debug logging: `false`
- Tool counts: `73` core, `123` full

## Project Context

- Project name: `Arqueiro Roguelite`
- Main scene: `res://scenes/main.tscn`
- Project root: `res://` (the currently open Godot project)

## Operating Rules

- Start by reading `godot://project/context` or calling `get_project_info` before broad edits.
- Prefer `execute_code` for multi-step editor orchestration, then use focused helper tools for common Godot operations.
- Use returned `instance_id` values as short-lived node identifiers during one editor session; paths are better for persistent references.
- Call `save_scene` after scene mutations that should persist.
- Use `get_script_errors`, `validate_script`, logs, and play-mode tools before considering a task complete.
- Keep generated project files under `res://` and avoid touching `res://addons/funplay_mcp/` unless updating the addon itself.

## High-Value Resources

- `godot://scene/current`
- `godot://selection/current`
- `godot://scripts/errors`
- `godot://logs/recent`
- `godot://interaction/history`
