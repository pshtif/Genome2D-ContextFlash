/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.stage3d.renderers;

import com.genome2d.context.stage3d.GStage3DContext;
import flash.display3D.textures.TextureBase;
import flash.utils.Dictionary;
import com.genome2d.context.filters.GFilter;
import com.adobe.utils.AGALMiniAssembler;
import com.genome2d.textures.GContextTexture;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.utils.ByteArray;
import flash.Vector;

class GTriangleTextureBufferCPURenderer implements IGRenderer
{
    static private inline var BATCH_SIZE:Int = 1200;
    static private inline var DATA_PER_VERTEX:Int = 4;
    static private inline var DATA_PER_VERTEX_ALPHA:Int = DATA_PER_VERTEX+4;

    static private inline var VERTEX_SHADER_CODE:String =
        "m44 op, va0, vc0       \n" +

        "mov v0, va1";

    inline static private var VERTEX_SHADER_CODE_ALPHA:String = VERTEX_SHADER_CODE + "\nmov v1, va2";

    private var g2d_vertexBuffer:VertexBuffer3D;
    private var g2d_vertexBufferAlpha:VertexBuffer3D;
    private var g2d_vertexVector:Vector<Float>;
    private var g2d_triangleIndexBuffer:IndexBuffer3D;

    private var g2d_triangleCount:Int = 0;

    private var g2d_initializedThisFrame:Bool;
    private var g2d_activeAlpha:Bool = false;
    private var g2d_activeAtf:String = "";
    private var g2d_activeFilter:GFilter;
    private var g2d_activeFiltering:Int;
    private var g2d_activeTexture:TextureBase;

    private var g2d_useSeparatedAlphaPipeline:Bool = true;

    private var g2d_cachedPrograms:Dictionary;
    private var g2d_vertexShaderCode:ByteArray;
    private var g2d_vertexShaderAlphaCode:ByteArray;

    private var g2d_context:GStage3DContext;
    private var g2d_nativeContext:Context3D;

    private function getCachedProgram(p_repeat:String, p_filtering:Int, p_alpha:Bool, p_atf:String, p_filter:GFilter):Program3D {
        var filterId:String = (p_filter != null) ? p_filter.id : "";
        if (untyped g2d_cachedPrograms.hasOwnProperty(p_repeat + String(p_filtering) + String(p_alpha) + p_atf + filterId)) return untyped g2d_cachedPrograms[p_repeat + String(p_filtering) + String(p_alpha) + p_atf + filterId];

        var program:Program3D = g2d_nativeContext.createProgram();
        program.upload(p_alpha ? g2d_vertexShaderAlphaCode : g2d_vertexShaderCode, GRenderersCommon.getTexturedShaderCode(false, p_filtering, p_alpha, p_atf, p_filter));
        untyped g2d_cachedPrograms[p_repeat + String(p_filtering) + String(p_alpha) + p_atf + filterId] = program;

        return program;
    }

    public function new() {
    }

    public function initialize(p_context:GStage3DContext):Void {
        g2d_context = p_context;
        g2d_nativeContext = g2d_context.getNativeContext();

        g2d_cachedPrograms = new Dictionary(false);

        var agal:AGALMiniAssembler = new AGALMiniAssembler();
        agal.assemble("vertex", VERTEX_SHADER_CODE);
        g2d_vertexShaderCode = agal.agalcode;
        agal.assemble("vertex", VERTEX_SHADER_CODE_ALPHA);
        g2d_vertexShaderAlphaCode = agal.agalcode;

        g2d_vertexVector = new Vector<Float>(3 * BATCH_SIZE * DATA_PER_VERTEX_ALPHA);
        g2d_vertexBuffer = g2d_nativeContext.createVertexBuffer(3 * BATCH_SIZE, DATA_PER_VERTEX);
        g2d_vertexBufferAlpha = g2d_nativeContext.createVertexBuffer(3 * BATCH_SIZE, DATA_PER_VERTEX_ALPHA);

        var indices:Vector<UInt> = new Vector<UInt>(3 * BATCH_SIZE);
        for (i in 0...3 * BATCH_SIZE) {
            indices[i] = i;
        }

        g2d_triangleIndexBuffer = g2d_nativeContext.createIndexBuffer(3 * BATCH_SIZE);
        g2d_triangleIndexBuffer.uploadFromVector(indices, 0, 3 * BATCH_SIZE);

        g2d_triangleCount = 0;
    }

