/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.textures;

import flash.display.Bitmap;
import com.genome2d.textures.GTextureManager;
import com.genome2d.context.GContextFeature;
import flash.display3D.textures.TextureBase;
import com.genome2d.context.GContextConfig;
import com.genome2d.context.stage3d.GStage3DContext;
import com.genome2d.debug.GDebug;
import com.genome2d.geom.GRectangle;
import flash.utils.Object;
import com.genome2d.context.IContext;
import flash.utils.Dictionary;
import flash.display3D.Context3DTextureFormat;
import flash.geom.Point;
import com.genome2d.context.stage3d.GStage3DContext;
import com.genome2d.textures.GTextureSourceType;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.utils.ByteArray;

@:access(com.genome2d.textures.GTextureManager)
class GContextTexture
{
    private var g2d_dirty:Bool = true;
    inline public function isDirty():Bool {
        return g2d_dirty;
    }

    private var g2d_id:String;
    #if swc @:extern #end
    public var id(get,never):String;
    #if swc @:getter(id) #end
    inline private function get_id():String {
        return g2d_id;
    }
    #if swc @:setter(id) #end
    inline private function set_id(p_value:String):String {
        GTextureManager.g2d_removeTexture(this);
        g2d_id = p_value;
        GTextureManager.g2d_addTexture(this);
        return g2d_id;
    }

    #if swc @:extern #end
    public var width(get, never):Float;
    #if swc @:getter(width) #end
    inline private function get_width():Float {
        return g2d_width*scaleFactor;
    }

    #if swc @:extern #end
    public var height(get, never):Float;
    #if swc @:getter(height) #end
    inline private function get_height():Float {
        return g2d_height*scaleFactor;
    }

    private var g2d_gpuWidth:Int;
    #if swc @:extern #end
    public var gpuWidth(get, never):Int;
    #if swc @:getter(gpuWidth) #end
    inline private function get_gpuWidth():Int {
        return g2d_gpuWidth;
    }

    private var g2d_gpuHeight:Int;
    #if swc @:extern #end
    public var gpuHeight(get, never):Int;
    #if swc @:getter(gpuHeight) #end
    inline private function get_gpuHeight():Int {
        return g2d_gpuHeight;
    }

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
    #if swc @:extern #end
    public var sourceType(get,never):Int;
    #if swc @:getter(sourceType) #end
    public function get_sourceType():Int {
        return g2d_sourceType;
    }

