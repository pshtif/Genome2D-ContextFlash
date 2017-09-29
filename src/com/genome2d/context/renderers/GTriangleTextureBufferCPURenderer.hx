/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.renderers;

import com.genome2d.textures.GTextureFilteringType;
import com.genome2d.textures.GTexture;
import com.genome2d.textures.GTextureManager;
import com.genome2d.context.GStage3DContext;
import flash.display3D.textures.TextureBase;
import flash.utils.Dictionary;
import com.genome2d.context.filters.GFilter;
import com.adobe.utils.extended.AGALMiniAssembler;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.utils.ByteArray;
import flash.Vector;

@:access(com.genome2d.textures.GTexture)
class GTriangleTextureBufferCPURenderer implements IGRenderer
{
    inline static private var BATCH_SIZE:Int = 1200;
    inline static private var DATA_PER_VERTEX:Int = 4;
    inline static private var DATA_PER_VERTEX_ALPHA:Int = DATA_PER_VERTEX+4;

	inline static private var VERTEX_SHADER_CODE:String =
        "m44 op, va0, vc0";
	
	inline static private var VERTEX_SHADER_CODE_COLOR:String = VERTEX_SHADER_CODE + "\nmov v0, va1";
	
    inline static private var VERTEX_SHADER_CODE_TEXTURED:String =
        "m44 op, va0, vc0       \n" +
        "mov v0, va1";

    inline static private var VERTEX_SHADER_CODE_TEXTURED_COLOR:String = VERTEX_SHADER_CODE_TEXTURED + "\nmov v1, va2";

    private var g2d_vertexBuffer:VertexBuffer3D;
    private var g2d_vertexBufferAlpha:VertexBuffer3D;
    private var g2d_vertexVector:Vector<Float>;
    private var g2d_triangleIndexBuffer:IndexBuffer3D;

    private var g2d_triangleCount:Int = 0;

    private var g2d_initialized:Int = 0;
    private var g2d_activeAlpha:Bool = false;
    private var g2d_activeAtf:String = "";
    private var g2d_activeFilter:GFilter;
    private var g2d_activeFiltering:GTextureFilteringType;
    private var g2d_activeTexture:TextureBase;
    private var g2d_activeRepeat:Bool = false;

    private var g2d_useSeparatedAlphaPipeline:Bool = true;

    private var g2d_cachedPrograms:Dictionary;
    private var g2d_cachedProgramIds:Dictionary;
    private var g2d_vertexShaderTexturedCode:ByteArray;
    private var g2d_vertexShaderTexturedAlphaCode:ByteArray;

    private var g2d_context:GStage3DContext;
    private var g2d_nativeContext:Context3D;

    inline private function getCachedProgram(p_textured:Bool, p_alpha:Bool, p_repeat:Bool, p_filtering:GTextureFilteringType, p_atf:String, p_filter:GFilter):Program3D {
        var programBit:Int = 0;

        if (p_alpha) programBit |= 1;
        if (p_repeat) programBit |= 1 << 2;
        if (p_filtering == GTextureFilteringType.LINEAR) programBit |= 1 << 3;

        if (p_atf == "dxt1") programBit |= 1 << 4;
        else if (p_atf == "dxt5") programBit |= 1 << 5;

        var programId:String = untyped g2d_cachedProgramIds[programBit];

        if (programId == null) {
            programId = untyped String(programBit);
            untyped g2d_cachedProgramIds[programBit] = programId;
        }

        if (p_filter != null) programId+=p_filter.id;

        var program:Program3D = untyped g2d_cachedPrograms[programId];
        if (program == null) {
            program = g2d_nativeContext.createProgram();
			if (p_textured) {
				program.upload((p_alpha) ? g2d_vertexShaderTexturedAlphaCode : g2d_vertexShaderTexturedCode, GRenderersCommon.getTexturedShaderCode(p_repeat, p_filtering, p_alpha?1:0, p_atf, p_filter));	
			} else {
				//program.upload((p_alpha) ? g2d_vertexShaderTexturedAlphaCode 
			}
            untyped g2d_cachedPrograms[programId] = program;
        }

        return program;
    }

    public function new() {
    }

