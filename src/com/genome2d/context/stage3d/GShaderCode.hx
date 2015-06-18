package com.genome2d.context.stage3d;

/**
 * ...
 * @author Peter @sHTiF Stefcek
 */
class GShaderCode
{
	inline static public var FRAGMENT_FINAL_VARYING_CODE:String = "mov oc, v0";
	
	inline static public var FRAGMENT_FINAL_CONSTANT_CODE:String = "mov oc, fc0";
	
	inline static public var FRAGMENT_FINAL_TEMPORARY_CODE:String = "mov oc, ft0";

    inline static public var FRAGMENT_MUL_COLOR_CONSTANT_CODE:String = "mul ft0, ft0, fc1";

    inline static public var FRAGMENT_MUL_COLOR_VARYING_CODE:String = "mul ft0, ft0, v1";
	
	inline static public function getSamplerFragmentCode(p_repeat:Bool, p_filtering:Int, p_atf:String):String {
        return "tex ft0, v0, fs0 <2d," + ((p_repeat) ? "repeat" : "clamp") + ((p_atf != "") ? "," + p_atf + "," : ",") + ((p_filtering == 0) ? "nearest>" : "linear>");
    }
	
	inline static public var VERTEX_COLOR_CODE:String = "m44 op, va0, vc0 \n"+ 
														"mov v0, va1";
}