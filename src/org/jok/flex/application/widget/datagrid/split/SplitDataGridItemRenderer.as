package org.jok.flex.application.widget.datagrid.split
{
import flash.display.DisplayObject;
import mx.core.UIComponent;
import mx.core.UITextField;
import mx.controls.DataGrid;
import mx.controls.listClasses.BaseListData;
import mx.controls.listClasses.IListItemRenderer;
import mx.controls.listClasses.IDropInListItemRenderer;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.controls.dataGridClasses.DataGridItemRenderer;
import mx.controls.dataGridClasses.DataGridListData;

public class SplitDataGridItemRenderer extends UIComponent implements IListItemRenderer, IDropInListItemRenderer
{
	public function SplitDataGridItemRenderer()
	{
	}

    //----------------------------------
    //  data
    //----------------------------------

    /**
     *  @private
     *  Storage for the data property.
     */
    private var _data:Object;

    [Bindable("dataChange")]
    [Inspectable(environment="none")]

    /**
     *  Lets you pass a value to the component
     *  when you use it in an item renderer or item editor.
     *  You typically use data binding to bind a field of the <code>data</code>
     *  property to a property of this component.
     *
     *  <p>When you use the control as a drop-in item renderer or drop-in
     *  item editor, Flex automatically writes the current value of the item
     *  to the <code>text</code> property of this control.</p>
     *
     *  <p>You do not set this property in MXML.</p>
     *
     *  @default null
     *  @see mx.core.IDataRenderer
     */
    public function get data():Object
    {
        return _data;
    }

    /**
     *  @private
     */
    public function set data(value:Object):void
    {
        _data = value;

		invalidateProperties();
    }

    //----------------------------------
    //  listData
    //----------------------------------

    /**
     *  @private
     *  Storage for the listData property.
     */
    private var _listData:BaseListData;

    [Bindable("dataChange")]
    [Inspectable(environment="none")]

    /**
     *  When a component is used as a drop-in item renderer or drop-in
     *  item editor, Flex initializes the <code>listData</code> property
     *  of the component with the appropriate data from the List control.
     *  The component can then use the <code>listData</code> property
     *  to initialize the <code>data</code> property of the drop-in
     *  item renderer or drop-in item editor.
     *
     *  <p>You do not set this property in MXML or ActionScript;
     *  Flex sets it when the component is used as a drop-in item renderer
     *  or drop-in item editor.</p>
     *
     *  @default null
     *  @see mx.controls.listClasses.IDropInListItemRenderer
     */
    public function get listData():BaseListData
    {
        return _listData;
    }

    /**
     *  @private
     */
    public function set listData(value:BaseListData):void
    {
        _listData = value;
    }

	private var childrenRenderer:Array;
//	private var leftRenderer:IListItemRenderer;
//	private var rightRenderer:IListItemRenderer;

	private var childrenListData:Array;
//	private var leftListData:DataGridListData;
//	private var rightListData:DataGridListData;

	private var childrenColumn:Array;
//	private var leftColumn:SplitDataGridChildColumn;
//	private var rightColumn:SplitDataGridChildColumn;

	private var dataGrid:DataGrid;

	override protected function commitProperties():void
	{
		super.commitProperties();

		var dgListData:DataGridListData = listData as DataGridListData;
		dataGrid = dgListData.owner as DataGrid;
		var column:SplitDataGridColumn = dataGrid.columns[dgListData.columnIndex];
		
		childrenColumn = column.childrenColumns;
		for (var i:int = 0; i < childrenColumn.length; i++)
		{
			var childColumn:SplitDataGridChildColumn = childrenColumn[i];
			
			var childRenderer:IListItemRenderer = null;			
			if (childrenRenderer != null)
			{
				childRenderer = childrenRenderer[i];
			} else 
			{
				childrenRenderer = new Array(childrenColumn.length);
			}
			
		
			if (!listData)
			{
				if (childRenderer)
					childRenderer.visible = false;
			}

	
			if (!childRenderer)
			{
				childRenderer = (childColumn.headerRenderer != null) ? 
									childColumn.itemRenderer.newInstance() : 
									new DataGridItemRenderer();
				childRenderer.styleName = childColumn;
				addChild(DisplayObject(childRenderer));
				
				childrenRenderer[i] = childRenderer;
				
			}
	
			
			var childListData:DataGridListData = new DataGridListData(childColumn.itemToLabel(data),
													childColumn.dataField, listData.columnIndex, 
													listData.uid, listData.owner, listData.rowIndex);
	
			if (childRenderer is IDropInListItemRenderer)
				IDropInListItemRenderer(childRenderer).listData = childListData;
			childRenderer.data = data[column.dataField];
	
			childRenderer.explicitWidth = childColumn.width;
		}
	}

	override protected function measure():void
	{
		measuredHeight = childrenRenderer[0].getExplicitOrMeasuredHeight();
		for (var i:int = 1 ; i < childrenRenderer.length; i++)
		{
			if (measuredHeight < childrenRenderer[i].getExplicitOrMeasuredHeight())
			{
				measuredHeight = childrenRenderer[i].getExplicitOrMeasuredHeight();
			}
		}

	}

	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		
		var leftPos:int = 0;
		for (var i:int = 0 ; i < childrenColumn.length; i++)
		{
			var childRenderer:IListItemRenderer = childrenRenderer[i];
			var childColumn:SplitDataGridChildColumn = childrenColumn[i];
			
			childRenderer.setActualSize(childColumn.width, unscaledHeight);
			childRenderer.x = leftPos;
			
			leftPos += childColumn.width; 			
		}
		
		graphics.clear();
		//trace("draw cell seps");
		// draw cell separators
		var sepPos:int = childrenColumn[0].width;		
		for (i = 1 ; i < childrenColumn.length; i++)
		{	
	        var lineCol:uint = dataGrid.getStyle("verticalGridLineColor");
	        if (dataGrid.getStyle("verticalGridLines"))
			{
				graphics.lineStyle(1, lineCol);
				
				//trace(sepPos + " : " + unscaledHeight);
				
				graphics.moveTo(sepPos, 0);
				graphics.lineTo(sepPos, unscaledHeight);
			}
			
			sepPos += childrenColumn[i].width;
		}	
		
	}

}

}