    public function bind(p_context:GStage3DContext, p_reinitialize:Bool):Void {
        if (g2d_cachedPrograms==null || (p_reinitialize && !g2d_initializedThisFrame)) initialize(p_context);
        g2d_initializedThisFrame = p_reinitialize;

        g2d_nativeContext.setProgram(getCachedProgram("true",GContextTexture.defaultFilteringType, g2d_activeAlpha, g2d_activeAtf, g2d_activeFilter));

        g2d_nativeContext.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, Vector.ofArray([1, 0, 0, .5]), 1);
        g2d_nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.ofArray([1.0,1.0,1.0,1.0]), 1);

        g2d_triangleCount = 0;
        g2d_activeTexture = null;
        g2d_activeFilter = null;
    }

    public function draw(p_vertices:Array<Float>, p_uvs:Array<Float>, p_x:Float, p_y:Float, p_scaleX:Float, p_scaleY:Float, p_rotation:Float, p_red:Float, p_green:Float, p_blue:Float, p_alpha:Float, p_texture:GContextTexture, p_filter:GFilter):Void {
        var contextTexture:TextureBase = p_texture.nativeTexture;
        var notSameTexture:Bool = g2d_activeTexture != contextTexture;
        var notSameFiltering:Bool = g2d_activeFiltering != p_texture.g2d_filteringType;
        var useAlpha:Bool = !g2d_useSeparatedAlphaPipeline || !(p_red==1 && p_green==1 && p_blue==1 && p_alpha==1);
        var notSameAlpha:Bool = g2d_activeAlpha != useAlpha;
        var notSameAtf:Bool = g2d_activeAtf != p_texture.atfType;
        var notSameFilter:Bool = g2d_activeFilter != p_filter;

        if (notSameTexture || notSameFiltering || notSameAlpha || notSameAtf) {
            if (g2d_activeTexture != null) push();

            if (notSameTexture) {
                g2d_activeTexture = contextTexture;
                g2d_nativeContext.setTextureAt(0, g2d_activeTexture);
            }

            if (notSameFiltering || notSameAlpha || notSameAtf) {
                g2d_activeFiltering = p_texture.g2d_filteringType;
                g2d_activeAlpha = useAlpha;
                g2d_activeAtf = p_texture.atfType;
                if (g2d_activeFilter != null) g2d_activeFilter.clear(g2d_context);
                g2d_activeFilter = p_filter;
                if (g2d_activeFilter != null) g2d_activeFilter.bind(g2d_context, p_texture);
                g2d_nativeContext.setProgram(getCachedProgram("true", g2d_activeFiltering, g2d_activeAlpha, g2d_activeAtf, g2d_activeFilter));
            }
        }

        var cos:Float = (p_rotation==0) ? 1 : Math.cos(p_rotation);
        var sin:Float = (p_rotation==0) ? 0 : Math.sin(p_rotation);

        var ux:Float = p_texture.uvX;
        var usx:Float = p_texture.uvScaleX;
        var uy:Float = p_texture.uvY;
        var usy:Float = p_texture.uvScaleY;

        if (p_texture.premultiplied) {
            p_red*=p_alpha;
            p_green*=p_alpha;
            p_blue*=p_alpha;
        }

        var dataSize:Int = p_vertices.length;
        var vertexCount:Int = dataSize>>1;

        var triangleCount:Int = untyped __int__(vertexCount/3);

        if (g2d_triangleCount+triangleCount > BATCH_SIZE) push();
        var index:Int = (g2d_activeAlpha ? DATA_PER_VERTEX_ALPHA : DATA_PER_VERTEX)*3*g2d_triangleCount;
        var i:Int = 0;
        while (i<dataSize) {
            // xy
            g2d_vertexVector[index] = cos*p_vertices[i]*p_scaleX - sin*p_vertices[i+1]*p_scaleY + p_x;
            g2d_vertexVector[index+1] = sin*p_vertices[i]*p_scaleY + cos*p_vertices[i+1]*p_scaleX + p_y;
            // uv
            g2d_vertexVector[index+2] = ux+p_uvs[i]*usx;
            g2d_vertexVector[index+3] = uy+p_uvs[i+1]*usy;
            // color
            if (g2d_activeAlpha) {
                g2d_vertexVector[index+4] = p_red;
                g2d_vertexVector[index+5] = p_green;
                g2d_vertexVector[index+6] = p_blue;
                g2d_vertexVector[index+7] = p_alpha;

                index+=DATA_PER_VERTEX_ALPHA;
            } else {
                index+=DATA_PER_VERTEX;
            }

            i+=2;
        }

        g2d_triangleCount+=triangleCount;
        if (g2d_triangleCount >= BATCH_SIZE) push();
    }

    inline public function push():Void {
        if (g2d_triangleCount != 0) {
            if (g2d_activeAlpha) {
                g2d_vertexBufferAlpha.uploadFromVector(g2d_vertexVector, 0, 3*BATCH_SIZE);
                g2d_nativeContext.setVertexBufferAt(0, g2d_vertexBufferAlpha, 0, Context3DVertexBufferFormat.FLOAT_2);
                g2d_nativeContext.setVertexBufferAt(1, g2d_vertexBufferAlpha, 2, Context3DVertexBufferFormat.FLOAT_2);
                g2d_nativeContext.setVertexBufferAt(2, g2d_vertexBufferAlpha, 4, Context3DVertexBufferFormat.FLOAT_4);
            } else {
                g2d_vertexBuffer.uploadFromVector(g2d_vertexVector, 0, 3*BATCH_SIZE);
                g2d_nativeContext.setVertexBufferAt(0, g2d_vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
                g2d_nativeContext.setVertexBufferAt(1, g2d_vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
                g2d_nativeContext.setVertexBufferAt(2, null);
            }

            g2d_nativeContext.drawTriangles(g2d_triangleIndexBuffer, 0, g2d_triangleCount);

            g2d_triangleCount = 0;
        }
    }

    public function clear():Void {
        g2d_nativeContext.setTextureAt(0, null);
        g2d_nativeContext.setVertexBufferAt(0, null);
        g2d_nativeContext.setVertexBufferAt(1, null);
        g2d_nativeContext.setVertexBufferAt(2, null);

        g2d_activeTexture = null;

        if (g2d_activeFilter != null) g2d_activeFilter.clear(g2d_context);
        g2d_activeFilter = null;
    }
}