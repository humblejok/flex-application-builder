package org.jok.flex.application.widget.datagrid.split
{
	// FROM http://blog.widget-labs.com/2007/09/07/split-column-datagrid/
import flash.display.DisplayObject;
import flash.events.MouseEvent;
import flash.geom.Point;
import mx.core.IFlexDisplayObject;
import mx.core.UIComponent;
import mx.core.UITextField;
import mx.controls.DataGrid;
import mx.controls.listClasses.BaseListData;
import mx.controls.listClasses.IListItemRenderer;
import mx.controls.listClasses.IDropInListItemRenderer;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.controls.dataGridClasses.DataGridItemRenderer;
import mx.controls.dataGridClasses.DataGridListData;
import mx.managers.CursorManager;
import mx.managers.CursorManagerPriority;
import mx.styles.ISimpleStyleClient;

public class SplitDataGridHeader extends UIComponent implements IListItemRenderer, IDropInListItemRenderer
{
	public function SplitDataGridHeader()
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
	//private var leftRenderer:IListItemRenderer;
	//private var rightRenderer:IListItemRenderer;

	
	private var title:DataGridItemRenderer;


	private var childrenListData:Array;
	//private var leftListData:DataGridListData;
	//private var rightListData:DataGridListData;

	private var childrenColumn:Array;
//	private var leftColumn:DataGridColumn;
//	private var rightColumn:DataGridColumn;

	private var dataGrid:DataGrid;

//	private var sep:UIComponent;
	private var seps:Array;
	private var sepSkin:IFlexDisplayObject;
    private var separatorAffordance:Number = 3;

	override protected function createChildren():void
	{
	}

	override protected function commitProperties():void
	{
		super.commitProperties();

		var dgListData:DataGridListData = listData as DataGridListData;
		dataGrid = dgListData.owner as DataGrid;
		var column:SplitDataGridColumn = data as SplitDataGridColumn;
		childrenColumn = column.childrenColumns;
		
		for (var i:int = 0 ; i < childrenColumn.length; i++)
		{
			var childColumn:DataGridColumn = childrenColumn[i];
			
			var childRenderer:IListItemRenderer = null;			
			if (childrenRenderer != null)
			{
				childRenderer = childrenRenderer[i];
			} else 
			{
				childrenRenderer = new Array(childrenColumn.length);
			}
			
			if (!childRenderer)
			{
				childRenderer = (childColumn.headerRenderer != null) ? 
									childColumn.headerRenderer.newInstance() : 
									new DataGridItemRenderer();
				childRenderer.styleName = childColumn;
				addChild(DisplayObject(childRenderer));
				
				childrenRenderer[i] = childRenderer;
			}
			
			var childListData:DataGridListData = new DataGridListData((childColumn.headerText != null) ? childColumn.headerText : childColumn.dataField,
													childColumn.dataField, listData.columnIndex, 
													listData.uid, listData.owner, listData.rowIndex);

	
			if (childRenderer is IDropInListItemRenderer)
				IDropInListItemRenderer(childRenderer).listData = childListData;
			childRenderer.data = childColumn;
	
			childRenderer.explicitWidth = childColumn.width;
		}
		
		if (!title)
		{
			title = new DataGridItemRenderer();
			title.styleName = column;
			addChild(title);
		}

		title.listData = listData;
		title.data = data;

	}

	override protected function measure():void
	{
		measuredHeight = childrenRenderer[0].getExplicitOrMeasuredHeight();
		for (var i:int = 1 ; i < childrenRenderer.length; i++)
		{
			if (measuredHeight <  childrenRenderer[i].getExplicitOrMeasuredHeight())
			{
				measuredHeight = childrenRenderer[i].getExplicitOrMeasuredHeight(); 
			}	
		}
		
		measuredHeight += title.getExplicitOrMeasuredHeight() + 4;
	}

	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);

		var th:Number = title.getExplicitOrMeasuredHeight() + 4;
		var hh:Number = unscaledHeight - th;

		if (!seps)
		{
			seps = new Array(childrenColumn.length-1);
			
			for (var i:int = 0;  i < childrenColumn.length - 1; i++)
			{	
				var headerSeparatorClass:Class = dataGrid.getStyle("headerSeparatorSkin");
				sepSkin = new headerSeparatorClass();
							
				if (sepSkin is ISimpleStyleClient)
					ISimpleStyleClient(sepSkin).styleName = this;
				
				var sep:ColumnSeparator = new ColumnSeparator();
				sep.leftColumnIndex = i;
				sep.rightColumnIndex = i+1;
				
				sep.addChild(DisplayObject(sepSkin));
				
				sepSkin.setActualSize(sep.getExplicitOrMeasuredWidth(),	hh);   					
				
				addChild(sep);
				DisplayObject(sep).addEventListener(MouseEvent.MOUSE_OVER, columnResizeMouseOverHandler);
				DisplayObject(sep).addEventListener(MouseEvent.MOUSE_OUT, columnResizeMouseOutHandler);
				DisplayObject(sep).addEventListener(MouseEvent.MOUSE_DOWN, columnResizeMouseDownHandler);
				seps[i] = sep;	
			}
		} 
		
		var prevColumnWidth:int = 0;
		for  (i = 0 ; i < childrenColumn.length; i++)
		{
			var childRenderer:IListItemRenderer = childrenRenderer[i];
			var childColumn:DataGridColumn = childrenColumn[i];
			
			childRenderer.setActualSize(childColumn.width, hh);
			childRenderer.move(prevColumnWidth, th);
			
			prevColumnWidth += childColumn.width;
		}
		
		var ww:Number = title.getExplicitOrMeasuredWidth() + 4;
		title.setActualSize(ww, th);
		title.move((unscaledWidth - ww)/2, 0);

        // Draw invisible background for separator affordance
        var sepPos:int = 0;
        for (i = 0 ; i < seps.length; i++)
        {
        	sep = seps[i];

	        sep.graphics.clear();
	        sep.graphics.beginFill(0xFFFFFF, 0);
	        sep.graphics.drawRect(-separatorAffordance, 0, sepSkin.measuredWidth + separatorAffordance , hh);
	        sep.graphics.endFill();
	        
	        sepPos += childrenColumn[i].width;
			sep.move(sepPos, th);
        }
  	}

    //--------------------------------------------------------------------------
    //
    //  Event handlers
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    private function columnResizeMouseOverHandler(event:MouseEvent):void
    {
		if (!childrenColumn[leftResizeColumnIndex].resizable)
			return;

        // hide the mouse, attach and show the cursor
        var stretchCursorClass:Class = dataGrid.getStyle("stretchCursor");
        resizeCursorID = CursorManager.setCursor(stretchCursorClass,
                                                 CursorManagerPriority.HIGH);
    }

    /**
     *  @private
     */
    private function columnResizeMouseOutHandler(event:MouseEvent):void
    {
 		if (!childrenColumn[leftResizeColumnIndex].resizable)
			return;

		CursorManager.removeCursor(resizeCursorID);
    }

	private var startX:Number;
	private var minX:Number;
	private var leftResizeColumnIndex:int;
	private var rightResizeColumnIndex:int;
	private var resizeGraphic:IFlexDisplayObject;
    private var resizeCursorID:int = CursorManager.NO_CURSOR;

	private var oldDraggableColumns:Boolean;

    /**
     *  @private
     *  Indicates where the right side of a resized column appears.
     */
    private function columnResizeMouseDownHandler(event:MouseEvent):void
    {
		if (!childrenColumn[0].resizable)
			return;

		oldDraggableColumns = dataGrid.draggableColumns;
		dataGrid.draggableColumns = false;

        startX = DisplayObject(event.target).x;
        
        leftResizeColumnIndex = int(event.target.leftColumnIndex);
        rightResizeColumnIndex = int(event.target.rightColumnIndex);

        minX = childrenColumn[leftResizeColumnIndex].minWidth;

        systemManager.addEventListener(MouseEvent.MOUSE_MOVE, columnResizingHandler, true);
        systemManager.addEventListener(MouseEvent.MOUSE_UP, columnResizeMouseUpHandler, true);

        var resizeSkinClass:Class = dataGrid.getStyle("columnResizeSkin");
        resizeGraphic = new resizeSkinClass();
        addChild(DisplayObject(resizeGraphic));
        resizeGraphic.move(DisplayObject(event.target).x, 0);
        resizeGraphic.setActualSize(resizeGraphic.measuredWidth, unscaledHeight);
    }

    /**
     *  @private
     */
    private function columnResizingHandler(event:MouseEvent):void
    {
        if (!MouseEvent(event).buttonDown)
            columnResizeMouseUpHandler(event);
        
        var pt:Point = new Point(event.stageX, event.stageY);
        pt = globalToLocal(pt);
        
        var totalMinWidth:int = 0;
        for(var i:int = rightResizeColumnIndex ; i < childrenColumn.length; i++)
        {
        	totalMinWidth += childrenColumn[i].minWidth;
        }
        
        resizeGraphic.move(pt.x, 0);
    }

    /**
     *  @private
     *  Determines how much to resize the column.
     */
    private function columnResizeMouseUpHandler(event:MouseEvent):void
    {
		if (!childrenColumn[0].resizable)
			return;

		dataGrid.draggableColumns = oldDraggableColumns;

        systemManager.removeEventListener(MouseEvent.MOUSE_MOVE, columnResizingHandler, true);
        systemManager.removeEventListener(MouseEvent.MOUSE_UP, columnResizeMouseUpHandler, true);

        removeChild(DisplayObject(resizeGraphic));

        CursorManager.removeCursor(resizeCursorID);

        var pt:Point = new Point(event.stageX, event.stageY);
        pt = globalToLocal(pt);
        
        var widthChange:Number = pt.x - startX;

        childrenColumn[leftResizeColumnIndex].width += widthChange;
		dataGrid.invalidateList();

        /* not sure it is worth sending an event here, but DataGrid does
        var dataGridEvent:DataGridEvent =
            new DataGridEvent(DataGridEvent.COLUMN_STRETCH);
        dataGridEvent.columnIndex = c.colNum;
        dataGridEvent.dataField = c.dataField;
        dataGridEvent.localX = pt.x;
        dispatchEvent(dataGridEvent);
		*/
    }


}

}