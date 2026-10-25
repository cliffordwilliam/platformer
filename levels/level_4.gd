extends Level
## River run: long stretches of water crossed on platforms, leapers in
## every pool, crushers over the path and a spring to a high coin trail.


func layout() -> void:
	biome = Biome.GRASS
	has_water = true
	floors = [
		Vector2i(10, 12), Vector2i(7, 13), Vector2i(8, 11), Vector2i(2, 13), Vector2i(6, 8),
		Vector2i(6, 13), Vector2i(12, 11), Vector2i(4, 13), Vector2i(10, 10), Vector2i(8, 13),
		Vector2i(10, 9), Vector2i(3, 13), Vector2i(8, 10), Vector2i(5, 13), Vector2i(14, 10),
		Vector2i(4, 13), Vector2i(8, 12), Vector2i(3, 13), Vector2i(6, 9), Vector2i(5, 13),
		Vector2i(12, 11),
	]
	blocks = [
		GiftBlockSpawn.new(Vector2i(36, 4), GiftBlockSpawn.Contents.DIAMOND),
		BreakableBlockSpawn.new(Vector2i(109, 6)),
		GiftBlockSpawn.new(Vector2i(110, 6), GiftBlockSpawn.Contents.COIN),
		BreakableBlockSpawn.new(Vector2i(111, 6)),
		GiftBlockSpawn.new(Vector2i(112, 6), GiftBlockSpawn.Contents.COIN),
	]
	coins = [
		Vector2i(19, 8), Vector2i(20, 8),
		Vector2i(42, 6), Vector2i(43, 6),
		Vector2i(74, 7), Vector2i(75, 7), Vector2i(77, 6), Vector2i(78, 6),
		Vector2i(82, 3), Vector2i(83, 2), Vector2i(84, 2), Vector2i(85, 3),
		Vector2i(99, 5), Vector2i(100, 5), Vector2i(101, 5),
		Vector2i(142, 6), Vector2i(143, 5), Vector2i(144, 6),
	]
	walkers = [
		WalkerSpawn.new(Vector2i(28, 10), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(55, 10), WalkerSpawn.Kind.SHELL),
		WalkerSpawn.new(Vector2i(87, 8), WalkerSpawn.Kind.SPIKED),
		WalkerSpawn.new(Vector2i(110, 9), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(113, 9), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(117, 9), WalkerSpawn.Kind.SHELL),
		WalkerSpawn.new(Vector2i(150, 10), WalkerSpawn.Kind.SPIKED),
		WalkerSpawn.new(Vector2i(154, 10), WalkerSpawn.Kind.PLAIN),
	]
	flyers = [FlyerSpawn.new(Vector2i(77, 3), 70.0), FlyerSpawn.new(Vector2i(143, 8), -60.0)]
	leapers = [19, 41, 44, 59, 103, 121, 133]
	crushers = [Vector2i(65, 6), Vector2i(68, 6), Vector2i(129, 8)]
	bars = [BarSpawn.new(Vector2i(52, 7), 1, 180.0, false)]
	springs = [Vector2i(82, 8)]
	platforms = [PlatformSpawn.new(Vector2i(19, 10), 2), PlatformSpawn.new(Vector2i(74, 9), 2),
		PlatformSpawn.new(Vector2i(99, 6), 3)]
	ladders = [LadderSpawn.new(Vector2i(98, 9), 4)]
	checkpoints = [Vector2i(63, 9), Vector2i(125, 11)]
