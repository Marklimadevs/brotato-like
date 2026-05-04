using Godot;

namespace BrotatoLike;

/// <summary>
/// Button cuja tooltip é renderizada via RichTextLabel (suporta BBCode).
/// Defina TooltipText com BBCode; engine chama _MakeCustomTooltip ao hover.
/// </summary>
public partial class RichTooltipButton : Button
{
	public override Control _MakeCustomTooltip(string forText)
	{
		var panel = new PanelContainer();

		var margin = new MarginContainer();
		margin.AddThemeConstantOverride("margin_left", 12);
		margin.AddThemeConstantOverride("margin_right", 12);
		margin.AddThemeConstantOverride("margin_top", 10);
		margin.AddThemeConstantOverride("margin_bottom", 10);
		panel.AddChild(margin);

		var rich = new RichTextLabel
		{
			BbcodeEnabled = true,
			FitContent = true,
			ScrollActive = false,
			CustomMinimumSize = new Vector2(300f, 0f),
		};
		rich.AddThemeFontSizeOverride("normal_font_size", 13);
		rich.AddThemeFontSizeOverride("bold_font_size", 15);
		rich.Text = forText;
		margin.AddChild(rich);

		return panel;
	}
}
