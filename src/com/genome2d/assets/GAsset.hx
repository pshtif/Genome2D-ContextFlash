/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.assets;

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
class GAsset
{
    private var g2d_url:String;

    private var g2d_loaded:Bool = false;
    public function isLoaded():Bool {
        return g2d_loaded;
    }

	public var onLoaded:Signal1<GAsset>;

    private var g2d_id:String;
    #if swc @:extern #end
    public var id(get, never):String;
    #if swc @:getter(id) #end
    inline private function get_id():String {
        return g2d_id;
    }

	public function new() {
        onLoaded = new Signal1();
    }

    public function initUrl(p_id:String, p_url:String):Void {
        g2d_id = p_id;
        g2d_url = p_url;
	}

    public function load():Void {
        if (g2d_url != null) {
            var urlLoader:URLLoader = new URLLoader();
            urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
            urlLoader.addEventListener(Event.COMPLETE, g2d_completeHandler);
            urlLoader.addEventListener(IOErrorEvent.IO_ERROR, g2d_ioErrorHandler);
            urlLoader.load(new URLRequest(g2d_url));
        }
    }

    private function g2d_completeHandler(p_event:Event):Void {
    }

    private function g2d_ioErrorHandler(event:IOErrorEvent):Void {
        trace(event);
    }
}