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
import com.genome2d.context.stats.GStats;
import flash.utils.Dictionary;
import flash.Lib;
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
import flash.utils.Endian;
import flash.Memory;

class GQuadTextureBufferGPURenderer implements IGRenderer
{
	inline static private var BATCH_SIZE:Int = 5000;
	inline static private var DATA_PER_VERTEX:Int = 2;
	inline static private var TRANSFORM_PER_VERTEX_ALPHA:Int = 10;
	inline static private var TRANSFORM_PER_VERTEX:Int = 9;
	
	inline static private var VERTEX_SHADER_CODE:String =
        "mov vt0, va0						\n" +

        "mul vt2, va0.xy, va1.zw			\n" +

        "sub vt2, vt2.xy, va3.xy			\n" +

        "mov vt4.x, va2.z					\n" +

        "sin vt1.x, vt4.x					\n" +
        "cos vt1.y, vt4.x					\n" +

        "mul vt3.x, vt2.x, vt1.y			\n" +
        "mul vt4.y, vt2.y, vt1.x			\n" +
        "sub vt5.x, vt3.x, vt4.y			\n" +

        "mul vt3.y, vt2.y, vt1.y			\n" +
        "mul vt4.x, vt2.x, vt1.x			\n" +
        "add vt5.y, vt3.y, vt4.x			\n" +

        "add vt1, vt5.xy, va1.xy			\n" +

        "mov vt1.zw, vt0.zw					\n" +
        "m44 op, vt1, vc0					\n" +

        "mov v0, va2						";
	
	inline static private var VERTEX_SHADER_CODE_ALPHA:String = VERTEX_SHADER_CODE + "\nmov v1, va4";
			
	private var g2d_useFastMem:Bool;
    private var g2d_fastMemArray:ByteArray;

	private var g2d_geometryBuffer:VertexBuffer3D;
    private var g2d_transformBufferAlpha:VertexBuffer3D;
    private var g2d_transformBuffer:VertexBuffer3D;
	
	private var g2d_transformVector:Vector<Float>;
	
	private var g2d_indexBuffer:IndexBuffer3D;
	
	private var g2d_quadCount:Int = 0;
	
	private var g2d_initializedThisFrame:Bool;
	private var g2d_activeTexture:TextureBase;
	private var g2d_activeAlpha:Bool = false;
	private var g2d_activeAtf:String = "";
	private var g2d_activeFilter:GFilter;
	private var g2d_activeFiltering:Int;

    private var g2d_context:GStage3DContext;
	private var g2d_nativeContext:Context3D;

	private var g2d_cachedPrograms:Dictionary;
	private var g2d_vertexShaderCode:ByteArray;
	private var g2d_vertexShaderAlphaCode:ByteArray;
	
	private var g2d_useSeparatedAlphaPipeline:Bool = true;

    public function new(p_useFastMem:Bool, p_fastMemArray:ByteArray) {
        g2d_useFastMem = p_useFastMem;
        g2d_fastMemArray = p_fastMemArray;
    }
	
	private function getCachedProgram(p_repeat:String, p_filtering:Int, p_alpha:Bool, p_atf:String, p_filter:GFilter):Program3D {
		var filterId:String = (p_filter != null) ? p_filter.id : "";
        if (untyped g2d_cachedPrograms.hasOwnProperty(p_repeat + String(p_filtering) + String(p_alpha) + p_atf + filterId)) return untyped g2d_cachedPrograms[p_repeat + String(p_filtering) + String(p_alpha) + p_atf + filterId];
		
		var program:Program3D = g2d_nativeContext.createProgram();
		program.upload((p_alpha) ? g2d_vertexShaderAlphaCode : g2d_vertexShaderCode, GRenderersCommon.getTexturedShaderCode(false, p_filtering, p_alpha, p_atf, p_filter));
		untyped g2d_cachedPrograms[p_repeat + String(p_filtering) + String(p_alpha) + p_atf + filterId] = program;
		
		return program;
	}

