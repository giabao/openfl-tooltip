package com.sandinh;

import haxe.ds.ObjectMap;
import openfl.display.Sprite;
import openfl.display.DisplayObject;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.display.GradientType;
import openfl.display.SpreadMethod;
import openfl.filters.GlowFilter;
import openfl.filters.BitmapFilterQuality;
import openfl.geom.Point;
import openfl.events.MouseEvent;
import openfl.events.Event;
import motion.Actuate;
import openfl.Lib;

using Lambda;

/** Hold ToolTip data */
private class TipData {
    public var htmlText(default, null): String;
    public var fixedPos(default, null): Bool;
    public var delay(default, null): Float;
    
    public function new(htmlText: String, fixedPos: Bool, delay: Float) {
        this.htmlText = htmlText;
        this.fixedPos = fixedPos;
        this.delay = delay;
    }
}

/** Should use as extension methods for DisplayObject */
class TipTools {
    /** The only Tip instance */
    static var tip = new Tip();
    /** Map from target DisplayObject that is register via `regisTip`  to TipData */
    static var datas = new ObjectMap<DisplayObject, TipData>();
    
    /** Register tip for the `target` DisplayObject.
     * @param fixedPos -
     *      + true: only register the tip data, you must call `showTip` to show & `hideTip` to hide the tooltip.
     *      + false: tooltip will be managed:
     *          - if target is already on stage, it will be setup so that the tip will be show when MOUSE_OVER `target`,
     *            hide when mouse out of target & move when mouse move.
     *          - Note if target is not added to stage & will never been added to stage
     *            then may have memory leak because the event listener onAddedToStage will not be removed. */
    public static function regisTip(target: DisplayObject, htmlText: String, fixedPos: Bool = false, delay: Float = 0) {
        var d = new TipData(htmlText, fixedPos, delay);
        datas.set(target, d);
        
        if (fixedPos) return;
        
        if (target.stage != null) {
            setup(target);
        } else {
            //may leak memory if target is never be added to stage.
            target.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
    }
    
    /** unregister tip data for `target`.
     * Also `free` the tip if its current target is `target` */
    public static function unregisTip(target: DisplayObject) {
        tip.free(target);
        datas.remove(target);
        target.removeEventListener(e.type, onAddedToStage);
        target.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
    }

    /** unregisTip for multi targets */
    public static inline function unregisTips(targets: Array<DisplayObject>) {
        targets.iter(unregisTip);
    }
    
    /** show tooltip that is registered for `target` */
    public static function showTip(target: DisplayObject) {
        var d: TipData = datas.get(target);
        if (d == null) return;
        tip.show(target, d.htmlText, d.fixedPos, d.delay);
    }
    
    /** hide the (only) tooltip */
    public static inline function hideTip(target: DisplayObject) {
        tip.hide();
    }
    
    static function onAddedToStage(e: Event) {
        var target = cast (e.target, DisplayObject);
        target.removeEventListener(e.type, onAddedToStage);
        
        setup(target);
    }
    
    static inline function setup(target: DisplayObject) {
        target.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
    }
    
    static function onMouseOver(e: MouseEvent) {
        var target = cast (e.target, DisplayObject);
        var d: TipData = datas.get(target);
        if (d == null) {
            unregisTip(target);
            return;
        }
        
        tip.show(target, d.htmlText, d.fixedPos, d.delay);
    }
}

/** The simple Tooltip implementation.
 * You could use this class directly.
 * But the recommended way is using TipTools class (as extension method for DisplayObject) */
class Tip extends Sprite {
    var bgColors: Array<UInt> = [0x131412, 0x131412];
    static inline var bgAlpha = 1;
    static inline var borderColor = 0xC7A65C;
    static inline var cornerRadius = 8;
    static inline var hpadding = 4;
    static inline var vpadding = 2;
    static inline var borderSize = 1;
    var contentFormat = new TextFormat("Tahoma", 11, 0xF2E6D5);
    
    var tipWidth: Float; //for caching purpose only
    
    //The text field for tooltip
    var content: TextField;
    var target: DisplayObject;

    public function new() {
        super();
        content = new TextField();
        content.defaultTextFormat = contentFormat;
        content.x = hpadding;
        content.y = vpadding;
        content.autoSize = TextFieldAutoSize.LEFT;
        content.selectable = false;
        content.multiline = true;
		content.wordWrap = true;
        
        addChild(content);
        
        mouseEnabled = mouseChildren = false;
        
        //bgGlow FIXME need?
        filters = [new GlowFilter(0, 0.2, 5, 5, 1, BitmapFilterQuality.HIGH)];

        //textGlow FIXME need?
        content.filters = [new GlowFilter(0, 0.35, 2, 2, 1, BitmapFilterQuality.HIGH)];
    }
    
    /** @param fixedPos -
     *      if true then you must call `hide` or `free` to hide the tooltip.
     *      if false then tooltip will be hide when mouse out of target & move when mouse move. */
    public function show(target: DisplayObject, htmlText: String, fixedPos: Bool = false, delay: Float = 0) {
        if (this.target != null) free();
        
        this.target = target;
        
        content.htmlText = htmlText;
        
        tipWidth = content.textWidth + 4 + 2 * hpadding;
        
        //draw background
        graphics.lineStyle(borderSize, borderColor, 1);
        
        var h = this.getBounds(this).height + vpadding * 2;
        var mat = new Matrix();
        mat.createGradientBox(tipWidth, h, Math.PI / 2, 0, 0);
        graphics.beginGradientFill(GradientType.LINEAR, bgColors, [bgAlpha, bgAlpha], [0x00, 0xFF], mat, SpreadMethod.PAD); 
        
        graphics.drawRoundRect(0, 0, tipWidth, h, cornerRadius);
                
        if (delay > 0) {
            this.alpha = 0;
            Actuate.tween(this, 0.5, { alpha: 1 } ).delay(delay);
        }
        
        Lib.current.stage.addChild(this);
        
        if (! fixedPos) {
            target.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
            Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        }
        
        var p = fixedPos?
            target.localToGlobal(new Point(tipWidth / 2, 10)) : //(0, 20)
            new Point(Lib.current.mouseX, Lib.current.mouseY);
            
        adjustPosition(p.x, p.y);
    }
    
    public function hide() {
        //nothing to hide
        if (target == null) return;
        
        Actuate.tween(this, 0.5, { alpha: 0 } ).autoVisible(false).onComplete(free);
    }
    
    /** call free() to free (destroy) the current `this.target`.
     *  call free(someTarget) to free ONLY IF the current target is == someTarget */
    public function free(onlyTarget: DisplayObject = null) {
        if (onlyTarget != null && onlyTarget != target) return;
        
        //nothing to cleanup
        if (target == null) return;
        
        target.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
        Lib.current.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        
        Actuate.stop(this);
        
        if (parent != null) parent.removeChild(this);
        
        graphics.clear();
        this.alpha = 1;
        
        target = null;
    }

    function onMouseOut(e: MouseEvent) {
        e.target.removeEventListener(e.type, onMouseOut);
        hide();
    }
    
    function onMouseMove(e: MouseEvent) {
        adjustPosition(Lib.current.mouseX, Lib.current.mouseY);
    }
    
    //require target != null
    inline function adjustPosition(px: Float, py: Float) {
        //align hcenter
        var x1 =  px - tipWidth / 2;
        x = x1 >= 0? x1 : 0;
        
        var y1 = py - height - 10;
        y = y1 >= 0? y1 : py + 10;
    }
}
