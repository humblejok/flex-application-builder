package org.jok.flex.application.widget.datagrid
{
	import mx.collections.ArrayCollection;
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.events.CollectionEvent;
	import mx.utils.ArrayUtil;
	import mx.utils.ColorUtil;
	
	[Bindable]
	public class ColumnExtensibleDataGrid extends DataGrid {
		
		private var _extensibleHeaderLabelFunction : Function = null;
		
		private var _extensibleDataLabelFunction : Function = null;
		
		private var _additionalColumnsProvider : ArrayCollection = new ArrayCollection();
		
		private var _additionalColumnsProviderField : String = "";
		
		private var _initialColumns : Array = null;
		
		private var _newColumns : ArrayCollection = null;
		
		private var _updatedColumns : ArrayCollection = null;
		
		public var newColumnBackgroundColor : Number = NaN;
		public var newColumnForegroundColor : Number = NaN;
		
		public var updatedColumnBackgroundColor : Number = NaN;
		public var updatedColumnForegroundColor : Number = NaN;
		
		
		public function ColumnExtensibleDataGrid() {
			super();
		}
		
		public function get newColumns() : ArrayCollection {
			return _newColumns;
		}
		
		public function get updatedColumns() : ArrayCollection {
			return _updatedColumns;
		}
		
		public function set newColumns(colList : ArrayCollection) : void {
			_newColumns = new ArrayCollection(colList.source);
			//onColumnsProviderChange(null);
		}
		
		public function set updatedColumns(colList : ArrayCollection) : void {
			_updatedColumns =  new ArrayCollection(colList.source);
			//onColumnsProviderChange(null);
		}
		
		public function get initialColumns() : Array {
			return _initialColumns;
		}
		
		public function set extensibleDataLabelFunction(f : Function) : void {
			_extensibleDataLabelFunction = f;
			onColumnsProviderChange(null);
		}
		
		public function get extensibleDataLabelFunction() : Function {
			return _extensibleDataLabelFunction;
		}
		
		public function set extensibleHeaderLabelFunction(f : Function) : void {
			_extensibleHeaderLabelFunction = f;
			onColumnsProviderChange(null);
		}
		
		public function get extensibleHeaderLabelFunction() : Function {
			return _extensibleHeaderLabelFunction;
		}
		
		public function set additionalColumnsProviderField(field : String) : void {
			_additionalColumnsProviderField = field;
		}
		
		public function get additionalColumnsProviderField() : String {
			return _additionalColumnsProviderField;
		}
		
		public function set additionalColumnsProvider(provider : ArrayCollection) : void {
			if (_initialColumns==null) {
				this._initialColumns = super.columns.concat();
			}
			if (_additionalColumnsProvider!=null) {
				_additionalColumnsProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onColumnsProviderChange);
			}
			_additionalColumnsProvider = provider;
			_additionalColumnsProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, onColumnsProviderChange);
			onColumnsProviderChange(null);
		}
		
		public function get additionalColumnsProvider() : ArrayCollection {
			return _additionalColumnsProvider;
		}
		
		/**
		 *  @private
		 */
		override public function set dataProvider(value:Object) : void {
			super.dataProvider = value;
	
		}
		
		override public function set columns(value:Array):void {
			super.columns = value;
			if (_initialColumns==null) {
				this._initialColumns = super.columns.concat();
			}
		}
			
		
		private function onColumnsProviderChange(event : CollectionEvent) : void {
			var cols : Array = new Array();
			var index : Number = 0;
			
			if (_initialColumns!=null) {
				cols = this._initialColumns.concat();
			}
				
			for each(var item : Object in _additionalColumnsProvider) {
				var dgColumn : DataGridColumn = new DataGridColumn();
				dgColumn.dataField = "";
				if (_newColumns!=null && _newColumns.contains(index)) {
					if (!isNaN(newColumnBackgroundColor)) {
						dgColumn.setStyle("backgroundColor",newColumnBackgroundColor);
					}
					if (!isNaN(newColumnForegroundColor)) {
						dgColumn.setStyle("color",newColumnForegroundColor);
					}
				} else if (_updatedColumns!=null && _updatedColumns.contains(index)) {
					if (!isNaN(updatedColumnBackgroundColor)) {
						dgColumn.setStyle("backgroundColor",updatedColumnBackgroundColor);
					}
					if (!isNaN(updatedColumnForegroundColor)) {
						dgColumn.setStyle("color",updatedColumnForegroundColor);
					}
				}
				
				if (_extensibleHeaderLabelFunction!=null) {
					dgColumn.headerText = _extensibleHeaderLabelFunction(item, dgColumn);
				} else {
					dgColumn.headerText = item.toString();
				}
				dgColumn.labelFunction = _extensibleDataLabelFunction;
				cols.push(dgColumn);
				index++;
			}
			this.columns = cols;
		}
		
	}
}