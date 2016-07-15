/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context;

import com.genome2d.context.GDepthFunc;
import com.genome2d.callbacks.GCallback;
import com.genome2d.debug.IGDebuggableInternal;
import com.genome2d.input.IGInteractive;
import com.genome2d.macros.MGDebug;
import flash.display.BitmapData;

import com.genome2d.textures.GTextureManager;
import com.genome2d.textures.GTexture;
import com.genome2d.context.filters.GColorMatrixFilter;
import com.genome2d.context.stats.GStats;
import com.genome2d.geom.GMatrix3D;
import com.genome2d.context.renderers.GRenderersCommon;
import com.genome2d.context.stats.IGStats;
import com.genome2d.geom.GRectangle;
import com.genome2d.context.renderers.GMatrixQuadTextureShaderRenderer;
import com.genome2d.context.renderers.GTriangleTextureBufferCPURenderer;
import com.genome2d.context.renderers.GQuadTextureShaderRenderer;
import com.genome2d.context.filters.GFilter;
import com.genome2d.context.renderers.GQuadTextureBufferGPURenderer;
import com.genome2d.context.GProjectionMatrix;
import com.genome2d.textures.GTexture;
import com.genome2d.context.GBlendMode;
import com.genome2d.context.GCamera;
import com.genome2d.context.IGRenderer;
import com.genome2d.input.GMouseInput;
import com.genome2d.input.GKeyboardInput;
import com.genome2d.input.GKeyboardInputType;
import com.genome2d.input.GMouseInputType;

import flash.utils.Object;
import flash.Vector;
import flash.display3D.Context3DTriangleFace;
import flash.display.Stage;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DClearMask;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DStencilAction;
import flash.display3D.Context3DTriangleFace;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.geom.Matrix3D;
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.Memory;
import flash.geom.Vector3D;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;

