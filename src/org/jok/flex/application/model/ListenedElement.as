package org.jok.flex.application.model
{
	import mx.collections.ArrayCollection;

	/**
	 * Model that describes listened element action to perform or fields to modify.
	 *   
	 * @author sdj
	 * 
	 */
	public class ListenedElement {
		// TODO Enhance comments
		public var sourceId : String;
		public var elementId : String;
		public var fieldChain : String;
		public var targetId : String;
		
		public var operatingFunction : Function;
		
		public function ListenedElement() {
		}
	}
}