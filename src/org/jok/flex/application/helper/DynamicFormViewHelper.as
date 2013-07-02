package org.jok.flex.application.helper
{
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.managers.CursorManager;
	
	import org.jok.flex.application.caller.DistantCaller;
	import org.jok.flex.application.interfaces.IFormView;
	import org.jok.flex.application.interfaces.IFormViewHelper;
	import org.jok.flex.application.model.FaultToken;
	import org.jok.flex.application.model.RemoteHandlerDescription;
	import org.jok.flex.utility.ObjectsUtility;

	public class DynamicFormViewHelper extends AbstractHelper implements IFormViewHelper {
		
		[Bindable]
		public var computedValue : Object = null;
		
		public function DynamicFormViewHelper(helperName:String) {
			super(helperName);
		}

		
		public function onCallFault(fault : FaultToken, handler : RemoteHandlerDescription = null) : void {
			CursorManager.setBusyCursor();
			Alert.show("Call to [" + fault.faultCall + "] failed!","Remote call failure");
		}
		
		public function callRemoteForField(remote : String, remoteField : String, view : UIComponent, fieldName : String, propertyName : String, ... args) : void {
			var onResultFunction : Function =
				function(result : Object, handler : RemoteHandlerDescription = null) : void {
					view[fieldName][propertyName] = ObjectsUtility.getObjectFieldValue(result,remoteField);
					CursorManager.removeAllCursors();
				}
			CursorManager.setBusyCursor();
			DistantCaller(controller.getRemoteObjectsCallers()[remote]).addHandler(this,onResultFunction, this.onCallFault);
			DistantCaller(controller.getRemoteObjectsCallers()[remote]).call(args);
		}
	}
}