	public function initialize(p_context:GStage3DContext):Void {
        g2d_context = p_context;
		g2d_nativeContext = g2d_context.getNativeContext();

		g2d_cachedPrograms = new Dictionary(false);
		
		var agal:AGALMiniAssembler = new AGALMiniAssembler();
		agal.assemble("vertex", VERTEX_SHADER_CODE, GRenderersCommon.AGAL_VERSION);
		g2d_vertexShaderCode = agal.agalcode;
		agal.assemble("vertex", VERTEX_SHADER_CODE_ALPHA, GRenderersCommon.AGAL_VERSION);
		g2d_vertexShaderAlphaCode = agal.agalcode;
		var vertices:Vector<Float> = new Vector<Float>(BATCH_SIZE*8);
        var normalizedVertices:Vector<Float> = GRenderersCommon.NORMALIZED_VERTICES;
		for (i in 0...BATCH_SIZE) {
            var index:Int = i*8;
			vertices[index] = normalizedVertices[0];
            vertices[index+1] = normalizedVertices[1];
            vertices[index+2] = normalizedVertices[2];
            vertices[index+3] = normalizedVertices[3];
            vertices[index+4] = normalizedVertices[4];
            vertices[index+5] = normalizedVertices[5];
            vertices[index+6] = normalizedVertices[6];
            vertices[index+7] = normalizedVertices[7];
		}

		g2d_geometryBuffer = g2d_nativeContext.createVertexBuffer(4 * BATCH_SIZE, DATA_PER_VERTEX);
		g2d_geometryBuffer.uploadFromVector(vertices, 0, 4 * BATCH_SIZE);

		g2d_transformVector = new Vector<Float>(4 * BATCH_SIZE * TRANSFORM_PER_VERTEX);
		g2d_transformBufferAlpha = g2d_nativeContext.createVertexBuffer(4 * BATCH_SIZE, TRANSFORM_PER_VERTEX_ALPHA);
		g2d_transformBuffer = g2d_nativeContext.createVertexBuffer(4 * BATCH_SIZE, TRANSFORM_PER_VERTEX);

		var indices:Vector<UInt> = new Vector<UInt>(BATCH_SIZE*6);
		for (i in 0...BATCH_SIZE) {
            var index:Int = i*6;
			indices[index] = 4*i;
            indices[index+1] = 4*i+1;
            indices[index+2] = 4*i+2;
            indices[index+3] = 4*i;
            indices[index+4] = 4*i+2;
            indices[index+5] = 4*i+3;
		}

		g2d_indexBuffer = g2d_nativeContext.createIndexBuffer(6 * BATCH_SIZE);
		g2d_indexBuffer.uploadFromVector(indices, 0, 6 * BATCH_SIZE);

		g2d_quadCount = 0;

		g2d_activeFiltering = GTextureFilteringType.LINEAR;
	}
	