    private var g2d_source:Object;
    /**
        Get the native source of this texture
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
            g2d_sourceAtlas = null;
            g2d_sourceByteArray = null;
            g2d_sourceBitmapData = null;
            if (Std.is(p_value,BitmapData)) {
                g2d_source = p_value;
                g2d_sourceType = GTextureSourceType.BITMAPDATA;
                g2d_sourceBitmapData = cast g2d_source;
                g2d_width = g2d_sourceBitmapData.width;
                g2d_height = g2d_sourceBitmapData.height;
                premultiplied = true;
            } else if (Std.is(p_value,ByteArray)) {
                g2d_source = p_value;
                g2d_sourceByteArray = g2d_source;
                var atf:String = String.fromCharCode(g2d_sourceByteArray[0]) + String.fromCharCode(g2d_sourceByteArray[1]) + String.fromCharCode(g2d_sourceByteArray[2]);
                if (atf == "ATF") {
                    g2d_sourceType = GTextureSourceType.ATF_BGRA;
                    var offset:Int = g2d_sourceByteArray[6] == 255 ? 12 : 6;

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
                    g2d_width = untyped __int__(Math.pow(2,g2d_sourceByteArray[offset+1]));
                    g2d_height = untyped __int__(Math.pow(2,g2d_sourceByteArray[offset+2]));
                    premultiplied = false;
                } else {
                    //g2d_sourceType = GTextureSourceType.BYTEARRAY;
                }
            } else if (Std.is(p_value,GRectangle)) {
                g2d_source = p_value;
                g2d_sourceType = GTextureSourceType.RENDER_TARGET;
                g2d_width = p_value.width;
                g2d_height = p_value.height;
            } else if (Std.is(p_value,GTextureAtlas)) {
                g2d_source = p_value;
                g2d_sourceAtlas = g2d_source;
                g2d_sourceType = GTextureSourceType.ATLAS;
                g2d_nativeTexture = g2d_sourceAtlas.nativeTexture;
            } else {
                GDebug.error("Invalid texture source.");
            }
            g2d_dirty = true;
        }
        return g2d_source;
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
    private var g2d_v:Float;
    private var g2d_uScale:Float;
    private var g2d_vScale:Float;

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

    private var g2d_atfType:String = "";

    public var premultiplied:Bool;
    private var g2d_initializedRenderTarget:Bool;

    private var g2d_sourceBitmapData:BitmapData;
    private var g2d_sourceByteArray:ByteArray;
    private var g2d_sourceAtlas:GTextureAtlas;

    private var g2d_contextId:Int;
    private var g2d_width:Int;
    private var g2d_height:Int;

	static private var g2d_instanceCount:Int = 0;

    public function new(p_id:String, p_source:Object) {
        g2d_width = g2d_height = 0;
        g2d_u = g2d_v = 0;
        g2d_uScale = g2d_vScale = 1;
        g2d_initializedRenderTarget = false;
        premultiplied = true;
        g2d_dirty = true;
        g2d_gpuWidth = g2d_gpuHeight = 0;
        g2d_scaleFactor = 1;

		g2d_instanceCount++;
		g2d_contextId = g2d_instanceCount;
        g2d_format = "bgra";
        g2d_repeatable = false;

        g2d_id = p_id;
        g2d_filteringType = GTextureManager.defaultFilteringType;
        source = p_source;
	}

    public function hasSameGPUTexture(p_texture:GContextTexture):Bool {
        return p_texture.nativeTexture == nativeTexture;
    }

    inline public function usesRectangle():Bool {
        return !g2d_repeatable && Genome2D.getInstance().getContext().hasFeature(GContextFeature.RECTANGLE_TEXTURES);
    }

    private function g2d_init():Void {
        GTextureManager.g2d_addTexture(this);

        g2d_gpuWidth = usesRectangle() ? untyped __int__(g2d_width) : GTextureUtils.getNextValidTextureSize(untyped __int__(g2d_width));
        g2d_gpuHeight = usesRectangle() ? untyped __int__(g2d_height) : GTextureUtils.getNextValidTextureSize(untyped __int__(g2d_height));

        // TODO support runtime compression
        /**
        if (g2d_sourceType == GTextureSourceType.ATF_COMPRESSEDALPHA || g2d_format == "compressedAlpha") {
            g2d_atfType = "dxt5";
        } else if (g2d_sourceType == GTextureSourceType.ATF_COMPRESSED || g2d_format == "compressed") {
            g2d_atfType = "dxt1";
        }
        /**/
    }

    public function needClearAsRenderTarget(p_clear:Bool):Bool {
        if (!g2d_initializedRenderTarget || p_clear) {
            g2d_initializedRenderTarget = true;
            return true;
        }
        return false;
    }

    public function invalidateNativeTexture(p_reinitialize:Bool):Void {
        var wi:Int = untyped __int__(g2d_width);
        var hi:Int = untyped __int__(g2d_height);

        if (untyped __is__(Genome2D.getInstance().getContext(), GStage3DContext)) {
            var contextStage3D:GStage3DContext = cast Genome2D.getInstance().getContext();

            if (g2d_sourceType != GTextureSourceType.ATLAS && contextStage3D.getNativeContext().driverInfo != "Disposed") {
                g2d_gpuWidth = usesRectangle() ? wi : GTextureUtils.getNextValidTextureSize(wi);
                g2d_gpuHeight = usesRectangle() ? hi : GTextureUtils.getNextValidTextureSize(hi);

                switch (g2d_sourceType) {
                    case GTextureSourceType.BITMAPDATA:
                        var resampled:BitmapData = g2d_sourceBitmapData;
                        if (!usesRectangle()) {
                            resampled = GTextureUtils.resampleBitmapData(g2d_sourceBitmapData);
                        }

                        if (g2d_nativeTexture == null || p_reinitialize || wi != resampled.width || hi != resampled.height) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            if (usesRectangle()) {
                                g2d_nativeTexture = untyped contextStage3D.getNativeContext()["createRectangleTexture"](resampled.width, resampled.height, untyped g2d_format, false);
                            } else {
                                g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(resampled.width, resampled.height, untyped g2d_format, false);
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
                            g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(wi, hi, Context3DTextureFormat.BGRA, false);
                        }
                        untyped g2d_nativeTexture["uploadCompressedTextureFromByteArray"](g2d_sourceByteArray, 0);
                    case GTextureSourceType.ATF_COMPRESSED:
                        if (g2d_nativeTexture == null || p_reinitialize) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(wi, hi, Context3DTextureFormat.COMPRESSED, false);
                        }
                        untyped g2d_nativeTexture["uploadCompressedTextureFromByteArray"](g2d_sourceByteArray, 0);
                    case GTextureSourceType.ATF_COMPRESSEDALPHA:
                        if (g2d_nativeTexture == null || p_reinitialize) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(wi, hi, Context3DTextureFormat.COMPRESSED_ALPHA, false);
                        }
                        untyped g2d_nativeTexture["uploadCompressedTextureFromByteArray"](g2d_sourceByteArray, 0);
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
            } else {
                g2d_nativeTexture = g2d_sourceAtlas.nativeTexture;
                g2d_gpuWidth = g2d_sourceAtlas.gpuWidth;
                g2d_gpuHeight = g2d_sourceAtlas.gpuHeight;
            }
        } else {
            if (g2d_sourceType == GTextureSourceType.ATLAS) {
                //g2d_bitmapData = new BitmapData(wi, hi, true, 0x000000);
                //g2d_bitmapData.copyPixels(g2d_parentAtlas.g2d_bitmapData, g2d_region, new Point());//, g2d_parentAtlas.g2d_bitmapData, new Point(), true);
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
        if (g2d_sourceType != GTextureSourceType.ATLAS && g2d_nativeTexture != null) g2d_nativeTexture.dispose();

        g2d_sourceBitmapData = null;
        g2d_sourceByteArray = null;
        g2d_sourceAtlas = null;
        g2d_source = null;
        g2d_nativeTexture = null;
        GTextureManager.g2d_removeTexture(this);
    }

    public function getAlphaAtUV(p_u:Float, p_v:Float):Float {
        if (g2d_sourceBitmapData == null)  return 255;

        return g2d_sourceBitmapData.getPixel32(untyped __int__((g2d_u + p_u)*g2d_width), untyped __int__((g2d_v + p_v)*g2d_height))>>24&0xFF;
    }
}