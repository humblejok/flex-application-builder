package org.jok.flex.application.interfaces
{
	import mx.collections.ArrayCollection;

	/**
	 * Interface that defines what is required to listen to the dynamic selector.
	 *  
	 * @author sdj
	 * 
	 */
	public interface DynamicSelectorDataChangeListener {
		
		/**
		 * Called on the listener when the source selector send a "data change event". 
		 * @param sourceId The name of the modified source
		 * @param newData The modified data (not yet implemented, may not be of any use)
		 * 
		 */
		function dataHasChanged(sourceId : String,newData : Array, filter : ArrayCollection = null) : void;
		
	}
}