    public function initialize(p_context:GStage3DContext):Void {
        g2d_context = p_context;
        g2d_nativeContext = g2d_context.getNativeContext();

        g2d_cachedPrograms = new Dictionary(false);
        g2d_cachedProgramIds = new Dictionary(false);

        var agal:AGALMiniAssembler = new AGALMiniAssembler();
        agal.assemble("vertex", VERTEX_SHADER_CODE_TEXTURED, GRenderersCommon.AGAL_VERSION);
        g2d_vertexShaderTexturedCode = agal.agalcode;
        agal.assemble("vertex", VERTEX_SHADER_CODE_TEXTURED_COLOR, GRenderersCommon.AGAL_VERSION);
        g2d_vertexShaderTexturedAlphaCode = agal.agalcode;

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

    public function bind(p_context:IGContext, p_reinitialize:Int):Void {
        if (g2d_cachedPrograms==null || (p_reinitialize != g2d_initialized)) initialize(cast p_context);
        g2d_initialized = p_reinitialize;

        g2d_nativeContext.setProgram(getCachedProgram(true, g2d_activeAlpha, false, GTextureManager.defaultFilteringType, g2d_activeAtf, g2d_activeFilter));

        g2d_nativeContext.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, Vector.ofArray([1, 0, 0, .5]), 1);
        g2d_nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.ofArray([1.0,1.0,1.0,1.0]), 1);

        g2d_triangleCount = 0;
        g2d_activeTexture = null;
        g2d_activeFilter = null;
    }

    public function draw(p_vertices:Array<Float>, p_uvs:Array<Float>, p_x:Float, p_y:Float, p_scaleX:Float, p_scaleY:Float, p_rotation:Float, p_red:Float, p_green:Float, p_blue:Float, p_alpha:Float, p_texture:GTexture, p_filter:GFilter):Void {
        var contextTexture:TextureBase = p_texture.nativeTexture;
        var notSameTexture:Bool = g2d_activeTexture != contextTexture;
        var notSameFiltering:Bool = g2d_activeFiltering != p_texture.g2d_filteringType;
        var useAlpha:Bool = !g2d_useSeparatedAlphaPipeline || !(p_red==1 && p_green==1 && p_blue==1 && p_alpha==1);
        var notSameAlpha:Bool = g2d_activeAlpha != useAlpha;
        var notSameAtf:Bool = g2d_activeAtf != p_texture.g2d_atfType;
        var notSameFilter:Bool = g2d_activeFilter != p_filter;
        var notSameRepeat:Bool = g2d_activeRepeat != p_texture.g2d_repeatable;

        if (notSameFilter || notSameRepeat || notSameTexture || notSameFiltering || notSameAlpha || notSameAtf) {
            if (g2d_activeTexture != null) push();

            if (notSameTexture) {
                g2d_activeTexture = contextTexture;
                g2d_nativeContext.setTextureAt(0, g2d_activeTexture);
            }

            if (notSameFilter || notSameRepeat || notSameFiltering || notSameAlpha || notSameAtf) {
                g2d_activeFiltering = p_texture.g2d_filteringType;
                g2d_activeAlpha = useAlpha;
                g2d_activeAtf = p_texture.g2d_atfType;
                if (g2d_activeFilter != null) g2d_activeFilter.clear(g2d_context);
                g2d_activeFilter = p_filter;
                if (g2d_activeFilter != null) g2d_activeFilter.bind(g2d_context, p_texture);
                g2d_activeRepeat = p_texture.g2d_repeatable;
                g2d_nativeContext.setProgram(getCachedProgram(true, g2d_activeAlpha, g2d_activeRepeat, g2d_activeFiltering, g2d_activeAtf, g2d_activeFilter));
            }
        }

        var cos:Float = (p_rotation==0) ? 1 : Math.cos(p_rotation);
        var sin:Float = (p_rotation==0) ? 0 : Math.sin(p_rotation);

        var ux:Float = p_texture.g2d_u;
        var usx:Float = p_texture.g2d_uScale;
        var uy:Float = p_texture.g2d_v;
        var usy:Float = p_texture.g2d_vScale;

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
            g2d_vertexVector[index+1] = sin*p_vertices[i]*p_scaleX + cos*p_vertices[i+1]*p_scaleY + p_y;
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