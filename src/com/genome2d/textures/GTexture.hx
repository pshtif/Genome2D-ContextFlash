/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.textures;

import com.genome2d.callbacks.GCallback.GCallback0;
import com.genome2d.callbacks.GCallback.GCallback1;
import com.genome2d.context.GContextFeature;
import com.genome2d.context.stage3d.GStage3DContext;
import com.genome2d.debug.GDebug;
import com.genome2d.geom.GRectangle;
import com.genome2d.textures.GTextureManager;
import com.genome2d.textures.GTextureSourceType;

import flash.display.BitmapData;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;
import flash.utils.ByteArray;
import flash.utils.Object;

@:access(com.genome2d.textures.GTextureManager)
class GTexture
{
	private var g2d_onInvalidated:GCallback1<GTexture>;
	#if swc @:extern #end
    public var onInvalidated(get,never):GCallback1<GTexture>;
    #if swc @:getter(onInvalidated) #end
    inline private function get_onInvalidated():GCallback1<GTexture> {
		if (g2d_onInvalidated == null) g2d_onInvalidated = new GCallback1(GTexture);
        return g2d_onInvalidated;
    }
	
	
    private var g2d_dirty:Bool = true;
    inline public function isDirty():Bool {
        return g2d_dirty;
    }

	private var g2d_pivotX:Float;
	/**
	 * 	X pivot
	 */
    #if swc @:extern #end
    public var pivotX(get, set):Float;
    #if swc @:getter(pivotX) #end
    inline private function get_pivotX():Float {
        return g2d_pivotX*scaleFactor;
    }
    #if swc @:setter(pivotX) #end
    inline private function set_pivotX(p_value:Float):Float {
        return g2d_pivotX = p_value/scaleFactor;
    }

    private var g2d_pivotY:Float;
	/**
	 * 	Y pivot
	 */
    #if swc @:extern #end
    public var pivotY(get, set):Float;
    #if swc @:getter(pivotY) #end
    inline private function get_pivotY():Float {
        return g2d_pivotY*scaleFactor;
    }
    #if swc @:setter(pivotY) #end
    inline private function set_pivotY(p_value:Float):Float {
        return g2d_pivotY = p_value/scaleFactor;
    }
	
	private var g2d_gpuWidth:Int;
	/**
	 * 	Gpu width
	 */
    #if swc @:extern #end
    public var gpuWidth(get, never):Int;
    #if swc @:getter(gpuWidth) #end
    inline private function get_gpuWidth():Int {
        return g2d_gpuWidth;
    }

	private var g2d_gpuHeight:Int;
	/**
	 * 	Gpu height
	 */
    #if swc @:extern #end
    public var gpuHeight(get, never):Int;
    #if swc @:getter(gpuHeight) #end
    inline private function get_gpuHeight():Int {
        return g2d_gpuHeight;
    }
	
	private var g2d_nativeWidth:Int;
	/**
	 * 	Native width
	 */
    #if swc @:extern #end
    public var nativeWidth(get, never):Int;
    #if swc @:getter(nativeWidth) #end
    inline private function get_nativeWidth():Int {
        return g2d_nativeWidth;
    }

	private var g2d_nativeHeight:Int;
	/**
	 * 	Native height
	 */
    #if swc @:extern #end
    public var nativeHeight(get, never):Int;
    #if swc @:getter(nativeHeight) #end
    inline private function get_nativeHeight():Int {
        return g2d_nativeHeight;
    }
	
	/**
	 * 	Width of the texture calculating with the scaleFactor
	 */
    #if swc @:extern #end
    public var width(get, never):Float;
    #if swc @:getter(width) #end
    inline private function get_width():Float {
        return g2d_nativeWidth*scaleFactor;
    }

	/**
	 * 	Height of the texture calculating with the scaleFactor
	 */
    #if swc @:extern #end
    public var height(get, never):Float;
    #if swc @:getter(height) #end
    inline private function get_height():Float {
        return g2d_nativeHeight*scaleFactor;
    }

