package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.JPEGEncoderOptions;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.media.StageVideo;
	import flash.media.Video;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import ru.inspirit.capture.CaptureDevice;
	import ru.inspirit.capture.CaptureDeviceInfo;
	
	public class Finder extends Sprite{
				
		public function get camera():Camera{ return _camera }
		public function get bd():BitmapData{ return _bd }
		
		// ステージから削除された時に処理を止めるか？
		public var disableOnRemovedFromStage:Boolean = true;
		private var _stageVideo:StageVideo
		
		
		private var _width:uint;
		private var _height:uint;
		private var _video:Video;
		private var _camera:Camera;
		private var _bd:BitmapData;
		private var _bmp:Bitmap;
		private var _preview_bmp:Bitmap;
		private var _cameraId:uint = 0;
		private var _initialized:Boolean = false;
		
		public var streamW:int = 640;
		public var streamH:int = 480;
		public var capture:CaptureDevice;
		public var devices:Vector.<CaptureDeviceInfo>;
		public const clipRect:Rectangle = new Rectangle(0, 0, 512, 512);
		public var captured_bd:BitmapData = new BitmapData( 640, 640, false )
		
		public function Finder( $width:uint, $height:uint, cameraId:uint=0 ){
			_width = $width;
			_height = $height;
			_cameraId = cameraId;
			
			_bd = new BitmapData( 640, 480, false );
			_bmp = new Bitmap( _bd )
			_bmp.rotation = 90
			_bmp.x = 480
			_bmp.height = 640;
			addChild( _bmp )
			
			this.addEventListener( Event.ADDED_TO_STAGE, _onAddedToStage );
			this.addEventListener( Event.REMOVED_FROM_STAGE, _onRemovedFromStage );
			this.addEventListener( MouseEvent.CLICK, _onClick );			
		}
		
		
		private function _onAddedToStage( e ){
			trace( "Finder _onAddedToStage" )
			if( _initialized==false ){
				//if( Capabilities.os.indexOf("iPhone")>-1 ){
					initCapture()
				//} else {
				//	trace( "CaptureDevice が使えないので通常のビデオにフォールバックします" )
				//	initNormalCamera()
				//}
			}
			_initialized = true;
			
			if (capture){
				addEventListener(Event.ENTER_FRAME, render);
			}
		}
		
		
		
		
		private function _onRemovedFromStage( e ){
			trace( "Finder _onRemovedFromStage" )
			if (capture){
				removeEventListener(Event.ENTER_FRAME, render);
			}
			
		}
		
		
		private function _onClick( e:MouseEvent ):void{
			if (capture){
				// ソースは横なので、回転させた座標を渡す
				var tx:Number = e.localY
				var ty:Number = 640 - e.localX
				var px:Number = tx / 640
				var py:Number = ty / 640
				trace( "フォーカスします。", px, py )
				capture.focusAtPoint( px, py );
				capture.exposureAtPoint(px, py);
				var flashMode:int = capture.getFlashMode();
				trace("Flash Mode: ", flashMode);
				//capture.setFlashMode(CaptureDevice.IOS_FLASH_MODE_ON);
				capture.setFlashMode(CaptureDevice.ANDROID_FLASH_MODE_ON);
			}
		}
		
		private function initStageVideo(){
			trace( "stage.stageVideos", stage.stageVideos, stage.stageVideos.length )
			_stageVideo = stage.stageVideos[0];
			_stageVideo.viewPort = new Rectangle( 0, 0, _width, _height );
			
			_camera.setMode( _width, _height, 60 );
			_stageVideo.attachCamera( _camera )
		}
		
		protected function initCapture():void{
			CaptureDevice.initialize();
			devices = CaptureDevice.getDevices(true);
			capture = null;
			
			// Back Camera on mobiles
			var dev:CaptureDeviceInfo = devices[_cameraId];
			//
			try{
				// u can change desired photo quality
				if (Capabilities.manufacturer.toLowerCase().indexOf('android') != -1){
					capture = new CaptureDevice(dev.name, streamW, streamH, 15, CaptureDevice.ANDROID_STILL_IMAGE_QUALITY_BEST);
				} else {
					capture = new CaptureDevice(dev.name, 0, streamH, 15);
				}
				trace( capture.width, capture.height )
			}catch (err:Error){
				trace( "CAN'T CONNECT TO CAMERA: ", err.message )
			}
			
			if (capture){
				// we will use bytearrays only
				// power of 2 for stage3D
				// and specify clipping rectangle so it will use smaller power of 2 texture size
				capture.setupForDataType( CaptureDevice.GET_FRAME_BITMAP, clipRect );
				capture.addEventListener(ru.inspirit.capture.CaptureDevice.EVENT_FOCUS_COMPLETE, onFocusComplete);
				capture.addEventListener(ru.inspirit.capture.CaptureDevice.EVENT_PREVIEW_READY, onPreviewReady);
				// Test code for listening status bar tap event
				capture.addEventListener(ru.inspirit.capture.CaptureDevice.EVENT_STATUS_BAR_TAPPED, onStatusBarTapped);
				capture.addEventListener(ru.inspirit.capture.CaptureDevice.EVENT_IMAGE_SAVED, onImageSaved);
			}
		}
		
		// Test code for listening status bar tap event
		private function onStatusBarTapped(event:Event):void {
			trace("STATUS BAR TAPPED");
		}
		
		private function onFocusComplete(event:Event):void {
			trace("FOCUS COMPLETE");
		}
		
		private function onPreviewReady(event:Event):void {
			trace("PREVIEW READY");
		}
		
		private function onImageSaved(event:Event):void {
			trace("IMAGE SAVED");
		}
		
		private function initNormalCamera():void {
			trace( Camera.names )
			_camera = Camera.getCamera( String(_cameraId) );
			
			if( _video ){
				removeChild( _video );
			}
			var standardRatio:Number = 1024/768;
			_video = new Video( _height*standardRatio, _height );
			_video.smoothing = true;
			
			// カメラ設定 いじると、flvの再生時に不具合が起こるので慎重に！
			_camera.setMode( 640*1.3333, 640, 30 );
			
			
			var frameSize:Rectangle = new Rectangle( 0, 0, _width, _height );
			
			if( Capabilities.os.indexOf("Mac")>-1 ){
				_video.x = 0 - (_video.width-_width)/2
			} else {
				_video.rotation = 90;
				_video.x = frameSize.width;
				_video.y = frameSize.height/2 - _video.width/2;
			}
			_video.attachCamera( _camera );
			addChild( _video );
			this.scrollRect = frameSize
		}
		
		var _origin:Point = new Point(0, 0);
		
		protected function render(e:Event):void{
			var isNewFrame:Boolean;
			isNewFrame = capture.requestFrame(CaptureDevice.GET_FRAME_BITMAP);
			
			if( isNewFrame ){
				//trace( capture.bmp.rect )
				//var fix:int = (640 - capture.bmp.rect.width) / 2
				bd.copyPixels( capture.bmp, capture.bmp.rect, _origin);
			}
		}
		
		public function shoot():void {
			var path:String = capture.captureAndSaveImage("blink", CaptureDevice.DEVICE_ORIENTATION_90);
		}
		/*
		public function shoot():void {
			if( capture ){
				capture.addEventListener(CaptureDevice.EVENT_STILL_IMAGE_READY, onStillImageReady);
				capture.captureStillImage();
			}
			captured_bd.draw( this )
		}
		*/
		
		/*
		protected function onStillImageReady(e:Event):void{
			capture.removeEventListener(CaptureDevice.EVENT_STILL_IMAGE_READY, onStillImageReady);
			
			// the result is JPEG file
			var ba:ByteArray = new ByteArray();
			ba.endian = Endian.LITTLE_ENDIAN;
			capture.grabStillImage(ba);
			ba.position = 0;
			
			// now lets save it to camera roll
			if(CaptureDevice.supportsSaveToCameraRoll()){
				var now:Date = new Date();
				var filename:String = "IMG_" + now.fullYear +
					now.month +
					now.day +
					now.hours +
					now.minutes +
					now.seconds + ".jpg";
				if (Capabilities.manufacturer.toLowerCase().indexOf('android') != -1){
					// on android we save to /sdcard/ folder by default
					// so u can adjust path by simply changing filename
					var fl:File = File.userDirectory.resolvePath("blink");
					if(!fl.exists) fl.createDirectory();
					
					filename = 'blink/' + filename;
				}
				CaptureDevice.saveToCameraRoll(filename, ba, ba.length);
			}
		}
		*/
		 
		
		
		public function getImageBinary( type:String="jpg", quality:uint=95 ):ByteArray{
			var ba:ByteArray = new ByteArray();
			captured_bd.encode( captured_bd.rect, new JPEGEncoderOptions(quality), ba );	
			return ba;		
		}
		
		
		
		
		public function reset():void{
			removeChild( _preview_bmp );
			addChild( _video );
			_video.attachCamera( _camera );
		}
		
		
		public function toggleCamera():void{
			switch( _cameraId ){
				case 0:
					_cameraId = 1
					break;
				case 1:
					_cameraId = 0
					break;
			}
			
			if (Capabilities.manufacturer.toLowerCase().indexOf('android') != -1){
				if (capture) {
					capture.dispose();
					capture = null;
				}
				
				var dev:CaptureDeviceInfo = devices[_cameraId];
				capture = new CaptureDevice(dev.name, streamW, streamH, 15, CaptureDevice.ANDROID_STILL_IMAGE_QUALITY_BEST);
				trace( capture.width, capture.height )
				if (capture){
					// we will use bytearrays only
					// power of 2 for stage3D
					// and specify clipping rectangle so it will use smaller power of 2 texture size
					capture.setupForDataType( CaptureDevice.GET_FRAME_BITMAP, clipRect );
					capture.addEventListener(ru.inspirit.capture.CaptureDevice.EVENT_FOCUS_COMPLETE, onFocusComplete);
					capture.addEventListener(ru.inspirit.capture.CaptureDevice.EVENT_PREVIEW_READY, onPreviewReady);
					// Test code for listening status bar tap event
					capture.addEventListener(ru.inspirit.capture.CaptureDevice.EVENT_STATUS_BAR_TAPPED, onStatusBarTapped);
				}
			} else {
				if (capture) {
					capture.stop();
				}
			
				trace( capture.width, capture.height )
				initCapture()
			}
		}
		
		public function changeToFrontCamera():void{
			if( _cameraId == 1){
				return;
			}
			if( Camera.names.length == 1 ){
				return;
			}
			_cameraId = 1
			
		}
		
		public function changeToBackCamera():void{
			if( _cameraId == 0){
				return;
			}
			if( Camera.names.length == 1 ){
				return;
			}
			_cameraId = 0
			
		}
		
	}
	
}
