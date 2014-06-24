/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.stage3d.renderers;

interface IGRenderer
{
    function bind(p_context:GStage3DContext, p_reinitialize:Bool):Void;
	
	function push():Void;
	
	function clear():Void;
}