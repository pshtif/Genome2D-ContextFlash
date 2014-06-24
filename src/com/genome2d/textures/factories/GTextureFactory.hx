/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.textures.factories;

import com.genome2d.assets.GImageAssetType;
import com.genome2d.context.IContext;
import com.genome2d.error.GError;
import com.genome2d.geom.GRectangle;
import com.genome2d.assets.GImageAsset;
import com.genome2d.textures.factories.GTextureFactory;
import com.genome2d.textures.GTexture;

import flash.utils.Function;
import flash.utils.ByteArray;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display3D.textures.Texture;

class GTextureFactory {
    static public var g2d_context:IContext;

    static public function createFromEmbedded(p_id:String, p_asset:Class<Bitmap>, p_format:String = "bgra", p_repeatable:Bool = false):GTexture {
        var bitmap:Bitmap = cast Type.createInstance(p_asset, []);

        return new GTexture(g2d_context, p_id, GTextureSourceType.BITMAPDATA, bitmap.bitmapData, bitmap.bitmapData.rect, p_format, p_repeatable, 0, 0, null);
    }

	static public function createFromBitmapData(p_id:String, p_bitmapData:BitmapData, p_format:String = "bgra", p_repeatable:Bool = false):GTexture {
		return new GTexture(g2d_context, p_id, GTextureSourceType.BITMAPDATA, p_bitmapData, p_bitmapData.rect, p_format, p_repeatable, 0, 0, null);
	}

	static public function createFromAsset(p_id:String, p_imageAsset:GImageAsset, p_format:String = "bgra", p_repeatable:Bool = false):GTexture {
        switch (p_imageAsset.type) {
            case GImageAssetType.BITMAPDATA:
		        return createFromBitmapData(p_id, p_imageAsset.nativeImage, p_format, p_repeatable);
            case GImageAssetType.ATF:
                return createFromATF(p_id, p_imageAsset.bytes);
        }

        return null;
	}

	//static public function createFromNativeTexture(p_id:String, p_nativeTexture:Texture, p_width:int, p_height:int):GTexture {
	//    return new GTexture(g2d_context, p_id, GTextureSourceType.TEXTURE, p_nativeTexture, new GRectangle(0, 0, p_width, p_height), 0, 0, null);
	//}

    static public function createFromATF(p_id:String, p_atfData:ByteArray, p_uploadCallback:Function = null):GTexture {
        var atf:String = String.fromCharCode(p_atfData[0]) + String.fromCharCode(p_atfData[1]) + String.fromCharCode(p_atfData[2]);
        if (atf != "ATF") throw new GError("Invalid ATF data");
        var type:Int = GTextureSourceType.ATF_BGRA;
        var offset:Int = p_atfData[6] == 255 ? 12 : 6;
        switch (p_atfData[offset]) {
            case 0,1:
                type = GTextureSourceType.ATF_BGRA;
            case 2,3:
                type = GTextureSourceType.ATF_COMPRESSED;
            case 4,5:
                type = GTextureSourceType.ATF_COMPRESSEDALPHA;
        }

        var width:Float = Math.pow(2, p_atfData[offset+1]);
        var height:Float = Math.pow(2, p_atfData[offset+2]);

        return new GTexture(g2d_context, p_id, type, p_atfData, new GRectangle(0, 0, width, height), "", false, 0, 0, null);
    }

    static public function createRenderTexture(p_id:String, p_width:Int, p_height:Int):GTexture {
        return new GTexture(g2d_context, p_id, GTextureSourceType.RENDER_TARGET, null, new GRectangle(0,0,p_width, p_height), "", false, 0, 0, null);
    }
}
