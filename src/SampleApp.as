package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.setTimeout;
	
	import jp.dividual.capture.CaptureDevice;
	
	[SWF(width="640", height="920", frameRate="60", backgroundColor="#FFFFFF")] 
	public class SampleApp extends Sprite {
				
		private var design:Design = new Design()
		private var capture:CaptureDevice
		private var bd:BitmapData;
		private var bmp:Bitmap;
		private var currentDeviceName:String;

		public function SampleApp(){
			addChild( design )
			design.startCamera_btn.addEventListener( MouseEvent.CLICK, function(e):void{ startCapture() } );
			design.stopCamera_btn.addEventListener( MouseEvent.CLICK, function(e):void{ stopCapture() } );
			design.shutter_btn.addEventListener( MouseEvent.CLICK, function(e):void{ shutter() } );
			design.flashOn_btn.addEventListener( MouseEvent.CLICK, function(e):void{ setFlashMode( CaptureDevice.FLASH_MODE_ON ) } );
			design.flashOff_btn.addEventListener( MouseEvent.CLICK, function(e):void{ setFlashMode( CaptureDevice.FLASH_MODE_OFF ) } );
			design.flashAuto_btn.addEventListener( MouseEvent.CLICK, function(e):void{ setFlashMode( CaptureDevice.FLASH_MODE_AUTO ) } );
			design.af_btn.addEventListener(MouseEvent.CLICK, function(e):void{ focusAndExposureAtPoint(320, 240); });
			design.changeCamera_btn.addEventListener( MouseEvent.CLICK, function(e):void{ toggleDevice() } );
			design.focusPoint_mc.visible = false;
		}

		// カメラを取得しキャプチャを開始
		public function startCapture():void{
			var names:Array = CaptureDevice.names;
			if( names.length==0 ){
				trace( "カメラが見つかりません" )
				return
			}
			var name:String = names[0]
			var _width:uint = 640;
			var _height:uint = 480
			capture = new CaptureDevice(0, _width, _height);
			if( capture==null ){
				trace( "カメラ"+ name +"を取得出来ませんでした。" )
				return;
			}
			currentDeviceName = name;
			addEventListener( Event.ENTER_FRAME, renderFrame )
			capture.addEventListener( CaptureDevice.EVENT_FOCUS_COMPLETE, onFocusComplete );
			capture.addEventListener( CaptureDevice.EVENT_PREVIEW_READY, function(event:Event):void {
				trace("EVENT: Preview ready");
			});
			capture.addEventListener( CaptureDevice.EVENT_IMAGE_SAVED, function(event:Event):void {
				trace("EVENT: Image has been saved.");
			});
			capture.startCapturing()
		}

		// ANE から新しいフレーム画像を取得し、画面に表示
		private function renderFrame(evt:Event):void{
			var isNewFrame:Boolean;
			if (capture != null) {
				isNewFrame = capture.requestFrame();
				if (isNewFrame) {
					if (!bd) {
						bd = new BitmapData( capture.bmp.width, capture.bmp.height )
						bmp = new Bitmap( bd )
						bmp.x = bd.height + (640 - bd.height) / 2;
						bmp.y = 130;
						bmp.rotation = 90;
						bmp.addEventListener( MouseEvent.CLICK, onPreviewClick );
						design.previewContainer_mc.addChild(bmp);
					}
					bd.copyPixels( capture.bmp, capture.bmp.rect, new Point(0,0));
				}
			}
		}

		// フォーカスと露出を合わせて撮影、フルサイズの画像を端末のカメラロールに保存し、withSound が true ならシャッター音を鳴らす
		// シャッター音は消せない可能性あり。要相談
		private function shutter( withSound:Boolean=true ):void{
			capture.shutter("Blink", CaptureDevice.ROTATION_90, withSound);
		}

		// キャプチャを終了
		private function stopCapture():void{
			capture.stopCapturing()
			removeEventListener( Event.ENTER_FRAME, renderFrame )
			capture.removeEventListener( CaptureDevice.EVENT_FOCUS_COMPLETE, onFocusComplete );
		}

		private function onPreviewClick(e:MouseEvent):void{
			var bmp:Bitmap = e.currentTarget as Bitmap;
			var px:Number = e.localX / bmp.width
			var py:Number = e.localY / bmp.height;
			focusAndExposureAtPoint( px, py )
		}

		private function onFocusComplete(e:Event):void{
			trace("EVENT: Auto focus complete.");
			design.focusPoint_mc.visible = false;
		}

		// フラッシュの状態を取得
		private function getFlashMode():uint{
			return capture.getFlashMode()
		}
		// フラッシュの状態を設定
		// CaptureDevice.FLASH_MODE_OFF など
		private function setFlashMode( mode:uint ):void{
			capture.setFlashMode( mode )
		}


		// 指定した位置( 0〜1.0 )でフォーカスと露出を調整
		private function focusAndExposureAtPoint( x:Number=0.5, y:Number=0.5 ):void{
			capture.focusAndExposureAtPoint( x, y )
		}

		// カメラをトグル
		private function toggleDevice():void{
			capture.toggleDevice()
		}

	}
}





class Design extends MainDesign{}


























