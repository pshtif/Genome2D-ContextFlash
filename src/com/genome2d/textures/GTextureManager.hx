package com.genome2d.textures;
import com.genome2d.textures.GTexture;
import com.genome2d.assets.GAssetManager;
import com.genome2d.geom.GRectangle;
import com.genome2d.geom.GRectangle;
import com.genome2d.geom.GRectangle;
import com.genome2d.assets.GXmlAsset;
import com.genome2d.utils.GMaxRectPacker;
import com.genome2d.utils.GPackerRectangle;
import flash.utils.Dictionary;
import com.genome2d.geom.GRectangle;
import flash.utils.ByteArray;
import com.genome2d.debug.GDebug;
import flash.utils.Function;
import com.genome2d.assets.GImageAssetType;
import flash.display.BitmapData;
import com.genome2d.assets.GImageAsset;
import flash.display.Bitmap;
import com.genome2d.context.IContext;

@:access(com.genome2d.textures.GContextTexture)
class GTextureManager {
    static public function init():Void {
        g2d_textures = new Dictionary(false);
    }

    static public var defaultFilteringType:Int = GTextureFilteringType.LINEAR;

    static private var g2d_textures:Dictionary;
    static public function getTextures():Dictionary {
        return g2d_textures;
    }

    static private function g2d_addTexture(p_texture:GContextTexture):Void {
        if (p_texture.id == null || p_texture.id.length == 0) GDebug.error("Invalid texture id");
        if (untyped g2d_textures[p_texture.id] != null) GDebug.error("Duplicate textures id: "+p_texture.id);
        untyped g2d_textures[p_texture.id] = p_texture;
    }

    static private function g2d_removeTexture(p_texture:GContextTexture):Void {
        untyped __delete__(g2d_textures, p_texture.id);
    }

    static public function getContextTextureById(p_id:String):GContextTexture {
        return untyped g2d_textures[p_id];
    }

    static public function getTextureById(p_id:String):GTexture {
        return untyped g2d_textures[p_id];
    }
	
	static public function getTexturesByIds(p_ids:Array<String>):Array<GTexture> {
		var textures:Array<GTexture> = new Array<GTexture>();
		for (id in p_ids) textures.push(untyped g2d_textures[id]);
        return textures;
    }

    static public function getAtlasById(p_id:String):GTextureAtlas {
        return untyped g2d_textures[p_id];
    }

    static public function getFontAtlasById(p_id:String):GTextureFontAtlas {
        return untyped g2d_textures[p_id];
    }

    static public function disposeAll():Void {
        var textureIds:Array<String> = untyped __keys__(g2d_textures);
        for (i in 0...textureIds.length) {
            untyped if (g2d_textures[textureIds[i]]!=null && g2d_textures[textureIds[i]].sourceType != GTextureSourceType.ATLAS) g2d_textures[textureIds[i]].dispose();
        }
    }

    static public function invalidateAll(p_force:Bool):Void {
        var textureIds:Array<String> = untyped __keys__(g2d_textures);
        for (i in 0...textureIds.length) {
            untyped g2d_textures[textureIds[i]].invalidateNativeTexture(p_force);
        }
    }

    /****************************************************************************************************
                                                TEXTURE STUFF
     ****************************************************************************************************/

    static public function createTextureFromEmbedded(p_id:String, p_asset:Class<Bitmap>, p_scaleFactor:Float = 1, p_repeatable:Bool = false, p_format:String = "bgra"):GTexture {
        var bitmap:Bitmap = cast Type.createInstance(p_asset, []);
        var texture:GTexture = new GTexture(p_id, bitmap.bitmapData);
        texture.repeatable = p_repeatable;
        texture.scaleFactor = p_scaleFactor;
        texture.invalidateNativeTexture(false);

        return texture;
    }

    static public function createTextureFromBitmapData(p_id:String, p_bitmapData:BitmapData, p_scaleFactor:Float = 1, p_repeatable:Bool = false, p_format:String = "bgra"):GTexture {
        var texture:GTexture = new GTexture(p_id, p_bitmapData);
        texture.repeatable = p_repeatable;
        texture.scaleFactor = p_scaleFactor;
        texture.invalidateNativeTexture(false);
        return texture;
    }

