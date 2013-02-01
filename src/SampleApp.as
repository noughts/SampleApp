package {
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.utils.setTimeout;
	
	[SWF(width="640", height="920", frameRate="60", backgroundColor="#FFFFFF")] 
	public class SampleApp extends Sprite {
				
		var design:Design = new Design()
		var capture:CaptureDevice
		var bd:BitmapData;
		var bmp:Bitmap;
		var currentDeviceName:String;

		public function SampleApp(){
			addChild( design )
		}


		// カメラを取得しキャプチャを開始
		public function startCapture(){
			var names:Array = CaptureDevice.names;
			if( names.length==0 ){
				trace( "カメラが見つかりません" )
				return
			}
			var name:String = names[0]
			var _width:uint = 640;
			var _height:uint = 480
			capture = CaptureDevice.getDevice( name, _width, _height )
			if( capture==null ){
				trace( "カメラ"+ name +"を取得出来ませんでした。" )
				return;
			}
			currentDeviceName = name;
			addEventListener( Event.ENTER_FRAME, renderFrame )
			capture.start()
		}

		// ANE から新しいフレーム画像を取得し、画面に表示
		private function renderFrame(){
			var isNewFrame:Boolean;
			isNewFrame = capture.requestFrame();
			if( isNewFrame ){
				if( !bd ){
					bd = new BitmapData( capture.bmp.width, capture.bmp.height )
					bmp = new Bitmap( bd )
					addChild( bmp )
				}
				bd.copyPixels( capture.bmp, capture.bmp.rect, _origin);
			}
		}

		// フォーカスと露出を合わせて撮影、フルサイズの画像を端末のカメラロールに保存し、withSound が true ならシャッター音を鳴らす
		// シャッター音は消せない可能性あり。要相談
		private function shutter( withSound:Boolean=true ):void{
			capture.shutter( withSound )
		}

		// キャプチャを終了
		private function stopCapture(){
			capture.stop()
			removeEventListener( Event.ENTER_FRAME, renderFrame )
		}

		// フラッシュの状態を取得
		private function getFlashMode():String{
			return capture.getFlashMode()
		}
		// フラッシュの状態を設定
		// "on" or "off" or "auto"
		private function setFlashMode( mode:String ):void{
			capture.setFlashMode( mode )
		}


		// 指定した位置( 0〜1.0 )でフォーカスと露出を調整
		private function focusAndExposureAtPoint( x:Number=0.5, y:Number=0.5 ):void{
			capture.focusAndExposureAtPoint( x, y )
		}

		// カメラをトグル
		private function toggleCamera(){
			capture.toggleCamera()
		}
		
		

	}
}





class Design extends MainDesign{}


























