package org.jok.flex.application.caller
{
	/**
	 * NOT YET IMPLEMENTED 
	 * @author sdj
	 * 
	 */
	public class DistantPagedCaller extends DistantCaller {
		
		public var currentPage : uint = 0;
		public var maxItemsPerPage : uint = 100;
		public var currentFilter : String = "";
		public var currentOrderBy : String = "";
		public var desc : Boolean = false;
		public var remoteCounter : String = null;
		public var maxPages : uint = 0;
		public var maximumItems : uint = 0;
		
		public function DistantPagedCaller(calledObjectName : String, calledMethod : String = "send") {
			super(calledObjectName,calledMethod);
		}
	}
}