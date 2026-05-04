class_name EnemyResource
extends Resource

enum EnemyShape {
	TRIANGLE,
	DIAMOND,
	SPIKE,
	BOSS_DIAMOND,
}

@export var MaxHp: int = 10
@export var Damage: int = 5
@export var Speed: float = 90.0
@export var EnemyColor: Color = Color(0.9, 0.4, 0.3)
@export var Shape: EnemyShape = EnemyShape.TRIANGLE
@export var XpDrop: int = 1
@export var MaterialDrop: int = 1
@export var Radius: float = 12.0
@export var IsBoss: bool = false

# Splitter
@export var SplitsOnDeath: bool = false
@export var SplitInto: EnemyResource
@export var SplitCount: int = 2

# Charger
@export var IsCharger: bool = false
@export var ChargeInterval: float = 2.5
@export var ChargeDuration: float = 0.5
@export var ChargeSpeedMult: float = 4.0

# Ranged
@export var HasRangedAttack: bool = false
@export var RangedStopDistance: float = 280.0
@export var RangedFireInterval: float = 2.0
@export var RangedDamage: int = 5
@export var RangedBulletSpeed: float = 300.0
