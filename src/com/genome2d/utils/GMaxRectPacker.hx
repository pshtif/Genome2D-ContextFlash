/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.utils;

import flash.display.BitmapData;
import flash.geom.Matrix;
class GMaxRectPacker
{				
    static public inline var BOTTOM_LEFT:Int = 0;
    static public inline var SHORT_SIDE_FIT:Int = 1;
    static public inline var LONG_SIDE_FIT:Int = 2;
    static public inline var AREA_FIT:Int = 3;

    static public inline var SORT_NONE:Int = 0;
    static public inline var SORT_ASCENDING:Int = 1;
    static public inline var SORT_DESCENDING:Int = 2;

    static public var nonValidTextureSizePrecision:Int = 5;
    
    private var g2d_heuristics:Int = BOTTOM_LEFT;
    
    private var g2d_firstAvailableArea:GPackerRectangle;
    private var g2d_lastAvailableArea:GPackerRectangle;
    
    private var g2d_firstNewArea:GPackerRectangle;
    private var g2d_lastNewArea:GPackerRectangle;
    
    private var g2d_newBoundingArea:GPackerRectangle;
    private var g2d_negativeArea:GPackerRectangle;

    private var g2d_maxWidth:Int;
    private var g2d_maxHeight:Int;
    private var g2d_autoExpand:Bool = false;
    private var g2d_sortOnExpand:Int = SORT_DESCENDING;
    private var g2d_forceValidTextureSizeOnExpand:Bool = true;

    private var g2d_width:Int;
    public function getWidth():Int {
        return g2d_width;
    }

    private var g2d_height:Int;
    public function getHeight():Int {
        return g2d_height;
    }

    private var g2d_rectangles:Array<GPackerRectangle>;
    public function getRectangles():Array<GPackerRectangle> {
        return g2d_rectangles.slice(0);
    }

    public function new(p_width:Int = 1, p_height:Int = 1, p_maxWidth:Int = 2048, p_maxHeight:Int = 2048, p_autoExpand:Bool = false, p_heuristics:Int = BOTTOM_LEFT) {
        if (p_width <= 0 || p_height <= 0) throw "Invalid packer size";
        g2d_width = p_width;
        g2d_height = p_height;
        g2d_maxWidth = p_maxWidth;
        g2d_maxHeight = p_maxHeight;
        g2d_autoExpand = p_autoExpand;

        clear();

        g2d_newBoundingArea = GPackerRectangle.get(0,0,0,0);
        g2d_heuristics = p_heuristics;
    }
    
    public function g2d_packRectangles(p_rectangles:Array<GPackerRectangle>, p_padding:Int = 0, p_sort:Int = SORT_DESCENDING):Bool {
        if (p_sort != SORT_NONE) p_rectangles.sort((p_sort == SORT_ASCENDING) ? g2d_sortOnHeightAscending : g2d_sortOnHeightDescending);
        var count:Int = p_rectangles.length;
        var success:Bool = true;
        var failedRectangles:Array<GPackerRectangle> = (g2d_autoExpand) ? new Array<GPackerRectangle>() : null;
        for (i in 0...count) {
            var rect:GPackerRectangle = p_rectangles[i];
            var s:Bool = g2d_addRectangle(rect, p_padding);
            if (!s && g2d_autoExpand) failedRectangles.push(p_rectangles[i]);
            success = success&&s;
        }
        if (!success && g2d_autoExpand) {
            var storedRectangles:Array<GPackerRectangle> = getRectangles();
            storedRectangles = storedRectangles.concat(failedRectangles);

            if (g2d_sortOnExpand != SORT_NONE) storedRectangles.sort((g2d_sortOnExpand == SORT_ASCENDING) ? g2d_sortOnHeightAscending : g2d_sortOnHeightDescending);
            
            var minimalArea:Int = g2d_getRectanglesArea(storedRectangles);

            do {
                if ((g2d_width<=g2d_height||g2d_height==g2d_maxHeight)&&g2d_width<g2d_maxWidth) g2d_width = (g2d_forceValidTextureSizeOnExpand) ? g2d_width*2 : g2d_width+1;
                else g2d_height = (g2d_forceValidTextureSizeOnExpand) ? g2d_height*2 : g2d_height+1;
            } while (g2d_width*g2d_height<minimalArea&&(g2d_width<g2d_maxWidth||g2d_height<g2d_maxHeight));

            clear();
            
            success = g2d_addRectangles(storedRectangles, p_padding);
            
            while (!success&&(g2d_width<g2d_maxWidth||g2d_height<g2d_maxHeight)) {
                if ((g2d_width<=g2d_height||g2d_height==g2d_maxHeight)&&g2d_width<g2d_maxWidth) g2d_width = (g2d_forceValidTextureSizeOnExpand) ? g2d_width*2 : g2d_width+nonValidTextureSizePrecision
                else g2d_height = (g2d_forceValidTextureSizeOnExpand) ? g2d_height*2 : g2d_height+nonValidTextureSizePrecision;
                clear();
                success = g2d_addRectangles(storedRectangles, p_padding);
            }

            success = (g2d_width<=g2d_maxWidth&&g2d_height<=g2d_maxHeight);
        }
        
        return success;
    }

