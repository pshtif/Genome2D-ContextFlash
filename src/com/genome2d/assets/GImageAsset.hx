/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.assets;

import flash.utils.ByteArray;
import com.genome2d.assets.GAssetManager;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.system.ImageDecodingPolicy;
import flash.system.LoaderContext;
import flash.display.Loader;
import flash.events.Event;

class GImageAsset extends GBinaryAsset {
    private var g2d_bytes:ByteArray;
    #if swc @:extern #end
    public var bytes(get,never):ByteArray;
    #if swc @:getter(bytes) #end
    inline private function get_bytes():ByteArray {
        return g2d_bytes;
    }

    private var g2d_bitmapData:BitmapData;
    #if swc @:extern #end
    public var bitmapData(get,never):BitmapData;
    #if swc @:getter(bitmapData) #end
    inline private function get_bitmapData():BitmapData {
        return g2d_bitmapData;
    }

    private var g2d_type:GImageAssetType;
    #if swc @:extern #end
    public var type(get,never):GImageAssetType;
    #if swc @:getter(type) #end
    inline private function get_type():GImageAssetType {
        return g2d_type;
    }

    public function initBitmapData(p_id:String, p_image:BitmapData):Void {
        g2d_id = p_id;
        g2d_bitmapData = p_image;
        g2d_loaded = true;
        g2d_type = GImageAssetType.BITMAPDATA;
    }

    override private function g2d_complete_handler(event:Event):Void {
        g2d_bytes = event.target.data;
        GAssetManager.PATH_REGEX.match(g2d_url);

        switch (GAssetManager.PATH_REGEX.matched(2)) {
            case "jpg" | "jpeg" | "png":
                var loaderContext:LoaderContext = new LoaderContext();
                var loader:Loader = new Loader();
                loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, g2d_bytesComplete);
                loader.loadBytes(g2d_bytes, loaderContext);
            case _:
                g2d_loading = false;
                g2d_loaded = true;
                if (String.fromCharCode(g2d_bytes[0])+String.fromCharCode(g2d_bytes[1])+String.fromCharCode(g2d_bytes[2]) == "ATF") {
                    g2d_type = GImageAssetType.ATF;
                    onLoaded.dispatch(this);
                } else {
                    onFailed.dispatch(this);
                }
        }
    }

    private function g2d_bytesComplete(event:Event):Void {
        g2d_loading = false;
        g2d_loaded = true;
        g2d_type = GImageAssetType.BITMAPDATA;
        g2d_bitmapData = cast (event.target.loader.content,Bitmap).bitmapData;
        onLoaded.dispatch(this);
    }
}
