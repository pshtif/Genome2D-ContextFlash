/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.input;

class GKeyboardInput {
    public var type:String;
    public var keyCode:Int;
	public var charCode:Int;

    public function new(p_type:String, p_keyCode:Int, p_charCode:Int) {
        type = p_type;
        keyCode = p_keyCode;
		charCode = p_charCode;
    }
}