    private function g2d_getRectanglesArea(p_rectangles:Array<GPackerRectangle>):Int {
        var area:Int = 0;
        var i:Int = p_rectangles.length-1;
        while (i>=0) {
            area+=p_rectangles[i].width*p_rectangles[i].height;
            i--;
        }
        return area;
    }
    
    public function packRectangle(p_rect:GPackerRectangle, p_padding:Int = 0, p_forceValidTextureSize:Bool = true):Bool {
        var success:Bool = g2d_addRectangle(p_rect, p_padding);
        
        if (!success && g2d_autoExpand) {
            var storedRectangles:Array<GPackerRectangle> = getRectangles();
            storedRectangles.push(p_rect);
            
            clear();
            g2d_packRectangles(storedRectangles, p_padding, g2d_sortOnExpand);
        
            success = true;
        }
        
        return success;
    }
    
    private function g2d_addRectangles(p_rectangles:Array<GPackerRectangle>, p_padding:Int = 0, p_force:Bool = true):Bool {
        var count:Int = p_rectangles.length;
        var success:Bool = true;
        for (i in 0...count) {
            var rect:GPackerRectangle = p_rectangles[i];
            success = success && g2d_addRectangle(rect, p_padding);
            if (!success&&!p_force) return false;
        }			
        return success;
    }
    
    inline private function g2d_addRectangle(p_rect:GPackerRectangle, p_padding:Int):Bool {
        var area:GPackerRectangle = g2d_getAvailableArea(p_rect.width+(p_padding-p_rect.padding)*2, p_rect.height+(p_padding-p_rect.padding)*2);
        if (area != null) {
            p_rect.set(area.x, area.y, p_rect.width+(p_padding-p_rect.padding)*2, p_rect.height+(p_padding-p_rect.padding)*2);
            p_rect.padding = p_padding;

            g2d_splitAvailableAreas(p_rect);
            g2d_pushNewAreas();

            if (p_padding != 0) p_rect.setPadding(0);

            g2d_rectangles.push(p_rect);
        }
        return area != null;
    }
    
    inline private function g2d_createNewArea(p_x:Int, p_y:Int, p_width:Int, p_height:Int):GPackerRectangle {
        var valid:Bool = true;

        var area:GPackerRectangle = g2d_firstNewArea;
        while (area != null) {
            var next:GPackerRectangle = area.g2d_next;
            if (!(area.x > p_x || area.y > p_y || area.right < p_x+p_width || area.bottom < p_y+p_height)) {
                valid = false;
                break;
            } else if (!(area.x < p_x || area.y < p_y || area.right > p_x+p_width || area.bottom > p_y+p_height)) {
                if (area.g2d_next != null) area.g2d_next.g2d_previous = area.g2d_previous;
                else g2d_lastNewArea = area.g2d_previous;
                
                if (area.g2d_previous != null) area.g2d_previous.g2d_next = area.g2d_next;
                else g2d_firstNewArea = area.g2d_next;
                
                area.dispose();
            }
            area = next;
        }
        if (valid) {
            /**/
            area = GPackerRectangle.get(p_x, p_y, p_width, p_height);
            if (g2d_newBoundingArea.x < p_x) g2d_newBoundingArea.x = p_x;
            if (g2d_newBoundingArea.right > area.right) g2d_newBoundingArea.right = area.right;
            if (g2d_newBoundingArea.y < p_y) g2d_newBoundingArea.y = p_y;
            if (g2d_newBoundingArea.bottom < area.bottom) g2d_newBoundingArea.bottom = area.bottom;
            /**/
            if (g2d_lastNewArea != null) {
                area.g2d_previous = g2d_lastNewArea;
                g2d_lastNewArea.g2d_next = area;
                g2d_lastNewArea = area;
            } else {
                g2d_lastNewArea = area;
                g2d_firstNewArea = area;
            }
        } else {
            area = null;
        }

        return area;
    }
    
