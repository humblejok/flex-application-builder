package org.jok.flex.application.interfaces
{
	import flash.display.LoaderInfo;

	public interface IResourceProvider {
		/**
		 * Add the given loaded info to this object instance
		 * @param The new resource id
		 * @param The loader information
		 */
		function addResource(resourceId : String, info : Object) : void;
		
		/**
		 * Returns the resource
		 * @param The resource id
		 */
		function getResource(resourceId : String) : Object;
	}
}