#if genome_stage3donly
@:native("com.genome2d.context.IGContext")
class GStage3DContext implements IGDebuggableInternal implements IGInteractive
#else
class GStage3DContext implements IGContext implements IGDebuggableInternal implements IGInteractive
#end
{
    private var NORMALIZED_VECTOR:Vector3D;

    private var g2d_nativeStage:Stage;
    public function getNativeStage():Stage {
        return g2d_nativeStage;
    }

    private var g2d_activeCamera:GCamera;
    public function getActiveCamera():GCamera {
        return g2d_activeCamera;
    }
    private var g2d_activeViewRect:GRectangle;

    private var g2d_activeMaskRect:GRectangle;

    private var g2d_initialized:Bool = false;
    private var g2d_reinitialize:Int = 0;

    private var g2d_stageViewRect:GRectangle;
    inline public function getStageViewRect():GRectangle {
        return g2d_stageViewRect;
    }
    private var g2d_defaultCamera:GCamera;
    inline public function getDefaultCamera():GCamera {
        return g2d_defaultCamera;
    }

    private var g2d_stats:IGStats;

    private var g2d_currentTime:Float = 0;
    private var g2d_currentDeltaTime:Float;
	
	private var g2d_useBitmapDataTargetOnce:Bool = true;
	private var g2d_bitmapDataTarget:BitmapData;

    /*
     *  CALLBACKS
     */
    private var g2d_onInitialized:GCallback0;
    #if swc @:extern #end
    public var onInitialized(get,never):GCallback0;
    #if swc @:getter(onInitialized) #end
    inline private function get_onInitialized():GCallback0{
        return g2d_onInitialized;
    }

    private var g2d_onFailed:GCallback1<String>;
    #if swc @:extern #end
    public var onFailed(get,never):GCallback1<String>;
    #if swc @:getter(onFailed) #end
    inline private function get_onFailed():GCallback1<String>{
        return g2d_onFailed;
    }

    private var g2d_onFrame:GCallback1<Float>;
    #if swc @:extern #end
    public var onFrame(get,never):GCallback1<Float>;
    #if swc @:getter(onFrame) #end
    inline private function get_onFrame():GCallback1<Float>{
        return g2d_onFrame;
    }

    private var g2d_onKeyboardInput:GCallback1<GKeyboardInput>;
    #if swc @:extern #end
    public var onKeyboardInput(get,never):GCallback1<GKeyboardInput>;
    #if swc @:getter(onKeyboardInput) #end
    inline private function get_onKeyboardInput():GCallback1<GKeyboardInput>{
        return g2d_onKeyboardInput;
    }

    private var g2d_onResize:GCallback2<Int,Int>;
    #if swc @:extern #end
    public var onResize(get,never):GCallback2<Int,Int>;
    #if swc @:getter(onResize) #end
    inline private function get_onResize():GCallback2<Int,Int>{
        return g2d_onResize;
    }

    private var g2d_onMouseInput:GCallback1<GMouseInput>;
    #if swc @:extern #end
    public var onMouseInput(get,never):GCallback1<GMouseInput>;
    #if swc @:getter(onMouseInput) #end
    inline private function get_onMouseInput():GCallback1<GMouseInput>{
        return g2d_onMouseInput;
    }

    private var g2d_onInvalidated:GCallback0;
    #if swc @:extern #end
    public var onInvalidated(get,never):GCallback0;
    #if swc @:getter(onInvalidated) #end
    inline private function get_onInvalidated():GCallback0{
        return g2d_onInvalidated;
    }

    private var g2d_nativeStage3D:Stage3D;

    private var g2d_nativeContext:Context3D;
    inline public function getNativeContext():Context3D {
        return g2d_nativeContext;
    }
	
	public var g2d_onMouseInputInternal:GMouseInput->Void;

	private var g2d_activeRenderer:IGRenderer;
	private var g2d_activeBlendMode:Int;
	private var g2d_activePremultiply:Bool;

	private var g2d_hdResolution:Bool;
	
    private var g2d_antiAliasing:Int;
	public function getAntiAliasing():Int {
		return g2d_antiAliasing;
	}
	public function setAntiAliasing(p_value:Int):Void {
		g2d_antiAliasing = p_value;
		g2d_configureBackBuffer();
	}
	
    private var g2d_enableDepthAndStencil:Bool;
    private var g2d_renderMode:String;
    private var g2d_profile:Object;
    private var g2d_usingExternalContext:Bool;
	
	private var g2d_enableErrorChecking:Bool;

    private var g2d_backgroundRed:Float = 0;
    private var g2d_backgroundGreen:Float = 0;
    private var g2d_backgroundBlue:Float = 0;
    private var g2d_backgroundAlpha:Float = 1;
    public function setBackgroundColor(p_color:Int, p_alpha:Float = 1):Void {
        g2d_backgroundRed = untyped __int__(p_color >> 16 & 0xFF) / 0xFF;
        g2d_backgroundGreen = untyped __int__(p_color >> 8 & 0xFF) / 0xFF;
        g2d_backgroundBlue = untyped __int__(p_color & 0xFF) / 0xFF;
        g2d_backgroundAlpha = p_alpha;
    }

    public var enableNativeContentMouseCapture:Bool = false;

    public var g2d_useSeparateAlphaPipeline:Bool;
    public var g2d_useFastMem:Bool;

    private var g2d_fastMemArray:ByteArray;

	// RENDERERS
	private var g2d_quadTextureShaderRenderer:GQuadTextureShaderRenderer;
    private var g2d_quadTextureBufferGPURenderer:GQuadTextureBufferGPURenderer;
    private var g2d_matrixQuadTextureShaderRenderer:GMatrixQuadTextureShaderRenderer;
    private var g2d_triangleTextureBufferCPURenderer:GTriangleTextureBufferCPURenderer;

    /**
     *  CONSTRUCTOR
     **/
    public function new(p_config:GContextConfig) {

        if (p_config.nativeStage == null) MGDebug.ERROR("You need to specify nativeStage in the config");

        NORMALIZED_VECTOR = new Vector3D();

        g2d_onInitialized = new GCallback0();
        g2d_onFailed = new GCallback1<String>();
        g2d_onFrame = new GCallback1<Float>();
        g2d_onMouseInput = new GCallback1<GMouseInput>();
        g2d_onKeyboardInput = new GCallback1<GKeyboardInput>();
        g2d_onInvalidated = new GCallback0();
        g2d_onResize = new GCallback2<Int,Int>();
		
		g2d_onMouseInput = new GCallback1<GMouseInput>();

        g2d_stageViewRect = p_config.viewRect;
		g2d_nativeStage = p_config.nativeStage;
		g2d_stats = untyped __new__(p_config.statsClass);
        g2d_usingExternalContext = p_config.externalStage3D != null;
        g2d_nativeStage3D = p_config.externalStage3D;

        g2d_antiAliasing = p_config.antiAliasing;
		g2d_hdResolution = p_config.hdResolution;
        g2d_enableDepthAndStencil = p_config.enableDepthAndStencil;
		g2d_enableErrorChecking = p_config.enableErrorChecking;
        g2d_renderMode = p_config.renderMode;
        g2d_profile = p_config.profile;

        g2d_useSeparateAlphaPipeline = p_config.useSeparateAlphaPipeline;
        g2d_useFastMem = p_config.useFastMem;
		
		if (g2d_useFastMem) {
            g2d_fastMemArray = new ByteArray();
            g2d_fastMemArray.endian = Endian.LITTLE_ENDIAN;
            g2d_fastMemArray.length = 10040000;
            Memory.select(g2d_fastMemArray);
        }
    }

/**
        Check if context supports a feature

        Returns true if a feature is supported within current context
    **/
    public function hasFeature(p_feature:Int):Bool {
        switch (p_feature) {
            case GContextFeature.STENCIL_MASKING:
                return g2d_enableDepthAndStencil;
            case GContextFeature.RECTANGLE_TEXTURES:
                return (g2d_profile != "baselineConstrained" && untyped g2d_nativeContext.hasOwnProperty("createRectangleTexture"));
        }

        return false;
    }
	
	/**
	 * 	Initialize the context
	 */
    public function init():Void {
        if (g2d_usingExternalContext) {
            g2d_contextInitialized_handler(null);
            g2d_nativeStage3D.addEventListener(Event.CONTEXT3D_CREATE, g2d_contextInitialized_handler);
        } else {
            g2d_nativeStage3D = g2d_nativeStage.stage3Ds[0];
            g2d_nativeStage3D.addEventListener(Event.CONTEXT3D_CREATE, g2d_contextInitialized_handler);
            g2d_nativeStage3D.addEventListener(ErrorEvent.ERROR, g2d_contextError_handler);

            var multipleProfiles:Bool = untyped __is__(g2d_profile,  __as__(__global__["flash.utils.getDefinitionByName"]("__AS3__.vec::Vector.<String>"), Class));
            var autoDetectAvailable:Bool = untyped g2d_nativeStage3D.hasOwnProperty("requestContext3DMatchingProfiles");
            if (autoDetectAvailable && multipleProfiles) {
                untyped g2d_nativeStage3D["requestContext3DMatchingProfiles"](g2d_profile);
            } else {
                g2d_nativeStage3D.requestContext3D(untyped g2d_renderMode, (multipleProfiles) ? g2d_profile[untyped __int__(g2d_profile.length-1)] : g2d_profile);
            }
        }
	}

    private function g2d_contextInitialized_handler(event:Event):Void {
        g2d_nativeContext = g2d_nativeStage3D.context3D;
        g2d_nativeContext.enableErrorChecking = g2d_enableErrorChecking;

        if (untyped g2d_nativeContext.hasOwnProperty("profile")) {
            g2d_profile = untyped g2d_nativeContext["profile"];
        }

        // Init renderers
        GRenderersCommon.init(g2d_profile == "standard" ? 2 : 1);
        g2d_quadTextureShaderRenderer = new GQuadTextureShaderRenderer(g2d_useFastMem, g2d_fastMemArray);
        g2d_quadTextureBufferGPURenderer = new GQuadTextureBufferGPURenderer(g2d_useFastMem, g2d_fastMemArray);
        g2d_matrixQuadTextureShaderRenderer = new GMatrixQuadTextureShaderRenderer(g2d_useFastMem, g2d_fastMemArray);

        g2d_triangleTextureBufferCPURenderer = new GTriangleTextureBufferCPURenderer();

        GTextureManager.invalidateAll(true);

        g2d_invalidate();

        g2d_reinitialize++;
    }
	
	private function g2d_configureBackBuffer():Void {
		var w:Int = untyped __int__(g2d_stageViewRect.width);
        var h:Int = untyped __int__(g2d_stageViewRect.height);
        g2d_nativeContext.configureBackBuffer(w, h, g2d_antiAliasing, g2d_enableDepthAndStencil, g2d_hdResolution);
	}

    private function g2d_invalidate():Void {
        if (g2d_nativeContext.driverInfo == "Disposed") return;
        g2d_nativeStage3D.x = g2d_stageViewRect.x;
        g2d_nativeStage3D.y = g2d_stageViewRect.y;

        if (g2d_nativeContext == null) {
            g2d_onFailed.dispatch("Context failed to initialize.");
            return;
        }

        var success:Bool = true;
        if (!g2d_usingExternalContext) {
            try {
                g2d_configureBackBuffer();
            }
            catch (msg:String) {
                success = false;
                g2d_onFailed.dispatch(msg);
            }
        }

        if (success) {
            if (!g2d_initialized) {
                g2d_initComplete();
            } else {
                g2d_defaultCamera.x = g2d_stageViewRect.width*.5;
                g2d_defaultCamera.y = g2d_stageViewRect.height*.5;
                setActiveCamera(g2d_defaultCamera);

                g2d_onInvalidated.dispatch();
            }
        }
    }

    private function g2d_initComplete():Void {
        g2d_defaultCamera = new GCamera();
        g2d_defaultCamera.x = g2d_stageViewRect.width*.5;
        g2d_defaultCamera.y = g2d_stageViewRect.height*.5;
        g2d_activeViewRect = new GRectangle();

        // Frame handler
        g2d_nativeStage.addEventListener(Event.ENTER_FRAME, g2d_enterFrame_handler);

        // Mouse interaction handlers
        g2d_nativeStage.addEventListener(MouseEvent.MOUSE_DOWN, g2d_mouseEvent_handler);
        g2d_nativeStage.addEventListener(MouseEvent.MOUSE_UP, g2d_mouseEvent_handler);
        g2d_nativeStage.addEventListener(MouseEvent.MOUSE_MOVE, g2d_mouseEvent_handler);
        g2d_nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, g2d_mouseEvent_handler);

        // Keyboard interaction handlers
        g2d_nativeStage.addEventListener(KeyboardEvent.KEY_DOWN, g2d_keyboardEvent_handler);
        g2d_nativeStage.addEventListener(KeyboardEvent.KEY_UP, g2d_keyboardEvent_handler);

        g2d_initialized = true;
        g2d_onInitialized.dispatch();
    }

    public function dispose():Void {
        GTextureManager.disposeAll();

		if (g2d_onInitialized != null) g2d_onInitialized.removeAll();
        g2d_onInitialized = null;
		if (g2d_onFailed != null) g2d_onFailed.removeAll();
        g2d_onFailed = null;
		if (g2d_onInitialized != null) g2d_onInitialized.removeAll();
        g2d_onInvalidated = null;
		if (g2d_onFrame != null) g2d_onFrame.removeAll();
        g2d_onFrame = null;
		if (g2d_onMouseInput != null) g2d_onMouseInput.removeAll();
        g2d_onMouseInput = null;
		g2d_onMouseInputInternal = null;
		if (g2d_onKeyboardInput != null) g2d_onKeyboardInput.removeAll();
        g2d_onKeyboardInput = null;

		g2d_nativeStage.removeEventListener(Event.ENTER_FRAME, g2d_enterFrame_handler);
		
		g2d_nativeStage.removeEventListener(MouseEvent.MOUSE_DOWN, g2d_mouseEvent_handler);
        g2d_nativeStage.removeEventListener(MouseEvent.MOUSE_UP, g2d_mouseEvent_handler);
        g2d_nativeStage.removeEventListener(MouseEvent.MOUSE_MOVE, g2d_mouseEvent_handler);
        g2d_nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, g2d_mouseEvent_handler);

        g2d_nativeStage.removeEventListener(KeyboardEvent.KEY_DOWN, g2d_keyboardEvent_handler);
        g2d_nativeStage.removeEventListener(KeyboardEvent.KEY_UP, g2d_keyboardEvent_handler);
		
		
		g2d_nativeStage.stage3Ds[0].removeEventListener(Event.CONTEXT3D_CREATE, g2d_contextInitialized_handler);
		g2d_nativeStage.stage3Ds[0].removeEventListener(ErrorEvent.ERROR, g2d_contextError_handler);
		if (g2d_nativeContext != null) g2d_nativeContext.dispose();
		
		g2d_reinitialize = 0;
	}

    public function resize(p_rect:GRectangle):Void {
        g2d_stageViewRect = p_rect;
        g2d_invalidate();
        g2d_onResize.dispatch(untyped __int__(g2d_stageViewRect.width), untyped __int__(g2d_stageViewRect.height));
    }
	
	private function g2d_contextError_handler(event:ErrorEvent):Void {
        g2d_onFailed.dispatch(event.text);
	}

    /****************************************************************************************************
     *  Scissor masking methods
     ****************************************************************************************************/
    /**
	  	Get the masking rectangle
	 */
    inline public function getMaskRect():GRectangle {
        return g2d_activeMaskRect;
    }

    /**
	  	Set masking rectangle for all subsequent draws

	  	@param p_maskRect AABB rectangle that defines masking
	 */
    inline public function setMaskRect(p_maskRect:GRectangle):Void {
        if (p_maskRect != g2d_activeMaskRect) {
            if (g2d_activeRenderer != null) g2d_activeRenderer.push();

            if (p_maskRect == null) {
                g2d_activeMaskRect = null;
                g2d_nativeContext.setScissorRectangle(g2d_activeViewRect);
            } else {
                g2d_activeMaskRect = g2d_activeViewRect.intersection(p_maskRect);
                g2d_nativeContext.setScissorRectangle(g2d_activeMaskRect);
            }
        }
    }

    /**
	  	Set camera that should be used for all subsequent draws
	 */
    public function setActiveCamera(p_camera:GCamera):Void {
		if (g2d_activeRenderer != null) g2d_activeRenderer.push();
		
        g2d_activeCamera = p_camera;

        g2d_activeViewRect.setTo(untyped __int__(g2d_stageViewRect.width*g2d_activeCamera.normalizedViewX),
                                 untyped __int__(g2d_stageViewRect.height*g2d_activeCamera.normalizedViewY),
                                 untyped __int__(g2d_stageViewRect.width*g2d_activeCamera.normalizedViewWidth),
                                 untyped __int__(g2d_stageViewRect.height*g2d_activeCamera.normalizedViewHeight));

        g2d_activeCamera.matrix.ortho(g2d_stageViewRect.width, g2d_stageViewRect.height);
        var vx:Float = g2d_activeViewRect.x + g2d_activeViewRect.width*.5;
        var vy:Float = g2d_activeViewRect.y + g2d_activeViewRect.height * .5;

        p_camera.matrix.prependTranslation(vx, vy, 0);
        p_camera.matrix.prependRotation(g2d_activeCamera.rotation*180/Math.PI, Vector3D.Z_AXIS, NORMALIZED_VECTOR);
        p_camera.matrix.prependScale(g2d_activeCamera.scaleX, g2d_activeCamera.scaleY, 1);
        p_camera.matrix.prependTranslation(-g2d_activeCamera.x, -g2d_activeCamera.y, 0);

        g2d_nativeContext.setScissorRectangle(g2d_activeViewRect);
        g2d_nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, g2d_activeCamera.matrix, true);
    }

    public function setDepthTest(p_depthMask:Bool, p_depthFunc:GDepthFunc):Void {
        if (g2d_activeRenderer != null) g2d_activeRenderer.push();

		switch (p_depthFunc) {
			case GDepthFunc.EQUAL:
				g2d_nativeContext.setDepthTest(p_depthMask, Context3DCompareMode.EQUAL);
			case GDepthFunc.GEQUAL:
				g2d_nativeContext.setDepthTest(p_depthMask, Context3DCompareMode.GREATER_EQUAL);
			case GDepthFunc.GREATER:
				g2d_nativeContext.setDepthTest(p_depthMask, Context3DCompareMode.GREATER);
			case GDepthFunc.LEQUAL:
				g2d_nativeContext.setDepthTest(p_depthMask, Context3DCompareMode.LESS_EQUAL);
			case GDepthFunc.LESS:
				g2d_nativeContext.setDepthTest(p_depthMask, Context3DCompareMode.LESS);
			case GDepthFunc.NEVER:
				g2d_nativeContext.setDepthTest(p_depthMask, Context3DCompareMode.NEVER);
			case GDepthFunc.NOTEQUAL:
				g2d_nativeContext.setDepthTest(p_depthMask, Context3DCompareMode.NOT_EQUAL);
			case GDepthFunc.ALWAYS:
				g2d_nativeContext.setDepthTest(p_depthMask, Context3DCompareMode.ALWAYS);
		}
    }
	
	/**
	  	Start the drawing
	 */
    public function begin():Bool {
        if (g2d_nativeContext.driverInfo == "Disposed") return false;
        g2d_stats.clear();
        setActiveCamera(g2d_defaultCamera);

		g2d_renderTarget = null;
		g2d_activeRenderer = null;
		g2d_activePremultiply = true;
		g2d_activeBlendMode = GBlendMode.NORMAL;

        if (!g2d_usingExternalContext) {
		    g2d_nativeContext.clear(g2d_backgroundRed, g2d_backgroundGreen, g2d_backgroundBlue, g2d_backgroundAlpha, 1);
        }

		setDepthTest(false, GDepthFunc.ALWAYS);
        g2d_nativeContext.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP);
        g2d_nativeContext.setCulling(Context3DTriangleFace.BACK);
		GBlendMode.setBlendMode(g2d_nativeContext, GBlendMode.NORMAL, g2d_activePremultiply);
        return true;
	}
	
	/**
	  	End the drawing
	 */
    public function end():Void {
		if (g2d_renderTarget != null) setRenderTarget(null);
        g2d_stats.render(this);

        flushRenderer();

		if (g2d_bitmapDataTarget != null) {
			g2d_nativeContext.drawToBitmapData(g2d_bitmapDataTarget);
			if (g2d_useBitmapDataTargetOnce) g2d_bitmapDataTarget = null;
		}
		
        if (!g2d_usingExternalContext) {
		    g2d_nativeContext.present();
        }
	}

    @:dox(hide)
    inline public function draw2(p_texture:GTexture, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null, p_id:Int = 0):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            setRenderer(g2d_quadTextureBufferGPURenderer);

            g2d_quadTextureBufferGPURenderer.draw(p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_red, p_green, p_blue, p_alpha, p_texture, p_filter);
        }
    }

    /**
       Draw quad

       @param p_texture textures instance used to drawing
     */
	inline public function draw(p_texture:GTexture, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null):Void {
		if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
			setRenderer(g2d_quadTextureShaderRenderer);

			g2d_quadTextureShaderRenderer.draw(p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_red, p_green, p_blue, p_alpha, p_texture, p_filter, false, 0, 0, 0, 0, 0, 0);
		}
	}

    /**
       Draw quad using source rectangle

       @param p_texture textures to be drawn
     */
    inline public function drawSource(p_texture:GTexture, p_sourceX:Float, p_sourceY:Float, p_sourceWidth:Float, p_sourceHeight:Float, p_sourcePivotX:Float, p_sourcePivotY:Float, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            setRenderer(g2d_quadTextureShaderRenderer);

            g2d_quadTextureShaderRenderer.draw(p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_red, p_green, p_blue, p_alpha, p_texture, p_filter, true, p_sourceX, p_sourceY, p_sourceWidth, p_sourceHeight, p_sourcePivotX, p_sourcePivotY);
        }
    }

    /**
       Draw quad using 2D matrix raw data

       @param p_texture textures to be drawn
     */
    inline public function drawMatrix(p_texture:GTexture, p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float=1, p_blendMode:Int=1, p_filter:GFilter = null):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            setRenderer(g2d_matrixQuadTextureShaderRenderer);
            g2d_matrixQuadTextureShaderRenderer.draw(p_a, p_b, p_c, p_d, p_tx, p_ty, p_red, p_green, p_blue, p_alpha, p_texture, p_filter, false, 0, 0, 0, 0);
        }
    }

    /**
       Draw quad using 2D matrix raw data

       @param p_texture textures to be drawn
     */
    inline public function drawMatrixSource(p_texture:GTexture, p_sourceX:Float, p_sourceY:Float, p_sourceWidth:Float, p_sourceHeight:Float, p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float=1, p_blendMode:Int=1, p_filter:GFilter = null):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            setRenderer(g2d_matrixQuadTextureShaderRenderer);

            g2d_matrixQuadTextureShaderRenderer.draw(p_a, p_b, p_c, p_d, p_tx, p_ty, p_red, p_green, p_blue, p_alpha, p_texture, p_filter, true, p_sourceX, p_sourceY, p_sourceWidth, p_sourceHeight);
        }
    }

    /**
        Draw polygon

        @param p_texture textures to be used for fill
        @param p_vertices triangulated vertices that define the polygon
        @param p_uvs uvs that correspond to the vertices defined
        @param p_x x translation
        @param p_y y translation
        @param p_scaleX x scale
        @param p_scaleY y scale
        @param p_rotation rotation
     */
    inline public function drawPoly(p_texture:GTexture, p_vertices:Array<Float>, p_uvs:Array<Float>, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int=1, p_filter:GFilter = null):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            setRenderer(g2d_triangleTextureBufferCPURenderer);

            g2d_triangleTextureBufferCPURenderer.draw(p_vertices, p_uvs, p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_red, p_green, p_blue, p_alpha, p_texture, p_filter);
        }
    }

    inline public function setBlendMode(p_blendMode:Int, p_premultiplied:Bool):Void {
        if (p_blendMode != g2d_activeBlendMode || p_premultiplied != g2d_activePremultiply) {
            if (g2d_activeRenderer != null) g2d_activeRenderer.push();

            g2d_activeBlendMode = p_blendMode;
            g2d_activePremultiply = p_premultiplied;
            GBlendMode.setBlendMode(g2d_nativeContext, g2d_activeBlendMode, g2d_activePremultiply);
        }
    }

	inline public function setRenderer(p_renderer:IGRenderer):Void {
		if (p_renderer != g2d_activeRenderer || g2d_activeRenderer == null) {
			flushRenderer();
			
			g2d_activeRenderer = p_renderer;
            g2d_activeRenderer.bind(this, g2d_reinitialize);
		}
	}
	
	inline public function getRenderer():IGRenderer {
		return g2d_activeRenderer;
	}
	
	inline public function flushRenderer():Void {
		if (g2d_activeRenderer != null) {
            g2d_activeRenderer.push();
            g2d_activeRenderer.clear();
        }
	}

	/****************************************************************************************************
     *  Stencil methods
     ****************************************************************************************************/

	private var g2d_activeStencilLayer:Int = 0;

    /**
        Clears the stencil buffer
     */
	public function clearStencil():Void {
		if (g2d_activeRenderer != null) g2d_activeRenderer.push();
		g2d_nativeContext.clear(0,0,0,0,0,0,Context3DClearMask.STENCIL);
	}

    /**
        Sets the render target to stencil buffer

        @param p_stencilLayer active masking stencil layer
     */
	public function renderToStencil(p_stencilLayer:Int):Void {
		if (g2d_activeRenderer != null) g2d_activeRenderer.push();
		g2d_activeStencilLayer = p_stencilLayer;
		g2d_nativeContext.setStencilReferenceValue(g2d_activeStencilLayer);
		g2d_nativeContext.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.GREATER_EQUAL, Context3DStencilAction.INCREMENT_SATURATE);
		g2d_nativeContext.setColorMask(false, false, false, false);
	}

    /**
        Switch rendering to color buffer

        @param p_stencilLayer stencil layer to be used for masking
     */
	public function renderToColor(p_stencilLayer:Int):Void {
        if (g2d_activeRenderer != null) g2d_activeRenderer.push();
		g2d_activeStencilLayer = p_stencilLayer;
		g2d_nativeContext.setStencilReferenceValue(g2d_activeStencilLayer);
		g2d_nativeContext.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.LESS_EQUAL, Context3DStencilAction.KEEP);
		g2d_nativeContext.setColorMask(true, true, true, true);
	}

    /****************************************************************************************************
     *  Render target methods
     ****************************************************************************************************/
    private var g2d_usedRenderTargets:Int = 0;
    private var g2d_renderTargetStack:Array<GTexture>;
	
    private var g2d_renderTarget:GTexture;
	/**
        Gets the current render target, if null the target is backbuffer
     */
    public function getRenderTarget():GTexture {
        return g2d_renderTarget;
    }
	
    private var g2d_renderTargetMatrix:GMatrix3D;
	public function getRenderTargetMatrix():GMatrix3D {
		return g2d_renderTargetMatrix;
	}

    /**
        Sets the render target for all subsequent draw calls

        @param p_texture textures target, if null it will target backbuffer
        @param p_transform additional transformation that should be applied, not applicable to backbuffer target
     */
	public function setRenderTarget(p_texture:GTexture = null, p_transform:GMatrix3D = null, p_clear:Bool = true):Void {
		if (g2d_renderTarget == p_texture && g2d_usedRenderTargets==0) return;
		
		if (g2d_activeRenderer != null) g2d_activeRenderer.push();

        // Clear MRT
        for (i in 1...g2d_usedRenderTargets) {
            g2d_nativeContext.setRenderToTexture(null, g2d_enableDepthAndStencil, g2d_antiAliasing, 0, i);
        }
        g2d_usedRenderTargets = 0;

        // If the target is null its a backbuffer
		if (p_texture == null) {
			g2d_nativeContext.setRenderToBackBuffer();

            // Reset camera
            setActiveCamera(g2d_activeCamera);
        // Otherwise its a render texture
		} else {
			if (p_texture.nativeTexture == null) MGDebug.WARNING("Null render texture, will incorrectly render to backbuffer instead.");
			g2d_nativeContext.setRenderToTexture(p_texture.nativeTexture, g2d_enableDepthAndStencil, g2d_antiAliasing, 0);
            g2d_nativeContext.setScissorRectangle(null);
            if (p_texture.needClearAsRenderTarget(p_clear)) g2d_nativeContext.clear(0,0,0,0);

			g2d_nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, GProjectionMatrix.getOrtho(p_texture.nativeWidth, p_texture.nativeHeight, p_transform), true);
		}

        g2d_renderTargetMatrix = p_transform;
		g2d_renderTarget = p_texture;
    }

    public function setRenderTargets(p_textures:Array<GTexture>, p_transform:GMatrix3D = null, p_clear:Bool = true):Void {
        if (g2d_activeRenderer != null) g2d_activeRenderer.push();

        for (i in 0...p_textures.length) {
            g2d_nativeContext.setRenderToTexture(p_textures[i].nativeTexture, g2d_enableDepthAndStencil, g2d_antiAliasing, 0, i);
        }

        g2d_nativeContext.setScissorRectangle(null);
        if (p_clear) g2d_nativeContext.clear(0,0,0,0,0);
        g2d_nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, GProjectionMatrix.getOrtho(p_textures[0].width, p_textures[0].height, p_transform), true);

        g2d_usedRenderTargets = p_textures.length;
    }
	
	
	public function setBitmapDataTarget(p_bitmapData:BitmapData, p_useOnce:Bool = true):Void {
		g2d_bitmapDataTarget = p_bitmapData;
	}

    private function g2d_enterFrame_handler(event:Event):Void {
        var currentTime:Float =  untyped __global__["flash.utils.getTimer"]();
        g2d_currentDeltaTime = currentTime - g2d_currentTime;
        g2d_currentTime = currentTime;
        g2d_onFrame.dispatch(g2d_currentDeltaTime);
    }

    private function g2d_mouseEvent_handler(event:MouseEvent):Void {
        var captured:Bool = false;
        if (enableNativeContentMouseCapture && event.target != g2d_nativeStage) captured = true;

        var mx:Float = event.stageX - g2d_stageViewRect.x;
        var my:Float = event.stageY - g2d_stageViewRect.y;
		
        var input:GMouseInput = new GMouseInput(this, this, GMouseInputType.fromNative(event.type), mx, my);
		input.worldX = input.contextX = mx;
		input.worldY = input.contextY = my;
        input.buttonDown = event.buttonDown;
        input.ctrlKey = event.ctrlKey;
        input.altKey = event.altKey;
        input.shiftKey = event.shiftKey;
        input.delta = event.delta;
		input.nativeCaptured = captured;
		
        g2d_onMouseInput.dispatch(input);
		g2d_onMouseInputInternal(input);
    }

    private function g2d_keyboardEvent_handler(event:KeyboardEvent):Void {
        var input:GKeyboardInput = new GKeyboardInput(GKeyboardInputType.fromNative(event.type), event.keyCode, event.charCode);
		input.ctrlKey = event.ctrlKey;
		input.altKey = event.altKey;
		input.shiftKey = event.shiftKey;
        g2d_onKeyboardInput.dispatch(input);
    }
}