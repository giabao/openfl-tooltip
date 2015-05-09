import openfl.display.Sprite;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.events.MouseEvent;

using com.sandinh.TipTools;

class Main extends Sprite {
	public function new() {
		super();
        var txt = new TextField();
        txt.text = "Hello OpenFL Tooltip";
        txt.border = true;
		addChild(txt);
        
        txt.regisTip("Tip 1");
        
        txt = new TextField();
        txt.text = "OpenFL Tooltip 2";
        txt.x = 120; txt.y = 120;
        txt.autoSize = TextFieldAutoSize.LEFT;
        txt.border = true;
		addChild(txt);
        
        txt.regisTip("Tip 2", true);
        
        txt.showTip();
	}
}
