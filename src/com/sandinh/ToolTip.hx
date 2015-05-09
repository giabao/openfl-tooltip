package com.sandinh;

import openfl.display.SpreadMethod;
import openfl.display.GradientType;
import openfl.filters.GlowFilter;
import openfl.filters.BitmapFilterQuality;
import openfl.text.GridFitType;
import openfl.errors.Error;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TimerEvent;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
//import openfl.text.StyleSheet;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.utils.Timer;
import motion.Actuate;

/**
	 * Public Setters:
	 
	 *		tipWidth 				Number				Set the width of the tooltip
	 *		titleFormat				TextFormat			Format for the title of the tooltip
	 * 		stylesheet				StyleSheet			StyleSheet object //TODO support
	 *		contentFormat			TextFormat			Format for the bodycopy of the tooltip
	 *		titleEmbed				Boolean				Allow font embed for the title
	 *		contentEmbed			Boolean				Allow font embed for the content
	 *		align					String				left, right, center
	 *		delay					Number				Time in milliseconds to delay the display of the tooltip
	 *		hook					Boolean				Displays a hook on the bottom of the tooltip
	 *		hookSize				Number				Size of the hook
	 *		cornerRadius			Number				Corner radius of the tooltip, same for all 4 sides
	 *		colors					Array				Array of 2 color values ( [0xXXXXXX, 0xXXXXXX] ); 
	 *		autoSize				Boolean				Will autosize the fields and size of the tip with no wrapping or multi-line capabilities, 
	 													 helpful with 1 word items like "Play" or "Pause"
	 * 		border					Number				Color Value: 0xFFFFFF
	 *		borderSize				Number				Size Of Border
	 *		buffer					Number				text buffer
	 * 		bgAlpha					Number				0 - 1, transparency setting for the background of the ToolTip
	 *
	 * Example:
	 
	 		var tf:TextFormat = new TextFormat();
			tf.bold = true;
			tf.size = 12;
			tf.color = 0xff0000;
			
			var tt:ToolTip = new ToolTip();
			tt.hook = true;
			tt.hookSize = 20;
			tt.cornerRadius = 20;
			tt.align = "center";
			tt.titleFormat = tf;
			tt.show( DisplayObject, "Title Of This ToolTip", "Some Copy that would go below the ToolTip Title" );
	 *
	 *
	 * original author Duncan Reid, www.hy-brid.com
	 */
class ToolTip extends Sprite {
    public var buffer : Float;
    public var bgAlpha(get, set) : Float;
    public var tipWidth(never, set) : Float;
    public var titleFormat(never, set) : TextFormat;
    public var contentFormat(never, set) : TextFormat;
//    public var stylesheet(never, set) : StyleSheet;
    public var align(never, set) : String;
    public var delay(never, set) : Float;
    public var hook(never, set) : Bool;
    public var hookSize(never, set) : Float;
    public var cornerRadius(never, set) : Float;
    public var colors(never, set) : Array<UInt>;
    public var autoSize(never, set) : Bool;
    public var border(never, set) : UInt;
    public var borderSize(never, set) : Float;
    public var tipHeight(never, set) : Float;
    public var titleEmbed(never, set) : Bool;
    public var contentEmbed(never, set) : Bool;

    //objects
    private var _parentObject : DisplayObject;
    private var _tf : TextField;  // title field  
    private var _cf : TextField;  //content field  
    private var _contentContainer : Sprite = new Sprite();  // container to hold both textfields  
    
    //formats
    private var _titleFormat : TextFormat;
    private var _contentFormat : TextFormat;
    
//    private var _stylesheet : StyleSheet;
    
//    /* check for stylesheet override */
//    private var _styleOverride : Bool = false;
    
    /* check for format override */
    private var _titleOverride : Bool = false;
    private var _contentOverride : Bool = false;
    
    // font embedding
    private var _titleEmbed : Bool = false;
    private var _contentEmbed : Bool = false;
    
    //defaults
    private var _defaultWidth : Float = 200;
    private var _defaultHeight : Float;
    private var _buffer : Float = 10;
    private var _align : String = "center";
    private var _cornerRadius : Float = 12;
    private var _bgColors: Array<UInt> = [0xFFFFFF, 0x9C9C9C];
    private var _autoSize : Bool = false;
    private var _hookEnabled : Bool = false;
    private var _delay : Float = 0;  //millilseconds  
    private var _hookSize : Float = 10;
    private var _border : UInt;
    private var _borderSize : Float = 1;
    private var _bgAlpha : Float = 1;  // transparency setting for the background of the tooltip  
    
