/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.context.filters;

import flash.Vector;
import com.genome2d.context.filters.GFilter;
class GDesaturateFilter extends GFilter {
    public function new() {
        super();

        fragmentCode = 	"dp3 ft0.xyz, ft0.xyz, fc1.xyz";
        fragmentConstants = Vector.ofArray([0.299, 0.587, 0.114, 0]);
    }
}
