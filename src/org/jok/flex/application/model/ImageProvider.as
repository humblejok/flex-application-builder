package org.jok.flex.application.model
{
	import flash.display.LoaderInfo;
	
	import mx.controls.Image;
	
	import org.jok.flex.application.interfaces.IResourceProvider;

	[Bindable]
	public dynamic class ImageProvider implements IResourceProvider {
		
		private static var instance : ImageProvider = null;
		
		/**
		 * Private constructor for SINGLETON, do not use
		 */
		public function ImageProvider() {
		}
		
		
		/**
		 * Get the singleton
		 */
		public static function getInstance() : ImageProvider {
			if (instance==null) {
				instance = new ImageProvider();
			}
			return instance;
		}
		
		/**
		 * Add the given loaded info to this object instance
		 * @param The new resource id
		 * @param The loader information
		 */
		public function addResource(resourceId : String, info : Object) : void {
			this[resourceId] = new Image();
			this[resourceId].data = info.data;
		}
		
		/**
		 * Returns the resource
		 * @param The resource id
		 */
		public function getResource(resourceId : String) : Object {
			if (this.hasOwnProperty(resourceId)) {
				return this[resourceId].source;
			}
			return null;
		}
	}
}