	/**
	 * 	Scale factor
	 */
    private var g2d_scaleFactor:Float;
    #if swc @:extern #end
    public var scaleFactor(get, set):Float;
    #if swc @:getter(scaleFactor) #end
    inline private function get_scaleFactor():Float {
        return g2d_scaleFactor;
    }
    #if swc @:setter(scaleFactor) #end
    inline private function set_scaleFactor(p_value:Float):Float {
        g2d_scaleFactor = p_value;
        return g2d_scaleFactor;
    }

    private var g2d_filteringType:Int;
	/**
	 * 	Filtering type
	 */
    #if swc @:extern #end
    public var filteringType(get,set):Int;
    #if swc @:getter(filteringType) #end
    inline private function get_filteringType():Int {
        return g2d_filteringType;
    }
    #if swc @:setter(filteringType) #end
    inline private function set_filteringType(p_value:Int):Int {
        return g2d_filteringType = p_value;
    }

    private var g2d_sourceType:Int;
	/**
	 * 	Source type
	 */
    #if swc @:extern #end
    public var sourceType(get,never):Int;
    #if swc @:getter(sourceType) #end
    public function get_sourceType():Int {
        return g2d_sourceType;
    }
	
	private var g2d_format:String;
    #if swc @:extern #end
    public var format(get,set):String;
    #if swc @:getter(format) #end
    inline private function get_format():String {
        return g2d_format;
    }
    #if swc @:setter(format) #end
    inline private function set_format(p_value:String):String {
        g2d_format = p_value;
        g2d_dirty = true;
        return p_value;
    }

    private var g2d_u:Float;
	#if swc @:extern #end
    public var u(get, never):Float;
    #if swc @:getter(u) #end
    inline private function get_u():Float {
        return g2d_u;
    }
    private var g2d_v:Float;
	#if swc @:extern #end
    public var v(get, never):Float;
    #if swc @:getter(v) #end
    inline private function get_v():Float {
        return g2d_v;
    }
	
    private var g2d_uScale:Float;
	#if swc @:extern #end
    public var uScale(get, never):Float;
    #if swc @:getter(uScale) #end
    inline private function get_uScale():Float {
        return g2d_uScale;
    }
	
    private var g2d_vScale:Float;
	#if swc @:extern #end
    public var vScale(get, never):Float;
    #if swc @:getter(vScale) #end
    inline private function get_vScale():Float {
        return g2d_vScale;
    }

    private var g2d_repeatable:Bool;
    #if swc @:extern #end
    public var repeatable(get,set):Bool;
    #if swc @:getter(repeatable) #end
    inline private function get_repeatable():Bool {
        return g2d_repeatable;
    }
    #if swc @:setter(repeatable) #end
    inline private function set_repeatable(p_value:Bool):Bool {
        g2d_repeatable = p_value;
        g2d_dirty = true;
        return p_value;
    }

    private var g2d_nativeTexture:TextureBase;
    #if swc @:extern #end
    public var nativeTexture(get,never):TextureBase;
    #if swc @:getter(nativeTexture) #end
    inline private function get_nativeTexture():TextureBase {
        return g2d_nativeTexture;
    }
	
	private var g2d_frame:GRectangle;

    private var g2d_region:GRectangle;
    #if swc @:extern #end
    public var region(get,set):GRectangle;
    #if swc @:getter(region) #end
    inline private function get_region():GRectangle {
        return g2d_region;
    }
    #if swc @:setter(region) #end
    inline private function set_region(p_value:GRectangle):GRectangle {
        g2d_region = p_value;

        g2d_nativeWidth = Std.int(g2d_region.width);
        g2d_nativeHeight = Std.int(g2d_region.height);

        invalidateUV();

        return g2d_region;
    }

