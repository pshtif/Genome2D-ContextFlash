/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.stage3d;

import msignal.Signal.Signal0;
import msignal.Signal.Signal1;
import com.genome2d.geom.GMatrix3D;
import flash.utils.Object;
import com.genome2d.context.stage3d.renderers.GRenderersCommon;
import com.genome2d.context.stats.IStats;
import flash.Vector;
import com.genome2d.error.GError;
import com.genome2d.geom.GRectangle;
import com.genome2d.context.stage3d.renderers.GMatrixQuadTextureShaderRenderer;
import flash.display3D.Context3DTriangleFace;
import com.genome2d.context.stage3d.renderers.GTriangleTextureBufferCPURenderer;
import com.genome2d.context.stage3d.renderers.GQuadTextureShaderRenderer;
import com.genome2d.context.filters.GFilter;
import com.genome2d.context.stage3d.renderers.GQuadTextureBufferGPURenderer;
import com.genome2d.context.stage3d.GProjectionMatrix;
import flash.geom.Vector3D;
import com.genome2d.textures.GContextTexture;
import com.genome2d.context.GBlendMode;
import com.genome2d.context.GContextCamera;

import com.genome2d.context.stage3d.renderers.IGRenderer;
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
import com.genome2d.signals.GKeyboardSignalType;
import com.genome2d.signals.GMouseSignalType;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import com.genome2d.signals.GMouseSignal;
import com.genome2d.signals.GKeyboardSignal;

