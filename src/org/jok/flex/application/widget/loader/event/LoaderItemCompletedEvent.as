package org.jok.flex.application.widget.loader.event
{
	import flash.events.Event;
	import org.jok.flex.application.helper.AbstractHelper;
	
	public class LoaderItemCompletedEvent extends Event {
		
		public static var LOADER_ITEM_COMPLETED : String = "LOADER_ITEM_COMPLETED";
		public static var LOADER_SUB_ITEM_COMPLETED : String = "LOADER_SUB_ITEM_COMPLETED";
		public static var LAZY_LOADER_SUB_ITEM_COMPLETED : String = "LAZY_LOADER_SUB_ITEM_COMPLETED";
		public static var LAZY_LOADER_ITEM_COMPLETED : String = "LAZY_LOADER_ITEM_COMPLETED";
		public static var LOADER_CANCEL_CALLED : String = "LOADER_CANCEL_CALLED";
		
		public var helper : AbstractHelper;
		
		public function LoaderItemCompletedEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}
	}
}