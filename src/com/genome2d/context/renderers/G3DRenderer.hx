/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.renderers;

import com.genome2d.debug.GDebug;
import com.genome2d.context.IGRenderer;
import com.genome2d.geom.GFloat4;
import com.genome2d.context.stats.GStats;
import com.genome2d.textures.GTexture;
import com.genome2d.textures.GTextureFilteringType;
import com.genome2d.context.GStage3DContext;
import com.genome2d.geom.GMatrix3D;
import com.adobe.utils.extended.AGALMiniAssembler;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Vector3D;
import flash.utils.ByteArray;
import flash.Vector;

@:access(com.genome2d.textures.GTexture)
class G3DRenderer implements IGRenderer
{
    static private inline var DATA_PER_VERTEX:Int = 5;
    static private inline var DATA_PER_VERTEX_NORMALS:Int = 8;

    static private inline var VERTEX_SHADER_CODE:String =
            // Model view matrix
            "m44 vt0, va0, vc4          \n" +
            // Camera matrix
            "m44 vt0, vt0, vc8          \n" +
            // Projection matrix
            "m44 op, vt0, vc0			\n" +

            // Calculate UV
            "mul vt0.xy, va1.xy, vc12.zw	\n" +
            "add vt0.xy, vt0.xy, vc12.xy	\n" +

            // Move UV to fragment shader
            "mov v0, vt0.xy";

    static private inline var VERTEX_SHADER_CODE_NORMALS:String =
            // Model view matrix
            "m44 vt0, va0, vc4          \n" +
            "m44 vt0, vt0, vc8          \n" +
            //"m44 vt1, va2, vc4          \n" +
            // Projection matrix
            "m44 op, vt0, vc0			\n" +

            // Calculate UV
            "mul vt0.xy, va1.xy, vc16.zw	\n" +
            "add vt0.xy, vt0.xy, vc16.xy	\n" +

            // Move UV to fragment shader
            "mov v0, vt0.xy \n" +
            // Move Normal to fragment shader
            "m44 vt1, va2, vc12  \n" +
            "nrm vt1.xyz, vt1.xyz \n" +
            "mov v1, vt1";

    static private inline var FRAGMENT_SHADER_CODE_NORMALS:String =
            "tex ft0, v0, fs0 <2d,clamp,linear> \n" +
            "dp3 ft1, v1, fc1 \n" +
            "neg ft1, ft1 \n" +
            // Saturate to 0,1
            "sat ft1, ft1 \n" +
            // Light amount
            "mul ft1.xyz, ft0.xyz, ft1.xyz \n" +
            // Light color
            "mul ft1.xyz, ft1.xyz, fc4.xyz \n" +
            // Multiply with ambient
            "mul ft0.xyz, ft0.xyz, fc2.xyz \n" +
            // Add diffuse + ambient
            "add ft0.xyz, ft1.xyz, ft0.xyz \n" +
			//"sat ft1, ft1 \n" +
            // Multiply with tint
			"mul ft0, ft0, fc3 \n" +
            "mov oc, ft0";
            //"mov oc, v1";
			
	static private inline var FRAGMENT_SHADER_CODE_NORMALS_REPEAT:String =
            "tex ft0, v0, fs0 <2d,repeat,linear> \n" +
            "dp3 ft1, v1, fc1 \n" +
            "neg ft1, ft1 \n" +
            // Saturate to 0,1
            "sat ft1, ft1 \n" +
            // Light amount
            "mul ft1.xyz, ft0.xyz, ft1.xyz \n" +
            // Light color
            "mul ft1.xyz, ft1.xyz, fc4.xyz \n" +
            // Multiply with ambient
            "mul ft0.xyz, ft0.xyz, fc2.xyz \n" +
            // Add diffuse + ambient
            "add ft0.xyz, ft1.xyz, ft0.xyz \n" +
			//"sat ft1, ft1 \n" +
            // Multiply with tint
			"mul ft0, ft0, fc3 \n" +
            "mov oc, ft0";
            //"mov oc, v1";

    static private inline var VERTEX_SHADER_CODE_SHADOW:String =
            // Model matrix
            "m44 vt0, va0, vc4            \n" +
            // Clamp everything under water above it so it doesn't cast shadow
            "max vt0.zzzz, vt0.zzzz, vc16 \n" +
            // Shadow matrix
            "m44 vt1, vt0, vc12           \n" +
            // Camera matrix
            "m44 vt1, vt1, vc8            \n" +
            // Projection matrix
            "m44 op, vt1, vc0";