    inline private function g2d_splitAvailableAreas(p_splitter:GPackerRectangle):Void {
        var sx:Int = p_splitter.x;
        var sy:Int = p_splitter.y;
        var sright:Int = p_splitter.right;
        var sbottom:Int = p_splitter.bottom;

        var area:GPackerRectangle = g2d_firstAvailableArea;
        while (area != null) {
            var next:GPackerRectangle = area.g2d_next;
            
            if (!(sx >= area.right || sright <= area.x || sy >= area.bottom || sbottom <= area.y)) {
                if (sx > area.x) {
                    g2d_createNewArea(area.x, area.y, sx-area.x, area.height);
                }
                if (sright < area.right) {
                    g2d_createNewArea(sright, area.y, area.right - sright, area.height);
                }
                if (sy > area.y) {
                    g2d_createNewArea(area.x, area.y, area.width, sy - area.y);
                }
                if (sbottom < area.bottom) {
                    g2d_createNewArea(area.x, sbottom, area.width, area.bottom - sbottom);
                }
                
                if (area.g2d_next != null) area.g2d_next.g2d_previous = area.g2d_previous;
                else g2d_lastAvailableArea = area.g2d_previous;
                
                if (area.g2d_previous != null) area.g2d_previous.g2d_next = area.g2d_next;
                else g2d_firstAvailableArea = area.g2d_next;
                
                area.dispose();
            }
            area = next;
        }
    }
    
    inline private function g2d_pushNewAreas():Void {
    /*
        var availableArea:GPackerRectangle = g2d_firstAvailableArea;
        while (availableArea!=null) {
            var nextAvailableArea:GPackerRectangle = availableArea.g2d_next;
            if (!(g2d_newBoundingArea.x >= availableArea.right || g2d_newBoundingArea.right <= availableArea.x || g2d_newBoundingArea.y >= availableArea.y || g2d_newBoundingArea.right <= availableArea.y)) {
                var newArea:GPackerRectangle = g2d_firstNewArea;
                while (newArea != null) {
                    var nextNewArea:GPackerRectangle = newArea.g2d_next;
                    if (!(availableArea.x > newArea.x || availableArea.y > newArea.y || availableArea.right < newArea.right || availableArea.bottom < newArea.bottom)) {
                        if (newArea.g2d_next != null) newArea.g2d_next.g2d_previous = newArea.g2d_previous;
                        else g2d_lastNewArea = newArea.g2d_previous;
                        
                        if (newArea.g2d_previous != null) newArea.g2d_previous.g2d_next = newArea.g2d_next;
                        else g2d_firstNewArea = newArea.g2d_next;
                        
                        newArea.dispose();
                        if (g2d_firstNewArea == null) break;
                        //updateBoundingArea();
                    }
                    newArea = nextNewArea;
                }
            }
            availableArea = nextAvailableArea;
        }
    /**/

        while (g2d_firstNewArea != null) {
            var area:GPackerRectangle = g2d_firstNewArea;
            if (area.g2d_next != null) {
                g2d_firstNewArea = area.g2d_next;
                g2d_firstNewArea.g2d_previous = null;
            } else {
                g2d_firstNewArea = null;
            }
            area.g2d_previous = null;
            area.g2d_next = null;
            
            if (g2d_lastAvailableArea != null) {
                area.g2d_previous = g2d_lastAvailableArea;
                g2d_lastAvailableArea.g2d_next = area;
                g2d_lastAvailableArea = area;
            } else {
                g2d_lastAvailableArea = area;
                g2d_firstAvailableArea = area;
            }
        }
        
        g2d_lastNewArea = null;
        g2d_newBoundingArea.set(0,0,0,0);
    }

