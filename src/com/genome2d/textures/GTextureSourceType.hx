/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.textures;

class GTextureSourceType {
    inline static public var BITMAPDATA:Int = 0;
	inline static public var BYTEARRAY:Int = 1;
	inline static public var RENDER_TARGET:Int = 2;
    inline static public var ATF_BGRA:Int = 3;
    inline static public var ATF_COMPRESSED:Int = 4;
    inline static public var ATF_COMPRESSEDALPHA:Int = 5;
    inline static public var TEXTURE:Int = 6;
}