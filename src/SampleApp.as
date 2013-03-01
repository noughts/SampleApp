package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.setTimeout;
	
	import jp.dividual.capture.*;
	
	[SWF(width="640", height="920", frameRate="60", backgroundColor="#FFFFFF")] 
	public class SampleApp extends Sprite {
				
		private var design:Design = new Design()
		private var capture:CaptureDevice
		private var bd:BitmapData;
		private var bmp:Bitmap;

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
			if( capture==null ){
				var names:Array = CaptureDevice.names;
				if( names.length==0 ){
					trace( "カメラが見つかりません" )
					return
				}
				var name:String = names[0]
				var _width:uint = 852;
				var _height:uint = 640
				capture = new CaptureDevice(0, _width, _height);
				if( capture==null ){
					trace( "カメラ"+ name +"を取得出来ませんでした。" )
					return;
				}
				capture.addEventListener( CaptureDeviceEvent.EVENT_PREVIEW_READY, _onPreviewReady );
				capture.addEventListener( CaptureDeviceEvent.EVENT_IMAGE_SAVED, _onImageSaved );
				capture.addEventListener( CaptureDeviceEvent.EVENT_FOCUS_COMPLETE, onFocusComplete );
			}
			capture.startCapturing()
			addEventListener( Event.ENTER_FRAME, renderFrame )
		}

		private function _onPreviewReady( e:CaptureDeviceEvent ):void{
			trace("EVENT: Preview ready", capture.bmp.rect);
			if( bmp ){
				bmp.visible = true;
			}
		}

		private function _onImageSaved( e:CaptureDeviceEvent ):void{
			trace("EVENT: Image has been saved.");
			//capture.putExifLocation( e.data, 12.345, 23.456 );
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
						bmp.rotation = 90;
						bmp.x = capture.bmp.rect.height;

						// クリックしたポイントの座標をステージに配置したサイズと合わせるため、
						// finderContainer_mc 内に finder_mc を作成し、そこに bmp を addChild したあとスケール
						var finder_mc:Sprite = new Sprite()
						finder_mc.addChild( bmp );
						design.finderContainer_mc.addChild( finder_mc )

						design.finderContainer_mc.mouseEnabled = true
						design.finderContainer_mc.mouseChildren = false;
						design.finderContainer_mc.addEventListener( MouseEvent.CLICK, onPreviewClick );

						// 画面の幅に合わせてスケール
						var _aspectRatio:Number = bd.width / bd.height;
						finder_mc.width = 640;
						finder_mc.height = 640 * _aspectRatio;
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
			if( capture==null ){
				return;
			}
			capture.stopCapturing()
			removeEventListener( Event.ENTER_FRAME, renderFrame )
			if( bmp ){
				bmp.visible = false;
			}

		}

		private function onPreviewClick(e:MouseEvent):void{
			//trace( "_onPreviewClick", e )
			design.focusPoint_mc.visible = true
			design.focusPoint_mc.x = e.localX
			design.focusPoint_mc.y = e.localY

			// ソースは横なので、回転させた座標を渡す
			var tx:Number = e.localY
			var ty:Number = 640 - e.localX
			var px:Number = tx / design.finderContainer_mc.height
			var py:Number = ty / design.finderContainer_mc.width
			if( px > 1 ) px = 1;
			if( py > 1 ) py = 1;
			trace( "フォーカスします。", px, py )
			capture.focusAndExposureAtPoint( px, py );
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


























