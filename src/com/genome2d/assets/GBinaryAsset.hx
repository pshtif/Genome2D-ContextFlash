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
import com.genome2d.assets.GAsset;
import com.genome2d.debug.GDebug;
import flash.events.IOErrorEvent;
import flash.events.Event;
import flash.net.URLLoaderDataFormat;
import flash.net.URLLoader;
import flash.net.URLRequest;

/*
 *
 * @author Peter "sHTiF" Stefcek / www.flash-core.com
 */

class GBinaryAsset extends GAsset
{
    public var data:ByteArray;
    /**
        Load the asset
    **/
    override public function load():Void {
        if (!g2d_loaded && !g2d_loading && g2d_url != null) {
            g2d_loading = true;
            var urlLoader:URLLoader = new URLLoader();
            urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
            urlLoader.addEventListener(Event.COMPLETE, g2d_complete_handler);
            urlLoader.addEventListener(IOErrorEvent.IO_ERROR, g2d_ioError_handler);
            urlLoader.load(new URLRequest(g2d_url));
        } else {
            GDebug.warning("Asset already loading, was loaded or invalid url specified.");
        }
    }
	
	private function g2d_complete_handler(p_event:Event):Void {
        g2d_loading = false;
        data = p_event.target.data;
        g2d_loaded = true;
        onLoaded.dispatch(this);
    }

    private function g2d_ioError_handler(event:IOErrorEvent):Void {
        g2d_loading = false;
        onFailed.dispatch(this);
    }
}