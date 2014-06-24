/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.textures;

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

class GContextTexture
{
    static public var g2d_references:Dictionary;
    static public function getContextTextureById(p_id:String):GContextTexture {
        return untyped g2d_references[p_id];
    }

    static public function disposeAll():Void {
        if (g2d_references != null) {
            var textureIds:Array<String> = untyped __keys__(g2d_references);
            for (i in 0...textureIds.length) {
                untyped if (g2d_references[textureIds[i]]!=null && g2d_references[textureIds[i]].g2d_type != GTextureType.SUBTEXTURE) g2d_references[textureIds[i]].dispose();
            }
        }
    }

    static public function invalidateAll(p_force:Bool):Void {
        if (g2d_references != null) {
            var textureIds:Array<String> = untyped __keys__(g2d_references);
            for (i in 0...textureIds.length) {
               untyped g2d_references[textureIds[i]].invalidateNativeTexture(p_force);
            }
        }
    }

    private var g2d_context:IContext;
    private var g2d_nativeSource:Object;
    public function getNativeSource():Object {
        return g2d_nativeSource;
    }

    public var g2d_sourceType:Int;
    private var g2d_type:Int;
    inline public function getType():Int {
        return g2d_type;
    }

	public var g2d_contextId:Int;
    private var g2d_id:String;
    inline public function getId():String {
        return g2d_id;
    }

    #if swc @:extern #end
    public var width(get, never):Int;
    #if swc @:getter(width) #end
    inline private function get_width():Int {
        return untyped __int__(g2d_region.width);
    }

    #if swc @:extern #end
    public var height(get, never):Int;
    #if swc @:getter(height) #end
    inline private function get_height():Int {
        return untyped __int__(g2d_region.height);
    }

    private var g2d_gpuWidth:Int = 0;
    #if swc @:extern #end
    public var gpuWidth(get, never):Int;
    #if swc @:getter(gpuWidth) #end
    inline private function get_gpuWidth():Int {
        return g2d_gpuWidth;
    }

    private var g2d_gpuHeight:Int = 0;
    #if swc @:extern #end
    public var gpuHeight(get, never):Int;
    #if swc @:getter(gpuHeight) #end
    inline private function get_gpuHeight():Int {
        return g2d_gpuHeight;
    }

    public var g2d_region:GRectangle;
    private var g2d_parentAtlas:GContextTexture;
    private var g2d_format:String;

    public var uvX:Float = 0;
    public var uvY:Float = 0;
    public var uvScaleX:Float = 1;
    public var uvScaleY:Float = 1;

    public var g2d_repeatable:Bool;

    public var pivotX:Float = 0;
    public var pivotY:Float = 0;

    public var nativeTexture:TextureBase;

    public var g2d_bitmapData:BitmapData;
    public var g2d_byteArray:ByteArray;

    public var atfType:String = "";
    public var premultiplied:Bool = true;

    static public var defaultFilteringType:Int = 1;

    public var g2d_filteringType:Int;
    inline public function getFilteringType():Int {
        return g2d_filteringType;
    }
    inline public function setFilteringType(p_value:Int):Int {
        // TODO check for valid filtering type
        return g2d_filteringType = p_value;
    }

