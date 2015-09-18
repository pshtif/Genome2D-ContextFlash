package com.genome2d.context.stage3d.renderers;
import com.genome2d.context.IGContext;
import com.genome2d.context.stage3d.GStage3DContext;
import com.genome2d.debug.GDebug;
import com.genome2d.geom.GMatrix3D;
import com.genome2d.textures.GTexture;
import flash.display3D.Context3D;
import com.adobe.utils.extended.AGALMiniAssembler;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Vector3D;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.Vector;

/**
 * ...
 * @author Peter @sHTiF Stefcek
 */
class GBufferRenderer implements IGRenderer
{
	private var g2d_context:IGContext;
	private var g2d_nativeContext:Context3D;
	private var g2d_initializedThisFrame:Bool;
	
	private var g2d_cachedPrograms:Dictionary;
    private var g2d_cachedProgramIds:Dictionary;
	
	private var g2d_agal:AGALMiniAssembler;
	
	private var g2d_vertexData:Vector<Float>;
	private var g2d_dataPerVertex:Int;
	private var g2d_dataTypes:Array<Int>;
	private var g2d_vertexBuffer:VertexBuffer3D;
	
	private var g2d_indices:Vector<UInt>;
	private var g2d_triangleCount:Int;
	private var g2d_indexBuffer:IndexBuffer3D;
	
	private var g2d_vertexShaderCode:ByteArray;
	private var g2d_fragmentShaderCode:ByteArray;
	
	private var g2d_program:Program3D;
	private var g2d_setTextures:Int = 0;
	
	public function setVertexProgram(p_programCode:String):Void {
		g2d_agal.assemble("vertex", p_programCode);
        g2d_vertexShaderCode = g2d_agal.agalcode;
		
		if (g2d_fragmentShaderCode != null) {
			g2d_program.upload(g2d_vertexShaderCode, g2d_fragmentShaderCode);
		}
	}
	
	public function setVertexConstant(p_value:Dynamic):Void {
		if (Std.is(p_value, GMatrix3D)) {
			g2d_nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, p_value, true);
		}
	}
	
	public function setFragmentProgram(p_programCode:String):Void {
		g2d_agal.assemble("fragment", p_programCode);
        g2d_fragmentShaderCode = g2d_agal.agalcode;
		
		if (g2d_vertexShaderCode != null) {
			g2d_program.upload(g2d_vertexShaderCode, g2d_fragmentShaderCode);
		}
	}
	
	public function setFragmentConstant(p_value:Dynamic):Void {
		g2d_nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, p_value);
	}
	
	public function setTexture(p_texture:GTexture):Void {
		g2d_nativeContext.setTextureAt(g2d_setTextures, p_texture.nativeTexture);
		g2d_setTextures++;
	}
	
	public function setVertexBuffer(p_vertexData:Vector<Float>, p_dataTypes:Array<Int>):Void {
		g2d_vertexData = p_vertexData;
		g2d_dataTypes = p_dataTypes;
		g2d_dataPerVertex = 0;
		for (type in p_dataTypes) g2d_dataPerVertex += type;
		g2d_vertexBuffer = g2d_nativeContext.createVertexBuffer(Std.int(g2d_vertexData.length / g2d_dataPerVertex), g2d_dataPerVertex);
		g2d_vertexBuffer.uploadFromVector(g2d_vertexData, 0, Std.int(g2d_vertexData.length / g2d_dataPerVertex));
	}
	
	public function setIndexBuffer(p_indices:Vector<UInt>):Void {
		g2d_indices = p_indices;
		g2d_triangleCount = Std.int(g2d_indices.length / 3);
		g2d_indexBuffer = g2d_nativeContext.createIndexBuffer(g2d_indices.length);
        g2d_indexBuffer.uploadFromVector(g2d_indices, 0, g2d_indices.length);
	}
	
	public function new(p_context:IGContext) {
		g2d_context = p_context;
		g2d_nativeContext = g2d_context.getNativeContext();
		
		g2d_cachedPrograms = new Dictionary(false);
        g2d_cachedProgramIds = new Dictionary(false);
		
		g2d_agal = new AGALMiniAssembler();
		
		g2d_program = g2d_nativeContext.createProgram();
	}
	
	private function g2d_reinitialize(p_context:GStage3DContext):Void {
		
	}
	
	public function bind(p_context:IGContext, p_reinitialize:Bool):Void {
        if ((p_reinitialize && !g2d_initializedThisFrame)) g2d_reinitialize(cast p_context);
        g2d_initializedThisFrame = p_reinitialize;

        g2d_nativeContext.setProgram(g2d_program);
    }
	
	inline private function g2d_getFormat(p_type:Int):Context3DVertexBufferFormat {
		var format:Context3DVertexBufferFormat = null;
		switch (p_type) {
			case 1:
				format = Context3DVertexBufferFormat.FLOAT_1;
			case 2:
				format = Context3DVertexBufferFormat.FLOAT_2;
			case 3:
				format = Context3DVertexBufferFormat.FLOAT_3;
			case 4:
				format = Context3DVertexBufferFormat.FLOAT_4;
			default:
				GDebug.error("Invalid format type.");
		}
		return format;
	}
	
	public function draw(p_reupload:Bool = false):Void {
		if (g2d_vertexBuffer != null && g2d_indexBuffer != null) {
			if (p_reupload) g2d_vertexBuffer.uploadFromVector(g2d_vertexData, 0, Std.int(g2d_vertexData.length / g2d_dataPerVertex));
			var index:Int = 0;
			var offset:Int = 0;
			for (type in g2d_dataTypes) {
				g2d_nativeContext.setVertexBufferAt(index, g2d_vertexBuffer, offset, g2d_getFormat(type));
				index++;
				offset += type;
			}
				

			g2d_nativeContext.drawTriangles(g2d_indexBuffer, 0, g2d_triangleCount);
		}
    }
	
	public function push():Void {
		
	}

    public function clear():Void {
        for (index in 0...g2d_dataTypes.length) {
			g2d_nativeContext.setVertexBufferAt(index, null);
		}
		for (index in 0...g2d_setTextures) {
			g2d_nativeContext.setTextureAt(index, null);
		}
		g2d_setTextures = 0;
    }
	
}