	inline public function bind(p_context:GStage3DContext, p_reinitialize:Bool):Void {
		if (g2d_cachedPrograms == null || (p_reinitialize && !g2d_initializedThisFrame)) initialize(p_context);
		g2d_initializedThisFrame = p_reinitialize;

		g2d_nativeContext.setProgram(getCachedProgram("true", g2d_activeFiltering, g2d_activeAlpha, g2d_activeAtf, g2d_activeFilter));
		
		g2d_nativeContext.setVertexBufferAt(0, g2d_geometryBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
		
		g2d_quadCount = 0;
		g2d_activeTexture = null;
	}
	
	inline public function draw(p_x:Float, p_y:Float, p_scaleX:Float, p_scaleY:Float, p_rotation:Float, p_red:Float, p_green:Float, p_blue:Float, p_alpha:Float, p_texture:GContextTexture, p_filter:GFilter):Void {
		var contextTexture:TextureBase = p_texture.nativeTexture;
		var notSameTexture:Bool = g2d_activeTexture != contextTexture;
		var notSameFiltering:Bool = g2d_activeFiltering != p_texture.g2d_filteringType;
		var useAlpha:Bool = g2d_useSeparatedAlphaPipeline && !(p_red==1 && p_green==1 && p_blue==1 && p_alpha==1);
		var notSameUseAlpha:Bool = g2d_activeAlpha != useAlpha;
		var notSameAtf:Bool = g2d_activeAtf != p_texture.atfType;
		var notSameFilter:Bool = g2d_activeFilter != p_filter;

		if (notSameTexture || notSameFiltering || notSameUseAlpha || notSameAtf || notSameFilter) {
			if (g2d_activeTexture != null) push();
			
			if (notSameTexture) {
				g2d_activeTexture = p_texture.nativeTexture;
				g2d_nativeContext.setTextureAt(0, g2d_activeTexture);
			}
			
			if (notSameFiltering || notSameUseAlpha || notSameAtf || notSameFilter) {
				g2d_activeFiltering = p_texture.g2d_filteringType;
				g2d_activeAlpha = useAlpha;
				g2d_activeAtf = p_texture.atfType;
				if (g2d_activeFilter != null) g2d_activeFilter.clear(g2d_context);
				g2d_activeFilter = p_filter;
				if (g2d_activeFilter != null) g2d_activeFilter.bind(g2d_context, p_texture);
				g2d_nativeContext.setProgram(getCachedProgram("true", g2d_activeFiltering, g2d_activeAlpha, g2d_activeAtf, g2d_activeFilter));
			}
		}

        var red:Int = 0;
        var green:Int = 0;
        var blue:Int = 0;
        var alpha:Int = 0;
        if (g2d_activeAlpha) {
            if (p_texture.premultiplied) {
                p_red*=p_alpha;
                p_green*=p_alpha;
                p_blue*=p_alpha;
            }
            red = untyped __int__(p_red*255);
            green = untyped __int__(p_green*255);
            blue = untyped __int__(p_blue*255);
            alpha = untyped __int__(p_alpha*255);
        }

		/**/
		var w:Float = p_texture.width * p_scaleX;
		var h:Float = p_texture.height * p_scaleY;
        var px:Float = p_texture.pivotX * p_scaleX;
        var py:Float = p_texture.pivotY * p_scaleY;
		var t:Int = (g2d_activeAlpha) ? TRANSFORM_PER_VERTEX_ALPHA : TRANSFORM_PER_VERTEX;
		
		if (g2d_useFastMem) {
			t = t << 2;
			var index:Int = (t << 2) * g2d_quadCount;

			Memory.setFloat(0 + index, p_x);
			Memory.setFloat(4 + index, p_y);
			Memory.setFloat(8 + index, w);
			Memory.setFloat(12 + index, h);
			Memory.setFloat(16 + index, p_texture.uvX);
			Memory.setFloat(20 + index, p_texture.uvY + p_texture.uvScaleY);
			Memory.setFloat(24 + index, p_rotation);
			Memory.setFloat(28 + index, px);
			Memory.setFloat(32 + index, py);
			if (g2d_activeAlpha) {
                Memory.setByte(36 + index, red);
                Memory.setByte(37 + index, green);
                Memory.setByte(38 + index, blue);
                Memory.setByte(39 + index, alpha);
			}
			
			index += t;
			
			Memory.setFloat(0 + index, p_x);
			Memory.setFloat(4 + index, p_y);
			Memory.setFloat(8 + index, w);
			Memory.setFloat(12 + index, h);
			Memory.setFloat(16 + index, p_texture.uvX);
			Memory.setFloat(20 + index, p_texture.uvY);
			Memory.setFloat(24 + index, p_rotation);
			Memory.setFloat(28 + index, px);
			Memory.setFloat(32 + index, py);
			if (g2d_activeAlpha) {
                Memory.setByte(36 + index, red);
                Memory.setByte(37 + index, green);
                Memory.setByte(38 + index, blue);
                Memory.setByte(39 + index, alpha);
			}
			
			index += t;

			Memory.setFloat(0 + index, p_x);
			Memory.setFloat(4 + index, p_y);
			Memory.setFloat(8 + index, w);
			Memory.setFloat(12 + index, h);
			Memory.setFloat(16 + index, p_texture.uvX + p_texture.uvScaleX);
			Memory.setFloat(20 + index, p_texture.uvY);
			Memory.setFloat(24 + index, p_rotation);
			Memory.setFloat(28 + index, px);
			Memory.setFloat(32 + index, py);
			if (g2d_activeAlpha) {
                Memory.setByte(36 + index, red);
                Memory.setByte(37 + index, green);
                Memory.setByte(38 + index, blue);
                Memory.setByte(39 + index, alpha);
			}
			
			index += t;
			
			Memory.setFloat(0 + index, p_x);
			Memory.setFloat(4 + index, p_y);
			Memory.setFloat(8 + index, w);
			Memory.setFloat(12 + index, h);
			Memory.setFloat(16 + index, p_texture.uvX + p_texture.uvScaleX);
			Memory.setFloat(20 + index, p_texture.uvY + p_texture.uvScaleY);
			Memory.setFloat(24 + index, p_rotation);
			Memory.setFloat(28 + index, px);
			Memory.setFloat(32 + index, py);
			if (g2d_activeAlpha) {
                Memory.setByte(36 + index, red);
                Memory.setByte(37 + index, green);
                Memory.setByte(38 + index, blue);
                Memory.setByte(39 + index, alpha);
			}
		} else {
			var index:Int = (t << 2) * g2d_quadCount;
		
			g2d_transformVector[index] = p_x;
			g2d_transformVector[index + 1] = p_y;
			g2d_transformVector[index + 2] = w;
			g2d_transformVector[index + 3] = h;
			g2d_transformVector[index + 4] = p_texture.uvX;
			g2d_transformVector[index + 5] = p_texture.uvY+p_texture.uvScaleY;
			g2d_transformVector[index + 6] = p_rotation;
			g2d_transformVector[index + 7] = px;
			g2d_transformVector[index + 8] = py;
			if (g2d_activeAlpha) {
				g2d_transformVector[index + 9] = p_red;
				g2d_transformVector[index + 10] = p_green;
				g2d_transformVector[index + 11] = p_blue;
				g2d_transformVector[index + 12] = p_alpha;
			}			
				
			index += t;

			g2d_transformVector[index] = p_x;
			g2d_transformVector[index + 1] = p_y;
			g2d_transformVector[index + 2] = w;
			g2d_transformVector[index + 3] = h;
			g2d_transformVector[index + 4] = p_texture.uvX;
			g2d_transformVector[index + 5] = p_texture.uvY;
			g2d_transformVector[index + 6] = p_rotation;
			g2d_transformVector[index + 7] = px;
			g2d_transformVector[index + 8] = py;
			if (g2d_activeAlpha) {
				g2d_transformVector[index + 9] = p_red;
				g2d_transformVector[index + 10] = p_green;
				g2d_transformVector[index + 11] = p_blue;
				g2d_transformVector[index + 12] = p_alpha;
			}			
				
			index += t;

			g2d_transformVector[index] = p_x;
			g2d_transformVector[index + 1] = p_y;
			g2d_transformVector[index + 2] = w;
			g2d_transformVector[index + 3] = h;
			g2d_transformVector[index + 4] = p_texture.uvX+p_texture.uvScaleX;
			g2d_transformVector[index + 5] = p_texture.uvY;
			g2d_transformVector[index + 6] = p_rotation;
			g2d_transformVector[index + 7] = px;
			g2d_transformVector[index + 8] = py;
			if (g2d_activeAlpha) {
				g2d_transformVector[index + 9] = p_red;
				g2d_transformVector[index + 10] = p_green;
				g2d_transformVector[index + 11] = p_blue;
				g2d_transformVector[index + 12] = p_alpha;
			}			
			
			index += t;

			g2d_transformVector[index] = p_x;
			g2d_transformVector[index + 1] = p_y;
			g2d_transformVector[index + 2] = w;
			g2d_transformVector[index + 3] = h;
			g2d_transformVector[index + 4] = p_texture.uvX+p_texture.uvScaleX;
			g2d_transformVector[index + 5] = p_texture.uvY+p_texture.uvScaleY;
			g2d_transformVector[index + 6] = p_rotation;
			g2d_transformVector[index + 7] = px;
			g2d_transformVector[index + 8] = py;
			if (g2d_activeAlpha) {
				g2d_transformVector[index + 9] = p_red;
				g2d_transformVector[index + 10] = p_green;
				g2d_transformVector[index + 11] = p_blue;
				g2d_transformVector[index + 12] = p_alpha;
			}			
		}
		/**/
		g2d_quadCount++;
		
		if (g2d_quadCount == BATCH_SIZE) push();
	}
	
	inline public function push():Void {
        if (g2d_quadCount > 0) {
            GStats.drawCalls++;
            var buffer:VertexBuffer3D = (g2d_activeAlpha) ? g2d_transformBufferAlpha : g2d_transformBuffer;
            if (g2d_useFastMem) {
                buffer.uploadFromByteArray(g2d_fastMemArray, 0, 0, 4 * BATCH_SIZE);
            } else {
                buffer.uploadFromVector(g2d_transformVector, 0, 4 * BATCH_SIZE);
            }

            g2d_nativeContext.setVertexBufferAt(1, buffer, 0, Context3DVertexBufferFormat.FLOAT_4);
            g2d_nativeContext.setVertexBufferAt(2, buffer, 4, Context3DVertexBufferFormat.FLOAT_3);
            g2d_nativeContext.setVertexBufferAt(3, buffer, 7, Context3DVertexBufferFormat.FLOAT_2);
            if (g2d_activeAlpha) {
                if (g2d_useFastMem) g2d_nativeContext.setVertexBufferAt(4, buffer, 9, Context3DVertexBufferFormat.BYTES_4);
                else g2d_nativeContext.setVertexBufferAt(4, buffer, 9, Context3DVertexBufferFormat.FLOAT_4);
            } else {
                g2d_nativeContext.setVertexBufferAt(4, null);
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
		g2d_nativeContext.setVertexBufferAt(3, null);
		g2d_nativeContext.setVertexBufferAt(4, null);
		
		g2d_activeTexture = null;
	}
	/**/
}