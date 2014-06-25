/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.bitmap;

#if !stage3Donly
import com.genome2d.geom.GMatrix3D;
import msignal.Signal.Signal0;
import msignal.Signal.Signal1;
import flash.geom.Matrix3D;
import com.genome2d.signals.GKeyboardSignalType;
import com.genome2d.signals.GMouseSignalType;
import com.genome2d.context.stats.GStats;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.Event;
import com.genome2d.geom.GRectangle;
import com.genome2d.signals.GKeyboardSignal;
import com.genome2d.signals.GMouseSignal;
import com.genome2d.error.GError;
import com.genome2d.context.filters.GFilter;
import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.display.Sprite;
import flash.display.Stage;
import flash.geom.Matrix;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;

import com.genome2d.context.GContextCamera;
import com.genome2d.textures.GContextTexture;

class GBitmapContext implements IContext
{
    public function hasFeature(p_feature:Int):Bool {
        return false;
    }

    private var ZERO_POINT:Point;

    private var g2d_nativeStage:Stage;
    public function getNativeStage():Stage {
        return g2d_nativeStage;
    }
    private var g2d_stageViewRect:GRectangle;
    inline public function getStageViewRect():GRectangle {
        return g2d_stageViewRect;
    }
    public var g2d_defaultCamera:GContextCamera;
    inline public function getDefaultCamera():GContextCamera {
        return g2d_defaultCamera;
    }

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

    private var g2d_stats:GStats;
    private var g2d_activeCamera:GContextCamera;
    private var g2d_activeViewRect:GRectangle;
    private var g2d_activeMaskRect:GRectangle;
    private var g2d_initialized:Bool = false;
    private var g2d_currentTime:Float = 0;
    private var g2d_currentDeltaTime:Float;
    private var g2d_renderTarget:GContextTexture;
    private var g2d_renderTargetMatrix:Matrix3D;

    public var enableNativeContentMouseCapture:Bool = false;

    private var g2d_nativeContext:BitmapData;
    public function getNativeContext():BitmapData {
        return g2d_nativeContext;
    }

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

    private var g2d_nativeContextWrapper:Bitmap;
	private var g2d_matrix:Matrix;
	private var g2d_colorTransform:ColorTransform;
	private var g2d_point:Point;
	private var g2d_cameraBitmap:BitmapData;
	
	public function new(p_config:GContextConfig) {
        if (p_config.nativeStage == null) new GError("You need to specify nativeStage in the GContextConfig");

        ZERO_POINT = new Point();

        g2d_onInitialized = new Signal0();
        g2d_onFailed = new Signal1<String>();
        g2d_onFrame = new Signal1<Float>();
        g2d_onMouseSignal = new Signal1<GMouseSignal>();
        g2d_onKeyboardSignal = new Signal1<GKeyboardSignal>();
        g2d_onInvalidated = new Signal0();

        g2d_stageViewRect = p_config.viewRect;
        g2d_nativeStage = p_config.nativeStage;
        g2d_stats = new GStats();

		g2d_matrix = new Matrix();
		g2d_point = new Point();
		g2d_colorTransform = new ColorTransform();
	}

    public function getMaskRect():GRectangle {
        return g2d_activeMaskRect;
    }
    public function setMaskRect(p_maskRect:GRectangle):Void {
        g2d_activeMaskRect = p_maskRect;
    }

	public function setCamera(p_camera:GContextCamera):Void {
        g2d_activeCamera = p_camera;

        g2d_activeViewRect.setTo(untyped __int__(g2d_stageViewRect.width*g2d_activeCamera.normalizedViewX),
                                 untyped __int__(g2d_stageViewRect.height*g2d_activeCamera.normalizedViewY),
                                 untyped __int__(g2d_stageViewRect.width*g2d_activeCamera.normalizedViewWidth),
                                 untyped __int__(g2d_stageViewRect.height*g2d_activeCamera.normalizedViewHeight));

        if (g2d_cameraBitmap != null) {
            g2d_point.x = g2d_stageViewRect.width * g2d_activeCamera.normalizedViewX;
            g2d_point.y = g2d_stageViewRect.height * g2d_activeCamera.normalizedViewY;
            g2d_nativeContext.copyPixels(g2d_cameraBitmap, g2d_cameraBitmap.rect, g2d_point);
            g2d_cameraBitmap.dispose();
        }

        g2d_cameraBitmap = new BitmapData(untyped __int__(g2d_stageViewRect.width * g2d_activeCamera.normalizedViewWidth), untyped __int__(g2d_stageViewRect.height * g2d_activeCamera.normalizedViewHeight),true,0x0);
    }
	
	public function init():Void {
		g2d_nativeContext = new BitmapData(untyped __int__(g2d_stageViewRect.width), untyped __int__(g2d_stageViewRect.height), false, 0x0);
		g2d_nativeContextWrapper = new Bitmap(g2d_nativeContext);
		g2d_nativeStage.addChildAt(g2d_nativeContextWrapper, 0);

        g2d_invalidate();

        if (!g2d_initialized) {
            initComplete();
        }
	}

    private function g2d_invalidate():Void {
        if (g2d_initialized) {
            g2d_defaultCamera.x = g2d_stageViewRect.width*.5;
            g2d_defaultCamera.y = g2d_stageViewRect.height*.5;
        }
    }

