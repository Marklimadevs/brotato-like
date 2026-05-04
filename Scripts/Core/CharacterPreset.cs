using System.Collections.Generic;
using Godot;

namespace BrotatoLike;

public class CharacterPreset
{
	public string Name;
	public string Description;
	public Color BaseColor = Colors.White;
	public List<WeaponResource> StartingWeapons = new();
}
