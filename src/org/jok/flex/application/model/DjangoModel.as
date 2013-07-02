package org.jok.flex.application.model
{
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	
	import org.granite.meta;
	import org.jok.flex.utility.python.JSonPythonConverter;

	[Bindable]
	public class DjangoModel {
		
		public function DjangoModel() {
		}
		
		public function populateFromDjangoJSONObject(o : Object) :  DjangoModel {
			var description : Object = describeType(getDefinitionByName(getQualifiedClassName(this)));
			var packageName : String = String(description.@name).substr(0,String(description.@name).indexOf(":"));
			trace("Working on package " + packageName + " and class " + getQualifiedClassName(this));
			for each (var field : XML in description.factory.accessor) {
				var name : String = field.@name;
				var type : String = field.@type;
				trace("Working on field " + name + " with type " + type);
				if (type=="Date") {
					trace("\tUsing target type:" + type);
					this[name] = new JSonPythonConverter().convertHTTPRequestDateToDate(o.fields[name]);
				} else if (type=="mx.collections::ArrayCollection") {
					var targetType : String = "Object";
					for each(var metaData : XML in field.metadata) {
						if (metaData.@name=="ArrayElementType") {
							targetType = String(metaData.arg.@value);
						}
					}
					trace("\tUsing target type:" + targetType);
					for each(var so : Object in (o.fields[name] as Array)) {
						var clazz : Class = Class(getDefinitionByName(targetType));
						var instance : DjangoModel = new clazz();
						instance.populateFromDjangoJSONObject(so);
						(this[name] as ArrayCollection).addItem(instance);
					}
				} else if (type=="Number" || type=="String" || type=="Boolean") {
					trace("\tUsing target type:" + type);
					this[name] = o.fields[name];
				}
			}
			return this;
		}
	}
}