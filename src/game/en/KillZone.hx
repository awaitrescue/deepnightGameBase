package en;


class KillZone extends Entity {

    public static var ALL : Array<KillZone> = [];

    public function new() {
        super(10, 10);

        var start = level.data.l_Entities.all_KillPoint[0];
        if (start != null)
            setPosCase(start.cx, start.cy);

        var bitmap = new h2d.Bitmap(h2d.Tile.fromColor(Red, iwid, ihei), spr);
        bitmap.tile.setCenterRatio(0.5, 1);
    }

    override function fixedUpdate() {
        super.fixedUpdate();
        // test for collisions
        if ( player.isAlive() ) {
            if ( distPx(player) <= innerRadius + player.hitRadius ) {
                player.hit(0, this);
            }
        }
    }
}