	static private var g2d_instanceCount:Int = 0;
	public function new(p_context:IContext, p_id:String, p_sourceType:Int, p_source:Object, p_region:GRectangle, p_format:String, p_repeatable:Bool = false, p_pivotX:Float = 0, p_pivotY:Float = 0) {
        if (g2d_references == null) g2d_references = new Dictionary(false);
        if (p_id == null || p_id.length == 0) new GError("Invalid textures id");
        //if (p_region.width == 0 || p_region.height == 0) new GError("Textures can't have 0 size regions.");
        if (untyped g2d_references[p_id] != null) new GError("Duplicate textures id");

		g2d_instanceCount++;
		g2d_contextId = g2d_instanceCount;
        g2d_region = p_region;
        g2d_format = p_format;
        g2d_repeatable = p_repeatable;

        untyped g2d_references[p_id] = this;

        g2d_context = p_context;
        g2d_id = p_id;
        g2d_sourceType = p_sourceType;
        g2d_nativeSource = p_source;
        g2d_filteringType = defaultFilteringType;

        var useRectangle:Bool = !g2d_repeatable && p_context.hasFeature(GContextFeature.RECTANGLE_TEXTURES);
        g2d_gpuWidth = useRectangle ? width : GTextureUtils.getNextValidTextureSize(width);
        g2d_gpuHeight = useRectangle ? height : GTextureUtils.getNextValidTextureSize(height);

        switch (g2d_sourceType) {
            case GTextureSourceType.BITMAPDATA:
                g2d_bitmapData = p_source;
                premultiplied = true;
            case GTextureSourceType.ATF_BGRA:
                g2d_byteArray = p_source;
                premultiplied = false;
            case GTextureSourceType.ATF_COMPRESSED:
                g2d_byteArray = p_source;
                atfType = "dxt1";
                premultiplied = false;
            case GTextureSourceType.ATF_COMPRESSEDALPHA:
                g2d_byteArray = p_source;
                atfType = "dxt5";
                premultiplied = false;
            case GTextureSourceType.BYTEARRAY:
                g2d_byteArray = p_source;
                premultiplied = false;
        }

        if (g2d_sourceType == GTextureSourceType.ATF_COMPRESSEDALPHA || p_format == "compressedAlpha") {
            atfType = "dxt5";
        } else if (g2d_sourceType == GTextureSourceType.ATF_COMPRESSED || p_format == "compressed") {
            atfType = "dxt1";
        }
	}

    public function invalidateNativeTexture(p_reinitialize:Bool):Void {
        if (untyped __is__(g2d_context, GStage3DContext)) {
            var contextStage3D:GStage3DContext = cast g2d_context;
            if (g2d_type != GTextureType.SUBTEXTURE && contextStage3D.getNativeContext().driverInfo != "Disposed") {
                var useRectangle:Bool = !g2d_repeatable && contextStage3D.hasFeature(GContextFeature.RECTANGLE_TEXTURES);

                switch (g2d_sourceType) {
                    case GTextureSourceType.BITMAPDATA:
                        var resampled:BitmapData = g2d_bitmapData;
                        if (!useRectangle) {
                            resampled = GTextureUtils.resampleBitmapData(g2d_bitmapData);
                        }

                        if (nativeTexture == null || p_reinitialize || width != resampled.width || height != resampled.height) {
                            if (nativeTexture != null) nativeTexture.dispose();
                            if (useRectangle) {
                                nativeTexture = untyped contextStage3D.getNativeContext()["createRectangleTexture"](resampled.width, resampled.height, untyped g2d_format, false);
                            } else {
                                nativeTexture = contextStage3D.getNativeContext().createTexture(resampled.width, resampled.height, untyped g2d_format, false);
                            }
                        }

                        untyped nativeTexture["uploadFromBitmapData"](resampled);
                    case GTextureSourceType.BYTEARRAY:
                        if (nativeTexture == null || p_reinitialize) {
                            if (nativeTexture != null) nativeTexture.dispose();
                            if (useRectangle) {
                                nativeTexture = untyped contextStage3D.getNativeContext()["createRectangleTexture"](width, height, untyped g2d_format, false);
                            } else {
                                nativeTexture = contextStage3D.getNativeContext().createTexture(width, height, untyped g2d_format, false);
                            }
                        }
                        untyped nativeTexture["uploadFromByteArray"](g2d_byteArray, 0);
                    case GTextureSourceType.ATF_BGRA:
                        if (nativeTexture == null || p_reinitialize) {
                            if (nativeTexture != null) nativeTexture.dispose();
                            nativeTexture = contextStage3D.getNativeContext().createTexture(width, height, Context3DTextureFormat.BGRA, false);
                        }
                        untyped nativeTexture["uploadCompressedTextureFromByteArray"](g2d_byteArray, 0);
                    case GTextureSourceType.ATF_COMPRESSED:
                        if (nativeTexture == null || p_reinitialize) {
                            if (nativeTexture != null) nativeTexture.dispose();
                            nativeTexture = contextStage3D.getNativeContext().createTexture(width, height, Context3DTextureFormat.COMPRESSED, false);
                        }
                        untyped nativeTexture["uploadCompressedTextureFromByteArray"](g2d_byteArray, 0);
                    case GTextureSourceType.ATF_COMPRESSEDALPHA:
                        if (nativeTexture == null || p_reinitialize) {
                            if (nativeTexture != null) nativeTexture.dispose();
                            nativeTexture = contextStage3D.getNativeContext().createTexture(width, height, Context3DTextureFormat.COMPRESSED_ALPHA, false);
                        }
                        untyped nativeTexture["uploadCompressedTextureFromByteArray"](g2d_byteArray, 0);
                    case GTextureSourceType.RENDER_TARGET:
                        var validWidth:Int = GTextureUtils.getNextValidTextureSize(width);
                        var validHeight:Int = GTextureUtils.getNextValidTextureSize(height);
                        if (nativeTexture == null || p_reinitialize) {
                            if (nativeTexture != null) nativeTexture.dispose();
                            nativeTexture = contextStage3D.getNativeContext().createTexture(validWidth, validHeight, Context3DTextureFormat.BGRA, true);
                        }
                    case GTextureSourceType.TEXTURE:
                        nativeTexture = g2d_nativeSource;
                    default:
                }
            }
        } else {
            if (g2d_type == GTextureType.SUBTEXTURE) {
                g2d_bitmapData = new BitmapData(width, height, true, 0x000000);
                g2d_bitmapData.copyPixels(g2d_parentAtlas.g2d_bitmapData, g2d_region, new Point());//, g2d_parentAtlas.g2d_bitmapData, new Point(), true);
            }
        }
    }

