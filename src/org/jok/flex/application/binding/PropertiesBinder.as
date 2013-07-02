package org.jok.flex.application.binding
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import mx.events.PropertyChangeEvent;
	
	[Bindable(event="propertyChange")]
	/**
	 * Utility class that allows to enable binding on dynamic objects. It extends the Proxy class and implements IEventDispatcher.<BR/>
	 * The behavior is currently like the ObjectProxy class.<BR/>
	 *  
	 * @author sdj
	 * 
	 */
	public dynamic class PropertiesBinder extends Proxy implements IEventDispatcher {
		
		/**
		 * The event dispatcher
		 */
		private var eventDispatcher:EventDispatcher;
		/**
		 * The binded object instance 
		 */
		private var data : Object;
		
		/**
		 * Contructor that needs the binded object instance.
		 * 
		 * @param sourceData
		 * 
		 */
		public function PropertiesBinder(sourceData : Object) {
			super();
			eventDispatcher = new EventDispatcher();
			data = sourceData;
		}
		
		// IEventDispatcher implementation
		
		/**
		 * Allows to add an event listener, please refer to the IEventDispatcher ASDOC.
		 * 
		 * @param type
		 * @param listener
		 * @param useCapture
		 * @param priority
		 * @param useWeakReference
		 * 
		 */
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void {
			eventDispatcher.addEventListener( type, listener, useCapture,priority, useWeakReference );
		}
		
		/**
		 * Allows to remove an event listener, please refer to the IEventDispatcher ASDOC.
		 * @param type
		 * @param listener
		 * @param useCapture
		 * 
		 */
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void {
			eventDispatcher.removeEventListener( type, listener, useCapture );
		}
		
		/**
		 * Dispatch an event, please refer to the IEventDispatcher ASDOC.
		 * 
		 * @param event
		 * @return 
		 * 
		 */
		public function dispatchEvent(event:Event):Boolean {
			return eventDispatcher.dispatchEvent( event );

		}
		
		/**
		 * Indicates if there is at least one listener, please refer to the IEventDispatcher ASDOC.
		 * @param type
		 * @return 
		 * 
		 */
		public function hasEventListener(type:String):Boolean {
			return eventDispatcher.hasEventListener( type );

		}
		
		/**
		 * Indicates if the given event is listened to, please refer to the IEventDispatcher ASDOC.
		 * 
		 * @param type
		 * @return 
		 * 
		 */
		public function willTrigger(type:String):Boolean {
			return eventDispatcher.willTrigger( type );
		}
		
		// Proxy overriden methods (done on purpose but maybe using ObjectProxy would have been enough)
		
		/**
		 * Utility method that allows to get the value of the given property, please refer to the Proxy ASDOC.
		 * 
		 * @param name Property name
		 * @return Property value
		 * 
		 */
		override flash_proxy function getProperty( name:* ):* {
			if( data == null ) {
				return null;
			}
			return data[name];
		}

		/**
		 * Utility metod that allows to set the value of a given property, please refer to the Proxy ASDOC.
		 * @param name Property name
		 * @param value Property value
		 * 
		 */
		override flash_proxy function setProperty( name:*, value:* ):void {
			var previousValue : Object = data[name];
			var event : Event;
			data[name] = value;
			event = PropertyChangeEvent.createUpdateEvent( this, name, previousValue, value );
			dispatchEvent( event );
		}

		
	}
}