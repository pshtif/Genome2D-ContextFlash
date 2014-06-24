/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.stats;

import com.genome2d.textures.GTextureFilteringType;
import com.genome2d.context.stage3d.GStage3DContext;
import com.genome2d.geom.GRectangle;
import com.genome2d.textures.GTextureUtils;
import flash.text.TextFieldAutoSize;
import com.genome2d.context.IContext;
import com.genome2d.textures.GContextTexture;
import flash.display.BitmapData;
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFormat;

class GStats implements IStats
{
    static public var fps:Int = 0;
    static public var drawCalls:Int = 0;
    static public var nodeCount:Int = 0;
    static public var customStats:Array<String>;

    static public var x:Int = 0;
    static public var y:Int = 0;
    static public var scaleX:Float = 1;
    static public var scaleY:Float = 1;
    static public var visible:Bool = false;

    private var g2d_statsField:TextField;
    private var g2d_initialized:Bool = false;

    private var g2d_previousTime:Int;

    private var g2d_fpsString:String;
    private var g2d_fpsCounter:Int = 0;

    private var g2d_memString:String;
    private var g2d_memSimpleString:String;
    private var g2d_mem:Int;
    private var g2d_memMax:Int;
    private var g2d_bitmapData:BitmapData;
    private var g2d_texture:GContextTexture;

    public function new() {
        var dtf:TextFormat = new TextFormat("_sans", 9, 0xFFFFFF);
        g2d_statsField = new TextField();
        g2d_statsField.defaultTextFormat = dtf;
        g2d_statsField.multiline = false;
        g2d_statsField.backgroundColor = 0x0;
        g2d_statsField.autoSize = TextFieldAutoSize.LEFT;
        g2d_statsField.selectable = false;
        g2d_statsField.background = true;
        g2d_statsField.height = 16;

        g2d_bitmapData = new BitmapData(256,16,true,0x0);

        g2d_initialized = true;
    }

    public function render(p_context:IContext):Void {
        if (!visible) return;
        var time:Int = untyped __global__["flash.utils.getTimer"]();

        if (time - 1000 > g2d_previousTime) {
            g2d_previousTime = time;
            fps = g2d_fpsCounter;
            g2d_fpsString = "<font color='#999999'>FPS:</font> " + fps + " / " + p_context.getNativeStage().frameRate;
            g2d_fpsCounter = 0;

            g2d_mem = untyped __int__(System.totalMemory / (1024 * 1024));
            g2d_memMax = g2d_mem > g2d_memMax ? g2d_mem : g2d_memMax;

            g2d_memString = "<font color='#999999'>MEM:</font> " + g2d_mem + " / " + g2d_memMax + "MB";
        }

        ++g2d_fpsCounter;

        g2d_statsField.htmlText = g2d_fpsString+" "+g2d_memString+ (untyped __is__(p_context, GStage3DContext) ? " <font color='#999999'>DRAWS:</font> "+drawCalls : "") + " ";

        if (customStats != null) {
            for (i in 0...customStats.length) {
                g2d_statsField.htmlText += customStats[i];
            }
        }

        if (g2d_texture == null) {
            g2d_texture = new GContextTexture(p_context, "stats_internal", 0, g2d_bitmapData, g2d_bitmapData.rect, "bgra");
            g2d_texture.setFilteringType(GTextureFilteringType.NEAREST);
            g2d_texture.invalidateNativeTexture(false);
        } else {
            if (g2d_bitmapData.width<g2d_statsField.width && g2d_bitmapData.width<1024) {
                g2d_bitmapData.dispose();
                var w:Int = untyped __int__(g2d_statsField.width);
                if (w>1024) w = 1024;
                g2d_bitmapData = new BitmapData(GTextureUtils.getNextValidTextureSize(w),16, true, 0x0);
                g2d_texture.g2d_bitmapData = g2d_bitmapData;
                g2d_texture.g2d_region = new GRectangle(0,0,g2d_bitmapData.width,16);
                g2d_bitmapData.draw(g2d_statsField);
                g2d_texture.invalidateNativeTexture(true);
            } else {
                g2d_bitmapData.fillRect(g2d_bitmapData.rect,0x0);
                g2d_bitmapData.draw(g2d_statsField);
                g2d_texture.invalidateNativeTexture(false);
            }
        }

        p_context.draw(g2d_texture, (g2d_texture.width*scaleX)/2+x, (g2d_texture.height*scaleY)/2+y, scaleX, scaleY, 0);
    }

    public function clear():Void {
        drawCalls = 1;
    }
}