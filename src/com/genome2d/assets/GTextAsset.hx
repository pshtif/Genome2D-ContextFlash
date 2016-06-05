/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.assets;

import flash.events.Event;

/**
 * @author Peter "sHTiF" Stefcek
 */
class GTextAsset extends GAsset {
	
	public var text:String;

	override private function g2d_complete_handler(p_event:Event):Void {
		text = p_event.target.data;
        g2d_loading = false;
        g2d_loaded = true;
		onLoaded.dispatch(this);
	}
}