#if stage3Donly
@:native("com.genome2d.context.IContext")
class GStage3DContext
#else
class GStage3DContext implements IContext
#end
{
    public function hasFeature(p_feature:Int):Bool {
        switch (p_feature) {
            case GContextFeature.STENCIL_MASKING:
                return g2d_enableDepthAndStencil;
            case GContextFeature.RECTANGLE_TEXTURES:
                return (g2d_profile != "baselineConstrained" && untyped g2d_nativeContext.hasOwnProperty("createRectangleTexture"));
        }

        return false;
    }

    private var NORMALIZED_VECTOR:Vector3D;

    private var g2d_nativeStage:Stage;
    public function getNativeStage():Stage {
        return g2d_nativeStage;
    }

    private var g2d_activeCamera:GContextCamera;
    public function getActiveCamera():GContextCamera {
        return g2d_activeCamera;
    }
    private var g2d_activeViewRect:GRectangle;

    private var g2d_activeMaskRect:GRectangle;

    private var g2d_initialized:Bool = false;
    private var g2d_reinitialize:Bool = false;

    private var g2d_stageViewRect:GRectangle;
    inline public function getStageViewRect():GRectangle {
        return g2d_stageViewRect;
    }
    private var g2d_defaultCamera:GContextCamera;
    inline public function getDefaultCamera():GContextCamera {
        return g2d_defaultCamera;
    }

    private var g2d_stats:IStats;

    private var g2d_currentTime:Float = 0;
    private var g2d_currentDeltaTime:Float;

    /*
     *  SIGNALS
     */
    private var g2d_onInitialized:Signal0;
    #if swc @:extern #end
    public var onInitialized(get,never):Signal0;
    #if swc @:getter(onInitialized) #end
    inline private function get_onInitialized():Signal0{
        return g2d_onInitialized;
    }

    private var g2d_onFailed:Signal1<String>;
    #if swc @:extern #end
    public var onFailed(get,never):Signal1<String>;
    #if swc @:getter(onFailed) #end
    inline private function get_onFailed():Signal1<String>{
        return g2d_onFailed;
    }

    private var g2d_onFrame:Signal1<Float>;
    #if swc @:extern #end
    public var onFrame(get,never):Signal1<Float>;
    #if swc @:getter(onFrame) #end
    inline private function get_onFrame():Signal1<Float>{
        return g2d_onFrame;
    }

    private var g2d_onKeyboardSignal:Signal1<GKeyboardSignal>;
    #if swc @:extern #end
    public var onKeyboardSignal(get,never):Signal1<GKeyboardSignal>;
    #if swc @:getter(onKeyboardSignal) #end
    inline private function get_onKeyboardSignal():Signal1<GKeyboardSignal>{
        return g2d_onKeyboardSignal;
    }

    private var g2d_onMouseSignal:Signal1<GMouseSignal>;
    #if swc @:extern #end
    public var onMouseSignal(get,never):Signal1<GMouseSignal>;
    #if swc @:getter(onMouseSignal) #end
    inline private function get_onMouseSignal():Signal1<GMouseSignal>{
        return g2d_onMouseSignal;
    }

    private var g2d_onInvalidated:Signal0;
    #if swc @:extern #end
    public var onInvalidated(get,never):Signal0;
    #if swc @:getter(onInvalidated) #end
    inline private function get_onInvalidated():Signal0{
        return g2d_onInvalidated;
    }

    private var g2d_nativeStage3D:Stage3D;

    private var g2d_nativeContext:Context3D;
    inline public function getNativeContext():Context3D {
        return g2d_nativeContext;
    }

	private var g2d_activeRenderer:IGRenderer;
	private var g2d_activeBlendMode:Int;
	private var g2d_activePremultiply:Bool;

    private var g2d_antiAliasing:Int;
    private var g2d_enableDepthAndStencil:Bool;
    private var g2d_renderMode:String;
    private var g2d_profile:Object;
    private var g2d_usingExternalContext:Bool;

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
        if (p_config.nativeStage == null) new GError("You need to specify nativeStage in the config");

        NORMALIZED_VECTOR = new Vector3D();

        g2d_onInitialized = new Signal0();
        g2d_onFailed = new Signal1<String>();
        g2d_onFrame = new Signal1<Float>();
        g2d_onMouseSignal = new Signal1<GMouseSignal>();
        g2d_onKeyboardSignal = new Signal1<GKeyboardSignal>();
        g2d_onInvalidated = new Signal0();

        g2d_stageViewRect = p_config.viewRect;
		g2d_nativeStage = p_config.nativeStage;
		g2d_stats = untyped __new__(p_config.statsClass);
        g2d_usingExternalContext = p_config.externalStage3D != null;
        g2d_nativeStage3D = p_config.externalStage3D;

        g2d_antiAliasing = p_config.antiAliasing;
        g2d_enableDepthAndStencil = p_config.enableDepthAndStencil;
        g2d_renderMode = p_config.renderMode;
        g2d_profile = p_config.profile;

        g2d_useSeparateAlphaPipeline = p_config.useSeparateAlphaPipeline;
        g2d_useFastMem = p_config.useFastMem;
    }
	
	/**
	 * 	Initialize the context
	 */
    public function init():Void {
        if (g2d_usingExternalContext) {
            g2d_contextInitializedHandler(null);
            g2d_nativeStage3D.addEventListener(Event.CONTEXT3D_CREATE, g2d_contextInitializedHandler);
        } else {
            g2d_nativeStage3D = g2d_nativeStage.stage3Ds[0];
            g2d_nativeStage3D.addEventListener(Event.CONTEXT3D_CREATE, g2d_contextInitializedHandler);
            g2d_nativeStage3D.addEventListener(ErrorEvent.ERROR, g2d_contextErrorHandler);

            var multipleProfiles:Bool = untyped __is__(g2d_profile,  __as__(__global__["flash.utils.getDefinitionByName"]("__AS3__.vec::Vector.<String>"), Class));
            var autoDetectAvailable:Bool = untyped g2d_nativeStage3D.hasOwnProperty("requestContext3DMatchingProfiles");
            if (autoDetectAvailable && multipleProfiles) {
                untyped g2d_nativeStage3D["requestContext3DMatchingProfiles"](g2d_profile);
            } else {
                g2d_nativeStage3D.requestContext3D(g2d_renderMode, (multipleProfiles) ? g2d_profile[untyped __int__(g2d_profile.length-1)] : g2d_profile);
            }
        }
	}

    private function g2d_contextInitializedHandler(event:Event):Void {
        g2d_nativeContext = g2d_nativeStage3D.context3D;
        g2d_nativeContext.enableErrorChecking = false;

        if (g2d_useFastMem) {
            g2d_fastMemArray = new ByteArray();
            g2d_fastMemArray.endian = Endian.LITTLE_ENDIAN;
            g2d_fastMemArray.length = 10040000;
            Memory.select(g2d_fastMemArray);
        }

        if (untyped g2d_nativeContext.hasOwnProperty("profile")) {
            g2d_profile = untyped g2d_nativeContext["profile"];
        }

        // Init renderers
        GRenderersCommon.init(g2d_profile == "standard" ? 2 : 1);
        g2d_quadTextureShaderRenderer = new GQuadTextureShaderRenderer(g2d_useFastMem, g2d_fastMemArray);
        g2d_quadTextureBufferGPURenderer = new GQuadTextureBufferGPURenderer(g2d_useFastMem, g2d_fastMemArray);
        g2d_matrixQuadTextureShaderRenderer = new GMatrixQuadTextureShaderRenderer(g2d_useFastMem, g2d_fastMemArray);

        g2d_triangleTextureBufferCPURenderer = new GTriangleTextureBufferCPURenderer();

        GContextTexture.invalidateAll(true);

        g2d_invalidate();

        g2d_reinitialize = true;
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
                var w:Int = untyped __int__(g2d_stageViewRect.width);
                var h:Int = untyped __int__(g2d_stageViewRect.height);
                g2d_nativeContext.configureBackBuffer(w, h, g2d_antiAliasing, g2d_enableDepthAndStencil);
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

                g2d_onInvalidated.dispatch();
            }
        }
    }

    private function g2d_initComplete():Void {
        g2d_defaultCamera = new GContextCamera();
        g2d_defaultCamera.x = g2d_stageViewRect.width*.5;
        g2d_defaultCamera.y = g2d_stageViewRect.height*.5;
        g2d_activeViewRect = new GRectangle();

        // Frame handler
        g2d_nativeStage.addEventListener(Event.ENTER_FRAME, g2d_enterFrameHandler);

        // Mouse interaction handlers
        g2d_nativeStage.addEventListener(MouseEvent.MOUSE_DOWN, g2d_mouseEventHandler);
        g2d_nativeStage.addEventListener(MouseEvent.MOUSE_UP, g2d_mouseEventHandler);
        g2d_nativeStage.addEventListener(MouseEvent.MOUSE_MOVE, g2d_mouseEventHandler);

        // Keyboard interaction handlers
        g2d_nativeStage.addEventListener(KeyboardEvent.KEY_DOWN, g2d_keyboardEventHandler);
        g2d_nativeStage.addEventListener(KeyboardEvent.KEY_UP, g2d_keyboardEventHandler);

        g2d_initialized = true;
        g2d_onInitialized.dispatch();
    }

    public function dispose():Void {
        GContextTexture.disposeAll();

        g2d_onInitialized = null;
        g2d_onFailed = null;
        g2d_onInvalidated = null;
        g2d_onFrame = null;
        g2d_onMouseSignal = null;
        g2d_onKeyboardSignal = null;

		g2d_nativeStage.stage3Ds[0].removeEventListener(Event.CONTEXT3D_CREATE, g2d_contextInitializedHandler);
		g2d_nativeStage.stage3Ds[0].removeEventListener(ErrorEvent.ERROR, g2d_contextErrorHandler);
		g2d_nativeContext.dispose();
	}

    public function resize(p_rect:GRectangle):Void {
        g2d_stageViewRect = p_rect;
        g2d_invalidate();
    }
	
	private function g2d_contextErrorHandler(event:ErrorEvent):Void {
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
    public function setCamera(p_camera:GContextCamera):Void {
        g2d_activeCamera = p_camera;

        g2d_activeViewRect.setTo(untyped __int__(g2d_stageViewRect.width*g2d_activeCamera.normalizedViewX),
                                 untyped __int__(g2d_stageViewRect.height*g2d_activeCamera.normalizedViewY),
                                 untyped __int__(g2d_stageViewRect.width*g2d_activeCamera.normalizedViewWidth),
                                 untyped __int__(g2d_stageViewRect.height*g2d_activeCamera.normalizedViewHeight));

        if (g2d_activeRenderer != null) g2d_activeRenderer.push();

        g2d_activeCamera.matrix.ortho(g2d_stageViewRect.width, g2d_stageViewRect.height);
        var vx:Float = g2d_activeViewRect.x + g2d_activeViewRect.width*.5;
        var vy:Float = g2d_activeViewRect.y + g2d_activeViewRect.height * .5;

        p_camera.matrix.prependTranslation(vx, vy, 0);
        p_camera.matrix.prependRotation(g2d_activeCamera.rotation*180/Math.PI, Vector3D.Z_AXIS, NORMALIZED_VECTOR);
        p_camera.matrix.prependScale(g2d_activeCamera.scaleX, g2d_activeCamera.scaleY, 1);
        p_camera.matrix.prependTranslation( -g2d_activeCamera.x, -g2d_activeCamera.y, 0);

        g2d_nativeContext.setScissorRectangle(g2d_activeViewRect);
        g2d_nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, g2d_activeCamera.matrix, true);
    }

    public function setDepthTest(p_depthMask:Bool, p_compareMode:Context3DCompareMode):Void {
        if (g2d_activeRenderer != null) g2d_activeRenderer.push();

        g2d_nativeContext.setDepthTest(p_depthMask, p_compareMode);
    }
	
	/**
	  	Start the drawing
	 */
    public function begin():Void {
        g2d_stats.clear();
        setCamera(g2d_defaultCamera);

		g2d_renderTarget = null;
		g2d_activeRenderer = null;
		g2d_activePremultiply = true;
		g2d_activeBlendMode = GBlendMode.NORMAL;

        if (!g2d_usingExternalContext) {
		    g2d_nativeContext.clear(g2d_backgroundRed, g2d_backgroundGreen, g2d_backgroundBlue, g2d_backgroundAlpha, 0);
        }

		g2d_nativeContext.setDepthTest(false, Context3DCompareMode.ALWAYS);
        //g2d_nativeContext.setDepthTest(true, Context3DCompareMode.GREATER);
        g2d_nativeContext.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP);
        g2d_nativeContext.setCulling(Context3DTriangleFace.NONE);
		GBlendMode.setBlendMode(g2d_nativeContext, GBlendMode.NORMAL, g2d_activePremultiply);
	}
	
	/**
	  	End the drawing
	 */
    public function end():Void {
        g2d_stats.render(this);

        if (g2d_activeRenderer != null) {
            g2d_activeRenderer.push();
            g2d_activeRenderer.clear();
        }

        if (!g2d_usingExternalContext) {
		    g2d_nativeContext.present();
        }
		g2d_reinitialize = false;
	}

    @:dox(hide)
    inline public function draw2(p_texture:GContextTexture, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null, p_id:Int = 0):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            bindRenderer(g2d_quadTextureBufferGPURenderer);

            g2d_quadTextureBufferGPURenderer.draw(p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_red, p_green, p_blue, p_alpha, p_texture, p_filter);
        }
    }

    /**
       Draw quad

       @param p_texture texture instance used to drawing
     */
	inline public function draw(p_texture:GContextTexture, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null):Void {
		if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
			bindRenderer(g2d_quadTextureShaderRenderer);

			g2d_quadTextureShaderRenderer.draw(p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_red, p_green, p_blue, p_alpha, p_texture, p_filter, false, 0, 0, 0, 0);
		}
	}

    /**
       Draw quad using source rectangle

       @param p_texture texture to be drawn
     */
    inline public function drawSource(p_texture:GContextTexture, p_sourceX:Float, p_sourceY:Float, p_sourceWidth:Float, p_sourceHeight:Float, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            bindRenderer(g2d_quadTextureShaderRenderer);

            g2d_quadTextureShaderRenderer.draw(p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_red, p_green, p_blue, p_alpha, p_texture, p_filter, true, p_sourceX, p_sourceY, p_sourceWidth, p_sourceHeight);
        }
    }

    /**
       Draw quad using 2D matrix raw data

       @param p_texture texture to be drawn
     */
    inline public function drawMatrix(p_texture:GContextTexture, p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float=1, p_blendMode:Int=1, p_filter:GFilter = null):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            bindRenderer(g2d_matrixQuadTextureShaderRenderer);
            g2d_matrixQuadTextureShaderRenderer.draw(p_a, p_b, p_c, p_d, p_tx, p_ty, p_red, p_green, p_blue, p_alpha, p_texture, p_filter, false, 0, 0, 0, 0);
        }
    }

    /**
       Draw quad using 2D matrix raw data

       @param p_texture texture to be drawn
     */
    inline public function drawMatrixSource(p_texture:GContextTexture, p_sourceX:Float, p_sourceY:Float, p_sourceWidth:Float, p_sourceHeight:Float, p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float=1, p_blendMode:Int=1, p_filter:GFilter = null):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            bindRenderer(g2d_matrixQuadTextureShaderRenderer);

            g2d_matrixQuadTextureShaderRenderer.draw(p_a, p_b, p_c, p_d, p_tx, p_ty, p_red, p_green, p_blue, p_alpha, p_texture, p_filter, true, p_sourceX, p_sourceY, p_sourceWidth, p_sourceHeight);
        }
    }

    /**
        Draw polygon

        @param p_texture texture to be used for fill
        @param p_vertices triangulated vertices that define the polygon
        @param p_uvs uvs that correspond to the vertices defined
        @param p_x x translation
        @param p_y y translation
        @param p_scaleX x scale
        @param p_scaleY y scale
        @param p_rotation rotation
     */
    inline public function drawPoly(p_texture:GContextTexture, p_vertices:Array<Float>, p_uvs:Array<Float>, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int=1, p_filter:GFilter = null):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            bindRenderer(g2d_triangleTextureBufferCPURenderer);

            g2d_triangleTextureBufferCPURenderer.draw(p_vertices, p_uvs, p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_red, p_green, p_blue, p_alpha, p_texture, p_filter);
        }
    }

    inline public function setBlendMode(p_blendMode:Int, p_premultiplied:Bool):Void {
        if (p_blendMode != g2d_activeBlendMode || p_premultiplied != g2d_activePremultiply) {
            if (g2d_activeRenderer != null) {
                g2d_activeRenderer.push();
            }

            g2d_activeBlendMode = p_blendMode;
            g2d_activePremultiply = p_premultiplied;
            GBlendMode.setBlendMode(g2d_nativeContext, g2d_activeBlendMode, g2d_activePremultiply);
        }
    }

	inline public function bindRenderer(p_renderer:IGRenderer):Void {
		if (p_renderer != g2d_activeRenderer || g2d_activeRenderer == null) {
			if (g2d_activeRenderer != null) {
				g2d_activeRenderer.push();
				g2d_activeRenderer.clear();
			}
			
			g2d_activeRenderer = p_renderer;
            g2d_activeRenderer.bind(this, g2d_reinitialize);
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
    private var g2d_renderTarget:GContextTexture;
    private var g2d_renderTargetMatrix:Matrix3D;
    private var g2d_usedRenderTargets:Int = 0;

    /**
        Gets the current render target, if null the target is backbuffer
     */
    public function getRenderTarget():GContextTexture {
        return g2d_renderTarget;
    }

    /**
        Sets the render target for all subsequent draw calls

        @param p_texture texture target, if null it will target backbuffer
        @param p_transform additional transformation that should be applied, not applicable to backbuffer target
     */
	public function setRenderTarget(p_texture:GContextTexture = null, p_transform:GMatrix3D = null):Void {
		if (g2d_renderTarget == p_texture && g2d_usedRenderTargets==0) return;
		
		if (g2d_activeRenderer != null) g2d_activeRenderer.push();

        if (g2d_usedRenderTargets>0) {
            for (i in 1...g2d_usedRenderTargets) {
                g2d_nativeContext.setRenderToTexture(null, g2d_enableDepthAndStencil, g2d_antiAliasing, 0, i);
            }
            g2d_usedRenderTargets = 0;
        }

		if (p_texture == null) {
			g2d_nativeContext.setRenderToBackBuffer();

            // Reset camera
            setCamera(g2d_activeCamera);
		} else {
			g2d_nativeContext.setRenderToTexture(p_texture.nativeTexture, g2d_enableDepthAndStencil, g2d_antiAliasing, 0);
			g2d_nativeContext.clear(0,0,0,0);
			
			g2d_nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, GProjectionMatrix.getOrtho(p_texture.width, p_texture.height, p_transform), true);
		}
		
		g2d_renderTarget = p_texture;
    }

    public function setRenderTargets(p_textures:Array<GContextTexture>, p_transform:GMatrix3D = null):Void {
        if (g2d_activeRenderer != null) g2d_activeRenderer.push();

        for (i in 0...p_textures.length) {
            g2d_nativeContext.setRenderToTexture(p_textures[i].nativeTexture, g2d_enableDepthAndStencil, g2d_antiAliasing, 0, i);
        }

        g2d_nativeContext.clear(0,0,0,0,0);
        g2d_nativeContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, GProjectionMatrix.getOrtho(p_textures[0].width, p_textures[0].height, p_transform), true);

        g2d_usedRenderTargets = p_textures.length;
    }

    private function g2d_enterFrameHandler(event:Event):Void {
        var currentTime:Float =  untyped __global__["flash.utils.getTimer"]();
        g2d_currentDeltaTime = currentTime - g2d_currentTime;
        g2d_currentTime = currentTime;
        g2d_onFrame.dispatch(g2d_currentDeltaTime);
    }

    private function g2d_mouseEventHandler(event:MouseEvent):Void {
        var captured:Bool = false;
        if (enableNativeContentMouseCapture && event.target != g2d_nativeStage) captured = true;

        var mx:Float = event.stageX-g2d_stageViewRect.x;
        var my:Float = event.stageY-g2d_stageViewRect.y;
        var signal:GMouseSignal = new GMouseSignal(GMouseSignalType.fromNative(event.type), mx, my, captured);// event.buttonDown, event.ctrlKey,
        g2d_onMouseSignal.dispatch(signal);
    }

    private function g2d_keyboardEventHandler(event:KeyboardEvent):Void {
        var signal:GKeyboardSignal = new GKeyboardSignal(GKeyboardSignalType.fromNative(event.type), event.keyCode);
        g2d_onKeyboardSignal.dispatch(signal);
    }
}