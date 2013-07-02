package org.jok.flex.application.view
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.DataGrid;
	import mx.controls.Spacer;
	import mx.core.UIComponent;
	
	import org.jok.flex.application.helper.AbstractHelper;
	import org.jok.flex.application.helper.DynamicFormViewHelper;
	import org.jok.flex.application.interfaces.IFormView;
	import org.jok.flex.application.interfaces.IFormViewHelper;
	import org.jok.flex.application.model.FaultToken;
	import org.jok.flex.application.model.RemoteHandlerDescription;
	import org.jok.flex.utility.ObjectsUtility;
	
	import spark.components.CheckBox;
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Label;
	import spark.components.Panel;
	import spark.components.TextInput;
	import spark.layouts.HorizontalLayout;
	import spark.layouts.VerticalLayout;
	
	public dynamic class DynamicFormView extends Group implements IFormView {
		
		public static var OK_BUTTON_CLICKED_EVENT : String = "OK_BUTTON_CLICKED_EVENT";
		public static var CANCEL_BUTTON_CLICKED_EVENT : String = "CANCEL_BUTTON_CLICKED_EVENT";
		
		public static var ITEM_SUFFIX  : String = "Item";
		public static var LABEL_SUFFIX : String = "Label";
		public static var GROUP_SUFFIX : String = "Group";
		
		private var helper : DynamicFormViewHelper = null;
		
		[Bindable]
		private var _data : Object;
		
		[Bindable]
		private var _editMode : Boolean;
		
		
		private var contentDescription : XML;
		
		public function DynamicFormView(formName : String) {
			super();
			this.helper = new DynamicFormViewHelper(formName + "Helper");
			this.percentHeight = 100;
			this.percentWidth = 100;
		}
		
		public function buildFromXML(content : XML) : void {
			var contentPanel : Panel = new Panel();
			
			contentDescription = content;

			contentPanel.id = "contentPanel";
			
			this[contentPanel.id] = contentPanel;
						
			contentPanel.percentHeight = 100;
			contentPanel.percentWidth = 100;
			
			contentPanel.setStyle("horizontalAlign","center");
			
			if (String(contentDescription.@layout)=="horizontal") {
				contentPanel.layout = new HorizontalLayout();
			} else {
				contentPanel.layout = new VerticalLayout();
			}
			
			if (contentDescription.@title!=null && String(contentDescription.@title!="")) {
				contentPanel.title = String(contentDescription.@title);
			}
			var spacingGroup : HGroup = new HGroup();
			spacingGroup.addElement(new Spacer());
			contentPanel.addElement(spacingGroup);
			for each(var field : XML in content.field) {
				var formItem : HGroup = new HGroup();
				var formItemLabel : Label = new Label();
				formItem.id = field.@name + GROUP_SUFFIX;
				formItem.percentWidth = 95;
				formItemLabel.id = field.@name + LABEL_SUFFIX;
				this[formItem.id] = formItem;
				this[formItemLabel.id] = formItemLabel;
				
				formItemLabel.text = field.@label;
				formItemLabel.percentWidth = 33;
				formItemLabel.setStyle("textAlign","right");
				var component : UIComponent = null;
				if (field.@renderer!=null && String(field.@renderer)!="") {
					// User defined renderer
					var renderingClass : Class = getDefinitionByName(field.@renderer.toString()) as Class;
					component = new renderingClass();
				} else {
					// Default renderers
					if (field.@type=="String") {
						component = new TextInput();
					} else if (field.@type=="Boolean") {
						component = new CheckBox();
					} else if (field.@type=="External") {
						component = new TextInput();
					} else if (field.@type=="List") {
						component = new DataGrid();
					}
				}
				component.id = String(field.@name).replace(".","_") + ITEM_SUFFIX;
				this[component.id] = component;
				
				component.percentWidth = 67;
				
				formItem.addElement(formItemLabel);
				formItem.addElement(component);
				contentPanel.addElement(formItem);
			}
			buildControlBar(contentPanel);
			this.addElement(contentPanel);
		}
		
		private function handleOkButtonClick(event : Event) : void {
			this.dispatchEvent(new Event(OK_BUTTON_CLICKED_EVENT));
		}
		
		private function handleCancelButtonClick(event : Event) : void {
			this.dispatchEvent(new Event(CANCEL_BUTTON_CLICKED_EVENT));
		}
		
		private function buildControlBar(contentPanel : Panel) : void {
			var buttonsGroup : HGroup = new HGroup();
			buttonsGroup.percentWidth = 95;
			var spacer : Spacer = new Spacer();
			spacer.percentWidth = 50;
			buttonsGroup.addElement(spacer);
			var okButton : Button = new Button();
			okButton.label = "OK";
			okButton.percentWidth = 25;
			var cancelButton : Button = new Button();
			cancelButton.label = "Cancel";
			cancelButton.percentWidth = 25;
			buttonsGroup.addElement(spacer);
			buttonsGroup.addElement(okButton);
			buttonsGroup.addElement(cancelButton);
			contentPanel.addElement(buttonsGroup);
			
			okButton.addEventListener(MouseEvent.CLICK,handleOkButtonClick);
			cancelButton.addEventListener(MouseEvent.CLICK,handleCancelButtonClick);
		}
		
		public function set data(d : Object) : void {
			_data = d;
			if (contentDescription.@titleField!=null && String(contentDescription.@titleField)!="") {
				this["contentPanel"].title = _data[String(contentDescription.@titleField)];
			}
			for each(var field : XML in contentDescription.field) {
				var fieldProperty : String = null;
				var rendererId : String = String(field.@name).replace(".","_") + ITEM_SUFFIX;
				if (field.@renderer!=null && String(field.@renderer)!="") {
					// User defined renderer
					fieldProperty = "data";
					if (field.@rendererDataField!=null && String(field.@rendererDataField)!="") {
						fieldProperty = String(field.@rendererDataField);
					}
				} else {
					// Default renderers
					if (field.@type=="String") {
						fieldProperty = "text";
					} else if (field.@type=="Boolean") {
						fieldProperty = "selected";
					} else if (field.@type=="External") {
						fieldProperty = "text";
					} else if (field.@type=="List") {
						fieldProperty = "dataProvider";
					}
				}
				
				if (field.@type=="External" && field.@remoteLabel!=null && String(field.@remoteLabel)!="") {
					if (field.@renderer=="spark.components.TextInput") {
						helper.callRemoteForField(field.@remoteLabel,field.@remoteLabelField,this,field.@name + ITEM_SUFFIX,fieldProperty,_data[field.@name]);
					} else {
						this[field.@name + ITEM_SUFFIX].initializeWithRemote(helper,_data[field.@name],field);
					}
				}
				
				if (helper.computedValue==null) {
					this[rendererId][fieldProperty] = ObjectsUtility.getObjectFieldValue(_data,field.@name);
				} else {
					this[rendererId][fieldProperty] = helper.computedValue;
				}
			}
		}
		
		public function get data() : Object {
			return _data;
		}
		
		public function set editMode(b : Boolean) : void {
			_editMode = b;
		}
		public function get editMode() : Boolean {
			return _editMode;
		}
		
		public function getFormViewHelper() : IFormViewHelper {
			return helper;
		}
	}
}