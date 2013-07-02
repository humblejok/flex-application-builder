package org.jok.flex.application.model
{
	[Bindable]
	public class StaticItem extends Object {
		
		public var label : String;
		public var value : Object;
		public var selected : Boolean;
		
		public function StaticItem() {
			super();
		}
		
		
		public static function findStaticItemByValue(list : Array, value : Object) : StaticItem {
			for each (var si : StaticItem in list) {
				if (si.value==value.toString()) {
					return si;
				}
			}
			return null;
		}
		
		public static function findStaticItemByLabel(list : Array, label : Object) : StaticItem {
			for each (var si : StaticItem in list) {
				if (si.label==label) {
					return si;
				}
			}
			return null;			
		}
	}
}