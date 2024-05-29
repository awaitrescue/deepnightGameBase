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

    override function frameUpdate() {
        // test for collisions
        if ( player.isAlive() ) {
            if ( distPx(player) <= innerRadius + player.hitRadius ) {
                player.hit(0, this);
                // TODO: Should this class or the player be responsible for effects on the player?
                player.setSquashX(0.5);
                fx.flashBangS(0xffcc00, 0.04, 0.1);
                player.bump(-0.1, 0.0);
                trace("player hit");
            }
        }
    }
}