package org.jok.flex.application.helper
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getDefinitionByName;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.FlexEvent;
	import mx.managers.CursorManager;
	import mx.utils.ObjectUtil;
	
	import org.jok.flex.application.binding.PropertiesBinder;
	import org.jok.flex.application.caller.DistantCaller;
	import org.jok.flex.application.controller.ApplicationController;
	import org.jok.flex.application.model.ListenedElement;
	import org.jok.flex.application.view.XMLGroup;
	import org.jok.flex.application.widget.loader.LoaderStatusDataGridItemRenderer;
	import org.jok.flex.application.widget.loader.event.LoaderItemCompletedEvent;
	import org.jok.flex.utility.ObjectsUtility;
	
	[Bindable]
	/**
	 * The basic view helper that will "help" a view or an object to interact with the controller and that contains the value objects (Controller of the MVC pattern).<BR/> 
	 * <BR/>
	 * This class is an abstract one and should not be used directly. 
	 * @author sdj
	 * 
	 */
	public dynamic class AbstractHelper extends EventDispatcher {
		
		/**
		 * Application controller instance
		 */
		protected var controller : ApplicationController = ApplicationController.getInstance();
		
		/**
		 * The list of local elements.
		 */
		protected var localElements : Array = new Array();
		
		/**
		 * The id of the associated view
		 */
		protected var associatedViewId : String;
		
		public var viewAdministrator : Boolean = true;
		
		// NOT YET IMPLEMENTED
		//public var functionsRepository : Array = new Array();
		
		public var HELPER_NAME : String = "AbstractHelper";
		
		// Loading interaction
		
		/**
		 * The item loading/loader renderer
		 */
		public var loaderRenderer : LoaderStatusDataGridItemRenderer = null;
		
		/**
		 * The description
		 */
		public var description : String;
		
		public var todo : Number = 1;
		
		public var done : Number = 0;
		
		
		// NOT YET IMPLEMENTED
		//public var initialized : Boolean = false;
		
		// TEMPLATES
		public var templates : Array;
		
		/**
		 * Contructor. 
		 * @param helperName Id that helps identification
		 * 
		 */
		public function AbstractHelper(helperName : String) {
			super();
			HELPER_NAME = helperName;
			controller.registerViewHelper(this);
		}
		
		
		/**
		 * Default method that handles the population of a view.<BR/>
		 * It can create GUI object or DataProviders. It will initialize listeners and bindings on certain kinds of objects or data sources.
		 * 
		 * @param content The content of the view
		 * @param caller The view itself
		 * 
		 */
		public function populateWithXML(content : XML, caller : XMLGroup) : void {
			this.associatedViewId = content.@id;
			if (String(content.@admin)!=null && String(content.@admin)!="") {
				viewAdministrator = controller.isCurrentUserMemberOf(content.@admin);
			} 
			
			var f : Function = function(event : Event) : void {
				for each (var element : XML in content.element) {
					if (String(element.@viewBinding)!=null && String(element.@viewBinding)!="false") {
						BindingUtils.bindProperty(event.target,String(element.@id),event.target.helper[String(element.@id)],"value");
					}
				}
			}
			caller.addEventListener(FlexEvent.CREATION_COMPLETE,f);
			this.createLocalValues(content);
		}
		
		/** 
		 * Default method that creates the local values within the view helper
		 * 
		 * @param content The content of the view
		 */
		protected function createLocalValues(content : XML) : void {
			for each (var element : XML in content.element) {
				for each (var elementArgument : XML in element.argument) {
					if (elementArgument.@source=="local-element") {
						localElements.push(elementArgument.@sourceName + "." + elementArgument.@sourceFields);
						this[elementArgument.@sourceName] = null;
					}
				}
			}
		}
		
		/** 
		 * Method that maps the information from the view in this helper
		 * 
		 * @param view The view
		 */
		public function mapLocalValue(view : XMLGroup) : void {
			for each (var le : String in localElements) {
				var dotPosition : Number = le.indexOf(".");
				var viewProperty : String = le.substr(0,dotPosition);
				var viewPropertyField : String = le.substr(dotPosition + 1);
				this[viewProperty] = ObjectsUtility.getObjectFieldValue(view[viewProperty],viewPropertyField);
			}
		}
		
		/**
		 * Retrieves a value from the cache of the controller
		 * 
		 * @param cacheId The id of the cache entry
		 */
		public function getCacheValue(cacheId : String ) : Object {
			return controller.caches[cacheId];
		}
		
		/**
		 * Retrieves the list from controller's static entries
		 * 
		 * @param listId The id of the list entry
		 * 
		 */
		public function getStaticListValue(listId : String ) : IList {
			return new ArrayCollection(controller.staticLists[listId]);
		}
		
		/**
		 * Retrieves the list from controller's static entries
		 * 
		 * @param id The id of the entry 
		 */
		public function getStaticValue(id : String ) : Object {
			return controller.staticValues[id];
		}
		
		/**
		 * Abstract method, unused yet...Allows the modification of an element given its id
		 * 
		 * @param elementId The id of the element
		 */
		public function populateElement(elementId : String) : void {
			
		}
		
		public function callRemote(targetRemote : String, destinationId : String, resultFunction : Function, faultFunction : Function, ... args) : void {
			var callArguments : Array = args as Array;
			CursorManager.setBusyCursor();
			DistantCaller(controller.getRemoteObjectsCallers()[targetRemote]).addHandler(this,resultFunction,faultFunction,destinationId);
			DistantCaller(controller.getRemoteObjectsCallers()[targetRemote]).call(callArguments);
		}
		
		public function callDjangoRemote(targetRemote : String, destinationId : String, resultFunction : Function, faultFunction : Function, csrf : String, ... args) : void {
			var callArguments : Array = args as Array;
			CursorManager.setBusyCursor();
			DistantCaller(controller.getRemoteObjectsCallers()[targetRemote]).addHandler(this,resultFunction,faultFunction,destinationId);
			DistantCaller(controller.getRemoteObjectsCallers()[targetRemote]).call(callArguments, false, csrf);
		}
		
		public function callRemoteEnqueue(targetRemote : String, destinationId : String, resultFunction : Function, faultFunction : Function, ... args) : void {
			var callArguments : Array = args as Array;
			CursorManager.setBusyCursor();
			DistantCaller(controller.getRemoteObjectsCallers()[targetRemote]).addHandler(this,resultFunction,faultFunction,destinationId);
			DistantCaller(controller.getRemoteObjectsCallers()[targetRemote]).call(callArguments,true);
		}
		
		protected function dispatchLoaderEvent(eventType : String) : void {
			// Dispatching event
			var event : LoaderItemCompletedEvent = new LoaderItemCompletedEvent(eventType);
			event.helper = this;
			this.dispatchEvent(event);
			// Calling renderer
			if (loaderRenderer!=null) {
				loaderRenderer.handleLoaderItemEvent(event);
			}
		}
		
		/**
		 * Utility method that computes given xmlArguments as an array of objects values.
		 * @param selectorId The id of the selecting view/helper
		 * @param dpId The id of the data provide (not implemented yet)
		 * @param xmlArguments The arguments as XML list
		 * @return The array of objects values
		 * 
		 */
		public function computeArgumentsAsArray(selectorId : String,dpId : String,xmlArguments : XMLList, target : Array) : Array {
			if (xmlArguments!=null) {
				for each (var argument : XML in xmlArguments) {
					var transformerClassName : String = null;
					var transformerFunctionName : String = null;
					var argumentValue : Object = null;
					var transformerInstance : Object = null;
					var transformerClass : Class = null;
					
					if (argument.@source=="element" || argument.@source=="local-element") {
						var workingHelper : AbstractHelper = this;
						if (argument.@source=="element") {
							workingHelper = controller.views[selectorId].helper;
						}
						transformerClassName = argument.@tranformerClass;
						transformerFunctionName = argument.@transformerFunction;
						argumentValue = ObjectsUtility.getObjectFieldValue(workingHelper[String(argument.@sourceName)],String(argument.@sourceFields)); 
						if (transformerFunctionName!=null && transformerFunctionName!="") {
							transformerInstance = this;
							if (transformerClassName!=null && transformerClassName!="") {
								transformerClass = getDefinitionByName(transformerClassName) as Class;
								transformerInstance = new transformerClass();
							}
							argumentValue = transformerInstance[transformerFunctionName](argumentValue);
						} else if (transformerClassName!=null && transformerClassName!="") {
							transformerClass = getDefinitionByName(transformerClassName) as Class;
							argumentValue = new transformerClass(argumentValue);
						}
						target.push(argumentValue);
					} else if (argument.@source=="constant") {
						// TODO Implement type cast
						target.push(String(argument.@value));
					}
				}
			}
			return target;
		}
		
		/**
		 * Get the view instance associated to that helper.
		 * @return The view instance
		 */
		public function myView() : XMLGroup {
			return this.controller.views[this.HELPER_NAME];
		}

		
		public function getCurrentUser() : Object {
			return controller.caches[ApplicationController.CURRENT_USER_PROFILE];
		}
		
	}

}