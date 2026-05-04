class_name WeaponResource
extends Resource

@export var WeaponName: String = "Pistol"
@export var Cost: int = 10
@export var Damage: int = 4
@export var Cooldown: float = 0.55
@export var Reach: float = 380.0
@export var BulletSpeed: float = 700.0
@export var BulletRadius: float = 5.0
@export var ProjectileColor: Color = Color(1, 0.95, 0.5)
@export var BulletScene: PackedScene
@export var BarrelColor: Color = Color(0.55, 0.55, 0.6)
@export var BarrelLength: float = 18.0
@export var BarrelWidth: float = 6.0
@export var Pellets: int = 1
@export var SpreadAngleDeg: float = 0.0
@export var Pierce: int = 0


var SellValue: int:
	get:
		return maxi(1, Cost / 2)
