/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context;

import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;

class GBlendMode
{
	private static var blendFactors:Array<Array<Array<Context3DBlendFactor>>> = [
		[
			[Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO],
			[Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA],
			[Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.DESTINATION_ALPHA],
			[Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA],
			[Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE],
			[Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA],
		],
		[ 
			[Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO],
			[Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA],
			[Context3DBlendFactor.ONE, Context3DBlendFactor.ONE],
			[Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA],
			[Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR],
			[Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA],
		]
	];
	
	inline static public var NONE:Int = 0;
	inline static public var NORMAL:Int = 1;
	inline static public var ADD:Int = 2;
	inline static public var MULTIPLY:Int = 3;
	inline static public var SCREEN:Int = 4;
	inline static public var ERASE:Int = 5;
	
	static public function addBlendMode(p_normalFactors:Array<Context3DBlendFactor>, p_premultipliedFactors:Array<Context3DBlendFactor>):Int { 
		blendFactors[0].push(p_normalFactors);
		blendFactors[1].push(p_premultipliedFactors);
		
		return blendFactors[0].length;
	}
	
	static public function setBlendMode(p_context:Context3D, p_mode:Int, p_premultiplied:Bool):Void {
		var p:Int = (p_premultiplied) ? 1 : 0;
		p_context.setBlendFactors(blendFactors[p][p_mode][0], blendFactors[p][p_mode][1]);
	}
}