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
	private var g2d_initialized:Int;
	
	private var g2d_cachedPrograms:Dictionary;
    private var g2d_cachedProgramIds:Dictionary;
	
	private var g2d_agal:AGALMiniAssembler;
	
	private var g2d_vertexData:Vector<Float>;
	private var g2d_dataPerVertex:Int;
	private var g2d_dataTypes:Array<Int>;
	private var g2d_vertexBuffer:VertexBuffer3D;
	
	private var g2d_indexData:Vector<UInt>;
	private var g2d_triangleCount:Int;
	private var g2d_indexBuffer:IndexBuffer3D;
	
	private var g2d_vertexConstants:Map<Int, Dynamic>;
	private var g2d_fragmentConstants:Map<Int, Dynamic>;
	
	private var g2d_vertexShaderCode:ByteArray;
	private var g2d_fragmentShaderCode:ByteArray;
	
	private var g2d_program:Program3D;
	private var g2d_setTextures:Int = 0;
	
	private var g2d_gpuDataDirty:Int = 0;
	
	inline static private var DIRTY_PROGRAM:Int = 1;
	inline static private var DIRTY_VERTEX_BUFFER:Int = 2;
	inline static private var DIRTY_INDEX_BUFFER:Int = 4;
	
	public function setVertexProgram(p_programCode:String):Void {
		g2d_agal.assemble("vertex", p_programCode, GRenderersCommon.AGAL_VERSION);
        g2d_vertexShaderCode = g2d_agal.agalcode;
		
		if ((g2d_gpuDataDirty & DIRTY_PROGRAM) == 0) g2d_gpuDataDirty += DIRTY_PROGRAM;
	}
	
	public function setVertexConstant(p_index:Int, p_value:Dynamic):Void {
		if (Std.is(p_value, Array)) {
			p_value = Vector.ofArray(p_value);
		}		
		g2d_vertexConstants.set(p_index, p_value);
	}
	
	public function setFragmentProgram(p_programCode:String):Void {
		g2d_agal.assemble("fragment", p_programCode, GRenderersCommon.AGAL_VERSION);
        g2d_fragmentShaderCode = g2d_agal.agalcode;
		
		if ((g2d_gpuDataDirty & DIRTY_PROGRAM) == 0) g2d_gpuDataDirty += DIRTY_PROGRAM;
	}
	
	public function setFragmentConstant(p_index:Int, p_value:Dynamic):Void {
		if (Std.is(p_value, Array)) {
			var newValue:Vector<Float> = new Vector<Float>();
			for (value in cast (p_value,Array<Dynamic>)) newValue.push(value);
			p_value = newValue;
		}
		g2d_fragmentConstants.set(p_index, p_value);
	}
	
	public function setTexture(p_texture:GTexture):Void {
		g2d_nativeContext.setTextureAt(g2d_setTextures, p_texture.nativeTexture);
		g2d_setTextures++;
	}
	
	public function setVertexBuffer(p_vertexData:Dynamic, p_dataTypes:Array<Int>):Void {
		if (Std.is(p_vertexData, Vector)) {
			g2d_vertexData = p_vertexData;
		} else if (Std.is(p_vertexData, Array)) {
			g2d_vertexData = Vector.ofArray(p_vertexData);
		} else {
			GDebug.error("Invalid vertex data source.");
		}
		
		g2d_dataTypes = p_dataTypes;
		g2d_dataPerVertex = 0;
		for (type in p_dataTypes) g2d_dataPerVertex += type;
		
		if ((g2d_gpuDataDirty & DIRTY_VERTEX_BUFFER) == 0) g2d_gpuDataDirty += DIRTY_VERTEX_BUFFER;
	}
	
	public function setIndexBuffer(p_indexData:Dynamic):Void {
		if (Std.is(p_indexData, Vector)) {
			g2d_indexData = p_indexData;
		} else if (Std.is(p_indexData, Array)) {
			g2d_indexData = Vector.ofArray(p_indexData);
		} else {
			GDebug.error("Invalid index data source.");
		}
		
		g2d_triangleCount = Std.int(g2d_indexData.length / 3);
		
		if ((g2d_gpuDataDirty & DIRTY_INDEX_BUFFER) == 0) g2d_gpuDataDirty += DIRTY_INDEX_BUFFER;
	}
	
	public function new() {
		g2d_cachedPrograms = new Dictionary(false);
        g2d_cachedProgramIds = new Dictionary(false);
		
		g2d_vertexConstants = new Map<Int, Dynamic>();
		g2d_fragmentConstants = new Map<Int, Dynamic>();
		
		g2d_agal = new AGALMiniAssembler();
	}
	
	public function initialize(p_context:GStage3DContext):Void {
		g2d_context = p_context;
		g2d_nativeContext = g2d_context.getNativeContext();
		
		if (g2d_vertexShaderCode == null) GDebug.error("No vertex shader set.");
		if (g2d_fragmentShaderCode == null) GDebug.error("No fragment shader set.");
		
		if ((g2d_gpuDataDirty & DIRTY_PROGRAM) != 0) {
			g2d_program = g2d_nativeContext.createProgram();
			g2d_program.upload(g2d_vertexShaderCode, g2d_fragmentShaderCode);
		}
		
		if ((g2d_gpuDataDirty & DIRTY_VERTEX_BUFFER) != 0) {
			g2d_vertexBuffer = g2d_nativeContext.createVertexBuffer(Std.int(g2d_vertexData.length / g2d_dataPerVertex), g2d_dataPerVertex);
			g2d_vertexBuffer.uploadFromVector(g2d_vertexData, 0, Std.int(g2d_vertexData.length / g2d_dataPerVertex));
		}
		
		if ((g2d_gpuDataDirty & DIRTY_INDEX_BUFFER) != 0) {
			g2d_indexBuffer = g2d_nativeContext.createIndexBuffer(g2d_indexData.length);
			g2d_indexBuffer.uploadFromVector(g2d_indexData, 0, g2d_indexData.length);
		}
		
		g2d_gpuDataDirty = 0;
	}
	
	public function bind(p_context:IGContext, p_reinitialize:Int):Void {
        if ((p_reinitialize != g2d_initialized) || g2d_gpuDataDirty != 0) initialize(cast p_context);
        g2d_initialized = p_reinitialize;

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
	
	public function draw():Void {
		if (g2d_vertexBuffer != null && g2d_indexBuffer != null) {
			var index:Int = 0;
			var offset:Int = 0;
			for (type in g2d_dataTypes) {
				g2d_nativeContext.setVertexBufferAt(index, g2d_vertexBuffer, offset, g2d_getFormat(type));
				index++;
				offset += type;
			}
			
			for (index in g2d_vertexConstants.keys()) {
				var value:Dynamic = g2d_vertexConstants.get(index);
				if (Std.is(value, GMatrix3D)) {
					g2d_nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, index, value, true);
				// Assuming its a Vector<Float>, we can't check with Std.is since Haxe doesn't support it for some types in Vector<T> yet.
				} else {
					g2d_nativeContext.setProgramConstantsFromVector(Context3DProgramType.VERTEX, index, value);
				}
			}
			
			for (index in g2d_fragmentConstants.keys()) {
				var value:Dynamic = g2d_fragmentConstants.get(index);
				if (Std.is(value, GMatrix3D)) {
					g2d_nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.FRAGMENT, index, value, true);
				// Assuming its a Vector<Float>, we can't check with Std.is since Haxe doesn't support it for some types in Vector<T> yet.
				} else {
					g2d_nativeContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, index, value);
				}
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