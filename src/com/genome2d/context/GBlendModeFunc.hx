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

class GBlendModeFunc
{
	private static var blendFactors:Array<Map<GBlendMode,Array<Context3DBlendFactor>>> = [
		[
			GBlendMode.NONE => [Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO],
			GBlendMode.NORMAL => [Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA],
			GBlendMode.ADD => [Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.DESTINATION_ALPHA],
			GBlendMode.MULTIPLY => [Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA],
			GBlendMode.SCREEN => [Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE],
			GBlendMode.ERASE => [Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA],
		],
		[
			GBlendMode.NONE => [Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO],
			GBlendMode.NORMAL => [Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA],
			GBlendMode.ADD => [Context3DBlendFactor.ONE, Context3DBlendFactor.ONE],
			GBlendMode.MULTIPLY => [Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA],
			GBlendMode.SCREEN => [Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR],
			GBlendMode.ERASE => [Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA],
		]
	];
	/*
	static public function addBlendMode(p_normalFactors:Array<Context3DBlendFactor>, p_premultipliedFactors:Array<Context3DBlendFactor>):Int { 
		blendFactors[0].push(p_normalFactors);
		blendFactors[1].push(p_premultipliedFactors);
		
		return blendFactors[0].length;
	}
	/**/
	static public function setBlendMode(p_context:Context3D, p_mode:GBlendMode, p_premultiplied:Bool):Void {
		var p:Int = (p_premultiplied) ? 1 : 0;
		p_context.setBlendFactors(blendFactors[p][p_mode][0], blendFactors[p][p_mode][1]);
	}
}