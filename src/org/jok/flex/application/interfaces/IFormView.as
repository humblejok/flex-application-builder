package org.jok.flex.application.interfaces
{
	import org.jok.flex.application.helper.AbstractHelper;

	public interface IFormView {
		
		function buildFromXML(content : XML) : void;
		
		function getFormViewHelper() : IFormViewHelper;
		
		function set data(d : Object) : void;
		function get data() : Object;
		function set editMode(b : Boolean) : void;
		function get editMode() : Boolean;
	}
}