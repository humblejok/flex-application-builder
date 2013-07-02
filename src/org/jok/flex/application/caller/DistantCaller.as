package org.jok.flex.application.caller
{
	import flash.events.EventDispatcher;
	import flash.net.URLRequestHeader;
	import flash.sampler.getInvocationCount;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.rpc.remoting.RemoteObject;
	import mx.utils.StringUtil;
	
	import org.granite.meta;
	import org.granite.tide.Tide;
	import org.granite.tide.ejb.Context;
	import org.granite.tide.events.TideFaultEvent;
	import org.granite.tide.events.TideResultEvent;
	import org.jok.flex.application.caller.model.LazyLoad;
	import org.jok.flex.application.controller.ApplicationController;
	import org.jok.flex.application.helper.AbstractHelper;
	import org.jok.flex.application.interfaces.IJSONExternalizable;
	import org.jok.flex.application.model.FaultToken;
	import org.jok.flex.application.model.RemoteHandlerDescription;

	/**
	 * Utility class that permits "distant calls" meaning talking with servers outside of the Flash environment/sandbox. 
	 * @author sdj
	 * 
	 */
	public class DistantCaller extends EventDispatcher {

		/**
		 * Id of the called object
		 */
		public var calledObjectName : String;
		/**
		 * Name of the called method
		 */
		public var calledMethod : String;
		
		/**
		 * Application controller
		 */
		public var controller : ApplicationController = ApplicationController.getInstance();
		
		/**
		 * All static paramaters that will be applied to the method call
		 */
		public var staticParameters : Array = new Array();
		
		/**
		 * List of handlers linked to that call
		 */
		public var handlers : ArrayCollection = new ArrayCollection();
		
		/**
		 * Response data format (text, e4x, object, json,...)
		 */
		public var internalDataFormat : String = null;
		
		/**
		 * Class representing the result(s)
		 */
		public var resultsClass : Class;
		
		/**
		 * Field that stores the result(s)
		 */
		public var resultsField : String;
		
		/**
		 * Contains the list of items that will be read as lazy load items
		 */
		public var lazyLoads : ArrayCollection = new ArrayCollection();
		
		/**
		 * Queue mode status
		 */
		public var queuing : Boolean = false;
		
		/**
		 * Does that caller use Granite Tide feature (not fully implemented)
		 */
		public var useGraniteTide : Boolean = false;
		
		/**
		 * Defines the debug profiles URLs
		 */
		public var debugProfiles : Array = new Array();
		
		/**
		 * Defines the POST arguments list
		 */
		public var postArguments : Array = new Array();
		
		/**
		 * Constructor.
		 * 
		 * @param calledObjectName The id of the called object
		 * @param calledMethod The name of the called method
		 * 
		 */
		public function DistantCaller(calledObjectName : String, calledMethod : String = "send") {
			super();
			this.calledMethod = calledMethod;
			this.calledObjectName = calledObjectName;
		}
		
		/**
		 * Executes the distant call with the given arguments
		 * @param args The arguments
		 * @return TRUE is the call could be made.
		 * 
		 */
		public function call(args : Array, queuing : Boolean = false, csrfToken : String = null) : Boolean {
			var object : Object = controller.getRemoteObjectsRepository()[this.calledObjectName];
			this.queuing = queuing;
			if (object is HTTPService) {
				// Assign default URL
				var orgURL : String = this.calledMethod;
				// Check if debug profile is activated
				if (ApplicationController.getInstance().debugProfile!=null && ApplicationController.getInstance().debugProfile!="") {
					if (debugProfiles["Profile_" + ApplicationController.getInstance().debugProfile]!=null) {
						orgURL = debugProfiles["Profile_" + ApplicationController.getInstance().debugProfile];
					}
				}
				// Execute the effective call (using either the standard URL or the debug one)
				var newUrl : String = StringUtil.substitute(orgURL,args);
				if (HTTPService(object).method=="POST") {
					var arguments : Object = new Object();
					var index : Number = 0;
					for each(var a : String in postArguments) {
						arguments[a] = args[index];
						index++;
					}
					HTTPService(object).request = arguments;
				}
				if (csrfToken!=null) {
					HTTPService(object).headers["X-CSRFToken"] = csrfToken;
				}
				HTTPService(object).url = newUrl;
				HTTPService(object).send();
				return true;
			} else if (object is RemoteObject) {
				var remote : RemoteObject = RemoteObject(object);
				if (useGraniteTide) {
					if (args==null || args.length==0) {
						controller["tideContext"][RemoteObject(object).destination][this.calledMethod].apply(controller["tideContext"][RemoteObject(object).destination],new Array().concat(args).concat(this.onTideResultEvent,this.onTideFaultEvent));
					} else {
						controller["tideContext"][RemoteObject(object).destination][this.calledMethod].apply(controller["tideContext"][RemoteObject(object).destination],computeStaticParameters().concat(args).concat(this.onTideResultEvent,this.onTideFaultEvent));
					}

				} else {
					if (args==null || args.length==0) {
						remote[this.calledMethod].send.apply(object,computeStaticParameters());
					} else {
						RemoteObject(object)[this.calledMethod].send.apply(object,computeStaticParameters().concat(args));
					}
				}
				return true;
			}
			return false;
		}
		
		/**
		 * Create an array of parameters with the statics parameters
		 * @return The parameters array
		 */
		public function computeStaticParameters() : Array {
			var sp : Array = new Array();
			for each(var p : Object in staticParameters) {
				if (p is Function) {
					var f : Function = p as Function;
					var result : Object = f.call(ApplicationController.getInstance());
					sp.push(result);
				} else {
					sp.push(p);
				}
			}
			return sp;
		}
		
		
		/**
		 * Adds a handler, the handler is built in the method.
		 * @param helper
		 * @param handlingFunction
		 * @param faultFunction
		 * @param destinationId
		 * 
		 */
		public function addHandler( helper : AbstractHelper,handlingFunction : Function, faultFunction : Function, destinationId : String = null ) : void {
			var newHandler : RemoteHandlerDescription = new RemoteHandlerDescription();
			newHandler.helper = helper;
			newHandler.handlingFunction = handlingFunction;
			newHandler.faultFunction = faultFunction;
			newHandler.destinationId = destinationId;
			this.handlers.addItem(newHandler); 
		}
		
		/**
		 * Tide result event handler (not fully implemented)
		 */
		public function onTideResultEvent( event : TideResultEvent) : void {
			handleResultData(event.result);
		}
		
		/**
		 * Tide fault event handler (not fully implemented)
		 */
		public function onTideFaultEvent( event : TideFaultEvent) : void {
			var fault : FaultToken = new FaultToken();
			fault.faultCall = calledObjectName;
			//fault.faultEvent = event.;
			for each (var handler : RemoteHandlerDescription in handlers) {
				handler.faultFunction.call(handler.helper,fault,handler);
			}
			if (!queuing) {
				handlers.removeAll();
			}
		}
		
		
		/**
		 * Called when the distant is successful. It will warn the handlers.
		 * @param event The successful event
		 * 
		 */
		public function onResultEvent(event : ResultEvent) : void {
			trace("Getting results for: " + this.calledObjectName + "." + this.calledMethod);
			handleResultData(event.result);
		}

		/**
		 * Effective implementation of the result handler.
		 * @param The result data
		 * 
		 */
		private function handleResultData(result : Object) : void {
			// TODO Implement other format than JSON
			if (this.internalDataFormat!=null) {
				switch(this.internalDataFormat) {
					case "json":
						if (String(result)!=null && String(result)!="" && String(result).length>1) {
							result = JSON.parse(String(result));
							if (result is Array) {
								result = new ArrayCollection(result as Array);
							}
						} else {
							trace("Empty or invalid JSON result");
							result = null;
						}
						break;
					default:
						break;
				}
			} else {
				result = controller.getRemoteObjectsRepository()[calledObjectName][calledMethod].lastResult;
			}
			// Getting data
			if (this.resultsField!=null && this.resultsField!="") {
				result = result[this.resultsField];
			}
			// Casting result
			if (this.resultsClass!=null) {
				var castedResult : Object;
				if (result is Array) {
					// Converting array content
					var arrayResults : Array = new Array();
					for each(var resA : Object in result) {
						var tmpObjA : Object = new this.resultsClass();
						if (this.internalDataFormat=="json") {
							IJSONExternalizable(tmpObjA).populateFromJSON(resA);
						}
						arrayResults.push(tmpObjA);
					}
					castedResult = arrayResults;
				} else if (result is ArrayCollection) {
					// Converting collection content
					var arrayCollectionResults : ArrayCollection = new ArrayCollection();
					for each(var resAC : Object in result) {
						var tmpObjAC : Object = new this.resultsClass();
						if (this.internalDataFormat=="json") {
							IJSONExternalizable(tmpObjAC).populateFromJSON(resAC);
						}
						arrayCollectionResults.addItem(tmpObjAC);
					}
					castedResult = arrayResults;
				} else {
					// Direct object cast
					castedResult = this.resultsClass(result);
				}
				result = castedResult;
			}
			
			// Lazy loads data
			for each (var lazy : LazyLoad in lazyLoads) {
				lazy.target = result;
			}
			
			// Warn listeners
			for each (var handler : RemoteHandlerDescription in handlers) {
				handler.handlingFunction.call(handler.helper,result,handler);
			}
			
			// Disable handlers is there is no waiting queue
			if (!queuing) {
				handlers.removeAll();
			}
		}
		
		/**
		 * Called when the distant call is erroneous. It will warn the handlers.
		 * @param event The fault event
		 * 
		 */
		public function onFaultEvent(event : FaultEvent) : void {
			var fault : FaultToken = new FaultToken();
			fault.faultCall = calledObjectName;
			fault.faultEvent = event;
			for each (var handler : RemoteHandlerDescription in handlers) {
				handler.faultFunction.call(handler.helper,fault,handler);
			}
			if (!queuing) {
				handlers.removeAll();
			}
		}
		
		/**
		 * To string utility method 
		 * @return String version
		 * 
		 */
		public override function toString() : String {
			return "Caller for [" + calledObjectName + "] with method [" + calledMethod + "]"; 
		}
	}
}