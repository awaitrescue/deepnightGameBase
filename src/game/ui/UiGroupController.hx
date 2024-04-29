package ui;

enum abstract GroupDir(Int) {
	var North;
	var East;
	var South;
	var West;
}


@:allow(ui.UiGroupElement)
class UiGroupController extends dn.Process {
	static var UID = 0;

	var uid : Int;
	var ca : ControllerAccess<GameAction>;
	var current : Null<UiGroupElement>;

	var elements : Array<UiGroupElement> = [];
	var connectionsNeedRebuild = false;
	var uiGroupsConnections : Map<GroupDir, UiGroupController> = new Map();
	var componentsConnections : Map<Int, Map<GroupDir, UiGroupElement>> = new Map();

	var focused = true;
	var useMouse : Bool;


	public function new(process:dn.Process, useMouse=true) {
		super(process);

		this.useMouse = useMouse;

		uid = UID++;
		ca = App.ME.controller.createAccess();
		ca.lockCondition = ()->!focused || customControllerLock();
		ca.lock(0.1);
	}


	public dynamic function customControllerLock() return false;


	public function register(comp:ui.UiComponent) : UiGroupElement {
		var ge = new UiGroupElement(comp);
		elements.push(ge);
		comp.onAfterReflow = invalidateConnections;

		if( useMouse ) {
			comp.enableInteractive = true;
			comp.interactive.cursor = Button;

			comp.interactive.onOver = _->{
				focusElement(ge);
				focusGroup();
			}

			comp.interactive.onOut = _->{
				blurElement(ge);
			}

			comp.interactive.onClick = ev->{
				if( ev.button==0 )
					comp.use();
			}

			comp.interactive.enableRightButton = true;
		}

		return ge;
	}


	public function focusGroup() {
		var wasFocus = focused;
		focused = true;
		ca.lock(0.2);
		blurAllConnectedGroups();
		if( !wasFocus )
			onGroupFocus();
	}

	public function blurGroup() {
		var wasFocus = focused;
		focused = false;
		if( current!=null ) {
			current.comp.onBlur();
			current = null;
		}
		if( wasFocus )
			onGroupBlur();
	}

	public dynamic function onGroupFocus() {}
	public dynamic function onGroupBlur() {}

	function blurAllConnectedGroups(?ignoredGroup:UiGroupController) {
		var pending = [this];
		var dones = new Map();
		dones.set(uid,true);

		while( pending.length>0 ) {
			var cur = pending.pop();
			dones.set(cur.uid, true);
			for(g in cur.uiGroupsConnections) {
				if( dones.exists(g.uid) )
					continue;
				g.blurGroup();
				pending.push(g);
			}
		}
	}

	public function connectComponents(from:UiGroupElement, to:UiGroupElement, dir:GroupDir) {
		if( !componentsConnections.exists(from.uid) )
			componentsConnections.set(from.uid, new Map());
		componentsConnections.get(from.uid).set(dir, to);
	}

	public function countComponentConnections(c:UiGroupElement) {
		if( !componentsConnections.exists(c.uid) )
			return 0;

		var n = 0;
		for( next in componentsConnections.get(c.uid) )
			n++;
		return n;
	}

	public inline function hasComponentConnectionDir(c:UiGroupElement, dir:GroupDir) {
		return componentsConnections.exists(c.uid) && componentsConnections.get(c.uid).exists(dir);
	}

	public function hasComponentConnection(from:UiGroupElement, to:UiGroupElement) {
		if( !componentsConnections.exists(from.uid) )
			return false;

		for(next in componentsConnections.get(from.uid))
			if( next==to )
				return true;
		return false;
	}

	public inline function getComponentConnectionDir(from:UiGroupElement, dir:GroupDir) {
		return componentsConnections.exists(from.uid)
			? componentsConnections.get(from.uid).get(dir)
			: null;
	}



	public inline function invalidateConnections() {
		connectionsNeedRebuild = true;
	}

	function buildConnections() {
		// Clear
		componentsConnections = new Map();

		// Build connections with closest aligned elements
		for(from in elements)
			for(dir in [North,East,South,West]) {
				var other = findElementRaycast(from,dir);
				if( other!=null ) {
					connectComponents(from, other, dir);
					connectComponents(other, from, getOppositeDir(dir));
				}
			}

		// Fix missing connections
		for(from in elements)
			for(dir in [North,East,South,West]) {
				if( hasComponentConnectionDir(from,dir) )
					continue;
				var next = findElementFromAng(from, dirToAng(dir), M.PI*0.8, true);
				if( next!=null )
					connectComponents(from,next,dir);
			}
	}


	// Returns closest Element using an angle range
	function findElementFromAng(from:UiGroupElement, ang:Float, angRange:Float, ignoreConnecteds:Bool) : Null<UiGroupElement> {
		var best = null;
		for( other in elements ) {
			if( other==from || hasComponentConnection(from,other) )
				continue;

			if( M.radDistance(ang, from.angTo(other)) < angRange*0.5 ) {
				if( best==null )
					best = other;
				else {
					if( from.globalDistTo(other) < from.globalDistTo(best) )
						best = other;
				}
			}
		}
		return best;


	}

