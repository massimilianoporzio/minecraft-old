import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:minecraft/components/block_breaking_component.dart';
import 'package:minecraft/components/item_component.dart';
import 'package:minecraft/global/global_game_reference.dart';
import 'package:minecraft/resources/blocks.dart';
import 'package:minecraft/utils/game_methods.dart';

class BlockComponent extends SpriteComponent with Tappable {
  final Blocks block;
  final Vector2 blockIndex;
  final int chunkIndex; //* di che chunk fa parte
  final String blockID = DateTime.now().toString();

  //*ogni blocco ha un'istanza sua del breaking
  late SpriteSheet animationSpriteSheet;

  late BlockBreakingComponent blockBreakingComponent = BlockBreakingComponent()
    ..animation = animationSpriteSheet.createAnimation(
        row: 0,
        stepTime: BlockData.getBlockDataFor(block).baseMiningSpeed / 6,
        loop: false)
    ..animation!.onComplete = onBroken;

  void onBroken() {
    //*rimuovo dalla lista dei chunck
    GameMethods.replaceBlockAtWorldChuncks(null, blockIndex);
    //SPAWNING. add to main game list of items
    GlobalGameReference.instance.mainGameRef.worldData.items
        .add(ItemComponent(spawnBlockIndex: blockIndex, item: block));
    removeFromParent(); //*TOLGO LA ANIMAZIONE
  }

  BlockComponent(
      {required this.block,
      required this.blockIndex,
      required this.chunkIndex});

  @override
  Future<void>? onLoad() async {
    super.onLoad();
    animationSpriteSheet = SpriteSheet(
        //*meglio usare cache!
        image: Flame.images
            .fromCache('sprite_sheets/blocks/block_breaking_sprite_sheet.png'),
        srcSize: Vector2.all(60));
    add(RectangleHitbox()); //*collisioni
    sprite = await GameMethods.getSpriteFromBlock(block);
  }

  @override
  bool onTapDown(TapDownInfo info) {
    // print("BLOCK ($blockID) COMPONENT TAP DOWN");

    if (BlockData.getBlockDataFor(block).breakable) {
//*add block animation
      if (!blockBreakingComponent.isMounted) {
        blockBreakingComponent.animation!.reset();
        add(blockBreakingComponent);
      }
    }
    info.handled = true;
    return true;
  }

  @override
  bool onTapCancel() {
    //* se lascio il componente
    // print("BLCOK TAP CANCEL");
    super.onTapCancel();
    //* stop block breaking animation
    if (blockBreakingComponent.isMounted) {
      remove(blockBreakingComponent);
    }
    return true;
  }

  @override
  bool onTapUp(TapUpInfo info) {
    // print("BLCOK TAP UP");
    super.onTapUp(info);
    //* stop block breaking animation
    if (blockBreakingComponent.isMounted) {
      remove(blockBreakingComponent);
    }
    return true;
  }

  //*called every time the screen resize
  @override
  void onGameResize(Vector2 newScreenSize) {
    super.onGameResize(newScreenSize);
    size = GameMethods.blockSize;
    position = Vector2(
        size.x * blockIndex.x, size.y * blockIndex.y); //* valore iniziale
  }

//*CHECK SE INDEX DEL CHUNK è DA RENDER SE NO LO RIMUOVO
  @override
  void update(double dt) {
    super.update(dt);
    if (!GlobalGameReference
        .instance.mainGameRef.worldData.chunksThathShoudlBeRendered
        .contains(chunkIndex)) {
      //*UNRENDERING
      removeFromParent();
      GlobalGameReference.instance.mainGameRef.worldData.currentlyRenderedChunks
          .remove(chunkIndex); //*lo "notifico" che non è più render
    }
  }
}
