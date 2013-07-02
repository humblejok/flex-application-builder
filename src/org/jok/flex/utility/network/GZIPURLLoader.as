package org.jok.flex.utility.network
{
	import com.probertson.utils.GZIPBytesEncoder;
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	import flash.xml.XMLNode;
	import flash.xml.XMLNodeType;
	
	import mx.rpc.http.HTTPService;
	
	import org.jok.flex.utility.python.JSonPythonConverter;
	
	/**
	 * URL Loader that manages GZIP stream, code is inspired/copied from:
	 * http://www.skinkers.com/2010/09/02/adding-gzip-support-for-flexair-httpservice-urlloader/
	 */
	public class GZIPURLLoader extends EventDispatcher {
		
		/** Format string used to set the value of <code>resultFormat</code>. Indicates the result should be e4x XML */
		public static const FORMAT_E4X:String="e4x";
		/** Format string used to set the value of <code>resultFormat</code>. Indicates the result should be e4x XML */
		public static const FORMAT_JSON:String="json";
		/** Format string used to set the value of <code>resultFormat</code>. Indicates the result should be AS XML Nodes*/
		public static const FORMAT_XML:String="xml";
		/** Format string used to set the value of <code>resultFormat</code>. Indicates the result should be simple text*/
		public static const FORMAT_TEXT:String="text";
		/** Format string used to set the value of <code>resultFormat</code>. Indicates the result should be a AS Object*/
		public static const FORMAT_OBJECT:String="object";
		
		public var resultFormat : String = "";
		
		private var _loader : URLLoader;
		
		public function GZIPURLLoader( url : String, resultFormat : String = FORMAT_JSON) {
			super();
			var request : URLRequest = new URLRequest(url);
			request.contentType = HTTPService.CONTENT_TYPE_FORM;
			request.method = URLRequestMethod.POST;
			request.requestHeaders = [new URLRequestHeader('Accept-Encoding', 'gzip')];
			
			this.resultFormat = resultFormat;
			
			_loader = new URLLoader(request);
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, onLoadComplete);
		}
		
		private function onLoadComplete(event : Event) : void {
			if (loader.data is ByteArray) {
				var buffer : ByteArray = loader.data as ByteArray;
				
				try {
					var decoder : GZIPBytesEncoder = new GZIPBytesEncoder();
					loader.data = decoder.uncompressToByteArray(buffer).toString();
				} catch(e : IllegalOperationError) {
					// Bad format, the data are not gunzipped
					trace("The data are serialized using plain text or binary format!")
					buffer.position = 0;
					loader.data = buffer.readUTFBytes(buffer.length);
				}
				
				// Formatting the unzipped data
				switch( resultFormat ) {
					case FORMAT_XML:
						loader.data = new XMLNode(XMLNodeType.ELEMENT_NODE, loader.data);
						break;
					case FORMAT_E4X:
						loader.data = new XML(loader.data);
						break;
					case FORMAT_JSON:
					case FORMAT_TEXT:
						loader.data = loader.data.toString();
						break;
					default:
				}
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		
		public function get loader(): URLLoader {
			return _loader;
		}
		
		public function get data() : Object {
			return loader.data;
		}
		
	}
	
	
}