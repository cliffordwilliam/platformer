extends Level
## Green hills: walkers, blocks to bonk, a spring and the first shell.


func layout() -> void:
	biome = Biome.GRASS
	has_water = false
	floors = [
		Vector2i(12, 12), Vector2i(3, 15), Vector2i(8, 11), Vector2i(6, 9), Vector2i(4, 15),
		Vector2i(10, 10), Vector2i(3, 15), Vector2i(14, 12), Vector2i(2, 15), Vector2i(6, 10),
		Vector2i(4, 15), Vector2i(12, 11), Vector2i(3, 15), Vector2i(8, 12),
	]
	blocks = [
		BreakableBlockSpawn.new(Vector2i(10, 8)),
		BreakableBlockSpawn.new(Vector2i(11, 8)),
		GiftBlockSpawn.new(Vector2i(12, 8), GiftBlockSpawn.Contents.COIN),
		BreakableBlockSpawn.new(Vector2i(13, 8)),
		GiftBlockSpawn.new(Vector2i(33, 5), GiftBlockSpawn.Contents.COIN),
		GiftBlockSpawn.new(Vector2i(57, 8), GiftBlockSpawn.Contents.DIAMOND),
		BreakableBlockSpawn.new(Vector2i(84, 6)),
		GiftBlockSpawn.new(Vector2i(85, 6), GiftBlockSpawn.Contents.COIN),
		BreakableBlockSpawn.new(Vector2i(86, 6)),
	]
	coins = [
		Vector2i(19, 8), Vector2i(20, 7), Vector2i(21, 8),
		Vector2i(37, 6), Vector2i(38, 6),
		Vector2i(61, 7), Vector2i(62, 7), Vector2i(63, 7),
		Vector2i(70, 9), Vector2i(71, 9), Vector2i(72, 9),
		Vector2i(96, 4), Vector2i(96, 3),
	]
	walkers = [
		WalkerSpawn.new(Vector2i(16, 11), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(27, 10), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(45, 9), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(60, 11), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(64, 11), WalkerSpawn.Kind.PLAIN),
		WalkerSpawn.new(Vector2i(87, 10), WalkerSpawn.Kind.SHELL),
	]
	flyers = [FlyerSpawn.new(Vector2i(92, 5), 54.0)]
	springs = [Vector2i(96, 11)]
	platforms = [PlatformSpawn.new(Vector2i(61, 8), 3)]
	checkpoints = [Vector2i(54, 11)]
