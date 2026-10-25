extends Level
## A desert oasis: leapers jump out of the pools between the dunes, bars
## spin over the paths, and spiked walkers patrol.


func layout() -> void:
	biome = Biome.DESERT
	has_water = true
	floors = [
		Vector2i(10, 12), Vector2i(4, 13), Vector2i(6, 10), Vector2i(5, 13), Vector2i(8, 10),
		Vector2i(3, 13), Vector2i(10, 11), Vector2i(4, 13), Vector2i(6, 9), Vector2i(5, 13),
		Vector2i(12, 9), Vector2i(4, 13), Vector2i(10, 11), Vector2i(3, 13), Vector2i(8, 10),
		Vector2i(5, 13), Vector2i(14, 11), Vector2i(3, 13), Vector2i(10, 12),
	]
	blocks = [
		GiftBlockSpawn.new(Vector2i(12, 8), GiftBlockSpawn.Contents.COIN),
		BreakableBlockSpawn.new(Vector2i(34, 6)),
		GiftBlockSpawn.new(Vector2i(76, 5), GiftBlockSpawn.Contents.DIAMOND),
		BreakableBlockSpawn.new(Vector2i(116, 7)),
		BreakableBlockSpawn.new(Vector2i(117, 7)),
		GiftBlockSpawn.new(Vector2i(130, 8), GiftBlockSpawn.Contents.COIN),
	]
	coins = [
		Vector2i(18, 8), Vector2i(19, 8),
		Vector2i(28, 7), Vector2i(29, 6), Vector2i(30, 7),
		Vector2i(71, 4), Vector2i(72, 4), Vector2i(73, 4),
		Vector2i(106, 8), Vector2i(107, 8), Vector2i(108, 8),
		Vector2i(132, 10), Vector2i(133, 10), Vector2i(134, 10),
	]
	walkers = [
		WalkerSpawn.new(Vector2i(36, 9), WalkerSpawn.Kind.SPIKED),
		WalkerSpawn.new(Vector2i(74, 8), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(78, 8), WalkerSpawn.Kind.SPIKED),
		WalkerSpawn.new(Vector2i(114, 10), WalkerSpawn.Kind.SHELL),
		WalkerSpawn.new(Vector2i(119, 10), WalkerSpawn.Kind.PLAIN),
	]
	leapers = [18, 29, 54, 55, 81, 108, 125]
	flyers = [FlyerSpawn.new(Vector2i(121, 5), 50.0)]
	crushers = [Vector2i(90, 7)]
	bars = [BarSpawn.new(Vector2i(48, 6), 2, 90.0, false), BarSpawn.new(Vector2i(101, 6), 1, 0.0, false)]
	platforms = [PlatformSpawn.new(Vector2i(65, 9), 2), PlatformSpawn.new(Vector2i(71, 5), 3),
		PlatformSpawn.new(Vector2i(106, 10), 3)]
	checkpoints = [Vector2i(85, 10)]
