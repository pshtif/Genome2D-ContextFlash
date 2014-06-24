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
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3D;

/**
    Filter superclass all fitlers need to extend this class
**/
class GFilter {
    public var shaderVersionRequired:Int = 1;

    public var id:String;
    public var overrideFragmentShader:Bool = false;
    public var fragmentCode:String = "";
    public var fragmentConstants:Vector<Float>;

    static private var g2d_count:Int = 0;

    /**

    **/
    private function new() {
        id = untyped (g2d_count++)+"";
    }

    /**
        Called when filter is being bound to the render pipeline
    **/
    public function bind(p_context:GStage3DContext, p_defaultTexture:GContextTexture):Void {
        if (fragmentConstants != null && fragmentConstants.length>0) p_context.getNativeContext().setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, fragmentConstants, untyped __int__(fragmentConstants.length/4));
    }

    /**
        Called when filter is finished rendering
    **/
    public function clear(p_context:GStage3DContext):Void {}
}
