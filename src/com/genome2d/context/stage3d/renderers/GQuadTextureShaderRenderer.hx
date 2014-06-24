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
import flash.utils.Dictionary;
import flash.utils.Endian;

class GQuadTextureShaderRenderer implements IGRenderer
{
	inline static private var CONSTANTS_OFFSET:Int = 5;
	private var MAX_CONSTANTS:Int;

	inline static private var TRANSFORM_PER_VERTEX:Int = 1;
	private var BATCH_SIZE:Int;

    inline static private var TRANSFORM_PER_VERTEX_ALPHA:Int = TRANSFORM_PER_VERTEX+1;
    private var BATCH_SIZE_ALPHA:Int;
	
	inline static private var VERTEX_SHADER_CODE:String =
			"mov vt0, va0						\n" +
				
			"mov vt1.x, vc[va2.x].w				\n" +
			"add vt1.x, vt1.x, vc4.z			\n" +
			"mov vt1, vc[vt1.x]					\n" +

			"mul vt5, va0.xy, vt1.xy			\n" +

			// Pivot
			"sub vt5, vt5.xy, vt1.zw			\n" +
			"mov vt4.x, vc[va2.x].z				\n" +

			"sin vt1.x, vt4.x					\n" +
			"cos vt1.y, vt4.x					\n" +
				
			"mul vt2.x, vt5.x, vt1.y			\n" +
			"mul vt3.y, vt5.y, vt1.x			\n" +
			"sub vt4.x, vt2.x, vt3.y			\n" +
				
			"mul vt2.y, vt5.y, vt1.y			\n" +
			"mul vt3.x, vt5.x, vt1.x			\n" +
			"add vt4.y, vt2.y, vt3.x			\n" +

			"add vt1, vt4.xy, vc[va2.x].xy		\n" +

			"mov vt1.zw, vt0.zw					\n" +
			"m44 op, vt1, vc0					\n" +

			"mov vt6.x, vc[va2.x].w				\n" +

			"mul vt0.xy, va1.xy, vc[vt6.x].zw	\n" +
			"add vt0.xy, vt0.xy, vc[vt6.x].xy	\n" +

			"mov v0, vt0";
		
	inline static private var VERTEX_SHADER_CODE_ALPHA:String = VERTEX_SHADER_CODE + "\nmov v1, vc[va2.y]";

    public var g2d_useFastMem:Bool;
    public var g2d_fastMemArray:ByteArray;
	
	private var g2d_geometryBuffer : VertexBuffer3D;
	private var g2d_uvBuffer : VertexBuffer3D;

	private var g2d_constantIndexBuffer : VertexBuffer3D;
    private var g2d_constantIndexAlphaBuffer : VertexBuffer3D;

	private var g2d_indexBuffer : IndexBuffer3D;
	
	private var g2d_initializedThisFrame:Bool = false;
	private var g2d_quadCount:Int = 0;
	private var g2d_activeNativeTexture:TextureBase;
	private var g2d_activeFiltering:Int;
	private var g2d_activeAlpha:Bool = false;
	private var g2d_activeAtf:String = "";
	private var g2d_activeFilter:GFilter;
	private var g2d_activeTextureId:Int;
    private var g2d_activeTextureWidth:Float;
    private var g2d_activeTextureHeight:Float;
	private var g2d_textureIndex:Int = 0;
	
	private var g2d_useSeparatedAlphaPipeline:Bool;
	
	private var g2d_cachedPrograms:Dictionary;
    private var g2d_cachedProgramIds:Dictionary;
	private var g2d_vertexConstants:Vector<Float>;

	private var g2d_vertexShaderCode:ByteArray;
	private var g2d_vertexShaderAlphaCode:ByteArray;

    private var g2d_constantOffset:Int;

    private var g2d_context:GStage3DContext;
	private var g2d_nativeContext:Context3D;

    static inline private var TRUE:String = "true";
    static inline private var FALSE:String = "false";
	
	public function new(p_useFastMem:Bool, p_fastMemArray:ByteArray) {
        MAX_CONSTANTS = (GRenderersCommon.AGAL_VERSION == 2) ? 250-CONSTANTS_OFFSET : 128-CONSTANTS_OFFSET;
        BATCH_SIZE = untyped __int__(MAX_CONSTANTS/TRANSFORM_PER_VERTEX);
        BATCH_SIZE_ALPHA = untyped __int__(MAX_CONSTANTS/TRANSFORM_PER_VERTEX_ALPHA);

        g2d_useFastMem = p_useFastMem;
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
            program.upload((p_alpha) ? g2d_vertexShaderAlphaCode : g2d_vertexShaderCode, GRenderersCommon.getTexturedShaderCode(p_repeat, p_filtering, p_alpha, p_atf, p_filter));
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
		g2d_vertexConstants = new Vector<Float>(MAX_CONSTANTS * 4);

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
            var array:Array<Float> = [index, index, index, index];
			registerIndices = registerIndices.concat(Vector.ofArray(array));
			
            index = CONSTANTS_OFFSET + (i * TRANSFORM_PER_VERTEX_ALPHA);
            var arrayAlpha:Array<Float> = [index, index + 1, index, index + 1, index, index + 1, index, index + 1];
            registerIndicesAlpha = registerIndicesAlpha.concat(Vector.ofArray(arrayAlpha));
		}
		