    inline private function g2d_getAvailableArea(p_width:Int, p_height:Int):GPackerRectangle {
        var available:GPackerRectangle = g2d_negativeArea;
        var index:Int = -1;
        var area:GPackerRectangle;
        var w:Int;
        var h:Int;
        var m1:Int;
        var m2:Int;

        if (g2d_heuristics == BOTTOM_LEFT) {
            area = g2d_firstAvailableArea;
            while (area != null) {
                if (area.width>=p_width && area.height>=p_height) {
                    if (area.y < available.y || (area.y == available.y && area.x < available.x)) available = area;
                }
                area = area.g2d_next;
            }
        } else if (g2d_heuristics == SHORT_SIDE_FIT) {
            available.width = g2d_width+1;
            area = g2d_firstAvailableArea;
            while (area != null) {
                if (area.width >= p_width && area.height >= p_height) {
                    w = area.width - p_width;
                    h = area.height - p_height;
                    m1 = (w<h) ? w : h;
                    w = available.width - p_width;
                    h = available.height - p_height;
                    m2 = (w<h) ? w : h;
                    if (m1 < m2) available = area;
                }
                area = area.g2d_next;
            }
        } else if (g2d_heuristics == LONG_SIDE_FIT) {
            available.width = g2d_width+1;
            area = g2d_firstAvailableArea;
            while (area != null) {
                if (area.width >= p_width && area.height >= p_height) {
                    w = area.width - p_width;
                    h = area.height - p_height;
                    m1 = (w>h) ? w : h;
                    w = available.width - p_width;
                    h = available.height - p_height;
                    m2 = (w>h) ? w : h;
                    if (m1 < m2) available = area;
                }
                area = area.g2d_next;
            }
        } else if (g2d_heuristics == AREA_FIT) {
            available.width = g2d_width+1;
            area = g2d_firstAvailableArea;
            while (area != null) {
                if (area.width>=p_width && area.height>=p_height) {
                    var a1:Int = area.width*area.height;
                    var a2:Int = available.width*available.height;
                    if (a1 < a2 || (a1 == a2 && area.width < available.width)) available = area;
                }

                area = area.g2d_next;
            }
        }

        return (available!=g2d_negativeArea) ? available : null;
    }
    
    public function clear():Void {
        g2d_rectangles = new Array<GPackerRectangle>();

        while (g2d_firstAvailableArea != null) {
            var area:GPackerRectangle = g2d_firstAvailableArea;
            g2d_firstAvailableArea = area.g2d_next;
            area.dispose();
        }
        
        g2d_firstAvailableArea = g2d_lastAvailableArea = GPackerRectangle.get(0,0,g2d_width, g2d_height);
        g2d_negativeArea = GPackerRectangle.get(g2d_width+1, g2d_height+1, g2d_width+1, g2d_height+1);
    }

    inline private function g2d_sortOnAreaAscending(a:GPackerRectangle, b:GPackerRectangle):Int {
        var aa:Int = a.width*a.height;
        var ba:Int = b.width*b.height;
        if (aa<ba) 	return -1 else if (aa>ba) return 1;
        return 0;
    }

    inline private function g2d_sortOnAreaDescending(a:GPackerRectangle, b:GPackerRectangle):Int {
        var aa:Int = a.width*a.height;
        var ba:Int = b.width*b.height;
        if (aa>ba) 	return -1 else if (aa<ba) return 1;
        return 0;
    }

    inline private function g2d_sortOnHeightAscending(a:GPackerRectangle, b:GPackerRectangle):Int {
        if (a.height<b.height) return -1 else if (a.height>b.height) return 1;
        return 0;
    }

    inline private function g2d_sortOnHeightDescending(a:GPackerRectangle, b:GPackerRectangle):Int {
        if (a.height>b.height) return -1 else if (a.height<b.height) return 1;
        return 0;
    }

    public function draw(p_bitmapData:BitmapData):Void {
        var matrix:Matrix = new Matrix();
        for (i in 0...g2d_rectangles.length) {
            var rect:GPackerRectangle = g2d_rectangles[i];
            matrix.tx = g2d_rectangles[i].x;
            matrix.ty = g2d_rectangles[i].y;

            p_bitmapData.draw(rect.bitmapData, matrix);
        }
    }
}
