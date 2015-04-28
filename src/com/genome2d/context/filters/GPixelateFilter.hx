/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.context.filters;

import com.genome2d.context.IGContext;
import com.genome2d.textures.GTexture;
import com.genome2d.context.stage3d.GStage3DContext;
import flash.Vector;
import com.genome2d.context.filters.GFilter;

class GPixelateFilter extends GFilter {
    public var pixelSize:Int = 1;

    public function new(p_pixelSize:Int) {
        super();

        overrideFragmentShader = true;

        fragmentCode =
        "div ft0, v0, fc1                       \n" +
        "frc ft1, ft0                           \n" +
        "sub ft0, ft0, ft1                      \n" +
        "mul ft1, ft0, fc1                      \n" +
        "add ft0.xy, ft1,xy, fc1.zw 			\n" +
        "tex oc, ft0, fs0<2d, clamp, nearest>";

        pixelSize = p_pixelSize;

        fragmentConstants = Vector.ofArray([0.0, 0.0, 0.0, 0.0]);
    }

    override public function bind(p_context:IGContext, p_texture:GTexture):Void {
        fragmentConstants[0] = pixelSize / p_texture.nativeWidth;
        fragmentConstants[1] = pixelSize / p_texture.nativeHeight;
        fragmentConstants[2] = pixelSize / (p_texture.nativeWidth * 2);
        fragmentConstants[3] = pixelSize / (p_texture.nativeHeight * 2);

        super.bind(p_context, p_texture);
    }
}
