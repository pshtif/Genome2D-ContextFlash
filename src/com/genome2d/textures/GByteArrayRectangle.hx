package com.genome2d.textures;
import flash.utils.ByteArray;

/**
 * ...
 * @author Peter @sHTiF Stefcek
 */
class GByteArrayRectangle
{
	public var width:Int;
	public var height:Int;
	public var byteArray:ByteArray;
	
	public function new(p_width:Int, p_height:Int, p_byteArray:ByteArray) {
		width = p_width;
		height = p_height;
		byteArray = p_byteArray;
	}
	
}