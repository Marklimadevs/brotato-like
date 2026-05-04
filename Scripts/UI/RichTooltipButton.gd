class_name RichTooltipButton
extends Button

# Button cuja tooltip é renderizada via RichTextLabel (suporta BBCode).
# Defina TooltipText (tooltip_text) com BBCode; engine chama _make_custom_tooltip ao hover.


func _make_custom_tooltip(for_text: String) -> Control:
	var panel := PanelContainer.new()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.scroll_active = false
	rich.custom_minimum_size = Vector2(300, 0)
	rich.add_theme_font_size_override("normal_font_size", 13)
	rich.add_theme_font_size_override("bold_font_size", 15)
	rich.text = for_text
	margin.add_child(rich)

	return panel
