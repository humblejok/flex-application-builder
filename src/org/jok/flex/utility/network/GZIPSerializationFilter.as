package org.jok.flex.utility.network
{
	import com.anirudh.rpc.DirectHTTPBinaryChannel;
	import com.probertson.utils.GZIPBytesEncoder;
	
	import flash.errors.IllegalOperationError;
	import flash.utils.ByteArray;
	
	import mx.messaging.ChannelSet;
	import mx.rpc.http.AbstractOperation;
	import mx.rpc.http.SerializationFilter;
	
	/**
	 * GZIP Serialization handler for HTTPService modification, code is inspired/copied from:
	 * http://www.skinkers.com/2010/09/02/adding-gzip-support-for-flexair-httpservice-urlloader/
	 */
	public class GZIPSerializationFilter extends SerializationFilter {
		
		private static var instance : GZIPSerializationFilter;
		private static var channelSet : ChannelSet;
		
		/**
		 * PRIVATE Constructor, do not use, this is a singleton
		 */
		public function GZIPSerializationFilter() {
			super();
		}
		
		public static function getInstance() : GZIPSerializationFilter {
			if (instance==null) {
				instance = new GZIPSerializationFilter();
			}
			return instance;
		}
		
		public static function getChannelSet() : ChannelSet {
			if (channelSet==null) {
				channelSet = new ChannelSet();
				channelSet.addChannel(new DirectHTTPBinaryChannel("gzip_http_channel"));
			}
			return channelSet;
		}
		
		override public function deserializeResult(operation : AbstractOperation, result : Object) : Object {
			if (result is ByteArray) {
				var buffer : ByteArray = result as ByteArray;
				try {
					var decoder : GZIPBytesEncoder = new GZIPBytesEncoder();
					result = decoder.uncompressToByteArray(buffer).toString();
				} catch (e : IllegalOperationError) {
					buffer.position = 0;
					result = buffer.readUTFBytes(buffer.length);
				}
			}
			return result;
		}
	}
}