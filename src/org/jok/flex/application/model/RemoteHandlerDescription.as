package org.jok.flex.application.model
{
	import org.jok.flex.application.helper.AbstractHelper;

	public class RemoteHandlerDescription {
		public var helper : AbstractHelper;
		public var destinationId : String;
		public var handlingFunction : Function;
		public var faultFunction : Function;
	}
}