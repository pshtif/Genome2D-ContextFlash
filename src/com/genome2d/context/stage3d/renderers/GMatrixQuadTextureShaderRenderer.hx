/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.stage3d.renderers;

import flash.display3D.textures.TextureBase;
import com.genome2d.textures.GTextureFilteringType;
import com.genome2d.textures.GContextTexture;
import com.genome2d.context.stats.GStats;
import flash.utils.Dictionary;
import com.genome2d.context.filters.GFilter;
import com.adobe.utils.AGALMiniAssembler;
import flash.Memory;
import flash.Vector;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.utils.ByteArray;

class GMatrixQuadTextureShaderRenderer implements IGRenderer
{
	inline static private var CONSTANTS_OFFSET:Int = 4;
	inline static private var BATCH_CONSTANTS:Int = 128-CONSTANTS_OFFSET;

	inline static private var TRANSFORM_PER_VERTEX:Int = 3;
	inline static private var BATCH_SIZE:Int = 41;

    inline static private var TRANSFORM_PER_VERTEX_ALPHA:Int = TRANSFORM_PER_VERTEX+1;
    inline static private var BATCH_SIZE_ALPHA:Int = 31;

	inline static private var VERTEX_SHADER_CODE:String =
			"mov vt0, va2						\n" +
			"mov vt0, va0						\n" +

            "mul vt1, va0.xy, vc[va2.y].zw      \n" +

            "mul vt2, vt1.xy, vc[va2.x].xy      \n" +
            "add vt2.x, vt2.x, vt2.y            \n" +
            "add vt2.x, vt2.x, vc[va2.y].x      \n" +

            "mul vt3, vt1.xy, vc[va2.x].zw      \n" +
            "add vt3.x, vt3.x, vt3.y            \n" +
            "add vt3.x, vt3.x, vc[va2.y].y      \n" +

            "mov vt2.y, vt3.x \n" +

			"mov vt2.zw, vt0.zw					\n" +
			"m44 op, vt2, vc0					\n" +

			"mul vt0.xy, va1.xy, vc[va2.z].zw	\n" +
			"add vt0.xy, vt0.xy, vc[va2.z].xy	\n" +

			"mov v0, vt0";
		
	inline static private var VERTEX_SHADER_CODE_ALPHA:String = VERTEX_SHADER_CODE + "\nmov v1, vc[va2.w]";

    public var g2d_useFastMem:Bool;
    public var g2d_fastMemArray:ByteArray;

	private var g2d_geometryBuffer : VertexBuffer3D;
	private var g2d_uvBuffer : VertexBuffer3D;

	private var g2d_constantIndexBuffer : VertexBuffer3D;
    private var g2d_constantIndexBufferAlpha : VertexBuffer3D;

	private var g2d_indexBuffer : IndexBuffer3D;
	
	private var g2d_initializedThisFrame:Bool = false;
	private var g2d_quadCount:Int = 0;
	private var g2d_activeNativeTexture:TextureBase;
	private var g2d_activeFiltering:Int;
	private var g2d_activeAlpha:Bool = false;
	private var g2d_activeAtf:String = "";
	private var g2d_activeFilter:GFilter;
	
	private var g2d_useSeparatedAlphaPipeline:Bool;
	
	private var g2d_cachedPrograms:Dictionary;
    private var g2d_cachedProgramIds:Dictionary;
	private var g2d_vertexConstants:Vector<Float>;

	private var g2d_vertexShaderCode:ByteArray;
	private var g2d_vertexShaderAlphaCode:ByteArray;

    private var g2d_constantOffset:Int;

    private var g2d_context:GStage3DContext;
	private var g2d_nativeContext:Context3D;
	
	public function new(p_useFastMem:Bool, p_fastMemArray:ByteArray) {
        g2d_useFastMem = false;//p_useFastMem;
        g2d_fastMemArray = p_fastMemArray;
    }

    inline private function getCachedProgram(p_alpha:Bool, p_repeat:Bool, p_filtering:Int, p_atf:String, p_filter:GFilter):Program3D {
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
            program.upload((p_alpha) ? g2d_vertexShaderAlphaCode : g2d_vertexShaderCode, GRenderersCommon.getTexturedShaderCode(false, p_filtering, p_alpha, p_atf, p_filter));
            untyped g2d_cachedPrograms[programId] = program;
        }

