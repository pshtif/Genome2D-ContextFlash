/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.signals;

class GKeyboardSignalType {
    inline static public var KEY_DOWN:String = "keyDown";
    inline static public var KEY_UP:String = "keyUp";

    inline static public function fromNative(p_nativeType:String):String {
        var type:String = "";
        switch (p_nativeType) {
            case "keyDown":
                type = KEY_DOWN;
            case "keyUp":
                type = KEY_UP;
        }

        return type;
    }
}
