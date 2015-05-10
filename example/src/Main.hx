import openfl.display.Sprite;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.events.MouseEvent;
import openfl.events.Event;

using com.sandinh.TipTools;

class Main extends Sprite {
	public function new() {
		super();
        
        ex2();
	}
    
    function ex1() {
        var txt = new TextField();
        txt.text = "Hello OpenFL Tooltip";
        txt.border = true;
		addChild(txt);
        
        txt.tooltip("Tip 1");
        
        txt = new TextField();
        txt.text = "OpenFL Tooltip 2";
        txt.x = 120; txt.y = 120;
        txt.autoSize = TextFieldAutoSize.LEFT;
        txt.border = true;
		addChild(txt);
        
        txt.showTip("Tip 2");
    }
    
    function ex2() {
        Lib.current.stage.addEventListener(Event.ENTER_FRAME, enterFrameEx2);
    }
    
    //var mc = new Sprite(); //(1)
    function enterFrameEx2(e: Event) {
        for (i in 0...1000) {
            var mc = new Sprite();
            //not leak memory ONLY if mc is local variable.
            //leak if we declare mc as a field in class Main - see (1)
            mc.tooltip("hi");
            
            mc.showTip("hi");
        }
    }
    
    function ex3() {
        Lib.current.stage.addEventListener(Event.ENTER_FRAME, enterFrameEx3);
    }
    
    function enterFrameEx3(e: Event) {
        for (i in 0...1000) {
            var mc = new McEx3();
            //not leak memory
            Lib.current.stage.addEventListener(MouseEvent.CLICK, mc.onClick, false, 0, true);
            
            //not leak memory
            mc.addEventListener(MouseEvent.CLICK, mc.onClick);
            
            //LEAK!!!
            //Lib.current.stage.addEventListener(MouseEvent.CLICK, mc.onClick);
        }
    }
}

class McEx3 extends Sprite {
    public function onClick(e: MouseEvent) {}
}
