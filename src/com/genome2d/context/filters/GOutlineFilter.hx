/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.filters;

import flash.display3D.Context3D;
import flash.Vector;
import com.genome2d.textures.GTexture;
class GOutlineFilter extends GFilter
{
    public var blur:Float = 0;

    public var red:Float = 0;
    public var green:Float = 0;
    public var blue:Float = 0;
    public var alpha:Float = 1;

    public function new(p_blur:Int, p_direction:Int) {
        super();

        overrideFragmentShader = true;

        fragmentCode =
            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>     \n" +
            "mul ft0.w, ft0.w, fc2.x                        \n" +

            "sub ft1.xy, v0.x, fc1.x                        \n" +
            "tex ft2, ft1.xy, fs0 <2d,linear,mipnone,clamp> \n" +
            "sub ft0.w, ft0.w, ft2.w                        \n" +

            "add ft1.xy, v0.x, fc1.x                        \n" +
            "tex ft2, ft1.xy, fs0 <2d,linear,mipnone,clamp> \n" +
            "sub ft0.w, ft0.w, ft2.w                        \n" +

            "sub ft1.xy, v0.y, fc1.y                        \n" +
            "tex ft2, ft1.xy, fs0 <2d,linear,mipnone,clamp> \n" +
            "sub ft0.w, ft0.w, ft2.w                        \n" +

            "add ft1.xy, v0.y, fc1.y                        \n" +
            "tex ft2, ft1.xy, fs0 <2d,linear,mipnone,clamp> \n" +
            "sub ft0.w, ft0.w, ft2.w                        \n" +

            "mov ft0.xyz, fc3.xyz       					\n" +
            "mov oc, ft0 \n";

        fragmentConstants = Vector.ofArray([0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0.0]);

        blur = p_blur;
    }

    override public function bind(p_context:IGContext, p_texture:GTexture):Void {
        // We do invalidation each bind as the textures parameters are crucial for constants
        fragmentConstants[0] = 1 / p_texture.gpuWidth;// * 1.3846153846 * blur * .5;
        fragmentConstants[1] = 1 / p_texture.gpuHeight;// * 1.3846153846 * blur * .5;

        fragmentConstants[8] = red;
        fragmentConstants[9] = green;
        fragmentConstants[10] = blue;
        fragmentConstants[11] = alpha;

        super.bind(p_context, p_texture);
    }
}