/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.stage3d.renderers;

import com.genome2d.textures.GTexture;
import com.genome2d.textures.GTextureFilteringType;
import flash.display3D.textures.TextureBase;
import com.genome2d.context.stage3d.GStage3DContext;
import com.genome2d.context.stage3d.GStage3DContext;
import com.genome2d.context.stage3d.GStage3DContext;
import com.genome2d.geom.GMatrix3D;
import com.genome2d.textures.GContextTexture;
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
class GCustomRenderer implements IGRenderer
{
    static private inline var DATA_PER_VERTEX:Int = 5;

    static private inline var VERTEX_SHADER_CODE:String =
            // Model view matrix
            "m44 vt0, va0, vc4          \n" +
            // Projection matrix
            "m44 op, vt0, vc0			\n" +

            // Calculate UV
            "mul vt0.xy, va1.xy, vc8.zw	\n" +
            "add vt0.xy, vt0.xy, vc8.xy	\n" +

            // Move UV to fragment shader
            "mov v0, vt0.xy";

    private var g2d_initializedThisFrame:Bool;

    private var g2d_vertexShaderCode:ByteArray;
    private var g2d_fragmentShaderCode:ByteArray;

    private var g2d_context:GStage3DContext;

    private var g2d_vertexBuffer:VertexBuffer3D;
    private var g2d_indexBuffer:IndexBuffer3D;
    private var g2d_triangleCount:Int;
    private var g2d_program:Program3D;
    private var g2d_generatePerspectiveMatrix:Bool = false;

    private var g2d_vertices:Array<Float>;
    private var g2d_uvs:Array<Float>;
    private var g2d_indices:Array<UInt>;

    public var transformMatrix:GMatrix3D;
    public var projectionMatrix:GProjectionMatrix;

    public function new(p_vertices:Array<Float>, p_uvs:Array<Float>, p_indices:Array<UInt> = null, p_generatePerspectiveMatrix:Bool = false) {
        transformMatrix = new GMatrix3D();

        if (p_generatePerspectiveMatrix) {
            projectionMatrix = new GProjectionMatrix();
        }

        g2d_vertices = p_vertices;
        g2d_uvs = p_uvs;
        g2d_indices = p_indices;
        g2d_generatePerspectiveMatrix = p_generatePerspectiveMatrix;
    }

    public function initialize(p_context:GStage3DContext):Void {
        g2d_context = p_context;

        var agal:AGALMiniAssembler = new AGALMiniAssembler();
        agal.assemble("vertex", VERTEX_SHADER_CODE, GRenderersCommon.AGAL_VERSION);
        g2d_vertexShaderCode = agal.agalcode;

        g2d_program = g2d_context.getNativeContext().createProgram();
        g2d_program.upload(g2d_vertexShaderCode, GRenderersCommon.getTexturedShaderCode(false, GTextureFilteringType.LINEAR, false, "", null));

        var contextWidth:Float = p_context.getStageViewRect().width;
        var contextHeight:Float = p_context.getStageViewRect().height;

        if (g2d_generatePerspectiveMatrix) {
            projectionMatrix.perspective(contextWidth/contextHeight, 1, .1, 2*contextHeight);
        }

        var size:Int = g2d_uvs.length>>1;
        var vertexVector:Vector<Float> = new Vector<Float>(size  * DATA_PER_VERTEX);
        g2d_vertexBuffer = g2d_context.getNativeContext().createVertexBuffer(size, DATA_PER_VERTEX);

        var index:Int = 0;
        for (i in 0...size) {
            // xyz
            vertexVector[index] = g2d_vertices[i*3];
            vertexVector[index+1] = g2d_vertices[i*3+1];
            vertexVector[index+2] = g2d_vertices[i*3+2];
            // uv
            vertexVector[index+3] = g2d_uvs[i*2];
            vertexVector[index+4] = g2d_uvs[i*2+1];

            index += DATA_PER_VERTEX;
        }

        g2d_vertexBuffer.uploadFromVector(vertexVector, 0, size);

        if (g2d_indices == null) {
            g2d_triangleCount = untyped __int__(size/3);
            g2d_indexBuffer = g2d_context.getNativeContext().createIndexBuffer(size);
            var indices:Vector<UInt> = new Vector<UInt>(size);
            for (i in 0...size) {
                indices[i] = i;
            }
            g2d_indexBuffer.uploadFromVector(indices, 0, size);
        } else {
            g2d_triangleCount = untyped __int__(g2d_indices.length/3);
            g2d_indexBuffer = g2d_context.getNativeContext().createIndexBuffer(g2d_indices.length);
            var indices:Vector<UInt> = new Vector<UInt>(g2d_indices.length);
            for (i in 0...g2d_indices.length) {
                indices[i] = g2d_indices[i];
            }
            g2d_indexBuffer.uploadFromVector(indices,0,indices.length);
        }
    }

    public function bind(p_context:GStage3DContext, p_reinitialize:Bool):Void {
        if (g2d_program==null || (p_reinitialize && !g2d_initializedThisFrame)) initialize(p_context);
        g2d_initializedThisFrame = p_reinitialize;

        g2d_context.getNativeContext().setProgram(g2d_program);
    }

    public function draw(p_texture:GTexture):Void {
        var nativeContext:Context3D = g2d_context.getNativeContext();

        if (projectionMatrix != null) nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, projectionMatrix, true);

        nativeContext.setTextureAt(0, p_texture.nativeTexture);

        nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, transformMatrix, true);
        nativeContext.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 8, Vector.ofArray([p_texture.g2d_u, p_texture.g2d_v, p_texture.g2d_uScale, p_texture.g2d_vScale]), 1);

        nativeContext.setVertexBufferAt(0, g2d_vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
        nativeContext.setVertexBufferAt(1, g2d_vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);

        nativeContext.drawTriangles(g2d_indexBuffer, 0, g2d_triangleCount);
    }

    inline public function push():Void {
    }

    public function clear():Void {
        g2d_context.getNativeContext().setTextureAt(0, null);

        g2d_context.getNativeContext().setVertexBufferAt(0, null);
        g2d_context.getNativeContext().setVertexBufferAt(1, null);

        if (projectionMatrix != null) g2d_context.getNativeContext().setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, g2d_context.getActiveCamera().matrix, true);
    }
}