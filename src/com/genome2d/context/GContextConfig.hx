/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context;

import com.genome2d.context.GStage3DContext;
import flash.display.Stage3D;
import flash.utils.Object;
import com.genome2d.context.stats.GStats;
import com.genome2d.context.stats.IGStats;
import flash.Vector;
import com.genome2d.geom.GRectangle;
import flash.Lib;
import flash.display.Stage;

class GContextConfig
{
    //public var alwaysUseRectangleTextures:Bool = true;
    public var useSeparateAlphaPipeline:Bool = true;
    public var useFastMem:Bool = true;
	public var enableDepthAndStencil:Bool = false;
	public var enableErrorChecking:Bool = false;
	public var antiAliasing:Int = 0;
	public var hdResolution:Bool = false;
	public var renderMode:String;
	public var profile:Object;
    public var viewRect:GRectangle;
    public var nativeStage:Stage;
    public var contextClass:Class<IGContext>;
    public var statsClass:Class<IGStats>;
    public var fallbackContextClass:Class<IGContext> = null;
    public var externalStage3D:Stage3D;

    #if swc
    public function new(p_stage:Stage, ?p_viewRect:GRectangle = null) {
    #else
    public function new(?p_stage:Stage = null, ?p_viewRect:GRectangle = null) {
    #end
        #if !swc
        nativeStage = (p_stage == null) ? Lib.current.stage : p_stage;
        #else
        nativeStage = p_stage;
        #end
        if (p_viewRect == null) {
            viewRect = new GRectangle(0,0,nativeStage.stageWidth,nativeStage.stageHeight);
        } else {
            viewRect = p_viewRect;
        }

		profile = Vector.ofArray(["baselineExtended", "baseline", "baselineConstrained"]);
		renderMode = "auto";
        contextClass = GStage3DContext;
        statsClass = GStats;
        #if !genome_stage3donly
        fallbackContextClass = GBitmapContext;
        #end
	}
}