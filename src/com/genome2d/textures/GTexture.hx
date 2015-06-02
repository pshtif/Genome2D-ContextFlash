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
import com.genome2d.proto.IGPrototypable;
import com.genome2d.textures.GTextureManager;
import com.genome2d.textures.GTextureSourceType;
import com.genome2d.textures.GTextureBase;

import flash.display.BitmapData;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;
import flash.utils.ByteArray;
import flash.utils.Object;

@:access(com.genome2d.textures.GTextureManager)
class GTexture extends GTextureBase
{
    private var g2d_atfType:String = "";
    
    override public function setSource(p_value:Object):Object {
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
				//if (atf != "ATF") GDebug.error("Invalid ATF data");
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
				var parent:GTexture = cast g2d_source;
				parent.onInvalidated.add(parentInvalidated_handler);
				parent.onDisposed.add(parentDisposed_handler);
				g2d_gpuWidth = parent.g2d_gpuWidth;
				g2d_gpuHeight = parent.g2d_gpuHeight;
				g2d_nativeWidth = parent.g2d_nativeWidth;
				g2d_nativeHeight = parent.g2d_nativeHeight;
				g2d_nativeTexture = parent.nativeTexture;
				g2d_sourceType = GTextureSourceType.TEXTURE;
			} else {
                GDebug.error("Invalid texture source.");
            }
            g2d_dirty = true;
        }
        return g2d_source;
    }

    public function invalidateNativeTexture(p_reinitialize:Bool):Void {
        if (untyped __is__(g2d_context, GStage3DContext)) {
            var contextStage3D:GStage3DContext = cast g2d_context;

            if (g2d_sourceType != GTextureSourceType.TEXTURE && contextStage3D.getNativeContext().driverInfo != "Disposed") {
                g2d_gpuWidth = usesRectangle() ? g2d_nativeWidth : GTextureUtils.getNextValidTextureSize(g2d_nativeWidth);
                g2d_gpuHeight = usesRectangle() ? g2d_nativeHeight : GTextureUtils.getNextValidTextureSize(g2d_nativeHeight);

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
				
				region = new GRectangle(0,0,g2d_nativeWidth,g2d_nativeHeight);
				invalidateUV();

				if (g2d_onInvalidated != null) g2d_onInvalidated.dispatch(this);
            }
        }
		
        g2d_dirty = false;
    }

    private function g2d_uploadFromBitmapData(p_bitmapData:BitmapData):Void {
        var contextStage3D:GStage3DContext = cast g2d_context;
        if (g2d_nativeTexture == null || contextStage3D.getNativeContext().driverInfo == "Disposed") return;

        untyped g2d_nativeTexture["uploadFromBitmapData"](p_bitmapData);
    }

    private function g2d_uploadFromCompressedByteArray(p_data:ByteArray, p_byteArrayOffset:UInt, p_asyncBoolean:Bool = false):Void {
        var contextStage3D:GStage3DContext = cast g2d_context;
        if (g2d_nativeTexture == null || contextStage3D.getNativeContext().driverInfo == "Disposed") return;
        untyped g2d_nativeTexture["uploadCompressedTextureFromByteArray"](p_data, p_byteArrayOffset, p_asyncBoolean);
    }

    private function g2d_uploadFromByteArray(p_data:ByteArray, p_byteArrayOffset:UInt):Void {
        var contextStage3D:GStage3DContext = cast g2d_context;
        if (g2d_nativeTexture == null || contextStage3D.getNativeContext().driverInfo == "Disposed") return;

        untyped g2d_nativeTexture["uploadFromByteArray"](p_data, p_byteArrayOffset);
    }
	
	override private function parentInvalidated_handler(p_texture:GTexture):Void {
		g2d_nativeTexture = p_texture.g2d_nativeTexture;
		
		super.parentInvalidated_handler(p_texture);
	}

    override public function dispose():Void {
        if (g2d_sourceType != GTextureSourceType.TEXTURE && g2d_nativeTexture != null) g2d_nativeTexture.dispose();
        g2d_nativeTexture = null;
        
		super.dispose();
    }

    override public function getAlphaAtUV(p_u:Float, p_v:Float):Float {
		var bitmapData:BitmapData = cast g2d_source;
        if (bitmapData == null)  return 255;

        return bitmapData.getPixel32(untyped __int__((g2d_u + p_u) * g2d_nativeWidth), untyped __int__((g2d_v + p_v) * g2d_nativeHeight)) >> 24 & 0xFF;
    }
	
	/*
	 * 	Get an instance from reference
	 */
	static public function fromReference(p_reference:String) {
		return GTextureManager.getTexture(p_reference);
	}
	
	/****************************************************************************************************
	 * 	GPU DEPENDANT PROPERTIES
	 ****************************************************************************************************/
	
	private var g2d_nativeTexture:TextureBase;
	/**
	 * 	Native texture reference
	 */
    #if swc @:extern #end
    public var nativeTexture(get,never):TextureBase;
    #if swc @:getter(nativeTexture) #end
    inline private function get_nativeTexture():TextureBase {
        return g2d_nativeTexture;
    }
	
	/**
	 * 	Check if this texture has same gpu texture as the passed texture
	 *
	 * 	@param p_texture
	 */
    public function hasSameGPUTexture(p_texture:GTexture):Bool {
        return p_texture.nativeTexture == nativeTexture;
    }
}