    private function initComplete():Void {
        g2d_defaultCamera = new GContextCamera();
        g2d_defaultCamera.x = g2d_stageViewRect.width*.5;
        g2d_defaultCamera.y = g2d_stageViewRect.height*.5;
        g2d_activeViewRect = new GRectangle();

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
		g2d_nativeStage.removeChild(g2d_nativeContextWrapper);

        g2d_onInitialized = null;
        g2d_onFailed = null;
        g2d_onInvalidated = null;
        g2d_onFrame = null;
        g2d_onMouseSignal = null;
        g2d_onKeyboardSignal = null;
	}
	
	public function begin():Void  {
        g2d_stats.clear();

        setCamera(g2d_defaultCamera);

        // TODO add correct background color
		g2d_nativeContext.fillRect(g2d_nativeContext.rect, 0x0);
	}
	
	public function end():Void {
        g2d_stats.render(this);

	    g2d_point.x = g2d_stageViewRect.width * g2d_activeCamera.normalizedViewX;
	    g2d_point.y = g2d_stageViewRect.height * g2d_activeCamera.normalizedViewY;
	    g2d_nativeContext.copyPixels(g2d_cameraBitmap, g2d_cameraBitmap.rect, g2d_point);
	    g2d_cameraBitmap = null;
	}
	
	public function draw(p_texture:GContextTexture, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null):Void {
		if (p_texture.g2d_bitmapData == null) return;

        if (p_rotation == 0 && p_scaleX == 1 && p_scaleY == 1 && p_red == 1 && p_green == 1 && p_blue == 1 && p_alpha == 1 && g2d_activeCamera.rotation == 0 && g2d_activeCamera.scaleX == 1 && g2d_activeMaskRect == null) {
            g2d_point.x = p_x-p_texture.pivotX-p_texture.width/2 - g2d_activeCamera.x + g2d_activeViewRect.width*.5;
            g2d_point.y = p_y-p_texture.pivotY-p_texture.height/2 - g2d_activeCamera.y + g2d_activeViewRect.height*.5;
            g2d_cameraBitmap.copyPixels(p_texture.g2d_bitmapData, p_texture.g2d_bitmapData.rect, g2d_point, p_texture.g2d_bitmapData, ZERO_POINT, true);
        } else {
            // TODO this looks nasty
            if (p_texture.width != p_texture.g2d_bitmapData.width) p_scaleX *= p_texture.width/p_texture.g2d_bitmapData.width;

            var sx:Float = p_scaleX*g2d_activeCamera.scaleX;
            var sy:Float = p_scaleY*g2d_activeCamera.scaleY;
            var tx:Float;
            var ty:Float;
            if (g2d_activeCamera.rotation != 0) {
                var cos:Float = Math.cos(g2d_activeCamera.rotation);
                var sin:Float = Math.sin(g2d_activeCamera.rotation);
                tx = (p_x*g2d_activeCamera.scaleX)*cos - (p_y*g2d_activeCamera.scaleY)*sin;
                ty = (p_x*g2d_activeCamera.scaleX)*sin + (p_y*g2d_activeCamera.scaleY)*cos;
            } else {
                tx = p_x*g2d_activeCamera.scaleX;
                ty = p_y*g2d_activeCamera.scaleY;
            }

            g2d_matrix.identity();
            g2d_matrix.translate(-p_texture.pivotX-p_texture.width*.5, -p_texture.pivotY-p_texture.height*.5);
            g2d_matrix.scale(p_scaleX, p_scaleY);
            g2d_matrix.rotate(p_rotation);
            g2d_matrix.translate(-g2d_activeCamera.x, -g2d_activeCamera.y);
            if (g2d_activeCamera.scaleX != 1) g2d_matrix.scale(g2d_activeCamera.scaleX, g2d_activeCamera.scaleY);
            if (g2d_activeCamera.rotation != 0) g2d_matrix.rotate(g2d_activeCamera.rotation);
            g2d_matrix.translate(tx+g2d_activeViewRect.width*.5, ty+g2d_activeViewRect.height*.5);

            g2d_colorTransform.redMultiplier = p_red;
            g2d_colorTransform.greenMultiplier = p_green;
            g2d_colorTransform.blueMultiplier = p_blue;
            g2d_colorTransform.alphaMultiplier = p_alpha;
            g2d_cameraBitmap.draw(p_texture.g2d_bitmapData, g2d_matrix, g2d_colorTransform, null, (g2d_activeMaskRect == null ? null : g2d_activeMaskRect));
        }
	}

    public function drawSource(p_texture:GContextTexture, p_sourceX:Float, p_sourceY:Float, p_sourceWidth:Float, p_sourceHeight:Float, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null):Void {

    }

    public function drawMatrix(p_texture:GContextTexture, p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float=1, p_blendMode:Int=1, p_filter:GFilter = null):Void {
    }

    public function drawPoly(p_texture:GContextTexture, p_vertices:Array<Float>, p_uvs:Array<Float>, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int=1, p_filter:GFilter = null):Void {
        new GError("drawPoly not supported for this target.");
    }

    public function getRenderTarget():GContextTexture {
        return g2d_renderTarget;
    }

    public function setRenderTarget(p_texture:GContextTexture = null, p_transform:Matrix3D = null):Void {
        if (g2d_renderTarget == p_texture) return;

        g2d_renderTarget = p_texture;
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

    public function bindRenderer(p_renderer:Dynamic):Void {

    }

    public function clearStencil():Void {

    }

    public function renderToStencil(p_stencilLayer:Int):Void {

    }

    public function renderToColor(p_stencilLayer:Int):Void {

    }

    public function setDepthTest(p_depthMask:Bool, p_compareMode:Dynamic):Void {

    }

    public function setRenderTargets(p_textures:Array<GContextTexture>, p_transform:GMatrix3D = null):Void {

    }
}
#end