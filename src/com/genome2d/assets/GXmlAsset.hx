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
import flash.net.URLLoader;
import flash.net.URLRequest;

/**
 * ...
 * @author Peter "sHTiF" Stefcek
 */
class GXmlAsset extends GAsset {
    private var g2d_xml:Xml;
    #if swc @:extern #end
	public var xml(get,never):Xml;
    #if swc @:getter(xml) #end
    inline private function get_xml():Xml {
        return g2d_xml;
    }

    public function initXml(p_id:String, p_xml:Xml):Void {
        g2d_id = p_id;
        g2d_xml = p_xml;
        g2d_loaded = true;
    }

	override private function g2d_completeHandler(p_event:Event):Void {
		g2d_xml = Xml.parse(p_event.target.data);
        g2d_loaded = true;
		onLoaded.dispatch(this);
	}
}