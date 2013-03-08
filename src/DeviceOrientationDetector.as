/*

デバイスの回転ロック中にもデバイスの回転を検知するクラスです。

*/

package{

	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.desktop.*;
	import flash.sensors.*;

	public class DeviceOrientationDetector extends EventDispatcher{

		// [読み取り専用] デバイスの物理的な方向です。
		private var _deviceOrientation:String;
		public function get deviceOrientation():String{
			return _deviceOrientation;
		}

		public function DeviceOrientationDetector(){
			_deviceOrientation = StageOrientation.DEFAULT;
			var accelerometer:Accelerometer = new Accelerometer();
			accelerometer.addEventListener( AccelerometerEvent.UPDATE, accUpdateHandler );
		}

		private function accUpdateHandler( e:AccelerometerEvent ):void{
			var newOrientation:String = _getOrientation( e )
			if( deviceOrientation != newOrientation ){
				//trace( ">>>>>>>", newOrientation )
				var soe:StageOrientationEvent = new StageOrientationEvent( StageOrientationEvent.ORIENTATION_CHANGE, false, false, deviceOrientation, newOrientation );
				dispatchEvent( soe );
			}
			_deviceOrientation = newOrientation;
		}
		private function _getOrientation( e:AccelerometerEvent ):String{
			var ax:int = int(e.accelerationX*100)
			var ay:int = int(e.accelerationY*100)
			var az:int = int(e.accelerationZ*100)
			//trace( ax, ay, az )
			var out:String = StageOrientation.DEFAULT;
			if( 90-45 < ax && ax < 90+45 ){
				out = StageOrientation.ROTATED_LEFT;
			}
			if( -90-45 < ax && ax < -90+45 ){
				out = StageOrientation.ROTATED_RIGHT;
			}
			if( -90-45 < ay && ay < -90+45 ){
				out = StageOrientation.UPSIDE_DOWN;
			}
			return out;
		}

	}
}