package sample;


class SampleKillZone extends Entity {

    public static var ALL : Array<SampleKillZone> = [];

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
        if ( player.isAlive() 
            && attachX >= player.left && attachX <= player.right 
            && attachY >= player.top && attachY <= player.bottom ) {
            player.hit(0, this);
            player.setSquashX(0.5);
            fx.flashBangS(0xffcc00, 0.04, 0.1);
            trace("player hit");

            // TODO: repel the player
        }
    }
}