    static private inline var FRAGMENT_SHADER_CODE_SHADOW:String =
            "mov oc, fc1";
			
	static private inline var VERTEX_SHADER_CODE_DEPTH:String =
            // Model view matrix
            "m44 vt0, va0, vc4          \n" +
            "m44 vt0, vt0, vc8          \n" +
            //"m44 vt1, va2, vc4          \n" +
            // Projection matrix
            "m44 op, vt0, vc0			\n" +

            // Move UV to fragment shader
            "mov v0, va0";
			
	static private inline var FRAGMENT_SHADER_CODE_DEPTH:String =
			//"sub ft0, v0.zzzz, fc2		\n" +
			"div ft0, fc2, v0.zzzz		\n" +
			"sat ft0, ft0 \n" +
            "mul oc, ft0, fc1";


	private var g2d_initialized:Int = 0;
    private var g2d_initializedThisFrame:Bool;

    static private var g2d_vertexShaderCode:ByteArray;
    static private var g2d_vertexShaderCodeNormals:ByteArray;
    static private var g2d_fragmentShaderCodeNormals:ByteArray;
	static private var g2d_fragmentShaderCodeNormalsRepeat:ByteArray;
    static private var g2d_vertexShaderCodeShadow:ByteArray;
    static private var g2d_fragmentShaderCodeShadow:ByteArray;
	static private var g2d_vertexShaderCodeDepth:ByteArray;
    static private var g2d_fragmentShaderCodeDepth:ByteArray;

    private var g2d_context:GStage3DContext;

    private var g2d_vertexBuffer:VertexBuffer3D;
    private var g2d_indexBuffer:IndexBuffer3D;
    private var g2d_triangleCount:Int;
    private var g2d_program:Program3D;
	private var g2d_programRepeat:Program3D;
    private var g2d_programNormals:Program3D;
	private var g2d_programNormalsRepeat:Program3D;
    private var g2d_programShadow:Program3D;
	private var g2d_programDepth:Program3D;
    private var g2d_generatePerspectiveMatrix:Bool = false;
	private var g2d_needVertexBufferReinitialization:Bool = false;

    private var g2d_vertices:Array<Float>;
    private var g2d_uvs:Array<Float>;
    private var g2d_normals:Array<Float>;
    private var g2d_indices:Array<UInt>;

    public var renderType:Int = 0;

	public var modelMatrix:GMatrix3D;
    public var cameraMatrix:GMatrix3D;
    public var projectionMatrix:GProjectionMatrix;

	public var texture:GTexture;
	
    public var lightDirection:GFloat4;
    public var ambientColor:GFloat4;
    public var tintColor:GFloat4;
    public var lightColor:GFloat4;
	
	public var visible:Bool = true;

    public function new(p_vertices:Array<Float>, p_uvs:Array<Float>, p_indices:Array<UInt> = null, p_normals:Array<Float>, p_generatePerspectiveMatrix:Bool = false) {
        modelMatrix = new GMatrix3D();
        cameraMatrix = new GMatrix3D();

        lightDirection = new GFloat4(1,1,1);
        ambientColor = new GFloat4(1,1,1,1);
        tintColor = new GFloat4(1,1,1,1);
        lightColor = new GFloat4(1,1,1,1);

        if (p_generatePerspectiveMatrix) {
            projectionMatrix = new GProjectionMatrix();
        }

		invalidateGeometry(p_vertices, p_uvs, p_indices, p_normals);
        g2d_generatePerspectiveMatrix = p_generatePerspectiveMatrix;
    }
	
	public function invalidateGeometry(p_vertices:Array<Float>, p_uvs:Array<Float>, p_indices:Array<UInt> = null, p_normals:Array<Float>) {
		g2d_vertices = p_vertices;
        g2d_uvs = p_uvs;
        g2d_normals = p_normals;
        if (g2d_normals != null) renderType = 1;
        g2d_indices = p_indices;
		
		g2d_needVertexBufferReinitialization = true;
	}