    static public function createTextureFromAsset(p_id:String, p_imageAsset:GImageAsset, p_scaleFactor:Float = 1, p_repeatable:Bool = false, p_format:String = "bgra"):GTexture {
        switch (p_imageAsset.type) {
            case GImageAssetType.BITMAPDATA:
                return createTextureFromBitmapData(p_id, p_imageAsset.bitmapData, p_scaleFactor, p_repeatable, p_format);
            case GImageAssetType.ATF:
                return createTextureFromATF(p_id, p_imageAsset.bytes);
        }

        return null;
    }

    static public function createTextureFromAssetId(p_id:String, p_imageAssetId:String, p_scaleFactor:Float = 1, p_repeatable:Bool = false, p_format:String = "bgra"):GTexture {
        return createTextureFromAsset(p_id, GAssetManager.getImageAssetById(p_imageAssetId), p_scaleFactor, p_repeatable, p_format);
    }

    static public function createTextureFromATF(p_id:String, p_atfData:ByteArray, p_scaleFactor:Float = 1, p_uploadCallback:Function = null):GTexture {
        var atf:String = String.fromCharCode(p_atfData[0]) + String.fromCharCode(p_atfData[1]) + String.fromCharCode(p_atfData[2]);
        if (atf != "ATF") GDebug.error("Invalid ATF data");

        var texture = new GTexture(p_id, p_atfData);
        texture.scaleFactor = p_scaleFactor;
        texture.invalidateNativeTexture(false);
        return texture;
    }

    static public function createRenderTexture(p_id:String, p_width:Int, p_height:Int, p_scaleFactor:Float = 1):GTexture {
        var texture:GTexture = new GTexture(p_id, new GRectangle(0,0,p_width, p_height));
        texture.invalidateNativeTexture(false);
        return texture;
    }


    /****************************************************************************************************
                                                ATLAS STUFF
     ****************************************************************************************************/

    static public function createAtlasFromEmbedded(p_id:String, p_bitmapAsset:Class<Bitmap>, p_xmlAsset:Class<Dynamic>, p_scaleFactor:Float = 1, p_format:String = "bgra"):GTextureAtlas {
        var bitmap:Bitmap = cast Type.createInstance(p_bitmapAsset, []);
        var data:String = cast Type.createInstance(p_xmlAsset, []);
        var xml:Xml = Xml.parse(data);

        return createAtlasFromBitmapDataAndXml(p_id, bitmap.bitmapData, xml, p_scaleFactor, p_format);
    }

/**
	 * 	Helper function that will create atlas from bitmap data source and regions defined within an XML [Sparrow format]
	 *
	 * 	@param p_id id of the atlas
	 * 	@param p_bitmapData bitmap data
	 * 	@param p_xml
	 */
    static public function createAtlasFromBitmapDataAndXml(p_id:String, p_bitmapData:BitmapData, p_xml:Xml, p_scaleFactor:Float = 1, p_format:String = "bgra"):GTextureAtlas {
        if (!GTextureUtils.isValidTextureSize(p_bitmapData.width) || !GTextureUtils.isValidTextureSize(p_bitmapData.height)) GDebug.error("Atlas bitmap needs to have power of 2 size.");
        var textureAtlas:GTextureAtlas = new GTextureAtlas(p_id, p_bitmapData);
        textureAtlas.scaleFactor = p_scaleFactor;

        var root = p_xml.firstElement();
        var it:Iterator<Xml> = root.elements();

        while(it.hasNext()) {
            var node:Xml = it.next();

            var region:GRectangle = new GRectangle(Std.parseInt(node.get("x")), Std.parseInt(node.get("y")), Std.parseInt(node.get("width")), Std.parseInt(node.get("height")));

            if (node.get("frameX") != null && node.get("frameWidth") != null && node.get("frameY") != null && node.get("frameHeight") != null) {
                var frame:GRectangle = new GRectangle(Std.parseInt(node.get("frameX")), Std.parseInt(node.get("frameY")), Std.parseInt(node.get("frameWidth")), Std.parseInt(node.get("frameHeight")));
                textureAtlas.addSubTexture(node.get("name"), region, frame);
            } else {
                textureAtlas.addSubTexture(node.get("name"), region, null);
            }
        }

        textureAtlas.invalidateNativeTexture(false);
        return textureAtlas;
    }

