package org.jok.flex.application.helper
{
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.getDefinitionByName;
	
	import org.jok.flex.application.interfaces.IResourceProvider;
	import org.jok.flex.application.model.FaultToken;
	import org.jok.flex.application.model.RemoteHandlerDescription;
	import org.jok.flex.application.widget.loader.event.LoaderItemCompletedEvent;
	import org.jok.flex.utility.ObjectsUtility;

	[Bindable]
	/**
	 * A helper dedicated to cache objects population. <BR/>
	 * 
	 * @author sdj
	 * 
	 */
	[Event(name="LOADER_ITEM_COMPLETED", type="org.jok.flex.application.widget.loader.event.LoaderItemCompletedEvent")]
	[Event(name="LOADER_SUB_ITEM_COMPLETED", type="org.jok.flex.application.widget.loader.event.LoaderItemCompletedEvent")]
	public class CacheHelper extends AbstractHelper
	{
		
		public var label : String;
		public var remote : String;
		public var field : String;
		
		public var source : String;
		public var sourceField : String;
		public var append : Boolean = false;
		
		public var resource : String;
		public var resourceId : String;
		public var resourceTarget : String;
		
		public var target : String;
		
		public var type : String;
				
		public var userDependent : Boolean = false;
		
		/**
		 * Constructor. 
		 * @param helperName The helper id
		 * 
		 */
		public function CacheHelper(helperName:String) {
			super(helperName);
		}
 
		public function loadResource(url : String, resourceId : String, target : IResourceProvider) : void {
			var f : Function = function(event : Event ) : void {
				target.addResource(resourceId,event.target);
				this.done = this.done + 1;
				if (this.done<this.todo) {
					dispatchLoaderEvent(LoaderItemCompletedEvent.LOADER_SUB_ITEM_COMPLETED);
				} else {
					dispatchEvent(new Event("CacheLoadedEvent"));
				}
			}
			var loader : URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			var request : URLRequest = new URLRequest(url);
			loader.addEventListener(Event.COMPLETE,f);
			loader.load(request);
		}
		
		/**
		 * Default handler for a cache response. 
		 * @param result The content of the result
		 * @param handler The handler, no use here
		 * 
		 */
		public function handleCacheResponse(result : Object, handler : RemoteHandlerDescription = null) : void {
			if (append) {
				if (controller.caches[label]==null) {
					controller.caches[label] = new Array();
				}
				(controller.caches[label] as Array).push(ObjectsUtility.getObjectFieldValue(result,field));
				this.done++;
				if (this.done<this.todo) {
					dispatchLoaderEvent(LoaderItemCompletedEvent.LOADER_SUB_ITEM_COMPLETED);
				} else {
					dispatchEvent(new Event("CacheLoadedEvent"));
				}
			} else {
				this.done = this.todo;
				controller.caches[label] = ObjectsUtility.getObjectFieldValue(result,field);
				dispatchEvent(new Event("CacheLoadedEvent"));
				dispatchLoaderEvent(LoaderItemCompletedEvent.LOADER_ITEM_COMPLETED);
			}
		}
		
		/**
		 * Default handler for a cache error. 
		 * @param fault The fault object
		 * @param handler The handler, no use here
		 * 
		 */
		public function handleCacheFault(fault : FaultToken, handler : RemoteHandlerDescription = null) : void {
			if (append) {
				dispatchLoaderEvent(LoaderItemCompletedEvent.LOADER_SUB_ITEM_COMPLETED);
			} else {
				controller.caches[label] = new Array();
				dispatchEvent(new Event("CacheLoadedEvent"));
				dispatchLoaderEvent(LoaderItemCompletedEvent.LOADER_ITEM_COMPLETED);
			}
		}
	}
	
}