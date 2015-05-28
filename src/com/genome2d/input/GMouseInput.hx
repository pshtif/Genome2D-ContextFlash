/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.input;
import com.genome2d.context.GCamera;

class GMouseInput {
	public var g2d_captured:Bool = false;
	
	public var dispatcher:IGInteractive;
	public var target:IGInteractive;
	public var camera:GCamera;
    public var localX:Float;
    public var localY:Float;
	public var type:String;
	
	public var contextX:Float;
    public var contextY:Float;
	public var worldX:Float;
	public var worldY:Float;
    public var buttonDown:Bool = false;
    public var ctrlKey:Bool = false;
    public var altKey:Bool = false;
    public var shiftKey:Bool = false;
    public var nativeCaptured:Bool = false;
    public var delta:Int = 0;

    public function new(p_target:IGInteractive, p_dispatcher:IGInteractive, p_type:String, p_localX:Float, p_localY:Float) {
		dispatcher = p_dispatcher;
		target = p_target;
        type = p_type;
        localX = p_localX;
        localY = p_localY;
    }
	
	public function clone(p_target:IGInteractive, p_dispatcher:IGInteractive, p_type:String):GMouseInput {
		var input:GMouseInput = new GMouseInput(p_target, p_dispatcher, p_type, localX, localY);
		input.contextX = contextX;
		input.contextY = contextY;
		input.worldX = worldX;
		input.worldY = worldY;
		input.buttonDown = buttonDown;
		input.ctrlKey = ctrlKey;
		input.altKey = altKey;
		input.shiftKey = shiftKey;
		input.nativeCaptured = nativeCaptured;
		input.delta = delta;
		input.camera = camera;
		
		return input;
	}
}
