package {
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.utils.setTimeout;
	
	[SWF(width="640", height="920", frameRate="60", backgroundColor="#FFFFFF")] 
	public class SampleApp extends Sprite {
				
		var design:MainView = new MainView()
		private var imageLoader:Loader;
		static private var finder:Finder
		
		public function SampleApp(){
			addChild( design )			
			design.flash_mc.visible = false;
			design.footer_mc.progress_mc.visible = false;
			
			
			setTimeout( initFinder, 30 )
			
			design.footer_mc.shutter_btn.addEventListener( MouseEvent.CLICK, _capture );
			design.changeCamera_btn.addEventListener( MouseEvent.CLICK, toggleCamera );
		}
		
		
		
		
		public function initFinder(){
			if( finder==null ){
				finder = new Finder( 640, 640 )
				finder.disableOnRemovedFromStage = false;
			}
			
			design.finderContainer_mc.addChild( finder )
		}
		
		
		private function toggleCamera(e){
			finder.toggleCamera()
		}
		
		
		
		private function _capture(e){
			trace( "capture" )
			finder.shoot();
		}

	}
}





class MainView extends CaptureScene_design{}


























