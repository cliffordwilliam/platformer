extends Level
## The frozen fortress: spinning bars, crushers in pairs, shells and
## spiked walkers over icy water. A ladder leads to a secret door.


func layout() -> void:
	biome = Biome.SNOW
	has_water = true
	floors = [
		Vector2i(8, 12), Vector2i(4, 13), Vector2i(5, 10), Vector2i(2, 13), Vector2i(8, 8),
		Vector2i(3, 13), Vector2i(10, 10), Vector2i(5, 13), Vector2i(6, 10), Vector2i(2, 13),
		Vector2i(12, 9), Vector2i(6, 13), Vector2i(10, 10), Vector2i(3, 13), Vector2i(8, 11),
		Vector2i(4, 13), Vector2i(6, 9), Vector2i(5, 13), Vector2i(14, 10), Vector2i(4, 13),
		Vector2i(8, 9), Vector2i(3, 13), Vector2i(10, 11), Vector2i(2, 13), Vector2i(8, 12),
	]
	blocks = [
		GiftBlockSpawn.new(Vector2i(62, 5), GiftBlockSpawn.Contents.DIAMOND),
		BreakableBlockSpawn.new(Vector2i(117, 6)),
		BreakableBlockSpawn.new(Vector2i(118, 6)),
		GiftBlockSpawn.new(Vector2i(119, 6), GiftBlockSpawn.Contents.COIN),
		BreakableBlockSpawn.new(Vector2i(120, 6)),
	]
	coins = [
		Vector2i(16, 9), Vector2i(17, 9),
		Vector2i(48, 8), Vector2i(49, 8),
		Vector2i(74, 7), Vector2i(75, 7),
		Vector2i(108, 2), Vector2i(109, 2),
		Vector2i(145, 3), Vector2i(145, 2),
	]
	walkers = [
		WalkerSpawn.new(Vector2i(55, 9), WalkerSpawn.Kind.SHELL),
		WalkerSpawn.new(Vector2i(94, 10), WalkerSpawn.Kind.SPIKED),
		WalkerSpawn.new(Vector2i(97, 10), WalkerSpawn.Kind.SPIKED),
		WalkerSpawn.new(Vector2i(118, 9), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(122, 9), WalkerSpawn.Kind.SHELL),
		WalkerSpawn.new(Vector2i(126, 9), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(158, 11), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(161, 11), WalkerSpawn.Kind.SPIKED),
	]
	flyers = [FlyerSpawn.new(Vector2i(64, 4), 50.0), FlyerSpawn.new(Vector2i(68, 3), 70.0)]
	leapers = [16, 49, 50, 100, 111, 129, 141]
	crushers = [Vector2i(30, 4), Vector2i(81, 6), Vector2i(84, 6), Vector2i(150, 7)]
	bars = [BarSpawn.new(Vector2i(42, 5), 2, 90.0, false), BarSpawn.new(Vector2i(136, 5), 1, 0.0, false)]
	springs = [Vector2i(145, 10)]
	doors = [Vector2i(108, 4)]
	platforms = [PlatformSpawn.new(Vector2i(48, 9), 2), PlatformSpawn.new(Vector2i(74, 8), 2),
		PlatformSpawn.new(Vector2i(107, 5), 3)]
	ladders = [LadderSpawn.new(Vector2i(106, 8), 4)]
	checkpoints = [Vector2i(79, 9)]
