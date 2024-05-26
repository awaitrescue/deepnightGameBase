package sample;


class SampleKillZone extends Entity {

    public function new() {
        super(10, 10);

        var start = level.data.l_Entities.all_KillPoint[0];
        if (start != null)
            setPosCase(start.cx, start.cy);

        var bitmap = new h2d.Bitmap(h2d.Tile.fromColor(Red, iwid, ihei), spr);
        bitmap.tile.setCenterRatio(0.5, 1);
    }
}