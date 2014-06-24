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
import com.genome2d.error.GError;

import flash.display3D.Context3D;

class GHDRPassFilter extends GFilter
{
    public var texture:GContextTexture;

    private var g2d_saturation:Float = 1.3;
    #if swc @:extern #end
    public var saturation(get, set):Float;
    #if swc @:getter(saturation) #end
    public function get_saturation():Float {
        return g2d_saturation;
    }
    public function set_saturation(p_value:Float):Float {
        g2d_saturation = p_value;
        fragmentConstants[4] = g2d_saturation;
        return g2d_saturation;
    }

    public function new(p_saturation:Float = 1.3) {
        super();

        fragmentCode =
            "tex ft1, v0, fs1 <2d,linear,mipnone,clamp>	\n" + // original

            "sub ft0.xyz, fc1.www, ft0.xyz               \n" +
            "add ft0.xyz, ft1.xyz, ft0.xyz               \n" +
            "sub ft0.xyz, ft0.xyz, fc2.yyy               \n" +
            "sat ft0.xyz, ft0.xyz                        \n" +
            // boost original saturation
            "dp3 ft2.x, ft1.xyz, fc1.xyz                \n" +
            "sub ft1.xyz, ft1.xyz, ft2.xxx                \n" +
            "mul ft1.xyz, ft1.xyz, fc2.xxx                \n" +
            "add ft1.xyz, ft1.xyz, ft2.xxx                \n" +
            // merge result

            "add ft0.xyz, ft0.xyz, ft1.xyz               \n" +
            "sub ft0.xyz, ft0.xyz, fc2.yyy               \n";

        fragmentConstants = Vector.ofArray([0.2125, 0.7154, 0.0721, 1.0, p_saturation, 0.5, 0, 0]);

        g2d_saturation = p_saturation;
    }

    override public function bind(p_context:GStage3DContext, p_texture:GContextTexture):Void {
        super.bind(p_context, p_texture);
        if (texture == null) throw new GError("There is no texture set for HDR pass.");
        p_context.getNativeContext().setTextureAt(1, texture.nativeTexture);
    }

    override public function clear(p_context:GStage3DContext):Void {
        p_context.getNativeContext().setTextureAt(1, null);
    }
}