		g2d_geometryBuffer = g2d_nativeContext.createVertexBuffer(4*BATCH_SIZE, 2);
		g2d_geometryBuffer.uploadFromVector(vertices, 0, 4*BATCH_SIZE);
		
		g2d_uvBuffer = g2d_nativeContext.createVertexBuffer(4*BATCH_SIZE, 2);
		g2d_uvBuffer.uploadFromVector(uvs, 0, 4*BATCH_SIZE);
		
		g2d_constantIndexBuffer = g2d_nativeContext.createVertexBuffer(4*BATCH_SIZE, TRANSFORM_PER_VERTEX);
		g2d_constantIndexBuffer.uploadFromVector(registerIndices, 0, 4*BATCH_SIZE);

        g2d_constantIndexAlphaBuffer = g2d_nativeContext.createVertexBuffer(4*BATCH_SIZE, TRANSFORM_PER_VERTEX_ALPHA);
        g2d_constantIndexAlphaBuffer.uploadFromVector(registerIndicesAlpha, 0, 4*BATCH_SIZE);

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
		g2d_nativeContext.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, GRenderersCommon.DEFAULT_CONSTANTS, 1);
		
		g2d_nativeContext.setVertexBufferAt(0, g2d_geometryBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
		g2d_nativeContext.setVertexBufferAt(1, g2d_uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);

		if (g2d_activeAlpha) {
            g2d_nativeContext.setVertexBufferAt(2, g2d_constantIndexAlphaBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
        } else {
            g2d_nativeContext.setVertexBufferAt(2, g2d_constantIndexBuffer, 0, Context3DVertexBufferFormat.FLOAT_1);
        }
		
		g2d_quadCount = 0;
		g2d_activeNativeTexture = null;
		g2d_activeFiltering = -1;
		g2d_activeFilter = null;
		g2d_textureIndex = MAX_CONSTANTS;
		g2d_activeTextureId = 0;
	}
	
	inline public function draw(p_x:Float, p_y:Float, p_scaleX:Float, p_scaleY:Float, p_rotation:Float, p_red:Float, p_green:Float, p_blue:Float, p_alpha:Float, p_texture:GContextTexture, p_filter:GFilter, p_overrideSource:Bool, p_sourceX:Float, p_sourceY:Float, p_sourceWidth:Float, p_sourceHeight:Float):Void {
		var notSameTexture:Bool = g2d_activeNativeTexture != p_texture.nativeTexture;
		var notSameFiltering:Bool = g2d_activeFiltering != p_texture.getFilteringType();
		var useAlpha:Bool = !g2d_useSeparatedAlphaPipeline || !(p_red == 1 && p_green == 1 && p_blue == 1 && p_alpha == 1);
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
                if (g2d_activeAlpha) {
                    g2d_nativeContext.setVertexBufferAt(2, g2d_constantIndexAlphaBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
                } else {
                    g2d_nativeContext.setVertexBufferAt(2, g2d_constantIndexBuffer, 0, Context3DVertexBufferFormat.FLOAT_1);
                }
                // Set ATF type
				g2d_activeAtf = p_texture.atfType;
                // Set filter
				if (g2d_activeFilter != null) g2d_activeFilter.clear(g2d_context);
				g2d_activeFilter = p_filter;
				if (g2d_activeFilter != null) g2d_activeFilter.bind(g2d_context, p_texture);
				g2d_nativeContext.setProgram(getCachedProgram(g2d_activeAlpha, p_texture.g2d_repeatable, g2d_activeFiltering, g2d_activeAtf, g2d_activeFilter));
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
            sx = p_sourceWidth * p_scaleX;
            sy = p_sourceHeight * p_scaleY;
            px = 0;
            py = 0;
        } else {
            uvx = p_texture.uvX;
            uvy = p_texture.uvY;
            uvsx = p_texture.uvScaleX;
            uvsy = p_texture.uvScaleY;
            sx = p_texture.width * p_scaleX;
            sy = p_texture.height * p_scaleY;
            px = p_texture.pivotX * p_scaleX;
            py = p_texture.pivotY * p_scaleY;
        }

        var notSameTextureId:Bool = (g2d_activeTextureId != p_texture.g2d_contextId) || (g2d_activeTextureWidth != p_texture.width*p_scaleX || g2d_activeTextureHeight != p_texture.height*p_scaleY);
		if (notSameTextureId) {
			g2d_textureIndex -= 2;
			var textureOffset:Int;
			if (g2d_useFastMem) {
				textureOffset = g2d_textureIndex * 16;

				Memory.setFloat(textureOffset, uvx);
			    Memory.setFloat(textureOffset + 4, uvy);
				Memory.setFloat(textureOffset + 8, uvsx);
				Memory.setFloat(textureOffset + 12, uvsy);
				
				Memory.setFloat(textureOffset + 16, sx);
			    Memory.setFloat(textureOffset + 20, sy);
				Memory.setFloat(textureOffset + 24, px);
				Memory.setFloat(textureOffset + 28, py);
			} else {
				textureOffset = g2d_textureIndex * 4;
				
				g2d_vertexConstants[textureOffset] = uvx;
				g2d_vertexConstants[textureOffset + 1] = uvy;
				g2d_vertexConstants[textureOffset + 2] = uvsx;
				g2d_vertexConstants[textureOffset + 3] = uvsy;
				
				g2d_vertexConstants[textureOffset + 4] = sx;
				g2d_vertexConstants[textureOffset + 5] = sy;
				g2d_vertexConstants[textureOffset + 6] = px;
				g2d_vertexConstants[textureOffset + 7] = py;
			}
			g2d_activeTextureId = p_texture.g2d_contextId;
            g2d_activeTextureWidth = sx;
            g2d_activeTextureHeight = sy;
		}
		
		// Alpha is active and texture uses premultiplied source
		if (g2d_activeAlpha && p_texture.premultiplied) {
			p_red*=p_alpha;
			p_green*=p_alpha;
			p_blue*=p_alpha;
		}

        if (g2d_useFastMem) {
		    g2d_constantOffset = g2d_quadCount * (g2d_activeAlpha ? 32 : 16);

            Memory.setFloat(g2d_constantOffset, p_x);
            Memory.setFloat(4 + g2d_constantOffset, p_y);
            Memory.setFloat(8 + g2d_constantOffset, p_rotation);
            Memory.setFloat(12 + g2d_constantOffset, g2d_textureIndex + CONSTANTS_OFFSET);

            if (g2d_activeAlpha) {
                Memory.setFloat(16 + g2d_constantOffset, p_red);
                Memory.setFloat(20 + g2d_constantOffset, p_green);
                Memory.setFloat(24 + g2d_constantOffset, p_blue);
                Memory.setFloat(28 + g2d_constantOffset, p_alpha);
            }
        } else {
            g2d_constantOffset = g2d_quadCount * (g2d_activeAlpha ? 8 : 4);

            g2d_vertexConstants[g2d_constantOffset] = p_x;
            g2d_vertexConstants[g2d_constantOffset + 1] = p_y;
			g2d_vertexConstants[g2d_constantOffset + 2] = p_rotation;
            g2d_vertexConstants[g2d_constantOffset + 3] = g2d_textureIndex + CONSTANTS_OFFSET;
			
            if (g2d_activeAlpha) {
                g2d_vertexConstants[g2d_constantOffset + 4] = p_red;
                g2d_vertexConstants[g2d_constantOffset + 5] = p_green;
                g2d_vertexConstants[g2d_constantOffset + 6] = p_blue;
                g2d_vertexConstants[g2d_constantOffset + 7] = p_alpha;
            }
        }

		++g2d_quadCount;

        // Check if there is place for maximum information about the next quad
		if (g2d_quadCount >= untyped __int__((g2d_textureIndex - 2) / (g2d_activeAlpha ? TRANSFORM_PER_VERTEX_ALPHA : TRANSFORM_PER_VERTEX))) push();
	}
	
	inline public function push():Void {
		if (g2d_quadCount > 0) {
            GStats.drawCalls++;
            if (g2d_useFastMem) {
                g2d_nativeContext.setProgramConstantsFromByteArray(Context3DProgramType.VERTEX, CONSTANTS_OFFSET, MAX_CONSTANTS, g2d_fastMemArray, 0);
            } else {
			    g2d_nativeContext.setProgramConstantsFromVector(Context3DProgramType.VERTEX, CONSTANTS_OFFSET, g2d_vertexConstants, MAX_CONSTANTS);
            }
			g2d_nativeContext.drawTriangles(g2d_indexBuffer, 0, g2d_quadCount * 2);
			g2d_quadCount = 0;
			g2d_textureIndex = MAX_CONSTANTS;
			g2d_activeTextureId = 0;
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