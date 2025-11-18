extends "res://addons/dialogue_manager/example_balloon/example_balloon.gd"

# Кастомный balloon с поддержкой озвучки и скрытием тегов

var voice_audio_player: AudioStreamPlayer
var current_line_text: String = ""

func _ready():
	super._ready()
	
	# Создаем отдельный AudioStreamPlayer для озвучки
	voice_audio_player = AudioStreamPlayer.new()
	add_child(voice_audio_player)
	
	add_to_group("dialogue_balloon")

func _input(event):
	"""Обработка ввода для скипа диалогов"""
	# Скип диалога по клавише Tab (менее случайная)
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed:
		skip_current_dialogue()

func skip_current_dialogue():
	"""Скипает текущий диалог до выбора или конца"""
	# print("🔄 Скип диалога нажат")
	
	if dialogue_line and dialogue_label:
		# Останавливаем озвучку
		if voice_audio_player and voice_audio_player.playing:
			voice_audio_player.stop()
			# print("🔇 Озвучка остановлена")
		
		# Если текст еще печатается - показываем весь текст сразу
		if dialogue_label.is_typing:
			dialogue_label.skip_typing()
			# print("⏩ Печатание текста ускорено")
		else:
			# Если текст уже показан - переходим к следующей строке
			if dialogue_line.responses.size() == 0:
				# Нет выборов - переходим дальше
				# print("➡️ Переход к следующей строке")
				next(dialogue_line.next_id)
			else:
				# print("🤔 Есть выборы - ждем решения игрока")
				pass



func apply_dialogue_line() -> void:
	"""Переопределяем чтобы воспроизводить аудио ДО печатания текста"""
	if dialogue_line and dialogue_line.text != current_line_text:
		current_line_text = dialogue_line.text
		
		# СНАЧАЛА воспроизводим аудио если есть тег voice
		if dialogue_line.has_tag("voice"):
			var voice_path = dialogue_line.get_tag_value("voice")
			play_voice_immediately(voice_path)
	
	# Стандартная логика balloon'а но БЕЗ встроенной обработки voice
	mutation_cooldown.stop()
	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for next line БЕЗ встроенной обработки voice
	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()

func play_voice_immediately(voice_path: String):
	"""Немедленно воспроизводит озвучку"""
	if voice_audio_player.playing:
		voice_audio_player.stop()
	
	if FileAccess.file_exists(voice_path):
		var audio_stream = load(voice_path)
		if audio_stream and voice_audio_player:
			voice_audio_player.stream = audio_stream
			voice_audio_player.play()
