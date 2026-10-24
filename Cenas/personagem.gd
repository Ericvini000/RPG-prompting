extends Node2D

@export var velocidade: float = 260.0

const METADE_DO_QUADRADO: float = 24.0

func _ready() -> void:
	position = get_viewport_rect().size / 2.0
	print("Personagem pronto! Use as setas ou WASD para mover.")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_W:
				print("[Movimento] W pressionado: cima")
			KEY_A:
				print("[Movimento] A pressionado: esquerda")
			KEY_S:
				print("[Movimento] S pressionado: baixo")
			KEY_D:
				print("[Movimento] D pressionado: direita")

func _physics_process(delta: float) -> void:
	var direcao := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	)
	position += direcao.normalized() * velocidade * delta
	var tamanho := get_viewport_rect().size
	position.x = clampf(position.x, METADE_DO_QUADRADO, maxf(METADE_DO_QUADRADO, tamanho.x - METADE_DO_QUADRADO))
	position.y = clampf(position.y, METADE_DO_QUADRADO, maxf(METADE_DO_QUADRADO, tamanho.y - METADE_DO_QUADRADO))
