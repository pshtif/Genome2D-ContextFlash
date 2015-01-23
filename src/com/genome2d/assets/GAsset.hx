/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.assets;

import com.genome2d.debug.GDebug;
import com.genome2d.debug.GDebug;
import com.genome2d.proto.IGPrototypable;
import flash.net.URLRequest;
import flash.events.IOErrorEvent;
import flash.events.Event;
import flash.net.URLLoaderDataFormat;
import flash.net.URLLoader;
import msignal.Signal.Signal1;

/*
 * Simple asset class for alpha asset management, will be differentiated into multiple classes for different assets later
 *
 * @author Peter "sHTiF" Stefcek / www.flash-core.com
 */
@prototypeName("asset")
@:access(com.genome2d.assets.GAssetManager)
class GAsset implements IGPrototypable
{
    public var onLoaded:Signal1<GAsset>;
    public var onFailed:Signal1<GAsset>;

    private var g2d_id:String = "";
    /**
        Asset id
    **/
    #if swc @:extern #end
    @prototype public var id(get, set):String;
    #if swc @:getter(id) #end
    inline private function get_id():String {
        return g2d_id;
    }
    #if swc @:setter(id) #end
    inline private function set_id(p_value:String):String {
        if (p_value != g2d_id && p_value.length>0) {
            if (GAssetManager.g2d_references.get(p_value) != null) GDebug.error("Duplicate asset id: "+p_value);
            GAssetManager.g2d_references.set(p_value,this);

            if (GAssetManager.g2d_references.get(g2d_id) != null) GAssetManager.g2d_references.remove(g2d_id);
            g2d_id = p_value;
        }
        return g2d_id;
    }

    private var g2d_url:String;
    /**
        Asset url path
    **/
    #if swc @:extern #end
    @prototype public var url(get, set):String;
    #if swc @:getter(url) #end
    inline private function get_url():String {
        return g2d_url;
    }
    #if swc @:setter(url) #end
    inline private function set_url(p_value:String):String {
        if (!isLoaded()) {
            g2d_url = p_value;
            if (g2d_id == "") id = g2d_url;
        } else {
            GDebug.warning("Asset already loaded " + id);
        }
        return g2d_url;
    }

    private var g2d_loading:Bool = false;
    /**
        Check if asset is currently loading
    **/
    public function isLoading():Bool {
        return g2d_loading;
    }

    private var g2d_loaded:Bool = false;
    /**
        Check if asset is already loaded
    **/
    public function isLoaded():Bool {
        return g2d_loaded;
    }

	public function new(p_url:String = "", p_id:String = "") {
        onLoaded = new Signal1(GAsset);
        onFailed = new Signal1(GAsset);

        id = p_id;
        url = p_url;
    }

    /**
        Load the asset
    **/
    public function load():Void {
        if (!g2d_loaded && !g2d_loading && g2d_url != null) {
            g2d_loading = true;
            var urlLoader:URLLoader = new URLLoader();
            urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
            urlLoader.addEventListener(Event.COMPLETE, g2d_completeHandler);
            urlLoader.addEventListener(IOErrorEvent.IO_ERROR, g2d_ioErrorHandler);
            urlLoader.load(new URLRequest(g2d_url));
        } else {
            GDebug.warning("Asset already loading, was loaded or invalid url specified.");
        }
    }

    private function g2d_completeHandler(p_event:Event):Void {
    }

    private function g2d_ioErrorHandler(event:IOErrorEvent):Void {
        g2d_loading = false;
        onFailed.dispatch(this);
    }
}