	// Returns closest Element using a collider-raycast
	function findElementRaycast(from:UiGroupElement, dir:GroupDir) : Null<UiGroupElement> {
		var ang = dirToAng(dir);
		var step = switch dir {
			case North, South: from.globalHeight;
			case East,West: from.globalWidth;
		}
		var x = from.globalLeft + Math.cos(ang)*step;
		var y = from.globalTop + Math.sin(ang)*step;
		var elapsedDist = step;

		var possibleNexts = [];
		while( elapsedDist<step*3 ) {
			for( other in elements )
				if( other!=from && other.overlapsRect(x, y, from.globalWidth, from.globalHeight ) )
					possibleNexts.push(other);

			if( possibleNexts.length>0 )
				return dn.Lib.findBestInArray(possibleNexts, (t)->-t.globalDistTo(from) );

			x += Math.cos(ang)*step;
			y += Math.sin(ang)*step;
			elapsedDist+=step;
		}


		return null;
	}


	function findClosest(from:UiGroupElement) : Null<UiGroupElement> {
		var best = null;
		for(other in elements)
			if( other!=from && ( best==null || from.globalDistTo(other) < from.globalDistTo(best) ) )
				best = other;
		return best;
	}


	public function createDebugger() {
		var g = new h2d.Graphics(App.ME.root);
		var debugProc = createChildProcess();
		debugProc.onUpdateCb = ()->{
			if( !debugProc.cd.hasSetS("tick",0.1) )
				renderDebugToGraphics(g);
		}
		debugProc.onDisposeCb = ()->{
			g.remove();
		}
	}

	/**
		Draw a debug render of the group structure into an existing Graphics object.
		NOTE: the render uses global coordinates, so the Graphics object should be attached to the scene root.
	**/
	public function renderDebugToGraphics(g:h2d.Graphics) {
		g.clear();
		g.removeChildren();
		buildConnections();
		var font = hxd.res.DefaultFont.get();
		for(from in elements) {
			// Bounds
			g.lineStyle(2, Pink);
			g.beginFill(Pink, 0.5);
			g.drawRect(from.globalLeft, from.globalTop, from.globalWidth, from.globalHeight);
			g.endFill();
			// Connections
			for(dir in [North,East,South,West]) {
				if( !hasComponentConnectionDir(from,dir) )
					continue;

				var next = getComponentConnectionDir(from,dir);
				var ang = from.angTo(next);
				g.lineStyle(2, Yellow);
				g.moveTo(from.globalCenterX, from.globalCenterY);
				g.lineTo(next.globalCenterX, next.globalCenterY);

				// Arrow head
				var arrowDist = 16;
				var arrowAng = M.PI*0.95;
				g.moveTo(next.globalCenterX, next.globalCenterY);
				g.lineTo(next.globalCenterX+Math.cos(ang+arrowAng)*arrowDist, next.globalCenterY+Math.sin(ang+arrowAng)*arrowDist);

				g.moveTo(next.globalCenterX, next.globalCenterY);
				g.lineTo(next.globalCenterX+Math.cos(ang-arrowAng)*arrowDist, next.globalCenterY+Math.sin(ang-arrowAng)*arrowDist);

				var tf = new h2d.Text(font,g);
				tf.text = switch dir {
					case North: 'N';
					case East: 'E';
					case South: 'S';
					case West: 'W';
				}
				tf.x = Std.int( ( from.globalCenterX*0.3 + next.globalCenterX*0.7 ) - tf.textWidth*0.5 );
				tf.y = Std.int( ( from.globalCenterY*0.3 + next.globalCenterY*0.7 ) - tf.textHeight*0.5 );
				tf.filter = new dn.heaps.filter.PixelOutline();
			}
		}
	}


	override function onDispose() {
		super.onDispose();

		ca.dispose();
		ca = null;

		elements = null;
		current = null;
	}

	function focusClosestElementFromGlobal(x:Float, y:Float) {
		var best = Lib.findBestInArray(elements, e->{
			return -M.dist(x, y, e.globalCenterX, e.globalCenterY);
		});
		if( best!=null )
			focusElement(best);
	}

	function blurElement(ge:UiGroupElement) {
		if( current==ge ) {
			current.comp.onBlur();
			current = null;
		}
	}

	function focusElement(ge:UiGroupElement) {
		if( current==ge )
			return;

		if( current!=null )
			current.comp.onBlur();
		current = ge;
		current.comp.onFocus();
	}

	inline function getOppositeDir(dir:GroupDir) {
		return switch dir {
			case North: South;
			case East: West;
			case South: North;
			case West: East;
		}
	}

