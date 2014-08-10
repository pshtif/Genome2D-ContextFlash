/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.signals;

class GMouseSignal {
    public var x:Float;
    public var y:Float;
    public var buttonDown:Bool = false;
    public var ctrlKey:Bool = false;
    public var altKey:Bool = false;
    public var shiftKey:Bool = false;
    public var type:String;
    public var nativeCaptured:Bool = false;

    public function new(p_type:String, p_x:Float, p_y:Float, p_nativeCaptured:Bool) {
        type = p_type;
        x = p_x;
        y = p_y;
        nativeCaptured = p_nativeCaptured;
    }
}
