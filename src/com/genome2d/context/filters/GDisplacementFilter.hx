/*
* 	Genome2D - GPU 2D framework utilizing Stage3D API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.context.filters;

import com.genome2d.context.IGContext;
import com.genome2d.textures.GTexture;
import com.genome2d.geom.GMatrix3D;
import com.genome2d.context.filters.GFilter;

import flash.Vector;
import flash.display3D.Context3DProgramType;

class GDisplacementFilter extends GFilter {

    private var g2d_matrix:GMatrix3D;
    public var offset:Float = 0;

    public var displacementMap:GTexture;
    public var alphaMap:GTexture;
    public var alpha:Float = 1;


    public function new(p_scaleX:Float = .1, p_scaleY:Float = .1) {
        super();

        g2d_matrix = new GMatrix3D();
        g2d_matrix.copyRawDataFrom(Vector.ofArray([p_scaleX,0,0,0, 0, p_scaleY,0,0, 0,0,0,0, 0,0,0,0]));

        overrideFragmentShader = true;

        fragmentCode =
            "mov ft0, v0                                    \n" +
            "add ft0.y, v0.y, fc5.x                         \n" +
            "tex ft0, ft0, fs1 <2d,linear,mipnone,repeat>    \n" +
            "sub ft0, ft0, fc0.zzzz                         \n" +
            "m44 ft0, ft0, fc1                              \n" +
            "add ft0, v0, ft0                               \n" +
            "tex ft1, ft0, fs0 <2d,linear,mipnone,clamp>    \n" +
            "mul oc, ft1, fc6                              ";
            //"tex ft2, v0, fs2 <2d,linear,mipnone,clamp>     \n" +
            //"mul oc, ft1, ft2.wwww";
    }

    override public function bind(p_context:IGContext, p_defaultTexture:GTexture):Void {
        p_context.getNativeContext().setProgramConstantsFromMatrix(Context3DProgramType.FRAGMENT, 1, g2d_matrix, true);
        p_context.getNativeContext().setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, Vector.ofArray([offset,0,0,0.0,alpha,alpha,alpha,alpha]), 2);

        p_context.getNativeContext().setTextureAt(1, displacementMap.nativeTexture);
        //p_context.getNativeContext().setTextureAt(2, alphaMap.nativeTexture);
    }

    override public function clear(p_context:IGContext):Void {
        p_context.getNativeContext().setTextureAt(1, null);
        //p_context.getNativeContext().setTextureAt(2, null);
    }
}