	inline function dirToAng(dir:GroupDir) : Float {
		return switch dir {
			case North: -M.PIHALF;
			case East: 0;
			case South: M.PIHALF;
			case West: M.PI;
		}
	}

	function angToDir(ang:Float) : GroupDir {
		return  M.radDistance(ang,0)<=M.PIHALF*0.5 ? East
			: M.radDistance(ang,M.PIHALF)<=M.PIHALF*0.5 ? South
			: M.radDistance(ang,M.PI)<=M.PIHALF*0.5 ? West
			: North;
	}


	function gotoNextDir(dir:GroupDir) {
		if( current==null )
			return;

		if( hasComponentConnectionDir(current,dir) )
			focusElement( getComponentConnectionDir(current,dir) );
		else
			gotoConnectedGroup(dir);
	}


	function gotoConnectedGroup(dir:GroupDir) : Bool {
		if( !uiGroupsConnections.exists(dir) )
			return false;

		if( uiGroupsConnections.get(dir).elements.length==0 )
			return false;

		var g = uiGroupsConnections.get(dir);
		var from = current;
		// var pt = new h2d.col.Point(from.width*0.5, from.height*0.5);
		// from.f.localToGlobal(pt);
		blurGroup();
		g.focusGroup();
		g.focusClosestElementFromGlobal(from.globalCenterX, from.globalCenterY);
		return true;
	}


	public function connectGroup(dir:GroupDir, targetGroup:UiGroupController, symetric=true) {
		uiGroupsConnections.set(dir,targetGroup);
		if( symetric )
			targetGroup.connectGroup(getOppositeDir(dir), this, false);

		if( focused )
			blurAllConnectedGroups();
	}


	override function preUpdate() {
		super.preUpdate();

		if( !focused )
			return;

		// Build elements connections
		if( connectionsNeedRebuild ) {
			buildConnections();
			connectionsNeedRebuild = false;
		}

		// Init current
		if( current==null && elements.length>0 )
			if( !cd.hasSetS("firstInitDone",Const.INFINITE) || ca.isDown(MenuLeft) || ca.isDown(MenuRight) || ca.isDown(MenuUp) || ca.isDown(MenuDown) )
				focusElement(elements[0]);

		// Move current
		if( current!=null ) {
			if( ca.isPressed(MenuOk) )
				current.comp.use();

			if( ca.isPressedAutoFire(MenuLeft) )
				gotoNextDir(West);
			else if( ca.isPressedAutoFire(MenuRight) )
				gotoNextDir(East);

			if( ca.isPressedAutoFire(MenuUp) )
				gotoNextDir(North);
			else if( ca.isPressedAutoFire(MenuDown) )
				gotoNextDir(South);
		}
	}
}



private class UiGroupElement {
	var _pt : h2d.col.Point;

	public var uid(default,null) : Int;

	public var comp: UiComponent;

	public var globalLeft(get,never) : Float;
	public var globalRight(get,never) : Float;
	public var globalTop(get,never) : Float;
	public var globalBottom(get,never) : Float;

	public var globalWidth(get,never) : Int;
	public var globalHeight(get,never) : Int;

	public var globalCenterX(get,never) : Float;
	public var globalCenterY(get,never) : Float;


	public function new(comp:UiComponent) {
		uid = UiGroupController.UID++;
		_pt = new h2d.col.Point();
		this.comp = comp;
	}

	@:keep public function toString() {
		return 'UiGroupElement#$uid';
	}

	function get_globalLeft() {
		_pt.set();
		comp.localToGlobal(_pt);
		return _pt.x;
	}

	function get_globalRight() {
		_pt.set(comp.outerWidth, comp.outerHeight);
		comp.localToGlobal(_pt);
		return _pt.x;
	}

	function get_globalTop() {
		_pt.set();
		comp.localToGlobal(_pt);
		return _pt.y;
	}

	function get_globalBottom() {
		_pt.set(comp.outerWidth, comp.outerHeight);
		comp.localToGlobal(_pt);
		return _pt.y;
	}

	inline function get_globalWidth() return Std.int( globalRight - globalLeft );
	inline function get_globalHeight() return Std.int( globalBottom - globalTop );
	inline function get_globalCenterX() return ( globalLeft + globalRight ) * 0.5;
	inline function get_globalCenterY() return ( globalTop + globalBottom ) * 0.5;


	public inline function angTo(t:UiGroupElement) {
		return Math.atan2(t.globalCenterY-globalCenterY, t.globalCenterX-globalCenterX);
	}

	public inline function globalDistTo(t:UiGroupElement) {
		return M.dist(globalCenterX, globalCenterY, t.globalCenterX, t.globalCenterY);
	}

	public function overlapsRect(x:Float, y:Float, w:Int, h:Int) {
		return dn.Geom.rectOverlapsRect(
			globalLeft, globalTop, globalWidth, globalHeight,
			x, y, w, h
		);
	}

}