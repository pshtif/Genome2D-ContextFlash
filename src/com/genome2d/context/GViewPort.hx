package com.genome2d.context;
import com.genome2d.components.GCameraController;
import com.genome2d.Genome2D;
import com.genome2d.geom.GRectangle;
import com.genome2d.utils.GHAlignType;
import com.genome2d.utils.GVAlignType;
class GViewPort {

    private var g2d_vAlign:Int = GVAlignType.MIDDLE;
    #if swc @:extern #end
    public var vAlign(get, set):Int;
    #if swc @:getter(vAlign) #end
    inline private function get_vAlign():Int {
        return g2d_vAlign;
    }
    #if swc @:setter(vAlign) #end
    inline private function set_vAlign(p_value:Int):Int {
        return g2d_vAlign = p_value;
    }

    private var g2d_hAlign:Int = GHAlignType.CENTER;
    #if swc @:extern #end
    public var hAlign(get, set):Int;
    #if swc @:getter(hAlign) #end
    inline private function get_hAlign():Int {
        return g2d_hAlign;
    }
    #if swc @:setter(hAlign) #end
    inline private function set_hAlign(p_value:Int):Int {
        return g2d_hAlign = p_value;
    }

    public var viewLeft:Float;
    public var viewTop:Float;
    public var viewRight:Float;
    public var viewBottom:Float;

    public var screenLeft:Float;
    public var screenTop:Float;
    public var screenRight:Float;
    public var screenBottom:Float;

    private var g2d_cameraController:GCameraController;

    public function new(p_cameraController:GCameraController, p_viewWidth:Int, p_viewHeight:Int, p_autoResize:Bool = true) {
        g2d_cameraController = p_cameraController;

        viewLeft = 0;
        viewTop = 0;
        viewRight = p_viewWidth;
        viewBottom = p_viewHeight;

        if (p_autoResize) {
            Genome2D.getInstance().getContext().onResize.add(resizeHandler);
        }

        var rect:GRectangle = Genome2D.getInstance().getContext().getStageViewRect();
        resizeHandler(rect.width, rect.height);
    }

    private var g2d_previousZoom:Int = 1;

    private function resizeHandler(p_width:Float, p_height:Float):Void {
        var aw:Float = p_width/viewRight;
        var ah:Float = p_height/viewBottom;

        var aspect:Float = Math.min(aw, ah);
        g2d_cameraController.zoom = aspect;

        if (aw<ah) {
            screenLeft = 0;
            screenRight = viewRight;
            switch (vAlign) {
                case GVAlignType.MIDDLE:
                    screenTop = (viewBottom*aspect-p_height)/(2*aspect);
                    screenBottom = viewBottom+(p_height-aspect*viewBottom)/(2*aspect);
                    g2d_cameraController.node.transform.setPosition(viewRight*.5, viewBottom*.5);
                case GVAlignType.TOP:
                    screenTop = 0;
                    screenBottom = viewBottom+(p_height-aspect*viewBottom)/aspect;
                    g2d_cameraController.node.transform.setPosition(viewRight*.5, viewBottom*.5 + (p_height-aspect*viewBottom)/(2*aspect));
                case GVAlignType.BOTTOM:
                    screenTop = (viewBottom*aspect-p_height)/aspect;
                    screenBottom = p_height;
                    g2d_cameraController.node.transform.setPosition(viewRight*.5, viewBottom*.5 - (p_height-aspect*viewBottom)/(2*aspect));
            }
        } else {
            switch (hAlign) {
                case GHAlignType.CENTER:
                    screenLeft = (aspect*viewRight-p_width)/(2*aspect);
                    screenRight = viewRight+(p_width-aspect*viewRight)/(2*aspect);
                    g2d_cameraController.node.transform.setPosition(viewRight*.5, viewBottom*.5);
                case GHAlignType.LEFT:
                    screenLeft = 0;
                    screenRight = viewRight+(p_width-aspect*viewRight)/aspect;
                    g2d_cameraController.node.transform.setPosition(viewRight*.5 + (p_width-aspect*viewRight)/(2*aspect), viewBottom*.5);
                case GHAlignType.RIGHT:
                    screenLeft = (aspect*viewRight-p_width)/aspect;
                    screenRight = p_width;
                    g2d_cameraController.node.transform.setPosition(viewRight*.5 - (p_width-aspect*viewRight)/(2*aspect), viewBottom*.5);
            }
            screenTop = 0;
            screenBottom = viewBottom;
        }
    }
}