    public function initialize(p_context:GStage3DContext):Void {
        g2d_context = p_context;

		if (g2d_vertexShaderCode == null) {
			var agal:AGALMiniAssembler = new AGALMiniAssembler();
			agal.assemble("vertex", VERTEX_SHADER_CODE, GRenderersCommon.AGAL_VERSION);
			g2d_vertexShaderCode = agal.agalcode;
		}

		if (g2d_vertexShaderCodeNormals == null) {
			var agal:AGALMiniAssembler = new AGALMiniAssembler();
			agal.assemble("vertex", VERTEX_SHADER_CODE_NORMALS, GRenderersCommon.AGAL_VERSION);
			g2d_vertexShaderCodeNormals = agal.agalcode;
		}

		if (g2d_fragmentShaderCodeNormals == null) {
			var agal:AGALMiniAssembler = new AGALMiniAssembler();
			agal.assemble("fragment", FRAGMENT_SHADER_CODE_NORMALS, GRenderersCommon.AGAL_VERSION);
			g2d_fragmentShaderCodeNormals = agal.agalcode;
		}
		
		if (g2d_fragmentShaderCodeNormalsRepeat == null) {
			var agal:AGALMiniAssembler = new AGALMiniAssembler();
			agal.assemble("fragment", FRAGMENT_SHADER_CODE_NORMALS_REPEAT, GRenderersCommon.AGAL_VERSION);
			g2d_fragmentShaderCodeNormalsRepeat = agal.agalcode;
		}

		if (g2d_vertexShaderCodeShadow == null) {
			var agal:AGALMiniAssembler = new AGALMiniAssembler();
			agal.assemble("vertex", VERTEX_SHADER_CODE_SHADOW, GRenderersCommon.AGAL_VERSION);
			g2d_vertexShaderCodeShadow = agal.agalcode;
		}

		if (g2d_fragmentShaderCodeShadow == null) {
			var agal:AGALMiniAssembler = new AGALMiniAssembler();
			agal.assemble("fragment", FRAGMENT_SHADER_CODE_SHADOW, GRenderersCommon.AGAL_VERSION);
			g2d_fragmentShaderCodeShadow = agal.agalcode;
		}
		
		if (g2d_vertexShaderCodeDepth == null) {
			var agal:AGALMiniAssembler = new AGALMiniAssembler();
			agal.assemble("vertex", VERTEX_SHADER_CODE_DEPTH, GRenderersCommon.AGAL_VERSION);
			g2d_vertexShaderCodeDepth = agal.agalcode;
		}

		if (g2d_fragmentShaderCodeDepth == null) {
			var agal:AGALMiniAssembler = new AGALMiniAssembler();
			agal.assemble("fragment", FRAGMENT_SHADER_CODE_DEPTH, GRenderersCommon.AGAL_VERSION);
			g2d_fragmentShaderCodeDepth = agal.agalcode;
		}

        g2d_program = g2d_context.getNativeContext().createProgram();
        g2d_program.upload(g2d_vertexShaderCode, GRenderersCommon.getTexturedShaderCode(false, GTextureFilteringType.LINEAR, 2, "", null));
		
		g2d_programRepeat = g2d_context.getNativeContext().createProgram();
        g2d_programRepeat.upload(g2d_vertexShaderCode, GRenderersCommon.getTexturedShaderCode(true, GTextureFilteringType.LINEAR, 2, "", null));

        g2d_programNormals = g2d_context.getNativeContext().createProgram();
        g2d_programNormals.upload(g2d_vertexShaderCodeNormals, g2d_fragmentShaderCodeNormals);
		
		g2d_programNormalsRepeat = g2d_context.getNativeContext().createProgram();
        g2d_programNormalsRepeat.upload(g2d_vertexShaderCodeNormals, g2d_fragmentShaderCodeNormalsRepeat);

        g2d_programShadow = g2d_context.getNativeContext().createProgram();
        g2d_programShadow.upload(g2d_vertexShaderCodeShadow, g2d_fragmentShaderCodeShadow);
		
		g2d_programDepth = g2d_context.getNativeContext().createProgram();
        g2d_programDepth.upload(g2d_vertexShaderCodeDepth, g2d_fragmentShaderCodeDepth);

        var contextWidth:Float = p_context.getStageViewRect().width;
        var contextHeight:Float = p_context.getStageViewRect().height;

        if (g2d_generatePerspectiveMatrix) {
            projectionMatrix.perspective(contextWidth/contextHeight, 1, .1, 2*contextHeight);
        }
		
		reinitializeVertexBuffer();
		
        var size:Int = g2d_uvs.length>>1;
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
	
	public function reinitializeVertexBuffer():Void {
		var size:Int = g2d_uvs.length>>1;
		var vertexVector:Vector<Float> = new Vector<Float>((g2d_normals == null) ? size  * DATA_PER_VERTEX : size * DATA_PER_VERTEX_NORMALS);
        if (g2d_vertexBuffer != null) g2d_vertexBuffer.dispose();
        g2d_vertexBuffer = g2d_context.getNativeContext().createVertexBuffer(size, (g2d_normals == null) ? DATA_PER_VERTEX : DATA_PER_VERTEX_NORMALS);
		
		var index:Int = 0;
        for (i in 0...size) {
            // xyz
            vertexVector[index] = g2d_vertices[i*3];
            vertexVector[index+1] = g2d_vertices[i*3+1];
            vertexVector[index+2] = g2d_vertices[i*3+2];
            // uv
            vertexVector[index+3] = g2d_uvs[i*2];
            vertexVector[index+4] = g2d_uvs[i*2+1];

            if (g2d_normals != null) {
                // normal
                vertexVector[index+5] = g2d_normals[i*3];
                vertexVector[index+6] = g2d_normals[i*3+1];
                vertexVector[index+7] = g2d_normals[i*3+2];
            }

            index += (g2d_normals == null) ? DATA_PER_VERTEX : DATA_PER_VERTEX_NORMALS;
        }

        g2d_vertexBuffer.uploadFromVector(vertexVector, 0, size);

        g2d_needVertexBufferReinitialization = false;
	}

    public function bind(p_context:IGContext, p_reinitialize:Int):Void {
        if (g2d_program==null || (p_reinitialize != g2d_initialized)) initialize(cast p_context);
        g2d_initialized = p_reinitialize;

        g2d_context.getNativeContext().setDepthTest(true, Context3DCompareMode.LESS);
		
		if (g2d_needVertexBufferReinitialization) reinitializeVertexBuffer();
    }

    public function draw(p_cull:Int = 0, p_renderType:Int):Void {
        GStats.drawCalls++;
        var nativeContext:Context3D = g2d_context.getNativeContext();
        if (p_renderType != renderType) {
            clear();
            renderType = p_renderType;
        }
		
		switch (renderType) {
            case 0:
				if (texture.repeatable) {
					g2d_context.getNativeContext().setProgram(g2d_programRepeat);
				} else {
					g2d_context.getNativeContext().setProgram(g2d_program);
				}
            case 1:
				if (texture.repeatable) {
					g2d_context.getNativeContext().setProgram(g2d_programNormalsRepeat);
				} else {
					g2d_context.getNativeContext().setProgram(g2d_programNormals);
				}
            case 2:
                g2d_context.getNativeContext().setProgram(g2d_programShadow);
			case 3:
                g2d_context.getNativeContext().setProgram(g2d_programDepth);
            case _:
        }

        if (p_cull == 2) {
            g2d_context.getNativeContext().setCulling(Context3DTriangleFace.FRONT);
        } else if (p_cull == 1) {
            g2d_context.getNativeContext().setCulling(Context3DTriangleFace.BACK);
        } else {
            g2d_context.getNativeContext().setCulling(Context3DTriangleFace.NONE);
        }

        if (projectionMatrix != null) {
            nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, projectionMatrix, true);
        }

        nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, modelMatrix, true);
        nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 8, cameraMatrix, true);

        nativeContext.setVertexBufferAt(0, g2d_vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
        switch (renderType) {
			// Unlit
            case 0:
                nativeContext.setTextureAt(0, texture.nativeTexture);
				nativeContext.setVertexBufferAt(1, g2d_vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
				// UV
                nativeContext.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 12, Vector.ofArray([texture.g2d_u, texture.g2d_v, texture.g2d_uScale, texture.g2d_vScale]), 1);
				// TINT
				nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.ofArray([tintColor.x,tintColor.y,tintColor.z,tintColor.w]), 1);
            // With light/normals
            case 1:
                nativeContext.setTextureAt(0, texture.nativeTexture);
                nativeContext.setVertexBufferAt(1, g2d_vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
                nativeContext.setVertexBufferAt(2, g2d_vertexBuffer, 5, Context3DVertexBufferFormat.FLOAT_3);
                // Inverse transpose model view matrix
                // TODO: Cloning matrix per render is not a good idea just for testing!
                var invtran:GMatrix3D = modelMatrix.clone();
                invtran.invert();
                invtran.transpose();
                nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 12, invtran, true);
                // UV
                nativeContext.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 16, Vector.ofArray([texture.g2d_u, texture.g2d_v, texture.g2d_uScale, texture.g2d_vScale]), 1);
                // Light position
                nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.ofArray([lightDirection.x,lightDirection.y,lightDirection.z,1.0]), 1);
                // Ambient color
                nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.ofArray([ambientColor.x,ambientColor.y,ambientColor.z,ambientColor.w]), 1);
                nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, Vector.ofArray([tintColor.x,tintColor.y,tintColor.z,tintColor.w]), 1);
                nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 4, Vector.ofArray([lightColor.x,lightColor.y,lightColor.z,lightColor.w]), 1);
            // Shadows
            case 2:
                var plane:Vector3D = new Vector3D(0,0,1);
                plane.normalize();
                var point:Vector3D = new Vector3D(0,0,0);
                point.normalize();
                var shadowProjection:Vector<Float> = makeShadowProjection(plane, point, lightDirection);
                nativeContext.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 12, shadowProjection, 4);
                nativeContext.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 16, Vector.ofArray([0,0,0,0.0]), 1);
                nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.ofArray([0, 0, 0, 1.0]), 1);
			// Depth
            case 3:
                // Inverse transpose model view matrix
                // TODO: Cloning matrix per render is not a good idea just for testing!
                var invtran:GMatrix3D = modelMatrix.clone();
                invtran.invert();
                invtran.transpose();
                nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 12, invtran, true);
				// Color
                nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.ofArray([0, 0, 0, .35]), 1);
				// Height
                nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.ofArray([20,20,20,20.0]), 1);
            case _:
        }

        nativeContext.drawTriangles(g2d_indexBuffer, 0, g2d_triangleCount);
    }

    inline public function push():Void {
    }

    public function clear():Void {
        g2d_context.getNativeContext().setTextureAt(0, null);

        g2d_context.getNativeContext().setVertexBufferAt(0, null);
        g2d_context.getNativeContext().setVertexBufferAt(1, null);
        if (g2d_normals != null) g2d_context.getNativeContext().setVertexBufferAt(2, null);

        g2d_context.getNativeContext().setDepthTest(false, Context3DCompareMode.ALWAYS);
        g2d_context.getNativeContext().setCulling(Context3DTriangleFace.NONE);

        if (projectionMatrix != null) g2d_context.getNativeContext().setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, g2d_context.getActiveCamera().matrix, true);
    }

    private function makeShadowProjection(p_plane:GFloat4, p_point:GFloat4, p_light:GFloat4):Vector<Float> {
        var nL:Float = p_plane.dotProduct(p_light);
        var nr:Float = p_plane.dotProduct(p_point);
        var proj:Vector<Float> = new Vector<Float>();
        proj.push(nL - p_plane.x * p_light.x);
        proj.push(-p_plane.y * p_light.x);
        proj.push(-p_plane.z * p_light.x);
        proj.push(nr * p_light.x);
        proj.push(-p_plane.x * p_light.y);
        proj.push(nL - p_plane.y * p_light.y);
        proj.push(-p_plane.z * p_light.y);
        proj.push(nr * p_light.y);
        proj.push(-p_plane.x * p_light.z);
        proj.push(-p_plane.y * p_light.z);
        proj.push(nL - p_plane.z * p_light.z);
        proj.push(nr * p_light.z);
        proj.push(0);
        proj.push(0);
        proj.push(0);
        proj.push(1);
        for (i in 0...12) proj[i] /= nL;
        return proj;
    }
	
	public function dispose():Void {
		if (g2d_indexBuffer != null) g2d_indexBuffer.dispose();
		if (g2d_vertexBuffer != null) g2d_vertexBuffer.dispose();

		if (g2d_program != null) g2d_program.dispose();
		if (g2d_programNormals != null) g2d_programNormals.dispose();
		if (g2d_programDepth != null) g2d_programDepth.dispose();
		if (g2d_programShadow != null) g2d_programShadow.dispose();
	}
}