	private var g2d_parent:GTexture;
    private var g2d_source:Object;
    /**
        Source
    **/
    #if swc @:extern #end
    public var source(get,set):Object;
    #if swc @:getter(source) #end
    inline private function get_source():Object {
        return g2d_source;
    }
    #if swc @:setter(source) #end
    inline private function set_source(p_value:Object):Object {
        if (g2d_source != p_value) {
            g2d_dirty = true;
			g2d_source = p_value;
            if (Std.is(g2d_source, BitmapData)) {
				var bitmapData:BitmapData = cast g2d_source;
                g2d_sourceType = GTextureSourceType.BITMAPDATA;
                g2d_nativeWidth = bitmapData.width;
                g2d_nativeHeight = bitmapData.height;
                premultiplied = true;
            } else if (Std.is(g2d_source, ByteArray)) {
				var byteArray:ByteArray = cast g2d_source;
                var atf:String = String.fromCharCode(byteArray[0]) + String.fromCharCode(byteArray[1]) + String.fromCharCode(byteArray[2]);
                if (atf == "ATF") {
                    g2d_sourceType = GTextureSourceType.ATF_BGRA;
                    var offset:Int = byteArray[6] == 255 ? 12 : 6;

                    switch (g2d_source[offset]) {
                        case 0,1:
                            g2d_sourceType = GTextureSourceType.ATF_BGRA;
                        case 2,3:
                            g2d_sourceType = GTextureSourceType.ATF_COMPRESSED;
                            g2d_atfType = "dxt1";
                        case 4,5:
                            g2d_sourceType = GTextureSourceType.ATF_COMPRESSEDALPHA;
                            g2d_atfType = "dxt5";
                    }
                    g2d_nativeWidth = untyped __int__(Math.pow(2,byteArray[offset+1]));
                    g2d_nativeHeight = untyped __int__(Math.pow(2,byteArray[offset+2]));
                    premultiplied = false;
                } else {
                    //g2d_sourceType = GTextureSourceType.BYTEARRAY;
                }
            } else if (Std.is(g2d_source,GRectangle)) {
                g2d_sourceType = GTextureSourceType.RENDER_TARGET;
                g2d_nativeWidth = p_value.width;
                g2d_nativeHeight = p_value.height;
            } else if (Std.is(g2d_source, GTexture)) {
				g2d_parent = cast g2d_source;
				g2d_sourceType = GTextureSourceType.TEXTURE;
				g2d_parent.onInvalidated.add(parentInvalidated_handler);
				g2d_gpuWidth = g2d_parent.g2d_gpuWidth;
				g2d_gpuHeight = g2d_parent.g2d_gpuHeight;
				g2d_nativeWidth = g2d_parent.g2d_nativeWidth;
				g2d_nativeHeight = g2d_parent.g2d_nativeHeight;
				g2d_nativeTexture = g2d_parent.nativeTexture;
			} else {
                GDebug.error("Invalid texture source.");
            }
            g2d_dirty = true;
        }
        return g2d_source;
    }

    private var g2d_atfType:String = "";

    public var premultiplied:Bool;
	
    private var g2d_initializedRenderTarget:Bool;

    private var g2d_contextId:Int;

	static private var g2d_instanceCount:Int = 0;

    public function new(p_source:Object) {
        g2d_nativeWidth = g2d_nativeHeight = 0;
		g2d_gpuWidth = g2d_gpuHeight = 0;
		g2d_region = new GRectangle(0, 0, 1, 1);
        g2d_u = g2d_v = 0;
        g2d_uScale = g2d_vScale = 1;
		g2d_pivotX = g2d_pivotY = 0;
        g2d_initializedRenderTarget = false;
        premultiplied = true;
        g2d_dirty = true;
        g2d_scaleFactor = 1;

		g2d_instanceCount++;
		g2d_contextId = g2d_instanceCount;
        g2d_format = "bgra";
        g2d_repeatable = false;

        g2d_filteringType = GTextureManager.defaultFilteringType;
        source = p_source;
		
		GTextureManager.g2d_addTexture(this);
	}

