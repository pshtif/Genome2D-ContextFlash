/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.filters;

import com.genome2d.context.stage3d.GStage3DContext;
import flash.display3D.Context3D;
import flash.Vector;
import com.genome2d.textures.GContextTexture;
class GBlurPassFilter extends GFilter
{

    inline static public var VERTICAL:Int = 0;
    inline static public var HORIZONTAL:Int = 1;

    public var blur:Float = 0;
    public var direction:Int = VERTICAL;

    public var colorize:Bool = false;
    public var red:Float = 0;
    public var green:Float = 0;
    public var blue:Float = 0;
    public var alpha:Float = 1;

    public function new(p_blur:Int, p_direction:Int) {
        super();

        //if (Genome2D.getInstance().cConfig.profile != "baseline") throw new GError(GError.CANNOT_RUN_IN_CONSTRAINED, GBlurPassFilter);

        overrideFragmentShader = true;

        fragmentCode =
            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>     \n" +
            "mul ft0.xyzw, ft0.xyzw, fc2.y                  \n" +

            "sub ft1.xy, v0.xy, fc1.xy                      \n" +
            "tex ft2, ft1.xy, fs0 <2d,linear,mipnone,clamp> \n" +
            "mul ft2.xyzw, ft2.xyzw, fc2.z                  \n" +
            "add ft0, ft0, ft2                              \n" +

            "add ft1.xy, v0.xy, fc1.xy                      \n" +
            "tex ft2, ft1.xy, fs0 <2d,linear,mipnone,clamp> \n" +
            "mul ft2.xyzw, ft2.xyzw, fc2.z                  \n" +
            "add ft0, ft0, ft2                              \n" +

            "sub ft1.xy, v0.xy, fc1.zw                      \n" +
            "tex ft2, ft1.xy, fs0 <2d,linear,mipnone,clamp> \n" +
            "mul ft2.xyzw, ft2.xyzw, fc2.w                  \n" +
            "add ft0, ft0, ft2                              \n" +

            "add ft1.xy, v0.xy, fc1.zw                      \n" +
            "tex ft2, ft1.xy, fs0 <2d,linear,mipnone,clamp> \n" +
            "mul ft2.xyzw, ft2.xyzw, fc2.w                  \n" +
            "add ft0, ft0, ft2                              \n" +

            "mul ft0.xyz, ft0.xyz, fc2.xxx					\n" +
            "mul ft1.xyz, ft0.www, fc3.xyz					\n" +
            "add ft0.xyz, ft0.xyz, ft1.xyz					\n" +
            "mul oc, ft0, fc3.wwww							\n";

        fragmentConstants = Vector.ofArray([0, 0, 0, 0, 1, 0.2270270270, 0.3162162162, 0.0702702703, 0, 0, 0, 1]);

        blur = p_blur;
        direction = p_direction;
    }

    override public function bind(p_context:GStage3DContext, p_texture:GContextTexture):Void {
        // We do invalidation each bind as the texture parameters are crucial for constants
        if (direction == HORIZONTAL) {
            fragmentConstants[0] = 1/p_texture.gpuWidth * 1.3846153846 * blur * .5;
            fragmentConstants[1] = 0;
            fragmentConstants[2] = 1/p_texture.gpuWidth * 3.2307692308 * blur * .5;
            fragmentConstants[3] = 0;
        } else {
            fragmentConstants[0] = 0;
            fragmentConstants[1] = 1/p_texture.gpuHeight * 1.3846153846 * blur * .5;
            fragmentConstants[2] = 0;
            fragmentConstants[3] = 1/p_texture.gpuHeight * 3.2307692308 * blur * .5;
        }

        fragmentConstants[4] = (colorize) ? 0 : 1;

        fragmentConstants[8] = red;
        fragmentConstants[9] = green;
        fragmentConstants[10] = blue;
        fragmentConstants[11] = alpha;

        super.bind(p_context, p_texture);
    }
}