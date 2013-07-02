package org.jok.flex.application.model
{
	import mx.rpc.events.FaultEvent;
	
	/**
	 * Fault token model.
	 *  
	 * @author sdj
	 * 
	 */
	public class FaultToken
	{
		public var faultCall : String;
		public var faultEvent : FaultEvent;
		
		public function FaultToken() {
		}

	}
}