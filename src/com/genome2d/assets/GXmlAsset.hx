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
class GXmlAsset extends GBinaryAsset {
    private var g2d_xml:Xml;
    #if swc @:extern #end
	public var xml(get,never):Xml;
    #if swc @:getter(xml) #end
    inline private function get_xml():Xml {
        return g2d_xml;
    }

	override private function g2d_complete_handler(p_event:Event):Void {
		g2d_xml = Xml.parse(p_event.target.data);
        g2d_loading = false;
        g2d_loaded = true;
		onLoaded.dispatch(this);
	}
}