package org.jok.flex.application.provider
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	
	import org.jok.flex.utility.ObjectsUtility;

	[Bindable]
	public dynamic class IconsProvider {
		
		private static var instance : IconsProvider = null;
		
		public function IconsProvider() {
		}
		
		public static function getInstance() : IconsProvider {
			if (instance==null) {
				instance = new IconsProvider();
			}
			return instance;
		} 
		
		public static function getIconField(label : String, size : Number) : String {
			return label.replace(" ","_") + "_" + size;
		}
		
		public function loadAndAddIcon(object : Object, labelField : String, pathField : String = "icon", size : Number = 16) : void {
			var loader : Loader = new Loader();
			var iconField : String = IconsProvider.getIconField(ObjectsUtility.getObjectFieldValue(object,labelField).toString(), size);
			var doneFunction : Function = function(event : Event) : void {
				instance[iconField] = event.currentTarget.content;
			}
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,doneFunction);
			loader.load(new URLRequest(ObjectsUtility.getObjectFieldValue(object,pathField).toString()));
		}
		
		public function getIcon(label : String, size : Number) : Bitmap {
			var iconField : String = IconsProvider.getIconField(label, size);
			return this[iconField];
		}
		
	}
}