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
import com.genome2d.textures.GContextTexture;
import flash.Vector;
import com.genome2d.textures.GContextTexture;
import com.genome2d.context.GContextCamera;
import com.genome2d.error.GError;

import flash.display3D.Context3D;

class GBloomPassFilter extends GFilter
{
    public var texture:GContextTexture;

    public function new() {
        super();

        fragmentCode =
            "tex ft1, v0, fs1 <2d,linear,mipnone,clamp>	\n" +
            "dp3 ft2.x, ft0.xyz, fc1.xyz                \n" +
            "sub ft3.xyz, ft0.xyz, ft2.xxx              \n" +
            "mul ft3.xyz, ft3.xyz, fc2.zzz              \n" +
            "add ft3.xyz, ft3.xyz, ft2.xxx              \n" +
            "mul ft0.xyz, ft3.xytz, fc2.xxx             \n" +
            "dp3 ft2.x, ft1.xyz, fc1.xyz                \n" +
            "sub ft3.xyz, ft1.xyz, ft2.xxx              \n" +
            "mul ft3.xyz, ft3.xyz, fc2.www              \n" +
            "add ft3.xyz, ft3.xyz, ft2.xxx              \n" +
            "mul ft1.xyz, ft3.xyz, fc2.yyy              \n" +
            "sat ft2.xyz, ft0.xyz                       \n" +
            "sub ft2.xyz, fc0.yyy, ft2.xyz              \n" +
            "mul ft1.xyz, ft1.xyz, ft2.xyz              \n" +
            "add ft0, ft0, ft1              			\n";

        fragmentConstants = Vector.ofArray([0.3, 0.59, 0.11, 1,
                                            1.25, 1, 1, 1]);
    }

    override public function bind(p_context:GStage3DContext, p_texture:GContextTexture):Void {
        super.bind(p_context, p_texture);
        if (texture == null) new GError("There is no texture set for bloom pass.");
        p_context.getNativeContext().setTextureAt(1, texture.nativeTexture);
    }

    override public function clear(p_context:GStage3DContext):Void {
        p_context.getNativeContext().setTextureAt(1, null);
    }
}