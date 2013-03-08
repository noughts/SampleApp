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

		public var currentOrientation:String;

		public function DeviceOrientationDetector(){
			currentOrientation = StageOrientation.DEFAULT;
			var accelerometer:Accelerometer = new Accelerometer();
			accelerometer.addEventListener( AccelerometerEvent.UPDATE, accUpdateHandler );
		}

		private function accUpdateHandler( e:AccelerometerEvent ):void{
			var newOrientation:String = _getOrientation( e )
			if( currentOrientation != newOrientation ){
				var soe:StageOrientationEvent = new StageOrientationEvent( StageOrientationEvent.ORIENTATION_CHANGE );
				dispatchEvent( soe );
			}
			currentOrientation = newOrientation;
		}
		private function _getOrientation( e:AccelerometerEvent ):String{
			var out:String = StageOrientation.DEFAULT;
			return out;
		}

	}
}