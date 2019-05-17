package com.genome2d.assets;

import com.genome2d.assets.GAsset;
import com.genome2d.debug.GDebug;

class GAudioAsset extends GAsset {

    private var g2d_type:GAudioAssetType;
    public var type(default,null):GAudioAssetType;

    override public function load():Void {
        GDebug.warning("Audio assets for this context are not implemented.");
        g2d_complete_handler();
    }

    private function g2d_complete_handler():Void {
        g2d_loading = false;
        g2d_loaded = true;
        onLoaded.dispatch(this);
    }

    private function g2d_ioError_handler():Void {

    }
}