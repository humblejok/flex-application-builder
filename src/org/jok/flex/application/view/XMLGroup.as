package org.jok.flex.application.view
{
	import flash.utils.getDefinitionByName;
	
	import mx.containers.ApplicationControlBar;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.rpc.events.AbstractEvent;
	
	import org.jok.flex.application.controller.ApplicationController;
	import org.jok.flex.application.helper.AbstractHelper;
	import org.jok.flex.application.helper.DataSelectionDependingViewHelper;
	
	import spark.components.Group;
	
	[Bindable]
	/**
	 * Flex Group that can be populated with XML data. 
	 * @author sdj
	 * 
	 */
	public dynamic class XMLGroup extends Group {
		
		public var helper : AbstractHelper;
		
		public var controller : ApplicationController = ApplicationController.getInstance();
		
		public function XMLGroup() {
			super();
		}
		
		/**
		 * Populate with XML data 
		 * @param content The XML content
		 * 
		 */
		public function populateWithXML(content : XML) : void {
			helper = getHelperFromXML(content);
			helper.populateWithXML(content,this);
		}
		
		/**
		 * Get an instance of the dedicated helper 
		 * @param content
		 * @return 
		 * 
		 */
		public function getHelperFromXML(content : XML) : AbstractHelper {
			var helperClassName : String = String(content.@helper);
			var helper : AbstractHelper;
			var helperClass : Class = getDefinitionByName(helperClassName) as Class;
			helper = new helperClass(content.@id);
			return helper; 
		}
		
		public function displayChoicePopUp(title : String, text : String, icon : Class, onAcceptFunction : Function, onRejectFunction : Function, acceptLabel : String = "Ok", rejectLabel : String = "Cancel") : void {
			Alert.okLabel = acceptLabel;
			Alert.cancelLabel = rejectLabel;
			
			var handleChoicePopUpClose : Function = function e(event : CloseEvent) : void {
				switch (event.detail){
					case Alert.CANCEL:
						onRejectFunction.call(this, event);
						break;
					case Alert.OK:
						onAcceptFunction.call(this, event);
						break;
				}
				
			}
			
			Alert.show(text, title, Alert.OK |  Alert.CANCEL, this, handleChoicePopUpClose, icon);
		}
	}
}