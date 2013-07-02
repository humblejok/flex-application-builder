package org.jok.flex.application.controller
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	
	import mx.collections.ArrayCollection;
	import mx.containers.TabNavigator;
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.core.INavigatorContent;
	import mx.core.UIComponent;
	import mx.managers.CursorManager;
	import mx.managers.PopUpManager;
	import mx.resources.ResourceManager;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.rpc.remoting.RemoteObject;
	
	import org.granite.tide.Tide;
	import org.granite.tide.events.TideFaultEvent;
	import org.granite.tide.events.TideResultEvent;
	import org.jok.flex.application.caller.DistantCaller;
	import org.jok.flex.application.caller.DistantPagedCaller;
	import org.jok.flex.application.caller.model.LazyLoad;
	import org.jok.flex.application.helper.AbstractHelper;
	import org.jok.flex.application.helper.CacheHelper;
	import org.jok.flex.application.interfaces.IFormView;
	import org.jok.flex.application.interfaces.IResourceProvider;
	import org.jok.flex.application.model.StaticItem;
	import org.jok.flex.application.parameters.StylesList;
	import org.jok.flex.application.provider.IconsProvider;
	import org.jok.flex.application.security.ISecurityModel;
	import org.jok.flex.application.view.*;
	import org.jok.flex.application.widget.loader.LoaderItem;
	import org.jok.flex.application.widget.loader.LoadingTitleWindow;
	import org.jok.flex.application.widget.loader.event.LoaderItemCompletedEvent;
	import org.jok.flex.application.widget.security.LoginPasswordTitleWindow;
	import org.jok.flex.utility.ObjectsUtility;
	import org.jok.flex.utility.network.GZIPSerializationFilter;
	import org.jok.flex.utility.python.JSonPythonConverter;
	
	import spark.components.Application;
	import spark.components.NavigatorContent;
	import spark.components.TitleWindow;
	
	[Bindable]
	/**
	 * The main controller of the application. There must be only one instance in the whole application.<BR/>
	 * It handles the configuration files read, it contains the views, the distant calls, the cache, ...<BR/>
	 * It also centralizes calls and action on all the above.<BR/>
	 * It extends the EventDispatcher class in order to allow it to send event to the whole application.<BR/>
	 * <BR/>
	 * This is a singleton but as ActionScript doesn't allow to set a visibility property on constructors...
	 * @author sdj
	 * 
	 */
	public dynamic class ApplicationController extends EventDispatcher {
		
		public static var CURRENT_USER_LOGIN : String = "currentUserLogin";
		public static var CURRENT_USER_ID : String = "currentUserId";
		public static var CURRENT_USER_SECURITY_DESCRIPTION : String = "currentUserSecurityDescription";
		public static var CURRENT_USER_PROFILE : String = "currentUserProfile";
		
		
		// SINGLETON INSTANCE
		private static var instance : ApplicationController = null;

		// APPLICATION CONFIGURATION
		private const remoteControlsList : String = ResourceManager.getInstance().getString("Application","remote.controls.url");
		private var xmlLoaderForRemoteControls : URLLoader = new URLLoader();
		private var remoteControlsConfiguration : XML = null;
		private const staticItemsList : String = ResourceManager.getInstance().getString("Application","static.lists.url");
		private var xmlLoaderForStaticItems : URLLoader = new URLLoader();
		private var staticItemsConfiguration : XML = null;
		
		private const applicationContentList : String = ResourceManager.getInstance().getString("Application","application.content.url");
		private var xmlLoaderForApplicationContent : URLLoader = new URLLoader();
		private var applicationContentConfiguration : XML = null;
		
		// DEBUG MODE
		public const debugProfile : String = ResourceManager.getInstance().getString("Application","debug.profile");
		
		// SECURITY
		private var securityClass : Class = null;
		
		// REMOTE OBJECT CALLS FIELDS
		private var remoteObjectsRepository : Array = new Array();
		private var remoteObjectsCallers : Array = new Array();
		
		// CACHE
		private var awaitedCachedItems : Number = 0;
		private var loadedCachedItems : Number = 0;
		public var caches : Array = new Array();
		public var cacheHelpers : ArrayCollection = new ArrayCollection();
		public var cacheLoaderWindow : LoadingTitleWindow = new LoadingTitleWindow();
		
		// VIEWS
		private var navigator : UIComponent = null;
		public var navigatorContents : Array = new Array();
		public var views : Array = new Array();
		
		// FORMS
		public var forms : Array = new Array();
		
		// STATIC LISTS
		public var staticLists : Array = new Array();
		
		// STATIC LISTS
		public var staticValues : Array = new Array();
		
		// CONSTRUCTOR - SINGLETON DO NOT USE
		/**
		 * DO NOT USE - THIS CLASS IS A SINGLETON 
		 * @param target
		 * 
		 */
		public function ApplicationController(target:IEventDispatcher=null) {
			super(target);
		}
		
		// VIEWS MANAGEMENT FIELDS
		
		/**
		 * List of view helpers, not used for the moment.<BR/>
		 * It's easier to get the right helper instance by calling: <code>ApplicationController.getInstance().view[VIEW_NAME].helper</code>
		 */
		private var associatedViewHelpers : ArrayCollection = new ArrayCollection(); 

		
		// Display security computation trick 
		public var computeDisplayFunction : Function;
		public var loginWindow : LoginPasswordTitleWindow;
		
		// SINGLETON INSTANCE
		/**
		 * The instance getter
		 * @return The instance
		 * 
		 */
		public static function getInstance() : ApplicationController {
			if (instance == null) {
				instance = new ApplicationController();
			}
			return instance;
		}

		/**
		 * This will launch the initialization of the application by the Application Builder framework.<BR/>
		 * Once called, all configuration files will be read and application content will be displayed.<BR/>
		 */
		public function startApplication() : void {
			CursorManager.setBusyCursor();
			xmlLoaderForRemoteControls.addEventListener(Event.COMPLETE,onXmlLoadedForRemoteControls);
			xmlLoaderForRemoteControls.load(new URLRequest(remoteControlsList));
		}
		
		// REMOTE CONTROLS INITIALIZER
		
		/**
		 * Handle successful read of the remote-controls.xml file.<BR/>
		 * It will trigger the parsing of the file content.
		 * @param The read event
		 */
		public function onXmlLoadedForRemoteControls(event : Event) : void {
			FlexGlobals.topLevelApplication.initializeApplication();
			remoteControlsConfiguration = new XML(event.target.data);
			registerRemoteObjectsAccessors();
			registerHttpServiceAccessors();
			xmlLoaderForStaticItems.addEventListener(Event.COMPLETE,onXmlLoadedForStaticItems);
			xmlLoaderForStaticItems.load(new URLRequest(staticItemsList));
		}
		
			// INITIALIZATION
		/**
		 * Use the remote-controls.xml file content to create and declare the HTTP distant callers.<BR/>
		 */
		private function registerHttpServiceAccessors() : void {
			for each (var service : XML in remoteControlsConfiguration.httpservices.httpservice) {
				var httpService : HTTPService = new HTTPService();
				if (service.compressed=="true") {
					httpService.channelSet = GZIPSerializationFilter.getChannelSet();
					httpService.serializationFilter = GZIPSerializationFilter.getInstance();
					//httpService.headers =  {'Accept-Encoding':'gzip'};
				}
				
				httpService.method = "GET";
				
				var caller : DistantCaller = new DistantCaller(String(service.name));
				if (Boolean(String(service.ispaged))) {
					caller = new DistantPagedCaller(String(service.name));
				}
				
				// Initializing remote object
				httpService.url = service.url;
				httpService.resultFormat = service.resultformat=="json"?"text":service.resultformat;
				
				// Setting POST mode if necessary				
				if (XMLList(service.post).length()>0) {
					httpService.method = "POST";
					for each (var postArgument : XML in service.post.arg) {
						caller.postArguments.push(String(postArgument));
					}
				}
				
				// Initialize caller
				caller.calledMethod = service.url;
				caller.internalDataFormat = service.resultformat;
				if (service.resultclass!=null && String(service.resultclass)!="") {
					caller.resultsClass = Class(getDefinitionByName(String(service.resultclass)));
				}
				if (service.resultfield!=null && String(service.resultfield)!="") {
					caller.resultsField = String(service.resultfield);
				}
				
				// Assigning event listener				
				httpService.addEventListener(FaultEvent.FAULT,caller.onFaultEvent);
				httpService.addEventListener(ResultEvent.RESULT,caller.onResultEvent);
				
				// Registering remote object
				remoteObjectsRepository[String(service.name)] = httpService;
				
				// Assigning debug profiles
				for each(var debugNode : XML in service.debugUrl) {
					caller.debugProfiles["Profile_" +debugNode.@name] = String(debugNode);
				}
				
				// Assigning static parameters
				for each(var param : XML in service.params.param) {
					if(param.@source=="controller") {
						caller.staticParameters.push(this[String(param)]);
					} else {
						caller.staticParameters.push(param);
					}
				}
				
				// Assigning default paging options
				if (Boolean(String(service.ispaged))) {
					DistantPagedCaller(caller).currentPage = 0;
					DistantPagedCaller(caller).maxItemsPerPage = (service.paging.maxitemsperpage==null?100:Number(service.paging.maxitemsperpage));
					DistantPagedCaller(caller).currentFilter = String(service.paging.filter);
					DistantPagedCaller(caller).currentOrderBy = String(service.paging.orderby);
					DistantPagedCaller(caller).desc = (service.paging.desc==null?false:Boolean(String(service.paging.desc)));
					DistantPagedCaller(caller).remoteCounter = service.paging.remotecount;
				}
				
				// Registering caller
				remoteObjectsCallers[String(service.name)] = caller;
			}
		}
		
		/**
		 * Use the remote-controls.xml file content to create and declare the Remote Object distant callers.<BR/>
		 */
		private function registerRemoteObjectsAccessors() : void {
			for each (var remote : XML in remoteControlsConfiguration.remoteobjects.remoteobject) {
				var remoteObject : RemoteObject = new RemoteObject();
				var caller : DistantCaller = new DistantCaller(String(remote.name),String(remote.method));
				
				if (Boolean(String(remote.ispaged))) {
					caller = new DistantPagedCaller(String(remote.name),String(remote.method));
				}
				
				caller.useGraniteTide = (remote.useGraniteTide==null?false:String(remote.useGraniteTide)=="true");
				
				// Initializing remote object
				remoteObject.destination = remote.bean;
				remoteObject.addEventListener(FaultEvent.FAULT,caller.onFaultEvent);
				remoteObject.addEventListener(ResultEvent.RESULT,caller.onResultEvent);
				
				// Registering remote object
				remoteObjectsRepository[String(remote.name)] = remoteObject;
				
				// Assigning lazy loads
				for each(var lazy : XML in remote.lazyLoads.lazy) {
					caller.lazyLoads.addItem(new LazyLoad(lazy.@lazyFieldRoot,lazy.@lazyField,lazy.@remote, lazy.@remoteArgumentLazyField));
				}
				
				// Assigning static parameters
				var i : Number = 0;
				for each(var param : XML in remote.params.param) {
					if(param.@source=="controller") {
						caller.staticParameters.push(this[String(param)]);
					} else if(param.@source=="value") {
						var argumentClass : Class = getDefinitionByName(param.@type) as Class;
						if (String(param)=="null") {
							caller.staticParameters.push(new argumentClass());
						} else if (String(param.@type)=="Boolean") {
							caller.staticParameters.push(String(param)=="true");
						} else {
							caller.staticParameters.push(argumentClass(String(param)));
						}
					} else if (param.@source=="cache") {
						(function(v : String) : void {
							this[v + "fct"] = function() : Object {
								return this.caches[v];
							}
							caller.staticParameters.push(this[v + "fct"]);
						}(String(param)));
					} else if (param.@source=="static") {
						(function(v : String) : void {
							this[v + "fct"] = function() : Object {
								return this.staticValues[v];
							}
							caller.staticParameters.push(this[v + "fct"]);
						}(String(param)));
					}
				}
		
				
				// Assigning default paging options
				if (Boolean(String(remote.ispaged))) {
					DistantPagedCaller(caller).currentPage = 0;
					DistantPagedCaller(caller).maxItemsPerPage = (remote.paging.maxitemsperpage==null?100:Number(remote.paging.maxitemsperpage));
					DistantPagedCaller(caller).currentFilter = String(remote.paging.filter);
					DistantPagedCaller(caller).currentOrderBy = String(remote.paging.orderby);
					DistantPagedCaller(caller).desc = (remote.paging.desc==null?false:String(remote.paging.desc)=="true");
					DistantPagedCaller(caller).remoteCounter = remote.paging.remotecount;
				}
				
				// Registering caller
				remoteObjectsCallers[String(remote.name)] = caller;
			}
		}
		// REMOTE CONTROLS INITIALIZER
		/**
		 * Handle successful read of the static-lists.xml file.<BR/>
		 * It will trigger the parsing of the file content.
		 * @param The read event
		 */
		public function onXmlLoadedForStaticItems(event : Event) : void {
			staticItemsConfiguration = new XML(event.target.data);
			buildCaches(false);
		}
		
		/**
		 * Uses the content of the static-lists.xml file to generate the cached items
		 */
		public function buildCaches(userDependentCaches : Boolean) : void {
			cacheHelpers.filterFunction = null;
			if (cacheHelpers.length==0) {
			
				// Building the cache helpers if needed
				for each (var cache : XML in staticItemsConfiguration.caches.cache) {
					var cacheHelper : CacheHelper = new CacheHelper(cache.@label);
					cacheHelper.label = cache.@label;
					cacheHelper.field = cache.@field;
					cacheHelper.remote = cache.@remote;
					cacheHelper.source = cache.@source;
					cacheHelper.resource = cache.@resource;
					cacheHelper.resourceId = cache.@resourceId;
					cacheHelper.target = cache.@target;
					cacheHelper.todo = 1;
					cacheHelper.description = cache.@description;
					cacheHelper.sourceField = cache.@sourceField;
					cacheHelper.userDependent = String(cache.@userDependent)=="true";
					
					cacheHelper.addEventListener("CacheLoadedEvent",this.handleCacheLoadedEvent);
					cacheHelpers.addItem(cacheHelper);
				}
			}
			// Add the all cache items populated event handler
			if (userDependentCaches) {
				this.addEventListener("AllCacheItemsLoadedEvent",this.handleAllCacheItemsUserDependentLoadedEvent); 
			} else {
				this.addEventListener("AllCacheItemsLoadedEvent",this.handleAllCacheItemsLoadedEvent);
			}
			cacheHelpers.filterFunction = function(item : Object) : Boolean {
				return item.userDependent==userDependentCaches;
			};
			cacheHelpers.refresh();
			// Getting cache items lenght
			awaitedCachedItems = cacheHelpers.length;
			// If there is no cache item to load
			if (awaitedCachedItems==0) {
				dispatchEvent(new Event("AllCacheItemsLoadedEvent"));
			} else {
				loadedCachedItems = 0;
				cacheLoaderWindow.data = cacheHelpers;
				cacheLoaderWindow.title = "Loading cache...";
				PopUpManager.addPopUp(cacheLoaderWindow,DisplayObject(FlexGlobals.topLevelApplication),true);
				PopUpManager.centerPopUp(cacheLoaderWindow);
				doCachePopulation(loadedCachedItems);
				cacheLoaderWindow.closeButton.visible = false;
			}
		}
		
		/**
		 * Handles the chain of calls that will populate the cache.
		 * @param The current index in the chain of calls
		 */
		private function doCachePopulation(index : Number) : void {
			var cacheHelper : CacheHelper = CacheHelper(cacheHelpers.getItemAt(index));
			var valueArray : Array;
			var value : Object;
			if (cacheHelper.remote!=null && cacheHelper.remote!="") {
				DistantCaller(this.getRemoteObjectsCallers()[cacheHelper.remote]).addHandler(cacheHelper,cacheHelper.handleCacheResponse,cacheHelper.handleCacheFault);
			}
			if (cacheHelper.source!=null && cacheHelper.source!="") {
				
				value = ObjectsUtility.getObjectFieldValue(this.caches[cacheHelper.source],cacheHelper.sourceField);
				if (value is Array || value is ArrayCollection) {
					cacheHelper.append = true;
					cacheHelper.todo = value.length;
					for each(var v : Object in value) {
						valueArray = new Array().concat(v);
						DistantCaller(this.getRemoteObjectsCallers()[cacheHelper.remote]).call(valueArray,true);
					}
					DistantCaller(this.getRemoteObjectsCallers()[cacheHelper.remote]).dispatchEvent(new Event("CacheLoadedEvent"));
				} else {
					// Single value cache item
					valueArray = new Array(value);
					DistantCaller(this.getRemoteObjectsCallers()[cacheHelper.remote]).call(valueArray);
				}
			} else if (cacheHelper.resource!=null && cacheHelper.resource!="") {
				value = this.caches[cacheHelper.resource];
				cacheHelper.append = true;
				cacheHelper.todo = value.length;
				var target : Object = (getDefinitionByName(cacheHelper.target)).getInstance();
				for each(var r : Object in value) {
					cacheHelper.loadResource(ObjectsUtility.getObjectFieldValue(r,cacheHelper.field).toString(),ObjectsUtility.getObjectFieldValue(r,cacheHelper.resourceId).toString(),IResourceProvider(target));
				}
			} else {
				// No other cache source
				DistantCaller(this.getRemoteObjectsCallers()[cacheHelper.remote]).call(null);
			}
		}
		
		/**
		 * Loads icons from the asset repository (not embedded in the FLASH file)
		 */
		private function buildIconsSets() : void {
			var provider : IconsProvider = IconsProvider.getInstance();
			for each (var iconSet : XML in staticItemsConfiguration.icons.iconset) {
				var source : Object;
				if (String(iconSet.@source)=="cache") {
					source = this.caches[iconSet.@sourceName];
				}
				// TODO Implement other sources
				if (source is Array || source is ArrayCollection) {
					for each(var item : Object in source){
						provider.loadAndAddIcon(item, iconSet.@labelField, iconSet.@iconField,Number(String(iconSet.@size)));
					}
				} else {
					provider.loadAndAddIcon(source, iconSet.@labelField, iconSet.@iconField,Number(String(iconSet.@size)));
				}
			}
		}

		/**
		 * Use the content of the static-lists.xml to populate the constant (lists, items ...)
		 */
		private function buildStaticListsAndValues() : void {
			for each (var values : XML in staticItemsConfiguration.lists.values) {
				staticLists[values.@label] = new Array();
				if (String(values.@source)=="value") {
					var valueClass : Class = null;
					if (String(values.@type)!="") {
						valueClass = getDefinitionByName(values.@type) as Class;
					}
					var transformationString : String = String(values.@transform)==""?null:String(values.@transform);
					for each (var value : XML in values.value) {
						var item : StaticItem = new StaticItem();
						item.label = String(value.label);
						if (String(value.data)=="null") {
							item.value = null;
						} else {
							if (valueClass!=null) {
								item.value = valueClass(String(value.data));
							} else if (transformationString!=null) {
								item.value = ObjectsUtility.applyConverter(transformationString,String(value.data));
							} else {
								item.value = String(value.data);
							}
						}
						if (value.selected!=null && String(value.selected)=="true") {
							item.selected = true;
						}
						(staticLists[values.@label] as Array).push(item);
					}
				} else if (String(staticLists[values.@source])=="remote") {
					// TODO Implement me
				}
			}
			
			for each (var singleValue : XML in staticItemsConfiguration.singlevalues.value) {
				if (String(singleValue.@type)!="") {
					this.staticValues[String(singleValue.@name)] = getDefinitionByName(String(singleValue.@type))(singleValue);
				} else {
					this.staticValues[String(singleValue.@name)] = singleValue.toString();
				}
			}
			
			CursorManager.removeAllCursors();
		}
		
		/**
		 * Handles the event that indicates that all items, depending on the user, of the cache have been loaded.
		 * @param The all items loaded event
		 */
		private function handleAllCacheItemsUserDependentLoadedEvent(event : Event) : void {
			this.removeEventListener("AllCacheItemsLoadedEvent",this.handleAllCacheItemsUserDependentLoadedEvent);
			PopUpManager.removePopUp(cacheLoaderWindow);
			this.computeDisplayFunction();
		}
		
		
		/**
		 * Handles the event that indicates that all items of the cache have been loaded.
		 * @param The all items loaded event
		 */
		private function handleAllCacheItemsLoadedEvent(event : Event) : void {
			this.removeEventListener("AllCacheItemsLoadedEvent",this.handleAllCacheItemsLoadedEvent);
			buildStaticListsAndValues();
			buildIconsSets();
			xmlLoaderForApplicationContent.addEventListener(Event.COMPLETE,onXmlLoadedForApplicationContent);
			xmlLoaderForApplicationContent.load(new URLRequest(applicationContentList));
			PopUpManager.removePopUp(cacheLoaderWindow);
		}

		/**
		 * Handles the event that indicates that one item of the cache has been loaded.
		 * @param The item loaded event
		 */
		public function handleCacheLoadedEvent(event : Event) : void {
			var cacheHelper : CacheHelper = cacheHelpers[loadedCachedItems];
			cacheHelper.removeEventListener("CacheLoadedEvent",this.handleCacheLoadedEvent);
			loadedCachedItems = loadedCachedItems + 1;
			if (awaitedCachedItems==loadedCachedItems) {
				dispatchEvent(new Event("AllCacheItemsLoadedEvent"));
			} else {
				doCachePopulation(loadedCachedItems);
			}
		}
		
		/**
		 * Handle successful read of the application-content.xml file.<BR/>
		 * It will trigger the parsing of the file content.
		 * @param The read event
		 */		
		private function onXmlLoadedForApplicationContent(event : Event) : void {
			applicationContentConfiguration = new XML(event.target.data);
			readDisplayContentFromApplicationXML();
			readFormsFromApplicationXML();
		}
		
		/**
		 * Uses the content of the application-content.xml file to create and declare the forms of the application.
		 */
		private function readFormsFromApplicationXML() : void {
			for each (var form : XML in applicationContentConfiguration.forms.form) {
				var formClass : Class = getDefinitionByName(form.@type.toString()) as Class;
				var formInstance : IFormView = new formClass(form.@name);
				formInstance.buildFromXML(form);
				forms[form.@name] = formInstance;
			}
		}
		
		/**
		 * Uses the content of the application-content.xml file to create and declare the views of the application.
		 */
		private function readDisplayContentFromApplicationXML() : void {

			// Read security arguments
			var securityModel : String = String(applicationContentConfiguration.contents.@security);
			
			if (securityModel=="") {
				securityModel = null;
			}
			// Find security model if available
			if (securityModel!=null) {
				securityClass = getDefinitionByName(securityModel) as Class;
			}
			
			// Style the application
			StylesList.applyStyle(StylesList.FontRelated, applicationContentConfiguration[0], UIComponent(FlexGlobals.topLevelApplication));
			
			// Create display function
			computeDisplayFunction = function() : void {
				
				// Instanciate views
				for each (var view : XML in applicationContentConfiguration.views.view) {
					var viewClass : Class = getDefinitionByName(view.@type.toString()) as Class;
					var viewInstance : XMLGroup = new viewClass();
					
					// Registering current view instance
					views[view.@id] = viewInstance;
					
					viewInstance.percentHeight = 100;
					viewInstance.percentWidth = 100;
					viewInstance.populateWithXML.call(viewInstance,view);
				}
				
				if (applicationContentConfiguration.contents.@layout=="tabbed") {
					navigator = new TabNavigator();
					StylesList.applyStyle(StylesList.TabNavigator,applicationContentConfiguration.contents[0], navigator);
				}
				navigator.percentHeight = 100;
				navigator.percentWidth = 100;
				
				var authorizedWindows : Number = 0;
				// Instanciate the Windows
				for each (var container : XML in applicationContentConfiguration.contents.content) {
					
					var securityInstance : ISecurityModel = new securityClass();
					securityInstance.setSecurityToken(container.@securityToken);
					if (securityInstance.isAuthorized()) {
						var navigatorContent : NavigatorContent;
						
						var layoutContainerClass : Class = getDefinitionByName(container.@type) as Class;
						
						navigatorContent = new layoutContainerClass();
						navigatorContent.label = container.@label;
						navigatorContents[container.@id] = navigatorContent;
						
						StylesList.applyStyle(StylesList.FontRelated, container[0],navigatorContent);
						for each(var contentParameter : XML in container.parameter) {
							// TODO Implement type management
							navigatorContent[contentParameter.@name] = contentParameter.@value; 
						}
						navigator.addChild(navigatorContent);
						
						authorizedWindows++;
					}
				}
				FlexGlobals.topLevelApplication.applicationCanvas.addChild(navigator);
				
				if (authorizedWindows==0) {
					Alert.show("You are not authorized to use that application!","Security warning");
				}
			}

			var globalSecurityInstance : ISecurityModel = new securityClass();

			if (globalSecurityInstance.needsLoginPasswordPrompt()) {
				loginWindow = LoginPasswordTitleWindow(PopUpManager.createPopUp(Application(FlexGlobals.topLevelApplication),LoginPasswordTitleWindow,true));
				loginWindow.loginFunction = globalSecurityInstance.checkLoginPassword;
				loginWindow.icon = globalSecurityInstance.getLoginButtonIcon();
				loginWindow.title = globalSecurityInstance.getLoginWindowTitle();
				PopUpManager.centerPopUp(loginWindow);
			} else {
				buildCaches(true);
			}
		}
		
		// GETTERS / SETTERS

		public function isCurrentUserMemberOf(groups : String) : Boolean {
			
			if (securityClass!=null) {
				var securityModel : ISecurityModel = new securityClass();
				securityModel.setSecurityToken(groups);
				return securityModel.isAuthorized();
			}
			
			return true;
		}
		
		/**
		 * Add a view helper to the list of view helpers.
		 * @param The view helper to add
		 */
		public function registerViewHelper(helper : AbstractHelper) : void {
			associatedViewHelpers.addItem(helper);
		}
		
		/**
		 * Change to the currently displayed window.
		 * @param New window id
		 */
		public function setCurrentWindow(windowId : String) : void {
			if (navigator is TabNavigator) {
				TabNavigator(navigator).selectedChild = navigatorContents[windowId];
			}
		}
		
		/**
		 * Get the list of remote object (HTTP or Remote Object).
		 */
		public function getRemoteObjectsRepository() : Array {
			return remoteObjectsRepository;
		}
		
		/**
		 * Get the list of remote object (HTTP or Remote Object).
		 */
		public function getRemoteObjectsCallers() : Array {
			return remoteObjectsCallers;
		}
		
		/**
		 * Extract the data or a data subset from a cached item.<BR/>
		 * If the cached item is a list (Array or ArrayCollection), the <code>matchingValue</code> is used to determine the matching items(s).<BR/>
		 * If there is more than one matching items, the first item is returned.<BR/>
		 * <B>This has to be refactored.</B>
		 * @param The cached item id
		 * @param The field subset ("" to get the full object)
		 * @param Optional: The matching value, if present the field subset is used as matching field. 
		 */
		public function getObjectValueFromCache(cacheId : String, field : String, matchingValue : Object = null) : Object {
			if (caches[cacheId]!=null) {
				if (caches[cacheId] is Array || caches[cacheId] is ArrayCollection) {
					var ac : ArrayCollection = ObjectsUtility.getObjectsListWithMatch(caches[cacheId] is Array?new ArrayCollection(caches[cacheId]):caches[cacheId],field, matchingValue);
					if (ac!=null && ac.length>0) {
						return ac.getItemAt(0);
					}					
				} else {
					return ObjectsUtility.getObjectFieldValue(caches[cacheId],field);
				}
			}
			return null;
		}
		
		/**
		 * Extract a list of data or a data subset from a cached item.<BR/>
		 * The cached item must be a list (Array or ArrayCollection), the <code>matchingValue</code> in <code>field</code> is used to determine the matching items(s).<BR/>
		 * <B>This has to be refactored.</B>
		 * @param The cached item id
		 * @param The matching field
		 * @param The matching value 
		 */
		public function getObjectValuesFromCache(cacheId : String, field : String, matchingValue : Object = null) : ArrayCollection {
			if (caches[cacheId]!=null) {
				if (caches[cacheId] is Array || caches[cacheId] is ArrayCollection) {
					return ObjectsUtility.getObjectsListWithMatch(caches[cacheId],field, matchingValue);
				}
			}
			return null;
		}
			
	}
}