    //offsets
    private var _offSet : Float;
    private var _hookOffSet : Float;
    
    //delay
    private var _timer : Timer;
    
    public function new()
    {
        super();
        //do not disturb parent display object mouse events
        this.mouseEnabled = false;
        this.buttonMode = false;
        this.mouseChildren = false;
        //setup delay timer
        _timer = new Timer(this._delay, 1);
        _timer.addEventListener("timer", timerHandler);
    }
    public function setContent(title : String, content : String = null) : Void{
        this.graphics.clear();
        this.addCopy(title, content);
        this.setOffset();
        this.drawBG();
    }
    public function show(p : DisplayObject, title : String, content : String = null, fixedPos : Bool = false) : Void{
        //get the stage from the parent
        this._parentObject = p;
        var onStage : Bool = this.addedToStage(this._contentContainer);
        if (!onStage) {
            this.addChild(this._contentContainer);
        }
        this.addCopy(title, content);
        this.setOffset();
        this.drawBG();
        this.bgGlow();
        
        //initialize coordinates
        var parentCoords : Point = (fixedPos) ? new Point(0, 20) : new Point(_parentObject.mouseX, _parentObject.mouseY);
        var globalPoint : Point = p.localToGlobal(parentCoords);
        this.x = globalPoint.x + this._offSet;
        this.y = globalPoint.y - this.height - 10;
        
        this.alpha = 0;
        p.stage.addChild(this);
        if (!fixedPos) {
            p.addEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut);
            //removed mouse move handler in lieu of enterframe for smoother movement
            //this._parentObject.addEventListener( MouseEvent.MOUSE_MOVE, this.onMouseMovement );
            
            this.follow(true);
        }
        _timer.start();
    }
    public function hide() : Void{
        this.animate(false);
    }
    private function timerHandler(event : TimerEvent) : Void{
        this.animate(true);
    }
    private function onMouseOut(event : MouseEvent) : Void{
        event.target.removeEventListener(event.type, onMouseOut);
        this.hide();
    }
    private function follow(value : Bool) : Void{
        if (value) 
            addEventListener(Event.ENTER_FRAME, this.eof)
        else 
        removeEventListener(Event.ENTER_FRAME, this.eof);
    }
    private function eof(event : Event) : Void{
        this.position();
    }
    private function position() : Void{
        var speed : Float = 3;
        var parentCoords : Point = new Point(_parentObject.mouseX, _parentObject.mouseY);
        var globalPoint : Point = _parentObject.localToGlobal(parentCoords);
        var xp : Float = globalPoint.x + this._offSet;
        var yp : Float = globalPoint.y - this.height - 10;
        
        var overhangRight : Float = this._defaultWidth + xp;
        if (overhangRight > stage.stageWidth) 
            xp = stage.stageWidth - this._defaultWidth;
        if (xp < 0) 
            xp = 0;
        if ((yp) < 0) 
            yp = 0;
        this.x += (xp - this.x) / speed;
        this.y += (yp - this.y) / speed;
    }
    private function addCopy(title : String, content : String = null) : Void{
        if (this._tf == null) {
            this._tf = this.createField(this._titleEmbed);
        }  // if using a stylesheet for title field  
        
//        if (this._styleOverride) {
//            this._tf.styleSheet = this._stylesheet;
//        }
        this._tf.htmlText = title;
        
        // if not using a stylesheet
//        if (!this._styleOverride) {
            // if format has not been set, set default
            if (!this._titleOverride) {
                this.initTitleFormat();
            }
            this._tf.setTextFormat(this._titleFormat);
//        }
        if (this._autoSize) {
            this._defaultWidth = this._tf.textWidth + 4 + (_buffer * 2);
        }
        else {
            this._tf.width = this._defaultWidth - (_buffer * 2);
        }
        
        this._tf.x = this._tf.y = this._buffer;
        this.textGlow(this._tf);
        this._contentContainer.addChild(this._tf);
        
        //if using content
        if (content != null) {
            
            if (this._cf == null) {
                this._cf = this.createField(this._contentEmbed);
            }  // if using a stylesheet for title field  
            
            
            
//            if (this._styleOverride) {
//                this._cf.styleSheet = this._stylesheet;
//            }
            
            this._cf.htmlText = content;
            
            // if not using a stylesheet
//            if (!this._styleOverride) {
                // if format has not been set, set default
                if (!this._contentOverride) {
                    this.initContentFormat();
                }
                this._cf.setTextFormat(this._contentFormat);
//            }
            
            var bounds : Rectangle = this.getBounds(this);
            this._cf.x = this._buffer;
            this._cf.y = this._tf.y + this._tf.textHeight;
            this.textGlow(this._cf);
            
            if (this._autoSize) {
                var cfWidth : Float = this._cf.textWidth + 4 + (_buffer * 2);
                this._defaultWidth = cfWidth > (this._defaultWidth) ? cfWidth : this._defaultWidth;
            }
            else {
                this._cf.width = this._defaultWidth - (_buffer * 2);
            }
            this._contentContainer.addChild(this._cf);
        }
    }
    //create field. thanganuong changed!
    private function createField(embed : Bool) : TextField{
        var tf : TextField = new TextField();
        tf.embedFonts = embed;
        tf.gridFitType = GridFitType.PIXEL;
        //tf.border = true;
        tf.autoSize = TextFieldAutoSize.LEFT;
        tf.selectable = false;
        //			if( ! this._autoSize ){
        tf.multiline = true;
        tf.wordWrap = true;
        //			}
        return tf;
    }
    //draw background, use drawing api if we need a hook
    private function drawBG() : Void{
        /* re-add : 04.29.2010 : clear graphics in the event this is a re-usable tip */
        this.graphics.clear();
        /* end add */
        var bounds : Rectangle = this.getBounds(this);
        
        var h : Float = (Math.isNaN(this._defaultHeight)) ? bounds.height + (this._buffer * 2) : this._defaultHeight;
        var fillType = GradientType.LINEAR;
        //var colors:Array = [0xFFFFFF, 0x9C9C9C];
        var alphas = [this._bgAlpha, this._bgAlpha];
        var ratios = [0x00, 0xFF];
        var matr : Matrix = new Matrix();
        var radians : Float = 90 * Math.PI / 180;
        matr.createGradientBox(this._defaultWidth, h, radians, 0, 0);
        var spreadMethod = SpreadMethod.PAD;
        if (!Math.isNaN(this._border)) {
            this.graphics.lineStyle(_borderSize, _border, 1);
        }
        this.graphics.beginGradientFill(fillType, this._bgColors, alphas, ratios, matr, spreadMethod);
        if (this._hookEnabled) {
            var xp : Float = 0;var yp : Float = 0;var w : Float = this._defaultWidth;
            this.graphics.moveTo(xp + this._cornerRadius, yp);
            this.graphics.lineTo(xp + w - this._cornerRadius, yp);
            this.graphics.curveTo(xp + w, yp, xp + w, yp + this._cornerRadius);
            this.graphics.lineTo(xp + w, yp + h - this._cornerRadius);
            this.graphics.curveTo(xp + w, yp + h, xp + w - this._cornerRadius, yp + h);
            
            //hook
            this.graphics.lineTo(xp + this._hookOffSet + this._hookSize, yp + h);
            this.graphics.lineTo(xp + this._hookOffSet, yp + h + this._hookSize);
            this.graphics.lineTo(xp + this._hookOffSet - this._hookSize, yp + h);
            this.graphics.lineTo(xp + this._cornerRadius, yp + h);
            
            this.graphics.curveTo(xp, yp + h, xp, yp + h - this._cornerRadius);
            this.graphics.lineTo(xp, yp + this._cornerRadius);
            this.graphics.curveTo(xp, yp, xp + this._cornerRadius, yp);
            this.graphics.endFill();
        }
        else {
            this.graphics.drawRoundRect(0, 0, this._defaultWidth, h, this._cornerRadius);
        }
    }
    private function animate(show : Bool) : Void{
        Actuate.stop(this);
        if (show) Actuate.tween(this, .5, { alpha : 1 } );
        else {
            Actuate.tween(this, .5, { alpha : 0}).onComplete(cleanUp);
            _timer.reset();
        }
    }
    private function set_bgAlpha(value : Float) : Float{
        this._bgAlpha = value;
        return value;
    }
    private function get_bgAlpha() : Float{
        return this._bgAlpha;
    }
    private function set_tipWidth(value : Float) : Float{
        this._defaultWidth = value;
        return value;
    }
    private function set_titleFormat(tf : TextFormat) : TextFormat{
        this._titleFormat = tf;
        if (this._titleFormat.font == null) {
            this._titleFormat.font = "_sans";
        }
        this._titleOverride = true;
        return tf;
    }
    private function set_contentFormat(tf : TextFormat) : TextFormat{
        this._contentFormat = tf;
        if (this._contentFormat.font == null) {
            this._contentFormat.font = "_sans";
        }
        this._contentOverride = true;
        return tf;
    }
    /*private function set_stylesheet(ts : StyleSheet) : StyleSheet{
        this._stylesheet = ts;
        this._styleOverride = true;
        return ts;
    }*/
    private function set_align(value : String) : String{
        var a : String = value.toLowerCase();
        var values : String = "right left center";
        if (values.indexOf(value) == -1) {
            throw new Error(this + " : Invalid Align Property, options are: 'right', 'left' & 'center'");
        }
        else {
            this._align = a;
        }
        return value;
    }
    private function set_delay(value : Float) : Float{
        this._delay = value;
        this._timer.delay = value;
        return value;
    }
    private function set_hook(value : Bool) : Bool{
        this._hookEnabled = value;
        return value;
    }
    private function set_hookSize(value : Float) : Float{
        this._hookSize = value;
        return value;
    }
    private function set_cornerRadius(value : Float) : Float{
        this._cornerRadius = value;
        return value;
    }
    private function set_colors(colArray : Array<UInt>) : Array<UInt>{
        this._bgColors = colArray;
        return colArray;
    }
    private function set_autoSize(value : Bool) : Bool{
        this._autoSize = value;
        return value;
    }
    private function set_border(value : UInt) : UInt{
        this._border = value;
        return value;
    }
    private function set_borderSize(value : Float) : Float{
        this._borderSize = value;
        return value;
    }
    private function set_tipHeight(value : Float) : Float{
        this._defaultHeight = value;
        return value;
    }
    private function set_titleEmbed(value : Bool) : Bool{
        this._titleEmbed = value;
        return value;
    }
    private function set_contentEmbed(value : Bool) : Bool{
        this._contentEmbed = value;
        return value;
    }
    private function textGlow(field : TextField) : Void{
        var filter = new GlowFilter(0x000000, 0.35, 2, 2, 1, BitmapFilterQuality.HIGH);
        field.filters = [filter];
    }
    private function bgGlow() : Void{
        var filter = new GlowFilter(0x000000, 0.2, 5, 5, 1, BitmapFilterQuality.HIGH);
        filters = [filter];
    }
    private function initTitleFormat() : Void{
        _titleFormat = new TextFormat("_sans", 20, 0x333333, true);
    }
    private function initContentFormat() : Void{
        _contentFormat = new TextFormat("_sans", 14, 0x333333);
    }
    private function addedToStage(displayObject : DisplayObject) : Bool{
        var hasStage : Stage = displayObject.stage;
        return hasStage == (null) ? false : true;
    }
    private function setOffset() : Void{
        var _sw0_ = (this._align);        

        switch (_sw0_)
        {
            case "left":
                this._offSet = -_defaultWidth + (buffer * 3) + this._hookSize;
                this._hookOffSet = this._defaultWidth - (buffer * 3) - this._hookSize;
            
            case "right":
                this._offSet = 0 - (buffer * 3) - this._hookSize;
                this._hookOffSet = buffer * 3 + this._hookSize;
            
            case "center":
                this._offSet = -(_defaultWidth / 2);
                this._hookOffSet = (_defaultWidth / 2);
            
            default:
                this._offSet = -(_defaultWidth / 2);
                this._hookOffSet = (_defaultWidth / 2);
        }
    }
    public function cleanUp() : Void {
		Actuate.stop(this);
        if (_parentObject != null) 
            this._parentObject.removeEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut);  //this._parentObject.removeEventListener( MouseEvent.MOUSE_MOVE, this.onMouseMovement );  ;
        
        this.follow(false);
        if (this._tf != null) {
            this._tf.filters = [];
            this._contentContainer.removeChild(this._tf);
            this._tf = null;
        }
        this.filters = [];
        if (this._cf != null) {
            this._cf.filters = [];
            this._contentContainer.removeChild(this._cf);
            this._cf = null;
        }
        this.graphics.clear();
        if (contains(_contentContainer)) 
            removeChild(this._contentContainer);
        if (parent != null) 
            parent.removeChild(this);
    }
}

