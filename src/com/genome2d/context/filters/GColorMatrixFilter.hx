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
class GColorMatrixFilter extends GFilter
{
    private var g2d_identityMatrix:Vector<Float>;

    public function setMatrix(p_matrix:Vector<Float>):Void {
        if (fragmentConstants == null) fragmentConstants = new Vector<Float>(24);
        fragmentConstants[0] = p_matrix[0];
        fragmentConstants[1] = p_matrix[1];
        fragmentConstants[2] = p_matrix[2];
        fragmentConstants[3] = p_matrix[3];
        fragmentConstants[4] = p_matrix[5];
        fragmentConstants[5] = p_matrix[6];
        fragmentConstants[6] = p_matrix[7];
        fragmentConstants[7] = p_matrix[8];
        fragmentConstants[8] = p_matrix[10];
        fragmentConstants[9] = p_matrix[11];
        fragmentConstants[10] = p_matrix[12];
        fragmentConstants[11] = p_matrix[13];
        fragmentConstants[12] = p_matrix[15];
        fragmentConstants[13] = p_matrix[16];
        fragmentConstants[14] = p_matrix[17];
        fragmentConstants[15] = p_matrix[18];
        fragmentConstants[16] = p_matrix[4]/255;
        fragmentConstants[17] = p_matrix[9]/255;
        fragmentConstants[18] = p_matrix[14]/255;
        fragmentConstants[19] = p_matrix[19]/255;
        fragmentConstants[20] = 0;
        fragmentConstants[21] = 0;
        fragmentConstants[22] = 0;
        fragmentConstants[23] = 0.0001;
    }

    public function new(p_matrix:Vector<Float> = null) {
        super();

        g2d_identityMatrix = Vector.ofArray([1,0,0,0,0,
                              0,1,0,0,0,
                              0,0,1,0,0,
                              0,0,0,1,0.0]);

        setMatrix(p_matrix == null ? g2d_identityMatrix : p_matrix);

        fragmentCode =	"max ft0, ft0, fc6             \n" +
                        "div ft0.xyz, ft0.xyz, ft0.www \n" +
                        "m44 ft0, ft0, fc1             \n" +
                        "add ft0, ft0, fc5             \n" +
                        "mul ft0.xyz, ft0.xyz, ft0.www \n";
    }
}