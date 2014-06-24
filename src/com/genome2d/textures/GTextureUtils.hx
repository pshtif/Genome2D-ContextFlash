/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.textures;

import flash.geom.Matrix;
import flash.geom.Point;
import flash.display.BitmapData;

class GTextureUtils
{
	static public function isBitmapDataTransparent(p_bitmapData:BitmapData):Bool {
		return p_bitmapData.getColorBoundsRect(0xFF000000, 0xFF000000, false).width != 0;
	}
	
	static public function isValidTextureSize(p_size:Int):Bool {
		return (getNextValidTextureSize(p_size) == p_size);
	}
	
	static public function getNextValidTextureSize(p_size:Int):Int {
		var size:Int = 1;
		while (p_size > size) size*=2;
		return size;
	}
	
	static public function getPreviousValidTextureSize(p_size:Int):Int {
		return getNextValidTextureSize(p_size)>>1;
	}
	
	static public function getNearestValidTextureSize(p_size:Int):Int {
		var previous:Int = getPreviousValidTextureSize(p_size);
		var next:Int = getNextValidTextureSize(p_size);
		
		return (p_size-previous < next-p_size) ? previous : next; 
	}
	
	static public function resampleBitmapData(p_bitmapData:BitmapData):BitmapData {
		var zero:Point = new Point();
		var bitmapWidth:Int = p_bitmapData.width;
		var bitmapHeight:Int = p_bitmapData.height;

		var validWidth:Int = getNextValidTextureSize(bitmapWidth);
		var validHeight:Int = getNextValidTextureSize(bitmapHeight);

		if (validWidth == bitmapWidth && validHeight == bitmapHeight) return p_bitmapData;
		
		var resampled:BitmapData;
		var resampleMatrix:Matrix;
		
        resampleMatrix = new Matrix();
        resampled = new BitmapData(untyped __int__(validWidth), untyped __int__(validHeight), true, 0x0);
        resampled.copyPixels(p_bitmapData, p_bitmapData.rect, zero);

		return resampled;			
	}
}