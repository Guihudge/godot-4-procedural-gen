extends CharacterBody2D

const SPEED = 500


func _physics_process(delta):
	velocity.x = Input.get_axis("ui_left", "ui_right")
	velocity.y = Input.get_axis("ui_up", "ui_down")
	velocity = velocity.normalized()*SPEED
	if velocity.x != 0 or velocity.y != 0:
		move_and_slide()

func _process(delta):
	$FPS_COUNTER.text = "FPS: " + str(Engine.get_frames_per_second())
