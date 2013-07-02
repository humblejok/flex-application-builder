package org.jok.flex.application.widget.datagrid.split
{
import mx.controls.dataGridClasses.DataGridColumn;

public class SplitDataGridColumn extends DataGridColumn
{

	public function SplitDataGridColumn()
	{
		super();
	}
	

	private var _childrenColumns:Array;
	
	
	public function get numberOfChildren():int
	{
		return _childrenColumns.length;	
	}
	
	/**
	 *  A DataGridColumn that access a column at given index
	 */
	[Inspectable(arrayType="SplitDataGridChildColumn")]	 
	public function get childrenColumns():Array
	{
		return _childrenColumns;
	}
	
	/**
	 *  @private
	 */
	public function set childrenColumns(cols:Array):void
	{
		_childrenColumns = cols;
		
		for (var i:int = 0 ; i < cols.length; i++)
		{
			_childrenColumns[i].parentColumn = this;
		}
	}	

}

}