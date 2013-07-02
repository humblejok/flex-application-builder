package org.jok.flex.application.helper
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.utils.StringUtil;
	
	import org.jok.flex.application.binding.PropertiesBinder;
	import org.jok.flex.application.interfaces.DynamicSelectorDataChangeListener;
	import org.jok.flex.application.parameters.StylesList;
	import org.jok.flex.application.view.XMLGroup;
	import org.jok.flex.utility.ObjectsUtility;
	
	import spark.components.ButtonBar;
	import spark.components.ComboBox;
	import spark.components.DropDownList;
	import spark.components.Label;
	import spark.components.List;
	import spark.components.supportClasses.ButtonBarHorizontalLayout;
	import spark.components.supportClasses.DropDownListBase;
	import spark.events.IndexChangeEvent;

	
	[Bindable]
	public dynamic class DynamicSelectorViewHelper extends DataSelectionDependingViewHelper {
		
		public function DynamicSelectorViewHelper(helperName:String) {
			super(helperName);
		}
		
		public function handleDataChange(event : Event) : void {
			for each ( var listener : DynamicSelectorDataChangeListener in listeners) {
				listener.dataHasChanged(this.HELPER_NAME, null,this[event.currentTarget.id + TARGETS_SUFFIX]);
			}
		}
		
		public override function populateWithXML(content : XML, caller : XMLGroup) : void {
			for each (var element : XML in content.element) {
				var filterSource : String = String(element.@filterSource);
				var filtered : Boolean = filterSource!=null && filterSource!="";
				
				if (element.@type=="combo" || element.@type=="dropdown") {
					var combo : DropDownListBase;
					if (element.@type=="combo") {
						combo = new ComboBox();
					} else if (element.@type=="dropdown") {
						combo = new DropDownList();
					}
					var comboLabel : Label = new Label();
					
					StylesList.applyStyle(StylesList.FontRelated, element, comboLabel);
					StylesList.applyStyle(StylesList.FontRelated, element, combo);
					StylesList.applyStyle(StylesList.AlignmentRelated, element, comboLabel);
					
					if (element.@fill=="adjust") {
						// TODO Do something???
					} else if (element.@fill=="full") {
						combo.percentWidth = 100;
						comboLabel.percentWidth = 100;
					} else if (element.@fill=="define") {
						if (element.@comboLabelPercentWidth!=null && element.@comboLabelPercentWidth!="") {
							comboLabel.percentWidth = new Number(element.@comboLabelPercentWidth);
						}
						if (element.@comboPercentWidth!=null && element.@comboPercentWidth!="") {
							combo.percentWidth = new Number(element.@comboPercentWidth);
						}						
						if (element.@comboLabelWidth!=null && element.@comboLabelWidth!="") {
							comboLabel.width = new Number(element.@comboLabelWidth);
						}
						if (element.@comboWidth!=null && element.@comboWidth!="") {
							combo.width = new Number(element.@comboWidth);
						}
					}
					this[element.@id + TARGETS_SUFFIX] = new ArrayCollection();
					comboLabel.layoutDirection = "ltr";
					var providerId : String = this.createArrayCollectionProvider(element.@id,element.@source,element.@sourceName,filtered,element.argument.length()==0?null:element.argument);
					var labelFunctionId : String = 
						element.@itemLabel==null?
						null:
						this.createItemLabelFunction(
							element.@id,
							element.@itemLabel,
							String(element.@itemLabelFields).split(/,/),
							String(element.@itemLabelConverters)==""?new Array():String(element.@itemLabelConverters).split(/,/))
					
					comboLabel.text = element.@label;
					
					combo.id = element.@id;
					if (this[providerId] is PropertiesBinder) {
						BindingUtils.bindProperty(combo,"dataProvider",this[providerId],"value");
					} else {
						combo.dataProvider = this[providerId];
					}
					combo.addEventListener(IndexChangeEvent.CHANGE,this.handleDataChange);
					if (labelFunctionId==null) {
						combo.labelField = element.@itemLabelFields;
					} else {
						combo.labelFunction = this[labelFunctionId];
					}
					
					if (filtered) {
						if (this[element.@filterSource] is ComboBox || this[element.@filterSource] is DropDownList) {
							DropDownListBase(this[element.@filterSource]).addEventListener(
								IndexChangeEvent.CHANGE,
								this[this.createComboChangeListeningFunction(combo.id,this[providerId + this.COMPLETE_SUFFIX],this[providerId],element.@filterSource,element.@filterSourceField,element.@filteredSourceField)]);
						}
					}
					
					this[combo.id] = combo;
					caller.addElement(comboLabel);
					caller.addElement(combo);
					caller.layoutDirection = "ltr";
					caller.percentHeight = 100;
					caller.percentWidth = 100;
					caller.setStyle("verticalAlign","middle");
				} else if (element.@type=="buttonbar") {
					var buttonBar : ButtonBar = new ButtonBar();
					filterSource = String(element.@filterSource);
					filtered = filterSource!=null && filterSource!="";
					this[element.@id + TARGETS_SUFFIX] = new ArrayCollection();
					providerId = this.createArrayCollectionProvider(element.@id,element.@source,element.@sourceName,filtered,element.argument.length()==0?null:element.argument);
					labelFunctionId = 
						element.@itemLabel==null?
						null:
						this.createItemLabelFunction(
							element.@id,
							element.@itemLabel,
							String(element.@itemLabelFields).split(/,/),
							String(element.@itemLabelConverters)==""?new Array():String(element.@itemLabelConverters).split(/,/));
					buttonBar.layout = new ButtonBarHorizontalLayout();
					// TODO Finish
					
				} else if (element.@type=="list") {
					var list : List = new List();
					list.id = element.@id;
					filterSource = String(element.@filterSource);
					filtered = filterSource!=null && filterSource!="";
					this[element.@id + TARGETS_SUFFIX] = new ArrayCollection();
					providerId = this.createArrayCollectionProvider(element.@id,element.@source,element.@sourceName,filtered,element.argument.length()==0?null:element.argument);
					if (element.@fill=="adjust") {
						// TODO Do something???
					} else if (element.@fill=="full") {
						list.percentWidth = 100;
						list.percentHeight = 100;
					} else if (element.@fill=="define") {
						if (element.@width!=null && element.@width!="") {
							list.width = new Number(element.@width);
						}
						if (element.@percentWidth!=null && element.@percentWidth!="") {
							list.percentWidth = new Number(element.@percentWidth);
						}						
						if (element.@percentHeight!=null && element.@percentHeight!="") {
							list.percentHeight = new Number(element.@percentHeight);
						}
						if (element.@height!=null && element.@height!="") {
							list.height = new Number(element.@height);
						}
					}
					labelFunctionId = 
						element.@itemLabel==null?
						null:
						this.createItemLabelFunction(
							element.@id,
							element.@itemLabel,
							String(element.@itemLabelFields).split(/,/),
							String(element.@itemLabelConverters)==""?new Array():String(element.@itemLabelConverters).split(/,/));
					list.dataProvider = this[providerId];
					list.labelFunction = this[labelFunctionId];
					list.addEventListener(MouseEvent.CLICK,this.handleDataChange);
					if (filtered) {
						list.addEventListener(MouseEvent.CLICK,
							this[this.createListChangeListeningFunction(list.id,this[providerId + this.COMPLETE_SUFFIX],this[providerId],element.@filterSource,element.@filterSourceField,element.@filteredSourceField)]);
					}
					this[list.id] = list;
					caller.addElement(list);
				}
			}
		}
		
		
		public function createArrayCollectionProvider(comboId : String,source : String,sourceName : String ,filtered : Boolean, xmlArguments : XMLList) : String {
			var cbProviderId : String = comboId + PROVIDER_SUFFIX;
			if (source=="cache") {
				if (!filtered) {
					if (controller.caches[sourceName] is Array) {
						this[cbProviderId] = new ArrayCollection(controller.caches[sourceName]);
					} else {
						// If not an array, it is an Arraycollection
						this[cbProviderId] = controller.caches[sourceName];
					}
				} else {
					this[cbProviderId] = new ArrayCollection();
					if (controller.caches[sourceName] is Array) {
						this[cbProviderId + COMPLETE_SUFFIX] = new ArrayCollection(controller.caches[sourceName]);
					} else {
						// If not an array, it is an Arraycollection
						this[cbProviderId + COMPLETE_SUFFIX] = controller.caches[sourceName];
					}
				}
			} else if (source=="remote") {
				this.createRemoteDataProvider(HELPER_NAME,cbProviderId,sourceName,false,xmlArguments);
			}
			
			addSelectorFilters(this,comboId + PROVIDER_SUFFIX,xmlArguments);
			
			return cbProviderId;
		}
		
		public function addSelectorFilters(selector : DynamicSelectorViewHelper, targetId : String, xmlArguments : XMLList) : void {
			for each (var xmlArg : XML in xmlArguments) {
				var type : String = String(xmlArg.@source);
				var name : String = String(xmlArg.@sourceName);
				if (type=="element") {
					(selector[name + TARGETS_SUFFIX] as ArrayCollection).addItem(targetId);
				}
			}
		}
		
		
		public function createListChangeListeningFunction(listeningId : String,completeProvider : ArrayCollection, destinationProvider : ArrayCollection, filterSource : String, filterSourceField : String, filteredSourceField : String) : String {
			var lstChangeFunctionId : String = listeningId + "_listClickEvent";
			this[lstChangeFunctionId] = function(event:MouseEvent) : void {
				if (List(event.currentTarget).selectedItem!=null) {
					destinationProvider.removeAll();
					destinationProvider.addAll(ObjectsUtility.getObjectsListWithMatch(
						completeProvider,
						filteredSourceField,
						ObjectsUtility.getObjectFieldValue(List(event.currentTarget).selectedItem,filterSourceField)));
				}
			}
			return lstChangeFunctionId;
		}
		
		public function createComboChangeListeningFunction(listeningId : String,completeProvider : ArrayCollection, destinationProvider : ArrayCollection, filterSource : String, filterSourceField : String, filteredSourceField : String) : String {
			var cbChangeFunctionId : String = listeningId + "_selectedIndexChangedEvent";
			this[cbChangeFunctionId] = function(event:IndexChangeEvent) : void {
				if (DropDownListBase(event.target).selectedItem!=null) {
					destinationProvider.removeAll();
					destinationProvider.addAll(ObjectsUtility.getObjectsListWithMatch(
						completeProvider,
						filteredSourceField,
						ObjectsUtility.getObjectFieldValue(DropDownListBase(event.target).selectedItem,filterSourceField)));
				}
			}
			return cbChangeFunctionId;
		}
		
		public function createItemLabelFunction(comboId : String,labelFormat : String, substitutionFields : Array,converters : Array) : String {
			var cbFunctionId : String = comboId + FUNCTION_SUFFIX;
			this[cbFunctionId] = function(item : Object) : String {
				var arguments : Array = new Array();
				var index : Number = 0;
				for each (var fields : String in substitutionFields) {
					if (converters.length>0 && converters[0]!="") {
						arguments.push(ObjectsUtility.applyConverter(converters[index++],ObjectsUtility.getObjectFieldValue(item,fields)));
					} else {
						arguments.push(ObjectsUtility.getObjectFieldValue(item,fields));
					}
				}
				return StringUtil.substitute(labelFormat,arguments);
			}
			return cbFunctionId;
		}
		
	}
}