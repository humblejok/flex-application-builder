package org.jok.flex.application.helper
{
	import flash.events.Event;
	import flash.utils.getDefinitionByName;
	
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	import mx.events.PropertyChangeEvent;
	import mx.managers.CursorManager;
	import mx.managers.PopUpManager;
	import mx.utils.StringUtil;
	
	import org.jok.flex.application.binding.PropertiesBinder;
	import org.jok.flex.application.caller.DistantCaller;
	import org.jok.flex.application.interfaces.DynamicSelectorDataChangeListener;
	import org.jok.flex.application.model.FaultToken;
	import org.jok.flex.application.model.ListenedElement;
	import org.jok.flex.application.model.MatchingArgument;
	import org.jok.flex.application.model.RemoteHandlerDescription;
	import org.jok.flex.application.view.XMLGroup;
	import org.jok.flex.application.widget.loader.LoadingTitleWindow;
	import org.jok.flex.application.widget.loader.event.LoaderItemCompletedEvent;
	import org.jok.flex.utility.ObjectsUtility;
	
	import spark.components.Application;

	[Bindable]
	/**
	 * A specific view helper that preconfigures and manages a link to a Dynamic View Selector.
	 *  
	 * @author sdj
	 * 
	 */
	public dynamic class DataSelectionDependingViewHelper extends AbstractSelectionHelper implements DynamicSelectorDataChangeListener {
		
		public const TARGETS_SUFFIX : String = "ListeningTargets";
		
		public const PROVIDER_SUFFIX : String = "ProviderId";
		public const FUNCTION_SUFFIX : String = "FunctionId";
		public const COMPLETE_SUFFIX : String = "_complete";
		
		public const RESULT_HANDLER_PREFIX : String = "result_handler_";
		public const FAULT_HANDLER_PREFIX : String = "fault_handler_";
		
		public var loadingWindow : LoadingTitleWindow = new LoadingTitleWindow();
		
		private var listenedDataProvider : ArrayCollection = new ArrayCollection();
		
		private var associatedSelectors : ArrayCollection = new ArrayCollection();
		
		/**
		 * Constructor. 
		 * @param helperName The helper id
		 * 
		 */
		public function DataSelectionDependingViewHelper(helperName:String) {
			super(helperName);
			description = "Historical data load";
		}
		
		/**
		 * In this class, this method will create listener on other helpers/views that are using the DynamicSelector type.<BR/>
		 * A dedicated syntax does exist and is described in another document.
		 * @param content The content of the view
		 * @param caller The view itself
		 * 
		 */
		public override function populateWithXML(content : XML, caller : XMLGroup) : void {
			super.populateWithXML(content,caller);
			if (!associatedSelectors.contains(String(content.@selector))) {
				associatedSelectors.addItem(String(content.@selector));
			}
			for each (var element : XML in content.element) {
				if (element.@type=="dataprovider") {
					var selector : String = String(content.@selector);
					if (element.@selector != null && String(element.@selector)!="") {
						selector = String(element.@selector);
						if (selector=="self") {
							selector = HELPER_NAME;
						}
						if (!associatedSelectors.contains(selector)) {
							associatedSelectors.addItem(selector);
						}
					}
					var acceptNull : Boolean = String(element.@acceptNull)==null || String(element.@selector)=="" || String(element.@selector)== "true";
					if (element.@source=="element") {
						this.createElementDataProvider(selector,element.@id,element.@sourceName,element.@sourceFields,element.argument.length()==0?null:element.argument);
					} else if (element.@source=="cache") {
						this.createCacheDataProvider(selector,element.@id,element.@sourceName,element.@sourceFields,element.argument.length()==0?null:element.argument);
					} else if (element.@source=="remote") {
						this.createRemoteDataProvider(selector,element.@id,element.@sourceName,acceptNull,element.argument.length()==0?null:element.argument);
					} else if (element.@source=="list") {
						this.createListDataProvider(selector,element.@id,element.@sourceName,element.@sourceFields,element.argument.length()==0?null:element.argument);
					}
				} else if (element.@type=="transform") {
					if (element.@source=="local-element") {
						this.createLocalElementTransformation(
							element.@id,
							element.@sourceName,
							element.@transformerFunction,
							this,
							element.@transformerRemote,
							String(element.@allowCancel)=="true",
							String(element.@transformerFields));
					}
				} else if (element.@type=="value") {
					if (element.@source=="string") {
						this.createStringValue(content.@selector,element.@id,element.@sourceName,element.argument.length()==0?null:element.argument);
					} else if (element.@source=="arraycollection") {
						this.createArrayCollectionValue(content.@selector,element.@id,element.@sourceName,element.argument.length()==0?null:element.argument);
					} else {
						this.createObjectValue(content.@selector,element.@id,element.@sourceName,element.argument.length()==0?null:element.argument);
					}
				}
			}
			if (String(content.@forceInitialization)!=null && String(content.@forceInitialization)=="true") {
				this.dataHasChanged(String(content.@selector),null);
			}
		}

		public function prepareSelector(selectorId : String,dpId : String,targetElementId : String) : void {
			var selector : DynamicSelectorViewHelper = DynamicSelectorViewHelper(controller.views[selectorId].helper);
			selector.addDynamicSelecterDataChangeListener(this);
			if (selector.hasOwnProperty(dpId + TARGETS_SUFFIX)) {
				(selector[dpId + TARGETS_SUFFIX] as ArrayCollection).addItem(targetElementId);
			}
		}
		
		/**
		 * Create a dataprovider on a data provider or an object (element) from a foreign view or helper.
		 * @param selectorId The id of the selecting view/helper
		 * @param dpId The local id of the data provider
		 * @param targetElementId The distant id of the listened object
		 * @param valueField The fields chain (dot separated).
		 * @param arguments The arguments.
		 * 
		 */
		public function createElementDataProvider(selectorId : String,dpId : String,targetElementId : String,valueField : String, arguments : XMLList) : void {
			prepareSelector(selectorId,targetElementId,dpId);
			var element : ListenedElement = new ListenedElement();
			element.sourceId = selectorId;
			element.targetId = dpId;
			element.elementId = targetElementId;
			element.fieldChain = valueField;
			
			this[dpId] = new PropertiesBinder(new Object());
			listenedDataProvider.addItem(element);
		}

		/**
		 * Create a data provider on a static list object. xmlArguments provides the filtering options.
		 *  
		 * @param selectorId The id of the selecting view/helper
		 * @param dpId The local id of the data provider
		 * @param targetElementId The id of the cached object
		 * @param valueField The fields chains (dot separated)
		 * @param xmlArguments The arguments as XML for filtering (unused)
		 * 
		 */
		public function createListDataProvider(selectorId : String,dpId : String,targetElementId : String,valueField : String, xmlArguments : XMLList) : void {
			prepareSelector(selectorId,targetElementId,dpId);
			var element : ListenedElement = new ListenedElement();
			element.sourceId = selectorId;
			element.targetId = dpId;
			
			element.operatingFunction = 
				function(helper : AbstractHelper) : void {
					var argumentsList : ArrayCollection = new ArrayCollection();
					var result : ArrayCollection = new ArrayCollection();
					for each (var obj : Object in controller.staticLists[targetElementId]) {
						var doMatch : Boolean = true;
						for each(var m : MatchingArgument in argumentsList) {
							doMatch = doMatch && ObjectsUtility.getObjectFieldValue(obj,m.fieldChain)==m.matchingValue;
						}
						if (doMatch) {
							result.addItem(ObjectsUtility.getObjectFieldValue(obj,valueField));
						}
					}
					PropertiesBinder(helper[dpId]).value = result;
				}
			
			this[dpId] = new PropertiesBinder(new Object());
			listenedDataProvider.addItem(element);
		}
		
		
		/**
		 * Create a data provider on a cached object. xmlArguments provides the filtering options.
		 *  
		 * @param selectorId The id of the selecting view/helper
		 * @param dpId The local id of the data provider
		 * @param targetElementId The id of the cached object
		 * @param valueField The fields chains (dot separated)
		 * @param xmlArguments The arguments as XML for filtering
		 * 
		 */
		public function createCacheDataProvider(selectorId : String,dpId : String,targetElementId : String,valueField : String, xmlArguments : XMLList) : void {
			prepareSelector(selectorId,targetElementId,dpId);
			var element : ListenedElement = new ListenedElement();
			element.sourceId = selectorId;
			element.targetId = dpId;
			
			element.operatingFunction = 
				function(helper : AbstractHelper) : void {
					var argumentsList : ArrayCollection = new ArrayCollection();
					var result : ArrayCollection = new ArrayCollection();
					if (xmlArguments!=null) {
						for each (var argument : XML in xmlArguments) {
							var match : MatchingArgument = new MatchingArgument();
							match.fieldChain = argument.@match;
							if (argument.@source=="element") {
								match.matchingValue = ObjectsUtility.getObjectFieldValue(controller.views[selectorId].helper[argument.@sourceName],String(argument.@sourceFields));
							}
							argumentsList.addItem(match);
						}
					}
				
					for each (var obj : Object in controller.caches[targetElementId]) {
						var doMatch : Boolean = true;
						for each(var m : MatchingArgument in argumentsList) {
							doMatch = doMatch && ObjectsUtility.getObjectFieldValue(obj,m.fieldChain)==m.matchingValue;
						}
						if (doMatch) {
							result.addItem(ObjectsUtility.getObjectFieldValue(obj,valueField));
						}
					}
					PropertiesBinder(helper[dpId]).value = result;
				}
				
			this[dpId] = new PropertiesBinder(new Object());
			listenedDataProvider.addItem(element);
		}
		
		/**
		 * Create a String data provider.
		 * @param selectorId The selector id
		 * @param dpId The local name of the data provider
		 * @param inputString The input string
		 * @param xmlArguments The arguments
		 * 
		 */
		public function createStringValue(selectorId : String,dpId : String,inputString : String, xmlArguments : XMLList) : void {
			var element : ListenedElement = new ListenedElement();
			element.sourceId = selectorId;
			element.targetId = dpId;
			element.operatingFunction =
				function(helper : AbstractHelper) : void {
					var callArguments : Array = new Array(); 
					helper.computeArgumentsAsArray(selectorId,dpId,xmlArguments,callArguments);
					helper[dpId].value = StringUtil.substitute(inputString,callArguments);
				}
			this[dpId] = new PropertiesBinder(new Object());
			listenedDataProvider.addItem(element);
		}
		
		/**
		 * Create an ArrayCollection data provider.
		 * @param selectorId The selector id
		 * @param dpId The local name of the data provider
		 * @param inputString The input string
		 * @param xmlArguments The arguments
		 * 
		 */
		public function createArrayCollectionValue(selectorId : String,dpId : String,inputString : String,xmlArguments : XMLList) : void {
			var element : ListenedElement = new ListenedElement();
			element.sourceId = selectorId;
			element.targetId = dpId;
			element.operatingFunction =
				function(helper : AbstractHelper) : void {
					//
					// TODO Implement me with arguments :D
					//
					
				}
			this[dpId] = new PropertiesBinder(new Object());
			PropertiesBinder(this[dpId]).value = new ArrayCollection();
			listenedDataProvider.addItem(element);
		}
		
		/**
		 * Create an Object data provider.
		 * @param selectorId The selector id
		 * @param dpId The local name of the data provider
		 * @param inputString The input string
		 * @param xmlArguments The arguments
		 * 
		 */
		public function createObjectValue(selectorId : String,dpId : String,inputString : String,xmlArguments : XMLList) : void {
			var element : ListenedElement = new ListenedElement();
			element.sourceId = selectorId;
			element.targetId = dpId;
			element.operatingFunction =
				function(helper : AbstractHelper) : void {
					//
					// TODO Implement me with arguments :D
					//
					
				}
			this[dpId] = new PropertiesBinder(new Object());
			PropertiesBinder(this[dpId]).value = new Object();
			listenedDataProvider.addItem(element);
		}
		
		/**
		 * Create a data provider linked to distant call. 
		 * @param selectorId The selector id
		 * @param dpId The local id of the data provider
		 * @param targetRemote The name of the distant call
		 * @param xmlArguments The arguments
		 * 
		 */
		public function createRemoteDataProvider(selectorId : String,dpId : String,targetRemote : String, acceptNull : Boolean, xmlArguments : XMLList) : void {
			if (selectorId!=HELPER_NAME) {
				var selector : DynamicSelectorViewHelper = DynamicSelectorViewHelper(controller.views[selectorId].helper);
				selector.addDynamicSelecterDataChangeListener(this);
				selector.addSelectorFilters(selector,dpId,xmlArguments);
				
			} else {
				this.addDynamicSelecterDataChangeListener(this);
			}
			this.mapLocalValue(controller.views[this.HELPER_NAME]);
			var element : ListenedElement = new ListenedElement();
			element.sourceId = selectorId;
			element.targetId = dpId;
			element.operatingFunction =
				function(helper : AbstractHelper) : void {
					var callArguments : Array = new Array();
					var allowExecution : Boolean = true;
					helper.computeArgumentsAsArray(selectorId,dpId,xmlArguments,callArguments);
					if (!acceptNull) {
						for each(var o : Object in callArguments) {
							if (o==null) {
								allowExecution = false;
							}
						}
					}
					if (allowExecution) {
						CursorManager.setBusyCursor();
						DistantCaller(controller.getRemoteObjectsCallers()[targetRemote]).addHandler(helper,helper[RESULT_HANDLER_PREFIX + dpId],helper[FAULT_HANDLER_PREFIX + dpId],dpId);
						DistantCaller(controller.getRemoteObjectsCallers()[targetRemote]).call(callArguments);					
					}
				}
			
			this[RESULT_HANDLER_PREFIX + dpId] =
				function(result : Object, handler : RemoteHandlerDescription) : void {
					handler.helper[handler.destinationId].value = result;
					CursorManager.removeAllCursors();
				}
			this[FAULT_HANDLER_PREFIX + dpId] =
				function(fault : FaultToken, handler : RemoteHandlerDescription = null) : void {
					handler.helper[handler.destinationId].value = null;
					CursorManager.removeAllCursors();
				}
			this[dpId] = new PropertiesBinder(new Object());
			listenedDataProvider.addItem(element);
		}
		
		/**
		 * Create a data provider that perform a transformation on a local data provider (element). 
		 * @param targetName The name of the new data provider
		 * @param sourceName The name of the original data provider
		 * @param transformerFunction The function that will perform the transformation
		 * @param transformerClassInstance The object instance that contains the transforming method
		 * 
		 */
		public function createLocalElementTransformation(targetName : String,sourceName : String,transformerFunction : String, transformerClassInstance : Object, transformerRemote : String, allowCancel : Boolean, transformerFields : String = "") : void {
			var sourceChanged : Function =
				function(event : PropertyChangeEvent) : void {
					if (transformerFunction!=null && transformerFunction.indexOf("remote")==0) {
						// Calls a remote function to execute the transformation
						var dataFields : String = transformerFields;
						transformerClassInstance[transformerFunction](transformerRemote, targetName,event.newValue, dataFields, allowCancel);
						
					} else {
						// Default case
						transformerClassInstance[transformerFunction](targetName,event.newValue);
					}
				}
			this[targetName] = new PropertiesBinder(new Object());
			PropertiesBinder(this[sourceName]).addEventListener(PropertyChangeEvent.PROPERTY_CHANGE,sourceChanged);
		}
		
		public function remoteLoadFromArray(transformerRemote : String, targetName : String, data : Object, dataFields : String = "", allowCancel : Boolean = false,... args) : void {
			trace("Remote load from array: " + transformerRemote + " @ " + targetName);
			if (data != null && (data is Array  || data is ArrayCollection) && data.length>0) {
				var helper : AbstractHelper = this;
				this[targetName].value = null;
				this.todo = data.length;
				this.done = 0;
				trace("Remote load from array: " + transformerRemote + " @ " + targetName + " - " + this.todo + "/" + this.done);
				var resultFunction : Function = 
					function(result : Object, handler : RemoteHandlerDescription = null) : void {
						if (helper[targetName].value==null) {
							helper[targetName].value = new ArrayCollection();
							// Display loader window
							var ac : ArrayCollection = new ArrayCollection();
							ac.addItem(helper);
							loadingWindow.data = ac;
							loadingWindow.title = "Loading information...";
							PopUpManager.addPopUp(loadingWindow,Application(FlexGlobals.topLevelApplication),true);
							PopUpManager.centerPopUp(loadingWindow);
						}
						(helper[targetName].value as ArrayCollection).addItem(result);
						helper.done = helper.done + 1;
						dispatchLoaderEvent(LoaderItemCompletedEvent.LOADER_SUB_ITEM_COMPLETED);
						trace("Remote load from array: " + transformerRemote + " @ " + targetName + " - " + this.todo + "/" + this.done);
						if (helper.done==helper.todo) {
							PopUpManager.removePopUp(loadingWindow);
							DistantCaller(controller.getRemoteObjectsCallers()[transformerRemote]).handlers.removeAll();
							dispatchLoaderEvent(LoaderItemCompletedEvent.LOADER_ITEM_COMPLETED);
						} else {
							var valueArray : Array = computeArrayLoadArguments(data,dataFields,helper.done,args);
							var a : Array = new Array(valueArray,true);
							myView().callLater(DistantCaller(helper.controller.getRemoteObjectsCallers()[transformerRemote]).call,a);
						}
					}
					
				var cancelFunction : Function =
					function(event : Event) : void {
						PopUpManager.removePopUp(loadingWindow);
						DistantCaller(controller.getRemoteObjectsCallers()[transformerRemote]).handlers.removeAll();
						loadingWindow.removeEventListener(LoaderItemCompletedEvent.LOADER_CANCEL_CALLED,cancelFunction);
						dispatchLoaderEvent(LoaderItemCompletedEvent.LOADER_CANCEL_CALLED);
					}
					
				var faultFunction : Function = 
					function(fault : FaultToken, handler : RemoteHandlerDescription = null) : void {
						helper.done = helper.done + 1;
						dispatchLoaderEvent(LoaderItemCompletedEvent.LOADER_SUB_ITEM_COMPLETED);
						if (helper.done==helper.todo) {
							PopUpManager.removePopUp(loadingWindow);
						}
					}
				DistantCaller(controller.getRemoteObjectsCallers()[transformerRemote]).handlers.removeAll();
				DistantCaller(controller.getRemoteObjectsCallers()[transformerRemote]).addHandler(this,resultFunction,faultFunction);
				if (allowCancel) {
					loadingWindow.addEventListener(LoaderItemCompletedEvent.LOADER_CANCEL_CALLED,cancelFunction);
				}
				var valueArray : Array = computeArrayLoadArguments(data,dataFields,0,args as Array);
				DistantCaller(controller.getRemoteObjectsCallers()[transformerRemote]).call(valueArray,true);
			}
		}
		
		private function computeArrayLoadArguments(data : Object, dataFields : String = "", currentIndex : Number = 0,additionalArguments : Array = null) : Array {
			var valueArray : Array = new Array();
			if (data is Array) {
				valueArray.push(data[currentIndex]);
			} else {
				for each(var field : String in dataFields.split(/,/)) {
					if (field=="self") {
						valueArray.push((data as ArrayCollection).getItemAt(currentIndex));
					} else {
						var value : Object = ObjectsUtility.getObjectFieldValue((data as ArrayCollection).getItemAt(currentIndex),field);
						valueArray.push(value);
					}
				}
				if (additionalArguments!=null && additionalArguments.length>0) {
					valueArray = valueArray.concat(additionalArguments);
				}
			}
			return valueArray;
		}
		
		public function reloadElementValue(... args) : void {
			dataHasChanged(HELPER_NAME, null, new ArrayCollection(args));
		}
		
		
		public function myDataHasChanged() : void {
			dataHasChanged(HELPER_NAME, null);
		}
		
		public function resetSelectors() : void {
			for each(var s : String in associatedSelectors) {
				dataHasChanged(s,null);
			}
		}
		
		public function dataHasChanged(sourceId : String,newData : Array, filter : ArrayCollection = null) : void {
			for each (var ldp : Object in listenedDataProvider) {
				if (ldp is ListenedElement) {
					if (ldp.sourceId==sourceId) {
						if (filter==null || filter.contains(ldp.targetId)) {
							if (ldp.operatingFunction!=null) {
								ldp.operatingFunction(this);
							} else {
								PropertiesBinder(this[ldp.targetId]).value = ObjectsUtility.getObjectFieldValue(controller.views[ldp.sourceId].helper[ldp.elementId],ldp.fieldChain);
							}
						}
					}
				}
			}
		}
		
	}
}