    static public function createAtlasFromAssets(p_id:String, p_imageAsset:GImageAsset, p_xmlAsset:GXmlAsset, p_scaleFactor:Float = 1, p_format:String = "bgra"):GTextureAtlas {
        switch (p_imageAsset.type) {
            case GImageAssetType.BITMAPDATA:
                return createAtlasFromBitmapDataAndXml(p_id, p_imageAsset.bitmapData, p_xmlAsset.xml, p_scaleFactor, p_format);
            case GImageAssetType.ATF:
                return createAtlasFromATFAndXml(p_id, p_imageAsset.bytes, p_xmlAsset.xml, p_scaleFactor);
        }
        return null;
    }

    static public function createAtlasFromAssetIds(p_id:String, p_imageAssetId:String, p_xmlAssetId:String, p_scaleFactor:Float = 1, p_format:String = "bgra"):GTextureAtlas {
        return createAtlasFromAssets(p_id, GAssetManager.getImageAssetById(p_imageAssetId), GAssetManager.getXmlAssetById(p_xmlAssetId), p_scaleFactor, p_format);
    }

    static public function createAtlasFromBitmapDatas(p_id:String, p_bitmaps:Array<BitmapData>, p_ids:Array<String>, p_scaleFactor:Float = 1, p_format:String = "bgra", p_packer:GMaxRectPacker = null, p_padding:Int = 2):GTextureAtlas {
        var rectangles:Array<GPackerRectangle> = new Array<GPackerRectangle>();
        var i:Int;
        var rect:GPackerRectangle;
        for (i in 0...p_bitmaps.length) {
            var bitmap:BitmapData = p_bitmaps[i];
            rect = GPackerRectangle.get(0,0,bitmap.width,bitmap.height,p_ids[i],bitmap);
            rectangles.push(rect);
        }

        if (p_packer == null) {
            p_packer = new GMaxRectPacker(1,1,2048,2048,true);
        }

        p_packer.g2d_packRectangles(rectangles, p_padding);

        if (p_packer.getRectangles().length != p_bitmaps.length) return null;
        var packed:BitmapData = new BitmapData(p_packer.getWidth(), p_packer.getHeight(), true, 0x0);
        p_packer.draw(packed);

        var textureAtlas:GTextureAtlas = new GTextureAtlas(p_id, packed);
        textureAtlas.scaleFactor = p_scaleFactor;

        var count:Int = p_packer.getRectangles().length;
        for (i in 0...count) {
            rect = p_packer.getRectangles()[i];
            var texture:GTexture = textureAtlas.addSubTexture(rect.id, rect.getRect(), null);
            texture.g2d_pivotX = rect.pivotX;
            texture.g2d_pivotY = rect.pivotY;
        }

        textureAtlas.invalidateNativeTexture(false);
        return textureAtlas;
    }

    static public function createAtlasFromATFAndXml(p_id:String, p_atfData:ByteArray, p_xml:Xml, p_scaleFactor:Float = 1):GTextureAtlas {
        var atf:String = String.fromCharCode(p_atfData[0]) + String.fromCharCode(p_atfData[1]) + String.fromCharCode(p_atfData[2]);
        if (atf != "ATF") GDebug.error("Invalid ATF data.");

        var textureAtlas:GTextureAtlas = new GTextureAtlas(p_id, p_atfData);
        textureAtlas.scaleFactor = p_scaleFactor;

        var root = p_xml.firstElement();
        var it:Iterator<Xml> = root.elements();

        while(it.hasNext()) {
            var node:Xml = it.next();

            var region:GRectangle = new GRectangle(Std.parseInt(node.get("x")), Std.parseInt(node.get("y")), Std.parseInt(node.get("width")), Std.parseInt(node.get("height")));

            if (node.get("frameX") != null && node.get("frameWidth") != null && node.get("frameY") != null && node.get("frameHeight") != null) {
                var frame:GRectangle = new GRectangle(Std.parseInt(node.get("frameX")), Std.parseInt(node.get("frameY")), Std.parseInt(node.get("frameWidth")), Std.parseInt(node.get("frameHeight")));
                textureAtlas.addSubTexture(node.get("name"), region, frame);
            } else {
                textureAtlas.addSubTexture(node.get("name"), region, null);
            }
        }

        textureAtlas.invalidateNativeTexture(false);

        return textureAtlas;
    }

    static public function createFontAtlasFromAssets(p_id:String, p_imageAsset:GImageAsset, p_xmlAsset:GXmlAsset, p_scaleFactor:Float = 1, p_format:String = "bgra"):GTextureFontAtlas {
        return createFontAtlasFromBitmapDataAndXml(p_id, p_imageAsset.bitmapData, p_xmlAsset.xml, p_scaleFactor, p_format);
    }

