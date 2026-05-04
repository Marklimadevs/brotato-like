class_name Stats
extends RefCounted

var MaxHp: int = 30
var CurrentHp: int = 30
var BonusDamage: int = 0
var AttackSpeedMult: float = 1.0
var MoveSpeed: float = 260.0
var PickupRadius: float = 80.0
var XpGainMult: float = 1.0

# Combat depth
var CritChance: float = 0.0
var CritMultiplier: float = 2.0
var Armor: int = 0
var HpRegenPerSec: float = 0.0
var Knockback: float = 0.0
