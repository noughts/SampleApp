package {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.desktop.*;
	import flash.sensors.*;
	import flash.utils.setTimeout;

	import fl.controls.*;
	
	import jp.dividual.capture.*;
	
	[SWF(width="640", height="920", frameRate="60", backgroundColor="#FFFFFF")] 
	public class SampleApp extends Sprite {
				
		private var design:Design = new Design()
		private var capture:CaptureDevice
		private var bd:BitmapData;
		private var bmp:Bitmap;
		private var cameraLaunched:Boolean = false;
		private var orientationDetector:DeviceOrientationDetector

		public function SampleApp(){
			addChild( design )

			design.diaphragmAnime_mc.stop();

			design.startCamera_btn.addEventListener( MouseEvent.CLICK, function(e):void{ startCapture() } );
			design.stopCamera_btn.addEventListener( MouseEvent.CLICK, function(e):void{ stopCapture() } );
			design.shutter_btn.addEventListener( MouseEvent.CLICK, function(e):void{ shutter() } );
			design.flashOn_btn.addEventListener( MouseEvent.CLICK, function(e):void{ setFlashMode( CaptureDevice.FLASH_MODE_ON ) } );
			design.flashOff_btn.addEventListener( MouseEvent.CLICK, function(e):void{ setFlashMode( CaptureDevice.FLASH_MODE_OFF ) } );
			design.flashAuto_btn.addEventListener( MouseEvent.CLICK, function(e):void{ setFlashMode( CaptureDevice.FLASH_MODE_AUTO ) } );
			design.af_btn.addEventListener(MouseEvent.CLICK, function(e):void{ focusAndExposureAtPoint(320, 240); });
			design.changeCamera_btn.addEventListener( MouseEvent.CLICK, function(e):void{ toggleDevice() } );
			design.focusPoint_mc.visible = false;


			design.flashOn_btn.visible = false;
			design.flashOff_btn.visible = false;
			design.flashAuto_btn.visible = false;

			design.exposure_mc.visible = false;
			design.exposure_mc.p2_btn.addEventListener( MouseEvent.CLICK, _onExposureClick );
			design.exposure_mc.p1_btn.addEventListener( MouseEvent.CLICK, _onExposureClick );
			design.exposure_mc.default_btn.addEventListener( MouseEvent.CLICK, _onExposureClick );
			design.exposure_mc.m1_btn.addEventListener( MouseEvent.CLICK, _onExposureClick );
			design.exposure_mc.m2_btn.addEventListener( MouseEvent.CLICK, _onExposureClick );

			NativeApplication.nativeApplication.addEventListener( InvokeEvent.INVOKE, _onInvoke );
			NativeApplication.nativeApplication.addEventListener( Event.DEACTIVATE, _onDeactivateHandler );

			//stage.addEventListener( Event.ENTER_FRAME, function(){ trace( stage.deviceOrientation ) });

			orientationDetector = new DeviceOrientationDetector();
			orientationDetector.addEventListener( StageOrientationEvent.ORIENTATION_CHANGE, _onDeviceOrientationChange );
		}

		// 起動時
		private function _onInvoke( e:InvokeEvent ):void{
			trace( e );
			trace( "cameraLaunched", cameraLaunched )
			if( cameraLaunched ){
				startCapture();
			}
		}

		// 終了時
		private function _onDeactivateHandler( e:Event ):void{
			trace( e );
			if( cameraLaunched ){
				stopCapture( true );
			}
		}

		// 本体の向きが変わった時
		private function _onDeviceOrientationChange( e:StageOrientationEvent ):void{
			trace( "_onDeviceOrientationChange", e.afterOrientation )
		}


		// カメラを取得しキャプチャを開始
		public function startCapture():void{
			trace( ">>>>", CaptureDevice.names )
			trace( ">>>>", CaptureDevice.names )
			trace( ">>>>", CaptureDevice.names )
			if( capture==null ){
				var names:Array = CaptureDevice.names;
				if( names.length==0 ){
					trace( "カメラが見つかりません" )
					return
				}
				if( names.length==1 ){
					design.changeCamera_btn.visible = false;
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
			cameraLaunched = true;
		}

		// キャプチャを終了
		// onAppExit はアプリ終了時のカメラ停止時に true で呼ばれる。
		// その場合は、次回起動時にまたカメラを起動できるようにするため、cameraLaunched を false にしない。
		private function stopCapture( onAppExit:Boolean=false ):void{
			if( capture==null ){
				return;
			}
			capture.stopCapturing()
			removeEventListener( Event.ENTER_FRAME, renderFrame )
			if( bmp ){
				bmp.visible = false;
			}
			
			if( onAppExit==false ){
				cameraLaunched = false;
				design.diaphragmAnime_mc.gotoAndPlay( "close" )
			} else {
				design.diaphragmAnime_mc.gotoAndStop( "open" )
			}
		}


		private function _onPreviewReady( e:CaptureDeviceEvent ):void{
			trace("EVENT: Preview ready", capture.bmp.rect);
			design.diaphragmAnime_mc.gotoAndPlay( "open" )
			if( bmp ){
				bmp.visible = true;
			}
			_updateUI()
		}


		private function _updateUI():void{
			// LED フラッシュのサポート具合によって UI の表示を更新
			var isFlashSupported:Boolean = capture.isFlashSupported;
			design.flashOn_btn.visible = isFlashSupported;
			design.flashOff_btn.visible = isFlashSupported;
			design.flashAuto_btn.visible = isFlashSupported;

			// 露出補正のサポート具合によって UI の表示を更新
			var isExposureCompensationSupported:Boolean = capture.isExposureCompensationSupported;
			design.exposure_mc.visible = isExposureCompensationSupported
			if( isExposureCompensationSupported ){
				// 露出設定設定を UI に反映
				design.exposure_mc.p2_btn.selected = false;
				design.exposure_mc.p1_btn.selected = false;
				design.exposure_mc.default_btn.selected = false;
				design.exposure_mc.m1_btn.selected = false;
				design.exposure_mc.m2_btn.selected = false;
				var level:int = capture.getExposureCompensation();
				switch( level ){
					case 2:
						design.exposure_mc.p2_btn.selected = true;
						break
					case 1:
						design.exposure_mc.p1_btn.selected = true;
						break
					case 0:
						design.exposure_mc.default_btn.selected = true;
						break
					case -1:
						design.exposure_mc.m1_btn.selected = true;
						break
					case -2:
						design.exposure_mc.m2_btn.selected = true;
						break
				}
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
			var rot:int;
			switch( orientationDetector.deviceOrientation ){
				case StageOrientation.DEFAULT:
					rot = CaptureDevice.ROTATION_0;
					break;
				case StageOrientation.ROTATED_RIGHT:
					rot = CaptureDevice.ROTATION_90;
					break;
				case StageOrientation.UPSIDE_DOWN:
					rot = CaptureDevice.ROTATION_180;
					break;
				case StageOrientation.ROTATED_LEFT:
					rot = CaptureDevice.ROTATION_270;
					break;
			}
			trace( "shutter", orientationDetector.deviceOrientation, rot )
			capture.shutter("Blink", rot, withSound);
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


		// 露出補正
		private function _onExposureClick( e:MouseEvent ):void{
			var btn:Button = e.currentTarget as Button;
			var level:int = 0;
			switch( btn ){
				case design.exposure_mc.p2_btn:
					level = 2;
					break;
				case design.exposure_mc.p1_btn:
					level = 1;
					break;
				case design.exposure_mc.default_btn:
					level = 0;
					break;
				case design.exposure_mc.m1_btn:
					level = -1;
					break;
				case design.exposure_mc.m2_btn:
					level = -2;
					break;
			}
			capture.setExposureCompensation( level )
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


