    static public function createFontAtlasFromAssetIds(p_id:String, p_imageAssetId:String, p_xmlAssetId:String, p_scaleFactor:Float = 1, p_format:String = "bgra"):GTextureAtlas {
        return createFontAtlasFromAssets(p_id, GAssetManager.getImageAssetById(p_imageAssetId), GAssetManager.getXmlAssetById(p_xmlAssetId), p_scaleFactor, p_format);
    }

/*
    static public function createFromFont(p_id:String, p_textFormat:TextFormat, p_chars:String, p_embedded:Bool = true, p_horizontalPadding:Int = 0, p_verticalPadding:Int = 0, p_filters:Array<BitmapFilter> = null, p_forceMod2:Bool = false, p_format:String = "bgra"):GTextureAtlas {
        var text:TextField = new TextField();
        text.embedFonts = p_embedded;
        text.defaultTextFormat = p_textFormat;
        text.multiline = false;
        text.autoSize = TextFieldAutoSize.LEFT;

        if (p_filters != null) {
            text.filters = p_filters;
        }

        var bitmaps:Array<BitmapData> = new Array<BitmapData>();
        var ids:Array<String> = new Array<String>();
        var matrix:Matrix = new Matrix();
        matrix.translate(p_horizontalPadding, p_verticalPadding);

        for (i in 0...p_chars.length) {
            text.text = p_chars.charAt(i);
            var width:Float = (text.width%2 != 0 && p_forceMod2) ? text.width+1 : text.width;
            var height:Float = (text.height%2 != 0 && p_forceMod2) ? text.height+1 : text.height;
            var bitmapData:BitmapData = new BitmapData(untyped __int__(width+p_horizontalPadding*2), untyped __int__(height+p_verticalPadding*2), true, 0x0);
            bitmapData.draw(text, matrix);
            bitmaps.push(bitmapData);

            untyped ids.push(String(p_chars.charCodeAt(i)));
        }

        return createFromBitmapDatas(p_id, bitmaps, ids, p_format);
    }
    /**/

    static public function createFontAtlasFromBitmapDataAndXml(p_id:String, p_bitmapData:BitmapData, p_fontXml:Xml, p_scaleFactor:Float = 1, p_format:String = "bgra"):GTextureFontAtlas {
        var textureAtlas:GTextureFontAtlas = new GTextureFontAtlas(p_id, p_bitmapData);
        textureAtlas.scaleFactor = p_scaleFactor;

        var root:Xml = p_fontXml.firstElement();

        var common:Xml = root.elementsNamed("common").next();
        textureAtlas.lineHeight = Std.parseInt(common.get("lineHeight"));

        var it:Iterator<Xml> = root.elementsNamed("chars");
        it = it.next().elements();

        while(it.hasNext()) {
            var node:Xml = it.next();
            var w:Int = Std.parseInt(node.get("width"));
            var h:Int = Std.parseInt(node.get("height"));
            var region:GRectangle = new GRectangle(Std.parseInt(node.get("x")), Std.parseInt(node.get("y")), w, h);

            var subtexture:GCharTexture = textureAtlas.addSubTexture(node.get("id"), region, null);
            subtexture.g2d_pivotX = -w/2;
            subtexture.g2d_pivotY = -h/2;
            subtexture.g2d_xoffset = Std.parseFloat(node.get("xoffset"));
            subtexture.g2d_yoffset = Std.parseFloat(node.get("yoffset"));
            subtexture.g2d_xadvance = Std.parseFloat(node.get("xadvance"));
        }

        var kernings:Xml = root.elementsNamed("kernings").next();
        if (kernings != null) {
            it = kernings.elements();
            textureAtlas.g2d_kerning = new Map<Int,Map<Int,Int>>();

            while(it.hasNext()) {
                var node:Xml = it.next();
                var first:Int = Std.parseInt(node.get("first"));
                var map:Map<Int,Int> = textureAtlas.g2d_kerning.get(first);
                if (map == null) {
                    map = new Map<Int,Int>();
                    textureAtlas.g2d_kerning.set(first, map);
                }
                var second:Int = Std.parseInt(node.get("second"));
                map.set(second, Std.parseInt("amount"));
            }
        }

        textureAtlas.invalidateNativeTexture(false);
        return textureAtlas;
    }
}
