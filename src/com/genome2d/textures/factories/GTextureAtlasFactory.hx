/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.textures.factories;

import com.genome2d.textures.GTexture;
import com.genome2d.geom.GRectangle;
import com.genome2d.context.IContext;
import com.genome2d.geom.GRectangle;
import com.genome2d.error.GError;
import com.genome2d.textures.GTextureAtlas;
import com.genome2d.textures.GTextureSourceType;
import com.genome2d.assets.GImageAsset;
import com.genome2d.assets.GXmlAsset;

import flash.filters.BitmapFilter;
import flash.geom.Matrix;
import flash.text.TextFieldAutoSize;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.ByteArray;
import flash.display.Bitmap;
import flash.display.BitmapData;

import com.genome2d.utils.GMaxRectPacker;
import com.genome2d.utils.GPackerRectangle;

class GTextureAtlasFactory
{
    static public var g2d_context:IContext;

    static public function createFromEmbedded(p_id:String, p_bitmapAsset:Class<Bitmap>, p_xmlAsset:Class<Dynamic>, p_format:String = "bgra"):GTextureAtlas {
        var bitmap:Bitmap = cast Type.createInstance(p_bitmapAsset, []);
        var data:String = cast Type.createInstance(p_xmlAsset, []);
        var xml:Xml = Xml.parse(data);

        return createFromBitmapDataAndXml(p_id, bitmap.bitmapData, xml, p_format);
    }

	/**
	 * 	Helper function that will create atlas from bitmap data source and regions defined within an XML [Sparrow format]
	 * 
	 * 	@param p_id id of the atlas
	 * 	@param p_bitmapData bitmap data
	 * 	@param p_xml
	 */	
	static public function createFromBitmapDataAndXml(p_id:String, p_bitmapData:BitmapData, p_xml:Xml, p_format:String = "bgra"):GTextureAtlas {
        if (!GTextureUtils.isValidTextureSize(p_bitmapData.width) || !GTextureUtils.isValidTextureSize(p_bitmapData.height)) new GError("Atlas bitmap needs to have power of 2 size.");
		var textureAtlas:GTextureAtlas = new GTextureAtlas(g2d_context, p_id, GTextureSourceType.BITMAPDATA, p_bitmapData, p_bitmapData.rect, p_format, null);

		var root = p_xml.firstElement();
		var it:Iterator<Xml> = root.elements();
		
		while(it.hasNext()) {
			var node:Xml = it.next();
			
			var region:GRectangle = new GRectangle(Std.parseInt(node.get("x")), Std.parseInt(node.get("y")), Std.parseInt(node.get("width")), Std.parseInt(node.get("height")));
			
			var pivotX:Float = (node.get("frameX") == null || node.get("frameWidth") == null) ? 0 : (Std.parseInt(node.get("frameWidth"))-region.width)/2 + Std.parseInt(node.get("frameX"));
			var pivotY:Float = (node.get("frameY") == null || node.get("frameHeight") == null) ? 0 : (Std.parseInt(node.get("frameHeight"))-region.height)/2 + Std.parseInt(node.get("frameY"));

			textureAtlas.addSubTexture(node.get("name"), region, pivotX, pivotY);
		}

		textureAtlas.invalidateNativeTexture(false);
		return textureAtlas;
	}	

	static public function createFromAssets(p_id:String, p_imageAsset:GImageAsset, p_xmlAsset:GXmlAsset, p_format:String = "bgra"):GTextureAtlas {
		return createFromBitmapDataAndXml(p_id, p_imageAsset.nativeImage, p_xmlAsset.xml, p_format);
	}

    static public function createFontFromAssets(p_id:String, p_imageAsset:GImageAsset, p_xmlAsset:GXmlAsset, p_format:String = "bgra"):GFontTextureAtlas {
        return createFromBitmapDataAndFontXml(p_id, p_imageAsset.nativeImage, p_xmlAsset.xml, p_format);
    }

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

    static public function createFromBitmapDataAndFontXml(p_id:String, p_bitmapData:BitmapData, p_fontXml:Xml, p_format:String = "bgra"):GFontTextureAtlas {
        var textureAtlas:GFontTextureAtlas = new GFontTextureAtlas(g2d_context, p_id, GTextureSourceType.BITMAPDATA, p_bitmapData, p_bitmapData.rect, p_format, null);

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

            var subtexture:GCharTexture = textureAtlas.addSubTexture(node.get("id"), region, -w/2, -h/2);
            subtexture.xoffset = Std.parseInt(node.get("xoffset"));
            subtexture.yoffset = Std.parseInt(node.get("yoffset"));
            subtexture.xadvance = Std.parseInt(node.get("xadvance"));
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

    static public function createFromBitmapDatas(p_id:String, p_bitmaps:Array<BitmapData>, p_ids:Array<String>, p_format:String = "bgra", p_packer:GMaxRectPacker = null, p_padding:Int = 2):GTextureAtlas {
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

        var textureAtlas:GTextureAtlas = new GTextureAtlas(g2d_context, p_id, GTextureSourceType.BITMAPDATA, packed, packed.rect, p_format, null);

        var count:Int = p_packer.getRectangles().length;
        for (i in 0...count) {
            rect = p_packer.getRectangles()[i];
            textureAtlas.addSubTexture(rect.id, rect.getRect(), rect.pivotX, rect.pivotY);
        }

        textureAtlas.invalidateNativeTexture(false);
        return textureAtlas;
    }

    static public function createFromATFAndXml(p_id:String, p_atfData:ByteArray, p_xml:Xml):GTextureAtlas {
        var atf:String = String.fromCharCode(p_atfData[0]) + String.fromCharCode(p_atfData[1]) + String.fromCharCode(p_atfData[2]);
        if (atf != "ATF") throw new GError("Invalid ATF data.");

        var type:Int = GTextureSourceType.ATF_BGRA;
        var offset:Int = p_atfData[6] == 255 ? 12 : 6;
        switch (p_atfData[offset]) {
            case 0,1:
                type = GTextureSourceType.ATF_BGRA;
            case 2,3:
                type = GTextureSourceType.ATF_COMPRESSED;
            case 4,5:
                type = GTextureSourceType.ATF_COMPRESSEDALPHA;
        }
        var width:Float = Math.pow(2, p_atfData[offset+1]);
        var height:Float = Math.pow(2, p_atfData[offset+2]);

        var textureAtlas:GTextureAtlas = new GTextureAtlas(g2d_context, p_id, type, p_atfData, new GRectangle(0,0,width,height), "", null);

        var root = p_xml.firstElement();
        var it:Iterator<Xml> = root.elements();

        while(it.hasNext()) {
            var node:Xml = it.next();

            var region:GRectangle = new GRectangle(Std.parseInt(node.get("x")), Std.parseInt(node.get("y")), Std.parseInt(node.get("width")), Std.parseInt(node.get("height")));

            var pivotX:Float = (node.get("frameX") == null || node.get("frameWidth") == null) ? 0 : (Std.parseInt(node.get("frameWidth"))-region.width)/2 + Std.parseInt(node.get("frameX"));
            var pivotY:Float = (node.get("frameY") == null || node.get("frameHeight") == null) ? 0 : (Std.parseInt(node.get("frameHeight"))-region.height)/2 + Std.parseInt(node.get("frameY"));

            textureAtlas.addSubTexture(node.get("name"), region, pivotX, pivotY);
        }

        textureAtlas.invalidateNativeTexture(false);
        return textureAtlas;
    }
}