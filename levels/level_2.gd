extends Level
## Snow caves: crushers, shells, a ladder to a hidden ledge, and a door
## high above that a spring can reach.


func layout() -> void:
	biome = Biome.SNOW
	has_water = false
	floors = [
		Vector2i(10, 12), Vector2i(3, 15), Vector2i(8, 10), Vector2i(4, 6), Vector2i(5, 15),
		Vector2i(12, 10), Vector2i(2, 15), Vector2i(10, 12), Vector2i(4, 15), Vector2i(8, 9),
		Vector2i(3, 13), Vector2i(10, 9), Vector2i(5, 15), Vector2i(6, 9), Vector2i(2, 15),
		Vector2i(14, 11), Vector2i(4, 15), Vector2i(8, 12), Vector2i(3, 15), Vector2i(12, 11),
	]
	blocks = [
		GiftBlockSpawn.new(Vector2i(12, 8), GiftBlockSpawn.Contents.COIN),
		BreakableBlockSpawn.new(Vector2i(22, 6)),
		BreakableBlockSpawn.new(Vector2i(23, 6)),
		BreakableBlockSpawn.new(Vector2i(29, 2)),
		GiftBlockSpawn.new(Vector2i(30, 2), GiftBlockSpawn.Contents.COIN),
		GiftBlockSpawn.new(Vector2i(68, 5), GiftBlockSpawn.Contents.DIAMOND),
		BreakableBlockSpawn.new(Vector2i(102, 7)),
		BreakableBlockSpawn.new(Vector2i(103, 7)),
		GiftBlockSpawn.new(Vector2i(104, 7), GiftBlockSpawn.Contents.COIN),
	]
	coins = [
		Vector2i(33, 4), Vector2i(34, 4), Vector2i(35, 4),
		Vector2i(81, 4), Vector2i(82, 4), Vector2i(83, 4),
		Vector2i(87, 6), Vector2i(88, 5), Vector2i(89, 6),
		Vector2i(130, 8), Vector2i(131, 8),
	]
	walkers = [
		WalkerSpawn.new(Vector2i(25, 9), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(41, 9), WalkerSpawn.Kind.SHELL),
		WalkerSpawn.new(Vector2i(46, 9), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(74, 12), WalkerSpawn.Kind.SPIKED),
		WalkerSpawn.new(Vector2i(70, 8), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(110, 10), WalkerSpawn.Kind.SHELL),
		WalkerSpawn.new(Vector2i(137, 10), WalkerSpawn.Kind.PLAIN),
	]
	flyers = [FlyerSpawn.new(Vector2i(104, 3), 40.0), FlyerSpawn.new(Vector2i(108, 7), -60.0)]
	crushers = [Vector2i(54, 7), Vector2i(57, 7), Vector2i(133, 7)]
	springs = [Vector2i(119, 11)]
	doors = [Vector2i(122, 3)]
	checkpoints = [Vector2i(99, 10)]
	platforms = [PlatformSpawn.new(Vector2i(81, 5), 3), PlatformSpawn.new(Vector2i(121, 4), 3)]
	ladders = [LadderSpawn.new(Vector2i(80, 8), 4)]
