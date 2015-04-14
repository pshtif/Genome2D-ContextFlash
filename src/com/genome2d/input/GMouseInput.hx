/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.input;

class GMouseInput {
	public var dispatcher:IGInteractive;
	public var target:IGInteractive;
    public var x:Float;
    public var y:Float;
	public var type:String;
	
	public var contextX:Float;
    public var contextY:Float;
    public var buttonDown:Bool = false;
    public var ctrlKey:Bool = false;
    public var altKey:Bool = false;
    public var shiftKey:Bool = false;
    public var nativeCaptured:Bool = false;
    public var delta:Int = 0;

    public function new(p_dispatcher:IGInteractive, p_target:IGInteractive, p_type:String, p_x:Float, p_y:Float) {
		dispatcher = p_dispatcher;
		target = p_target;
        type = p_type;
        x = p_x;
        y = p_y;
    }
	
	public function clone(p_dispatcher:IGInteractive, p_target:IGInteractive, p_type:String, p_x:Float, p_y:Float):GMouseInput {
		var input:GMouseInput = new GMouseInput(dispatcher, target, type, p_x, p_y);
		input.contextX = contextX;
		input.contextY = contextY;
		input.buttonDown = buttonDown;
		input.ctrlKey = ctrlKey;
		input.altKey = altKey;
		input.shiftKey = shiftKey;
		input.nativeCaptured = nativeCaptured;
		input.delta = delta;
		
		return input;
	}
}
