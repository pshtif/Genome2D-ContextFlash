/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.textures;

import com.genome2d.textures.GTextureManager;
import com.genome2d.context.GContextFeature;
import flash.display3D.textures.TextureBase;
import com.genome2d.context.GContextConfig;
import com.genome2d.context.stage3d.GStage3DContext;
import com.genome2d.error.GError;
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
    private var g2d_dirty:Bool;
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

    private var g2d_type:Int;
    #if swc @:extern #end
    public var type(get,never):Int;
    #if swc @:getter(type) #end
    inline private function get_type():Int {
        return g2d_type;
    }

    #if swc @:extern #end
    public var width(get, never):Float;
    #if swc @:getter(width) #end
    inline private function get_width():Float {
        return g2d_region.width/scaleFactor;
    }

    #if swc @:extern #end
    public var height(get, never):Float;
    #if swc @:getter(height) #end
    inline private function get_height():Float {
        return g2d_region.height/scaleFactor;
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

    private var g2d_pivotX:Float;
    #if swc @:extern #end
    public var pivotX(get, set):Float;
    #if swc @:getter(pivotX) #end
    inline private function get_pivotX():Float {
        return g2d_pivotX/scaleFactor;
    }
    #if swc @:setter(pivotX) #end
    inline private function set_pivotX(p_value:Float):Float {
        return g2d_pivotX = p_value*scaleFactor;
    }

    private var g2d_pivotY:Float;
    #if swc @:extern #end
    public var pivotY(get, set):Float;
    #if swc @:getter(pivotY) #end
    inline private function get_pivotY():Float {
        return g2d_pivotY/scaleFactor;
    }
    #if swc @:setter(pivotY) #end
    inline private function set_pivotY(p_value:Float):Float {
        return g2d_pivotY = p_value*scaleFactor;
    }

    private var g2d_scaleFactor:Float;
    #if swc @:extern #end
    public var scaleFactor(get, never):Float;
    #if swc @:getter(scaleFactor) #end
    inline private function get_scaleFactor():Float {
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

    private var g2d_nativeSourceType:Int;
    #if swc @:extern #end
    public var nativeSourceType(get,never):Int;
    #if swc @:getter(nativeSourceType) #end
    public function get_nativeSourceType():Int {
        return g2d_nativeSourceType;
    }

    private var g2d_nativeSource:Object;
    /**
        Get the native source of this texture
    **/
    #if swc @:extern #end
    public var nativeSource(get,set):Object;
    #if swc @:getter(nativeSource) #end
    public function get_nativeSource():Object {
        return g2d_nativeSource;
    }
    public function set_nativeSource(p_value:Object):Void {
        if (g2d_type == GTextureType.SUBTEXTURE) new GError("Can't set source for subtextures!");
        if (g2d_nativeSource == p_value) return;
        g2d_nativeSource = p_value;
        switch (Type.typeof(g2d_nativeSource)) {
            case TClass(c):
                switch (c) {
                    case BitmapData:
                        g2d_nativeSourceType = GTextureSourceType.BITMAPDATA;
                        trace("BitmapData");
                    case ByteArray:
                        var atf:String = String.fromCharCode(g2d_nativeSource[0]) + String.fromCharCode(g2d_nativeSource[1]) + String.fromCharCode(g2d_nativeSource[2]);
                        if (atf == "ATF") {
                            g2d_nativeSourceType = GTextureSourceType.ATF_BGRA;
                            var offset:Int = g2d_nativeSource[6] == 255 ? 12 : 6;
                            switch (g2d_nativeSource[offset]) {
                                case 0,1:
                                    g2d_nativeSourceType = GTextureSourceType.ATF_BGRA;
                                case 2,3:
                                    g2d_nativeSourceType = GTextureSourceType.ATF_COMPRESSED;
                                case 4,5:
                                    g2d_nativeSourceType = GTextureSourceType.ATF_COMPRESSEDALPHA;
                            }
                        } else {
                            g2d_nativeSourceType = GTextureSourceType.BYTEARRAY;
                        }
                        trace("ByteArray");
                    case Texture:
                        g2d_nativeSourceType = GTextureSourceType.TEXTURE;
                    case _:
                        new GError("Invalid texture source.");
                }
            case _:
                g2d_nativeSourceType = GTextureSourceType.RENDER_TARGET;
        }
        g2d_dirty = true;
    }

    private var g2d_region:GRectangle;
    #if swc @:extern #end
    public var region(get,set):GRectangle;
    #if swc @:getter(nativeSource) #end
    public function get_region():GRectangle {
        return g2d_region;
    }
    #if swc @:setter(region) #end
    public function set_region():Object {

    }

    private var g2d_frame:GRectangle;
    private var g2d_format:String;

    private var g2d_uvX:Float;
    private var g2d_uvY:Float;
    private var g2d_uvScaleX:Float;
    private var g2d_uvScaleY:Float;

    private var g2d_repeatable:Bool;
    #if swc @:extern #end
    public var repeatable(get,set):Bool;
    #if swc @:getter(repeatable) #end
    inline private function get_repeatable():Bool {
        return g2d_repeatable;
    }
    #if swc @:setter(filteringType) #end
    inline private function set_repeatable(p_value:Bool):Bool {
        g2d_repeatable = p_value;
        // TODO invalidate gpu
        return p_value;
    }

    private var g2d_nativeTexture:TextureBase;
    #if swc @:extern #end
    public var nativeTexture(get,never):TextureBase;
    #if swc @:getter(nativeTexture) #end
    inline private function get_nativeTexture():TextureBase {
        return g2d_nativeTexture;
    }

    public var premultiplied:Bool;

    private var g2d_atfType:String = "";
    #if swc @:extern #end
    public var atfType(get,never):String;
    #if swc @:getter(atfType) #end
    inline private function get_atfType():String {
        return g2d_atfType;
    }

    private var g2d_initializedRenderTarget:Bool;

    public var g2d_bitmapData:BitmapData;
    private var g2d_byteArray:ByteArray;
    private var g2d_contextId:Int;

	static private var g2d_instanceCount:Int = 0;

	//public function new(p_id:String, p_source:Object, p_format:String, p_repeatable:Bool, p_pivotX:Float, p_pivotY:Float, p_scaleFactor:Float) {
    public function new(p_id:String, p_source:Object) {
        g2d_uvX = g2d_uvY = 0;
        g2d_uvScaleX = g2d_uvScaleY = 1;
        g2d_initializedRenderTarget = false;
        premultiplied = true;
        g2d_dirty = true;
        g2d_pivotX = g2d_pivotY = 0;
        g2d_gpuWidth = g2d_gpuHeight = 0;
        g2d_scaleFactor = 1//p_scaleFactor;

		g2d_instanceCount++;
		g2d_contextId = g2d_instanceCount;
        g2d_format = "bgra"//p_format;
        g2d_repeatable = false;//p_repeatable;

        g2d_id = p_id;
        g2d_nativeSourceType = p_sourceType;
        g2d_nativeSource = p_source;
        g2d_filteringType = GTextureManager.defaultFilteringType;

        if (p_source != null) nativeSource = p_source;

        g2d_init();
	}

    private function g2d_init():Void {
        GTextureManager.g2d_addTexture(this);

        var useRectangle:Bool = !g2d_repeatable && Genome2D.getInstance().getContext().hasFeature(GContextFeature.RECTANGLE_TEXTURES);
        g2d_gpuWidth = useRectangle ? untyped __int__(g2d_region.width) : GTextureUtils.getNextValidTextureSize(untyped __int__(g2d_region.width));
        g2d_gpuHeight = useRectangle ? untyped __int__(g2d_region.height) : GTextureUtils.getNextValidTextureSize(untyped __int__(g2d_region.height));

        switch (g2d_nativeSourceType) {
            case GTextureSourceType.BITMAPDATA:
                g2d_bitmapData = g2d_nativeSource;
                premultiplied = true;
            case GTextureSourceType.ATF_BGRA:
                g2d_byteArray = g2d_nativeSource;
                premultiplied = false;
            case GTextureSourceType.ATF_COMPRESSED:
                g2d_byteArray = g2d_nativeSource;
                g2d_atfType = "dxt1";
                premultiplied = false;
            case GTextureSourceType.ATF_COMPRESSEDALPHA:
                g2d_byteArray = g2d_nativeSource;
                g2d_atfType = "dxt5";
                premultiplied = false;
            case GTextureSourceType.BYTEARRAY:
                g2d_byteArray = g2d_nativeSource;
                premultiplied = false;
        }

        if (g2d_nativeSourceType == GTextureSourceType.ATF_COMPRESSEDALPHA || g2d_format == "compressedAlpha") {
            g2d_atfType = "dxt5";
        } else if (g2d_nativeSourceType == GTextureSourceType.ATF_COMPRESSED || g2d_format == "compressed") {
            g2d_atfType = "dxt1";
        }
    }

    public function needClearAsRenderTarget(p_clear:Bool):Bool {
        if (!g2d_initializedRenderTarget || p_clear) {
            g2d_initializedRenderTarget = true;
            return true;
        }
        return false;
    }

    public function invalidateNativeTexture(p_reinitialize:Bool):Void {
        var wi:Int = untyped __int__(g2d_region.width);
        var hi:Int = untyped __int__(g2d_region.height);

        if (untyped __is__(Genome2D.getInstance().getContext(), GStage3DContext)) {
            var contextStage3D:GStage3DContext = cast Genome2D.getInstance().getContext();
            if (g2d_type != GTextureType.SUBTEXTURE && contextStage3D.getNativeContext().driverInfo != "Disposed") {
                var useRectangle:Bool = !g2d_repeatable && contextStage3D.hasFeature(GContextFeature.RECTANGLE_TEXTURES);

                switch (g2d_nativeSourceType) {
                    case GTextureSourceType.BITMAPDATA:
                        var resampled:BitmapData = g2d_bitmapData;
                        if (!useRectangle) {
                            resampled = GTextureUtils.resampleBitmapData(g2d_bitmapData);
                        }

                        if (g2d_nativeTexture == null || p_reinitialize || wi != resampled.width || hi != resampled.height) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            if (useRectangle) {
                                g2d_nativeTexture = untyped contextStage3D.getNativeContext()["createRectangleTexture"](resampled.width, resampled.height, untyped g2d_format, false);
                            } else {
                                g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(resampled.width, resampled.height, untyped g2d_format, false);
                            }
                        }

                        untyped g2d_nativeTexture["uploadFromBitmapData"](resampled);
                    case GTextureSourceType.BYTEARRAY:
                        if (g2d_nativeTexture == null || p_reinitialize) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            if (useRectangle) {
                                g2d_nativeTexture = untyped contextStage3D.getNativeContext()["createRectangleTexture"](wi, hi, untyped g2d_format, false);
                            } else {
                                g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(wi, hi, untyped g2d_format, false);
                            }
                        }
                        untyped g2d_nativeTexture["uploadFromByteArray"](g2d_byteArray, 0);
                    case GTextureSourceType.ATF_BGRA:
                        if (g2d_nativeTexture == null || p_reinitialize) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(wi, hi, Context3DTextureFormat.BGRA, false);
                        }
                        untyped g2d_nativeTexture["uploadCompressedTextureFromByteArray"](g2d_byteArray, 0);
                    case GTextureSourceType.ATF_COMPRESSED:
                        if (g2d_nativeTexture == null || p_reinitialize) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(wi, hi, Context3DTextureFormat.COMPRESSED, false);
                        }
                        untyped g2d_nativeTexture["uploadCompressedTextureFromByteArray"](g2d_byteArray, 0);
                    case GTextureSourceType.ATF_COMPRESSEDALPHA:
                        if (g2d_nativeTexture == null || p_reinitialize) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(wi, hi, Context3DTextureFormat.COMPRESSED_ALPHA, false);
                        }
                        untyped g2d_nativeTexture["uploadCompressedTextureFromByteArray"](g2d_byteArray, 0);
                    case GTextureSourceType.RENDER_TARGET:
                        var validWidth:Int = GTextureUtils.getNextValidTextureSize(wi);
                        var validHeight:Int = GTextureUtils.getNextValidTextureSize(hi);
                        if (g2d_nativeTexture == null || p_reinitialize) {
                            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
                            g2d_nativeTexture = contextStage3D.getNativeContext().createTexture(validWidth, validHeight, Context3DTextureFormat.BGRA, true);
                        }
                    case GTextureSourceType.TEXTURE:
                        g2d_nativeTexture = g2d_nativeSource;
                    default:
                }
            }
        } else {
            if (g2d_type == GTextureType.SUBTEXTURE) {
                //g2d_bitmapData = new BitmapData(wi, hi, true, 0x000000);
                //g2d_bitmapData.copyPixels(g2d_parentAtlas.g2d_bitmapData, g2d_region, new Point());//, g2d_parentAtlas.g2d_bitmapData, new Point(), true);
            }
        }
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
        if (g2d_type != GTextureType.SUBTEXTURE) {
            if (g2d_nativeTexture != null) g2d_nativeTexture.dispose();
            g2d_bitmapData = null;
            g2d_byteArray = null;
            g2d_nativeSource = null;
            g2d_nativeTexture = null;
        }
        GTextureManager.g2d_removeTexture(this);
    }

    public function getAlphaAtUV(p_u:Float, p_v:Float):Float {
        if (g2d_bitmapData == null)  return 255;

        return g2d_bitmapData.getPixel32(untyped __int__(g2d_region.x + p_u*g2d_region.width), untyped __int__(g2d_region.y + p_v*g2d_region.height))>>24&0xFF;
    }
}