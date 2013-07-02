package org.jok.flex.application.interfaces
{
	import mx.core.UIComponent;

	public interface IFormViewHelper {
		
		function callRemoteForField(remote : String, remoteField : String, view : UIComponent, fieldName : String, propertyName : String, ... args) : void;
		
	}
}