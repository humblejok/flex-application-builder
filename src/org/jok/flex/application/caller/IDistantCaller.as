package org.jok.flex.application.caller
{
	/**
	 * Interface that defines what is required to be a distant caller. 
	 * @author sdj
	 * 
	 */
	public interface IDistantCaller {
		
		/**
		 * Executes the distant call with the given arguments.
		 * @param args The arguments
		 * @return TRUE is the call could be made.
		 */
		function callMe(args : Array) : Boolean;
		
	}
}