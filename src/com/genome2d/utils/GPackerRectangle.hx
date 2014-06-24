/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.utils;

import com.genome2d.geom.GRectangle;
import flash.display.BitmapData;

class GPackerRectangle
{
    public var g2d_next:GPackerRectangle;
    public var g2d_previous:GPackerRectangle;

    private var g2d_nextInstance:GPackerRectangle;

    static private var g2d_availableInstance:GPackerRectangle;

    public function new() {}

    static public function get(p_x:Int, p_y:Int, p_width:Int, p_height:Int, p_id:String = null, p_bitmapData:BitmapData = null, p_pivotX:Float = 0, p_pivotY:Float = 0):GPackerRectangle {
        var instance:GPackerRectangle = g2d_availableInstance;
        if (instance != null) {
            g2d_availableInstance = instance.g2d_nextInstance;
            instance.g2d_nextInstance = null;
        } else {
            instance = new GPackerRectangle();
        }

        instance.x = p_x;
        instance.y = p_y;
        instance.width = p_width;
        instance.height = p_height;
        instance.right = p_x + p_width;
        instance.bottom = p_y + p_height;
        instance.id = p_id;
        instance.bitmapData = p_bitmapData;
        instance.pivotX = p_pivotX;
        instance.pivotY = p_pivotY;

        return instance;
    }

    public var x:Int = 0;
    public var y:Int = 0;

    public var width:Int = 0;
    public var height:Int = 0;

    public var right:Int = 0;
    public var bottom:Int = 0;

    public var id:String;
    public var bitmapData:BitmapData;
    public var pivotX:Float;
    public var pivotY:Float;

    public var padding:Int = 0;

    public function set(p_x:Int, p_y:Int, p_width:Int, p_height:Int):Void {
        x = p_x;
        y = p_y;
        width = p_width;
        height = p_height;
        right = p_x + p_width;
        bottom = p_y + p_height;
    }

    public function dispose():Void {
        g2d_next = null;
        g2d_previous = null;
        g2d_nextInstance = g2d_availableInstance;
        g2d_availableInstance = this;
        bitmapData = null;
    }

    public function setPadding(p_value:Int):Void {
        x-=p_value-padding;
        y-=p_value-padding;
        width+=(p_value-padding)*2;
        height+=(p_value-padding)*2;
        right+=p_value-padding;
        bottom+=p_value-padding;
        padding = p_value;
    }

    public function getRect():GRectangle {
        return new GRectangle(x,y,width,height);
    }

    public function toString():String {
        return "["+id+"] x: "+x+" y: "+y+" w: "+width+" h: "+height+" bd: "+(bitmapData != null ? untyped bitmapData.rect : "")+" p: "+padding;
    }
}