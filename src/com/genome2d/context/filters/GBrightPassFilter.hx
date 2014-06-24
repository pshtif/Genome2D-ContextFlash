/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.filters;

import flash.Vector;

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

class GBrightPassFilter extends GFilter
{
    private var g2d_treshold:Float = .5;
    public var treshold(get,set):Float;
    public function get_treshold():Float {
        return g2d_treshold;
    }
    public function set_treshold(p_value:Float):Float {
        g2d_treshold = p_value;
        fragmentConstants[0] = g2d_treshold;
        fragmentConstants[1] = 1/(1-g2d_treshold);
        return g2d_treshold;
    }

    public function new(p_treshold:Float) {
        super();

        fragmentCode = "sub ft0.xyz, ft0.xyz, fc1.xxx    \n" +
                       "mul ft0.xyz, ft0.xyz, fc1.yyy    \n" +
                       "sat ft0, ft0           			 \n";

        fragmentConstants = Vector.ofArray([.5, 2, 0, 0]);

        treshold = p_treshold;
    }
}