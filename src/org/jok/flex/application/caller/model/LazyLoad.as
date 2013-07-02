package org.jok.flex.application.caller.model {
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.controls.Alert;
	import mx.events.CollectionEvent;
	
	import org.jok.flex.application.caller.DistantCaller;
	import org.jok.flex.application.controller.ApplicationController;
	import org.jok.flex.application.helper.AbstractHelper;
	import org.jok.flex.application.model.FaultToken;
	import org.jok.flex.application.model.RemoteHandlerDescription;
	import org.jok.flex.application.widget.loader.event.LoaderItemCompletedEvent;
	import org.jok.flex.utility.ObjectsUtility;

	
	/**
	 * This class is a quick and dirty implementation of a lazy load feature.<BR/>
	 * It should be using Event instead of weird style recursivity.<BR/>
	 * This class implementation should be changed.<BR/>
	 */
	public class LazyLoad extends EventDispatcher {
		
		private var _target : Object = null;
		private var workingSet : ArrayCollection = new ArrayCollection();
		
		public var lazyFieldRoot : String;
		public var lazyField : String;
		public var remote : String;
		public var remoteArgumentLazyField : String;
		
		private var controller : ApplicationController = ApplicationController.getInstance();
		
		public var done : Number = 0;
		public var todos : Number = 0;
		
		public var subDone : Number = 0;
		public var subTodos : Number = 0;
		
		/**
		 * Constructor
		 * @param lazyFieldRoot The root field containing the target object
		 * @param lazyField The effective field withing target object
		 * @paran remote The
		 */
		public function LazyLoad(lazyFieldRoot : String,lazyField : String,remote : String, remoteArgumentLazyField : String) {
			this.lazyFieldRoot = lazyFieldRoot;
			this.lazyField = lazyField;
			this.remote = remote;
			this.remoteArgumentLazyField = remoteArgumentLazyField;
		}
		
		/**
		 * Assign the target container
		 * @param value The target container
		 */
		public function set target(value : Object) : void {
			
			_target = value;
			workingSet = new ArrayCollection();
			if (value is ArrayCollection || value is Array) {
				workingSet.addAll(IList(value));
			} else {
				workingSet.addItem(value);
			}
			
			this.done = 0;
			this.todos = workingSet.length;
			if (this.todos!=this.done) {
				var workingObject : Object = workingSet.getItemAt(0);
				var laziesSet : ArrayCollection = new ArrayCollection();
				var lazyObject : Object = ObjectsUtility.getObjectFieldValue(workingObject,lazyFieldRoot);
				if (lazyObject is ArrayCollection || lazyObject is Array) {
					laziesSet.addAll(IList(lazyObject));
				} else {
					laziesSet.addItem(lazyObject);
				}
				
				this.subTodos = laziesSet.length;
				this.subDone = 0;
				if (this.subDone!=this.subTodos) {
					this.workOnLazyItem(laziesSet);
				}
			}
		}
		/**
		 * Given a collection of lazy fields, it retrieves their real values
		 * @param laziesSet The collection of lazy data
		 */
		public function workOnLazyItem(laziesSet : ArrayCollection) : void {
			var lazyLoader : LazyLoad = this;
			
			var resultFunction : Function = 
				function(result : Object, handler : RemoteHandlerDescription = null) : void {
					laziesSet.getItemAt(lazyLoader.subDone)[lazyField] = result;
					
					if (_target is ArrayCollection) {
						ArrayCollection(_target).dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE));
					}
					lazyLoader.subTodos = laziesSet.length;
					lazyLoader.subDone = lazyLoader.subDone + 1;
					if (lazyLoader.subDone==lazyLoader.subTodos) {
						dispatchLoaderEvent(LoaderItemCompletedEvent.LAZY_LOADER_ITEM_COMPLETED);
						lazyLoader.subDone = 0;
						lazyLoader.subTodos = 0;
						lazyLoader.done = lazyLoader.done + 1;
						if (lazyLoader.done<lazyLoader.todos) {
							var nextLaziesSet : ArrayCollection = ArrayCollection(ObjectsUtility.getObjectFieldValue(workingSet.getItemAt(lazyLoader.done),lazyFieldRoot));
							lazyLoader.subTodos = nextLaziesSet.length;
							lazyLoader.workOnLazyItem(nextLaziesSet);
						}
					} else {
						var argumentValue : Object = ObjectsUtility.getObjectFieldValue(laziesSet.getItemAt(lazyLoader.subDone),remoteArgumentLazyField);
						DistantCaller(controller.getRemoteObjectsCallers()[remote]).call( new Array().concat(argumentValue) , true);
					}
					
					dispatchLoaderEvent(LoaderItemCompletedEvent.LAZY_LOADER_SUB_ITEM_COMPLETED);
				}
			var faultFunction : Function = 
				function(fault : FaultToken, handler : RemoteHandlerDescription = null) : void {
					lazyLoader.subDone = lazyLoader.subDone + 1;
					dispatchLoaderEvent(LoaderItemCompletedEvent.LAZY_LOADER_SUB_ITEM_COMPLETED);
				}
			
			if (lazyLoader.subDone!=lazyLoader.subTodos) {
				var argumentValue : Object = ObjectsUtility.getObjectFieldValue(laziesSet.getItemAt(0),remoteArgumentLazyField);
				DistantCaller(controller.getRemoteObjectsCallers()[remote]).handlers.removeAll();
				DistantCaller(controller.getRemoteObjectsCallers()[remote]).addHandler(null,resultFunction,faultFunction,null);
				DistantCaller(controller.getRemoteObjectsCallers()[remote]).call( new Array().concat(argumentValue) , true);
			}
		}
		
		/**
		 * The event dispatcher
		 * @param eventType The event type
		 */
		public function dispatchLoaderEvent(eventType : String) : void {
			// Dispatching event
			var event : LoaderItemCompletedEvent = new LoaderItemCompletedEvent(eventType);
			this.dispatchEvent(event);
		}
	}
}