	private function invalidateUV():Void {
		g2d_u = g2d_region.x / gpuWidth;
		g2d_v = g2d_region.y / gpuHeight;

		g2d_uScale = g2d_nativeWidth / gpuWidth;
		g2d_vScale = g2d_nativeHeight / gpuHeight;
    }
	
	
	/**
	 * 	Check if this texture has same gpu texture as the passed texture
	 *
	 * 	@param p_texture
	 */
    public function hasSameGPUTexture(p_texture:GTexture):Bool {
        return p_texture.nativeTexture == nativeTexture;
    }

	/**
	 * 	Check if this texture uses rectangle texture
	 */
    inline public function usesRectangle():Bool {
        return !g2d_repeatable && Genome2D.getInstance().getContext().hasFeature(GContextFeature.RECTANGLE_TEXTURES);
    }

    public function needClearAsRenderTarget(p_clear:Bool):Bool {
        if (!g2d_initializedRenderTarget || p_clear) {
            g2d_initializedRenderTarget = true;
            return true;
        }
        return false;
    }

    public function invalidateNativeTexture(p_reinitialize:Bool):Void {
        if (untyped __is__(Genome2D.getInstance().getContext(), GStage3DContext)) {
            var contextStage3D:GStage3DContext = cast Genome2D.getInstance().getContext();

            if (g2d_sourceType != GTextureSourceType.TEXTURE && contextStage3D.getNativeContext().driverInfo != "Disposed") {
                g2d_gpuWidth = g2d_nativeWidth = usesRectangle() ? g2d_nativeWidth : GTextureUtils.getNextValidTextureSize(g2d_nativeWidth);
                g2d_gpuHeight = g2d_nativeHeight = usesRectangle() ? g2d_nativeHeight : GTextureUtils.getNextValidTextureSize(g2d_nativeHeight);

                switch (g2d_sourceType) {
                    case GTextureSourceType.BITMAPDATA:
                        var resampled:BitmapData = cast g2d_source;
                        if (!usesRectangle()) {
                            resampled = GTextureUtils.resampleBitmapData(resampled);
                        }

                        if (g2d_nativeTexture == null || p_reinitialize || g2d_gpuWidth != resampled.width || g2d_gpuHeight != resampled.height) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            if (usesRectangle()) {
                                g2d_nativeTexture = untyped contextStage3D.getNativeContext()["createRectangleTexture"](g2d_gpuWidth, g2d_gpuHeight, untyped g2d_format, false);
                            } else {
                                g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(g2d_gpuWidth, g2d_gpuHeight, untyped g2d_format, false);
                            }
                        }

                        untyped g2d_nativeTexture["uploadFromBitmapData"](resampled);
                    /*
                    case GTextureSourceType.BYTEARRAY:
                        if (g2d_nativeTexture == null || p_reinitialize) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            if (useRectangle) {
                                g2d_nativeTexture = untyped contextStage3D.getNativeContext()["createRectangleTexture"](wi, hi, untyped g2d_format, false);
                            } else {
                                g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(wi, hi, untyped g2d_format, false);
                            }
                        }
                        untyped g2d_nativeTexture["uploadFromByteArray"](g2d_sourceByteArray, 0);
                    /**/
                    case GTextureSourceType.ATF_BGRA:
                        if (g2d_nativeTexture == null || p_reinitialize) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(g2d_gpuWidth, g2d_gpuHeight, Context3DTextureFormat.BGRA, false);
                        }
                        untyped g2d_nativeTexture["uploadCompressedTextureFromByteArray"](cast g2d_source, 0);
                    case GTextureSourceType.ATF_COMPRESSED:
                        if (g2d_nativeTexture == null || p_reinitialize) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(g2d_gpuWidth, g2d_gpuHeight, Context3DTextureFormat.COMPRESSED, false);
                        }
                        untyped g2d_nativeTexture["uploadCompressedTextureFromByteArray"](cast g2d_source, 0);
                    case GTextureSourceType.ATF_COMPRESSEDALPHA:
                        if (g2d_nativeTexture == null || p_reinitialize) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(g2d_gpuWidth, g2d_gpuHeight, Context3DTextureFormat.COMPRESSED_ALPHA, false);
                        }
                        untyped g2d_nativeTexture["uploadCompressedTextureFromByteArray"](cast g2d_source, 0);
                    case GTextureSourceType.RENDER_TARGET:
                        if (g2d_nativeTexture == null || p_reinitialize) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            if (usesRectangle()) {
                                g2d_nativeTexture = untyped contextStage3D.getNativeContext()["createRectangleTexture"](g2d_gpuWidth, g2d_gpuHeight, Context3DTextureFormat.BGRA, true);
                            } else {
                                g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(g2d_gpuWidth, g2d_gpuHeight, Context3DTextureFormat.BGRA, true);
                            }
                        }
                    case GTextureSourceType.TEXTURE:
                        g2d_nativeTexture = g2d_source;
                    default:
                }
				
				invalidateUV();
				
				if (g2d_onInvalidated != null) g2d_onInvalidated.dispatch(this);
            }
        }

        g2d_dirty = false;
    }

    private function g2d_uploadFromBitmapData(p_bitmapData:BitmapData):Void {
        var contextStage3D:GStage3DContext = cast Genome2D.getInstance().getContext();
        if (g2d_nativeTexture == null || contextStage3D.getNativeContext().driverInfo == "Disposed") return;

        untyped g2d_nativeTexture["uploadFromBitmapData"](p_bitmapData);
    }

    private function g2d_uploadFromCompressedByteArray(p_data:ByteArray, p_byteArrayOffset:UInt, p_asyncBoolean:Bool = false):Void {
        var contextStage3D:GStage3DContext = cast Genome2D.getInstance().getContext();
        if (g2d_nativeTexture == null || contextStage3D.getNativeContext().driverInfo == "Disposed") return;
        untyped g2d_nativeTexture["uploadCompressedTextureFromByteArray"](p_data, p_byteArrayOffset, p_asyncBoolean);
    }

    private function g2d_uploadFromByteArray(p_data:ByteArray, p_byteArrayOffset:UInt):Void {
        var contextStage3D:GStage3DContext = cast Genome2D.getInstance().getContext();
        if (g2d_nativeTexture == null || contextStage3D.getNativeContext().driverInfo == "Disposed") return;

        untyped g2d_nativeTexture["uploadFromByteArray"](p_data, p_byteArrayOffset);
    }

    public function dispose():Void {
        if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();

        g2d_source = null;
        g2d_nativeTexture = null;
        GTextureManager.g2d_removeTexture(this);
    }

    public function getAlphaAtUV(p_u:Float, p_v:Float):Float {
		var bitmapData:BitmapData = cast g2d_source;
        if (bitmapData == null)  return 255;

        return bitmapData.getPixel32(untyped __int__((g2d_u + p_u) * g2d_nativeWidth), untyped __int__((g2d_v + p_v) * g2d_nativeHeight)) >> 24 & 0xFF;
    }
	
	private function parentInvalidated_handler(texture:GTexture):Void {
		g2d_gpuWidth = g2d_parent.g2d_gpuWidth;
		g2d_gpuHeight = g2d_parent.g2d_gpuHeight;
		g2d_nativeTexture = g2d_parent.g2d_nativeTexture;
		
		if (g2d_onInvalidated != null) g2d_onInvalidated.dispatch(this);
	}
	
    public function toString():String {
        return "[Texture: "+id+"]";
    }
	
	/*
	 *	Get a reference value
	 */
	public function toReference():String {
		return GTextureManager.getIdForTexture(this);
	}
	
	/*
	 * 	Get an instance from reference
	 */
	static public function fromReference(p_reference:String) {
		return GTextureManager.getTextureById(p_reference);
	}
}