/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.stage3d.renderers;

import com.genome2d.context.filters.GFilter;
import com.adobe.utils.AGALMiniAssembler;
import flash.utils.ByteArray;
import flash.Vector;

class GRenderersCommon
{
    inline static private var COLOR_FRAGMENT_CODE:String = "mov oc, fc0";

    static private function getSamplerFragmentCode(p_repeat:Bool, p_filtering:Int, p_atf:String):String {
        return "tex ft0, v0, fs0 <2d," + ((p_repeat) ? "repeat" : "clamp") + ((p_atf != "") ? "," + p_atf + "," : ",") + ((p_filtering == 0) ? "nearest>" : "linear>");
    }

    inline static private var ALPHA_FRAGMENT_CODE:String = "mul ft0, ft0, v1";

    inline static private var FINAL_FRAGMENT_CODE:String = "mov oc, ft0";

    static public function getColorShaderCode():ByteArray {
        var assembler:AGALMiniAssembler = new AGALMiniAssembler();
        assembler.assemble("fragment", COLOR_FRAGMENT_CODE, GRenderersCommon.AGAL_VERSION);

        return assembler.agalcode;
    }

    static public function getTexturedShaderCode(p_repeat:Bool, p_filtering:Int, p_alpha:Bool, p_atf:String = "", p_filter:GFilter = null):ByteArray {
        var shaderString:String;
        if (p_filter==null || !p_filter.overrideFragmentShader) {
            shaderString = getSamplerFragmentCode(p_repeat, p_filtering, p_atf);
            if (p_filter != null) shaderString += "\n"+p_filter.fragmentCode;
            if (p_alpha) shaderString += "\n"+ALPHA_FRAGMENT_CODE;
            shaderString+="\n"+FINAL_FRAGMENT_CODE;
        } else {
            shaderString = p_filter.fragmentCode;
        }

        var assembler:AGALMiniAssembler = new AGALMiniAssembler();
        assembler.assemble("fragment", shaderString, GRenderersCommon.AGAL_VERSION);

        return assembler.agalcode;
    }



    static public var AGAL_VERSION:Int = 1;

    static public var DEFAULT_CONSTANTS:Vector<Float>;

	static public var NORMALIZED_VERTICES:Vector<Float>;
	
	static public var NORMALIZED_UVS:Vector<Float>;

    static public function init(p_agalVersion:Int):Void {
        AGAL_VERSION = p_agalVersion;

        DEFAULT_CONSTANTS = Vector.ofArray([0, 0.5, 1, 2]);
        NORMALIZED_VERTICES = Vector.ofArray([-.5, .5,
                                              -.5,-.5,
                                               .5,-.5,
                                               .5, .5
                                             ]);
        NORMALIZED_UVS = Vector.ofArray([ .0, 1.0,
                                          .0,  .0,
                                         1.0,  .0,
                                         1.0, 1.0
                                        ]);
    }
}