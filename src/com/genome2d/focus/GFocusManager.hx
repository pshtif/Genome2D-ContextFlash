package com.genome2d.focus;
import com.genome2d.input.IGInteractive;

/**
 * ...
 * @author 
 */
class GFocusManager
{
	static public var activeFocus:IGInteractive;
	
	static public function setFocus(p_interactive:IGInteractive):Void {
		activeFocus = p_interactive;
	}	
}