    private function g2d_uploadFromBitmapData(p_bitmapData:BitmapData):Void {
        var contextStage3D:GStage3DContext = cast g2d_context;
        if (nativeTexture == null || contextStage3D.getNativeContext().driverInfo == "Disposed") return;

        untyped nativeTexture["uploadFromBitmapData"](p_bitmapData);
    }

    private function g2d_uploadFromCompressedByteArray(p_data:ByteArray, p_byteArrayOffset:UInt, p_asyncBoolean:Bool = false):Void {
        var contextStage3D:GStage3DContext = cast g2d_context;
        if (nativeTexture == null || contextStage3D.getNativeContext().driverInfo == "Disposed") return;
        untyped nativeTexture["uploadCompressedTextureFromByteArray"](p_data, p_byteArrayOffset, p_asyncBoolean);
    }

    private function g2d_uploadFromByteArray(p_data:ByteArray, p_byteArrayOffset:UInt):Void {
        var contextStage3D:GStage3DContext = cast g2d_context;
        if (nativeTexture == null || contextStage3D.getNativeContext().driverInfo == "Disposed") return;

        untyped nativeTexture["uploadFromByteArray"](p_data, p_byteArrayOffset);
    }

    public function dispose():Void {
        if (g2d_type != GTextureType.SUBTEXTURE) {
            if (nativeTexture != null) nativeTexture.dispose();
            g2d_bitmapData = null;
            g2d_byteArray = null;
            g2d_nativeSource = null;
            nativeTexture = null;
        }
        untyped __delete__(g2d_references, g2d_id);
    }

    public function getAlphaAtUV(p_u:Float, p_v:Float):Float {
        if (g2d_bitmapData == null)  return 255;

        return g2d_bitmapData.getPixel32(untyped __int__(g2d_region.x + p_u*g2d_region.width), untyped __int__(g2d_region.y + p_v*g2d_region.height))>>24&0xFF;
    }
}