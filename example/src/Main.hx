package;

import openfl.display.Sprite;
import openfl.Lib;
import com.sandinh.ToolTip;
import openfl.text.TextField;
import openfl.events.MouseEvent;

class Main extends Sprite {
    var tip = new ToolTip();

	public function new() {
		super();
		
        var txt = new TextField();
        txt.text = "Hello OpenFL Tooltip";
        txt.x = 100; txt.y = 100;
		addChild(txt);
        
        txt.addEventListener(MouseEvent.MOUSE_OVER, function(e) tip.show(txt, "My Title", "Tooltip content"));
	}
}
