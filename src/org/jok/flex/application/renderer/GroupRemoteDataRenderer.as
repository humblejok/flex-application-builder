package org.jok.flex.application.renderer
{
	import org.jok.flex.application.interfaces.IFormViewHelper;
	import org.jok.flex.application.interfaces.IRemoteDataRenderer;
	
	import spark.components.Group;
	
	public class GroupRemoteDataRenderer extends Group implements IRemoteDataRenderer {
		
		[Bindable]
		public var data : Object;
		
		protected var helper : IFormViewHelper;
		protected var remoteLabel : String;
		protected var remoteLabelField : String;
		protected var remoteFeeder : String;
		protected var remoteFeederField : String;
		protected var remoteFeederLabelField : String;
		
		public function GroupRemoteDataRenderer() {
			super();
		}
		
		public function initializeWithRemote( helper : IFormViewHelper,	data : Object, field : XML) : void {
			this.helper = helper;
			this.data = data;
			this.remoteLabel = String(field.@remoteLabel); 
			this.remoteLabelField = String(field.@remoteLabelField); 
			this.remoteFeeder = String(field.@remoteFeeder);
			this.remoteFeederField = String(field.@remoteFeederField);
			this.remoteFeederLabelField = String(field.@remoteFeederLabelField);
		}
	}
}