        return program;
    }
	
	public function initialize(p_context:GStage3DContext):Void {
        g2d_context = p_context;
		g2d_nativeContext = g2d_context.getNativeContext();
		g2d_useSeparatedAlphaPipeline = p_context.g2d_useSeparateAlphaPipeline;
		g2d_cachedPrograms = new Dictionary();
        g2d_cachedProgramIds = new Dictionary();
		g2d_vertexConstants = new Vector<Float>(BATCH_CONSTANTS * 4);

        // Assemble shader code
		var agal:AGALMiniAssembler = new AGALMiniAssembler();
		agal.assemble("vertex", VERTEX_SHADER_CODE, GRenderersCommon.AGAL_VERSION);
		g2d_vertexShaderCode = agal.agalcode;
		agal.assemble("vertex", VERTEX_SHADER_CODE_ALPHA, GRenderersCommon.AGAL_VERSION);
		g2d_vertexShaderAlphaCode = agal.agalcode;
		
		// Create vertex/uv/index vertex buffers
		var vertices:Vector<Float> = new Vector<Float>();
		var uvs:Vector<Float> = new Vector<Float>();
		var registerIndices:Vector<Float> = new Vector<Float>();
        var registerIndicesAlpha:Vector<Float> = new Vector<Float>();
		
		for (i in 0...BATCH_SIZE) {
			vertices = vertices.concat(GRenderersCommon.NORMALIZED_VERTICES);
			uvs = uvs.concat(GRenderersCommon.NORMALIZED_UVS);
			var index:Int = CONSTANTS_OFFSET + (i * TRANSFORM_PER_VERTEX);
            var array:Array<Float> = [index, index + 1, index + 2, index, index + 1, index + 2, index, index + 1, index + 2,  index, index + 1, index + 2];
            index = CONSTANTS_OFFSET + (i * TRANSFORM_PER_VERTEX_ALPHA);
            var arrayAlpha:Array<Float> = [index, index + 1, index + 2, index + 3, index, index + 1, index + 2, index + 3, index, index + 1, index + 2, index + 3, index, index + 1, index+2, index+3];
			registerIndices = registerIndices.concat(Vector.ofArray(array));
            registerIndicesAlpha = registerIndicesAlpha.concat(Vector.ofArray(arrayAlpha));
		}
		
		g2d_geometryBuffer = g2d_nativeContext.createVertexBuffer(4*BATCH_SIZE, 2);
		g2d_geometryBuffer.uploadFromVector(vertices, 0, 4*BATCH_SIZE);
		
		g2d_uvBuffer = g2d_nativeContext.createVertexBuffer(4*BATCH_SIZE, 2);
		g2d_uvBuffer.uploadFromVector(uvs, 0, 4*BATCH_SIZE);
		
		g2d_constantIndexBuffer = g2d_nativeContext.createVertexBuffer(4*BATCH_SIZE, TRANSFORM_PER_VERTEX);
		g2d_constantIndexBuffer.uploadFromVector(registerIndices, 0, 4*BATCH_SIZE);

        g2d_constantIndexBufferAlpha = g2d_nativeContext.createVertexBuffer(4*BATCH_SIZE, TRANSFORM_PER_VERTEX_ALPHA);
        g2d_constantIndexBufferAlpha.uploadFromVector(registerIndicesAlpha, 0, 4*BATCH_SIZE);

        // Create index buffer
		var indices:Vector<UInt> = new Vector<UInt>();
		for (i in 0...BATCH_SIZE) {
			var temp:Array<UInt> = [4 * i, 4 * i + 1, 4 * i + 2, 4 * i, 4 * i + 2, 4 * i + 3];
			indices = indices.concat(Vector.ofArray(temp));
		}
		g2d_indexBuffer = g2d_nativeContext.createIndexBuffer(6*BATCH_SIZE);
		g2d_indexBuffer.uploadFromVector(indices, 0, 6*BATCH_SIZE);
	}
	
	inline public function bind(p_context:GStage3DContext, p_reinitialize:Bool):Void {
		if (g2d_cachedPrograms == null || (p_reinitialize && !g2d_initializedThisFrame)) initialize(p_context);
		g2d_initializedThisFrame = p_reinitialize;

		g2d_nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, GRenderersCommon.DEFAULT_CONSTANTS, 1);
		
		g2d_nativeContext.setVertexBufferAt(0, g2d_geometryBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
		g2d_nativeContext.setVertexBufferAt(1, g2d_uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);

		if (g2d_activeAlpha) g2d_nativeContext.setVertexBufferAt(2, g2d_constantIndexBufferAlpha, 0, Context3DVertexBufferFormat.FLOAT_4);
        else g2d_nativeContext.setVertexBufferAt(2, g2d_constantIndexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
		
		g2d_quadCount = 0;
		g2d_activeNativeTexture = null;
		g2d_activeFiltering = -1;
		g2d_activeFilter = null;
	}

    inline public function draw(p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float, p_red:Float, p_green:Float, p_blue:Float, p_alpha:Float, p_texture:GContextTexture, p_filter:GFilter, p_overrideSource:Bool, p_sourceX:Float, p_sourceY:Float, p_sourceWidth:Float, p_sourceHeight:Float):Void {
		var notSameTexture:Bool = g2d_activeNativeTexture != p_texture.nativeTexture;
		var notSameFiltering:Bool = g2d_activeFiltering != p_texture.getFilteringType();
		var useAlpha:Bool = !g2d_useSeparatedAlphaPipeline || !(p_red==1 && p_green==1 && p_blue==1 && p_alpha==1);
		var notSameUseAlpha:Bool = g2d_activeAlpha != useAlpha;
		var notSameAtf:Bool = g2d_activeAtf != p_texture.atfType;
		var notSameFilter:Bool = g2d_activeFilter != p_filter;

		if (notSameTexture || notSameFiltering || notSameUseAlpha || notSameAtf || notSameFilter) {
            // If any state changed we need to push remaining stuff to backbuffer
			if (g2d_activeNativeTexture != null) push();
			// Texture has changed
			if (notSameTexture) {
				g2d_activeNativeTexture = p_texture.nativeTexture;
				g2d_nativeContext.setTextureAt(0, p_texture.nativeTexture);
			}
			// Any flag affecting shader has changed
			if (notSameFiltering || notSameUseAlpha || notSameAtf || notSameFilter) {
                // Set filtering
				g2d_activeFiltering = p_texture.getFilteringType();
                // Set alpha usage
				g2d_activeAlpha = useAlpha;
                if (g2d_activeAlpha) g2d_nativeContext.setVertexBufferAt(2, g2d_constantIndexBufferAlpha, 0, Context3DVertexBufferFormat.FLOAT_4);
                else g2d_nativeContext.setVertexBufferAt(2, g2d_constantIndexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
                // Set ATF type
				g2d_activeAtf = p_texture.atfType;
                // Set filter
				if (g2d_activeFilter != null) g2d_activeFilter.clear(g2d_context);
				g2d_activeFilter = p_filter;
				if (g2d_activeFilter != null) g2d_activeFilter.bind(g2d_context, p_texture);
				g2d_nativeContext.setProgram(getCachedProgram(g2d_activeAlpha, true, g2d_activeFiltering, g2d_activeAtf, g2d_activeFilter));
			}
		}

        var uvx:Float;
        var uvy:Float;
        var uvsx:Float;
        var uvsy:Float;
        var sx:Float;
        var sy:Float;
        var px:Float;
        var py:Float;
        if (p_overrideSource) {
            uvx = p_sourceX/p_texture.gpuWidth;
            uvy = p_sourceY/p_texture.gpuHeight;
            uvsx = p_sourceWidth/p_texture.gpuWidth;
            uvsy = p_sourceHeight/p_texture.gpuHeight;
            sx = p_sourceWidth;
            sy = p_sourceHeight;
            px = 0;
            py = 0;
        } else {
            uvx = p_texture.uvX;
            uvy = p_texture.uvY;
            uvsx = p_texture.uvScaleX;
            uvsy = p_texture.uvScaleY;
            sx = p_texture.width;
            sy = p_texture.height;
            px = p_texture.pivotX;
            py = p_texture.pivotY;
        }
		
		// Alpha is active and texture uses premultiplied source
		if (g2d_activeAlpha && p_texture.premultiplied) {
			p_red*=p_alpha;
			p_green*=p_alpha;
			p_blue*=p_alpha;
		}

        if (g2d_useFastMem) {
		    g2d_constantOffset = g2d_quadCount * (g2d_activeAlpha ? 64 : 48);

            Memory.setFloat(g2d_constantOffset, p_a);
            Memory.setFloat(4 + g2d_constantOffset, p_c);
            Memory.setFloat(8 + g2d_constantOffset, p_b);
            Memory.setFloat(12 + g2d_constantOffset, p_d);

            Memory.setFloat(16 + g2d_constantOffset, p_tx);
            Memory.setFloat(20 + g2d_constantOffset, p_ty);
            Memory.setFloat(24 + g2d_constantOffset, sx);
            Memory.setFloat(28 + g2d_constantOffset, sy);

            Memory.setFloat(32 + g2d_constantOffset, uvx);
            Memory.setFloat(36 + g2d_constantOffset, uvy);
            Memory.setFloat(40 + g2d_constantOffset, uvsx);
            Memory.setFloat(44 + g2d_constantOffset, uvsy);

            if (g2d_activeAlpha) {
                Memory.setFloat(48 + g2d_constantOffset, p_red);
                Memory.setFloat(52 + g2d_constantOffset, p_green);
                Memory.setFloat(56 + g2d_constantOffset, p_blue);
                Memory.setFloat(60 + g2d_constantOffset, p_alpha);
            }
        } else {
            g2d_constantOffset = g2d_quadCount * (g2d_activeAlpha ? 16 : 12);

            g2d_vertexConstants[g2d_constantOffset] = p_a;
            g2d_vertexConstants[g2d_constantOffset+1] = p_c;
            g2d_vertexConstants[g2d_constantOffset+2] = p_b;
            g2d_vertexConstants[g2d_constantOffset+3] = p_d;

            g2d_vertexConstants[g2d_constantOffset+4] = p_tx;
            g2d_vertexConstants[g2d_constantOffset+5] = p_ty;
            g2d_vertexConstants[g2d_constantOffset+6] = sx;
            g2d_vertexConstants[g2d_constantOffset+7] = sy;

            g2d_vertexConstants[g2d_constantOffset+8] = uvx;
            g2d_vertexConstants[g2d_constantOffset+9] = uvy;
            g2d_vertexConstants[g2d_constantOffset+10] = uvsx;
            g2d_vertexConstants[g2d_constantOffset+11] = uvsy;

            if (g2d_activeAlpha) {
                g2d_vertexConstants[g2d_constantOffset+12] = p_red;
                g2d_vertexConstants[g2d_constantOffset+13] = p_green;
                g2d_vertexConstants[g2d_constantOffset+14] = p_blue;
                g2d_vertexConstants[g2d_constantOffset+15] = p_alpha;
            }
        }

		++g2d_quadCount;
		
		if (g2d_quadCount == (g2d_activeAlpha ? BATCH_SIZE_ALPHA : BATCH_SIZE)) push();
	}
	
	inline public function push():Void {	
		if (g2d_quadCount > 0) {
            GStats.drawCalls++;
            if (g2d_useFastMem) {
                g2d_nativeContext.setProgramConstantsFromByteArray(Context3DProgramType.VERTEX, CONSTANTS_OFFSET, BATCH_CONSTANTS, g2d_fastMemArray, 0);
            } else {
			    g2d_nativeContext.setProgramConstantsFromVector(Context3DProgramType.VERTEX, CONSTANTS_OFFSET, g2d_vertexConstants, BATCH_CONSTANTS);
            }

			g2d_nativeContext.drawTriangles(g2d_indexBuffer, 0, g2d_quadCount*2);
			g2d_quadCount = 0;
		}
	}

	inline public function clear():Void {
		g2d_nativeContext.setTextureAt(0, null);
		g2d_nativeContext.setVertexBufferAt(0, null);
		g2d_nativeContext.setVertexBufferAt(1, null);
		g2d_nativeContext.setVertexBufferAt(2, null);
		
		g2d_activeNativeTexture = null;
		
		if (g2d_activeFilter != null) {
            g2d_activeFilter.clear(g2d_context);
		    g2d_activeFilter = null;
        }
	}
}