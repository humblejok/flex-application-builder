package org.jok.flex.application.helper
{
	import mx.collections.ArrayCollection;
	
	import org.jok.flex.application.interfaces.DynamicSelectorDataChangeListener;

	public class AbstractSelectionHelper extends AbstractHelper {
		
		protected var listeners : ArrayCollection = new ArrayCollection();
		
		public function AbstractSelectionHelper(helperName:String) {
			super(helperName);
		}
		
		public function addDynamicSelecterDataChangeListener( listener : DynamicSelectorDataChangeListener) : void {
			if (!listeners.contains(listener)) {
				listeners.addItem(listener);
			}
		}
		
	}
}