package org.jok.flex.application.widget.datagrid.split
{
import mx.controls.dataGridClasses.DataGridColumn;

// gotta do a little cheating here.  Maybe we'll fix this
// someday in which case we'll have to tweak this example
import mx.core.mx_internal;
use namespace mx_internal;

public class SplitDataGridChildColumn extends DataGridColumn
{

	public function SplitDataGridChildColumn()
	{
		super();
	}

	/**
	 *  A SplitDataGridColumn that contains this child
	 */
	public var parentColumn:SplitDataGridColumn;

	/**
	 *  @private
	 *  this is called early and we use it to set the owner property
	 */
    override public function itemToLabel(data:Object):String
	{
		owner = parentColumn.owner;
		return super.itemToLabel(data);
	}

	/**
	 *  @private
	 *  we turn off the owner property when sized so it 
	 *  doesn't run the column resize logic in the DataGrid
	 */
    override public function set width(value:Number):void
	{
		owner = null;
		super.width = value;
		owner = (parentColumn) ? parentColumn.owner : null;
	}

}


}