package org.jok.flex.application.parameters
{
	import mx.core.UIComponent;

	public class StylesList {
		
		public static var TabNavigator : Array = new Array(
			"accentColor",
			"backgroundAlpha",
			"backgroundAttachment",
			"backgroundColor",
			"borderAlpha",
			"borderColor",
			"borderSkin",
			"borderStyle",
			"borderVisible",
			"chromeColor",
			"color",
			"contentBackgroundAlpha",
			"contentBackgroundColor",
			"cornerRadius",
			"direction",
			"disabledColor",
			"disabledOverlayAlpha",
			"dropShadowVisible",
			"errorColor",
			"fillColor",
			"fillColors",
			"firstTabStyleName",
			"focusAlpha",
			"focusColor",
			"focusRounderCorners",
			"fontAntiAliasType",
			"fontFamily",
			"fontGridFitType",
			"fontSharpness",
			"fontSize",
			"fontStyle",
			"fontThichness",
			"fontWeight",
			"horizontalAlign",
			"horizontalGap",
			"kerning",
			"lastTabStyleName",
			"layoutDirection",
			"letterSpacing",
			"locale",
			"paddingBottom",
			"paddingLeft",
			"paddingRight",
			"paddingTop",
			"selectedTabTextStyleName",
			"symbolColor",
			"tabHeight",
			"tabOffset",
			"tabStyleName",
			"tabWidth",
			"textAlign",
			"textDecoration",
			"textFieldClass",
			"textIndent");
		
		public static var AlignmentRelated : Array = new Array(
			"textAlign",
			"verticalAlign",
			"horizontalAlign"
		);
		
		public static var FontRelated : Array = new Array(
			"fontAntiAliasType",
			"fontFamily",
			"fontGridFitType",
			"fontSharpness",
			"fontSize",
			"fontStyle",
			"fontThichness",
			"fontWeight",
			"color"
			);
		
		public static function applyStyle(styles : Array, source : XML, target : UIComponent) : void {
			for each(var s : String in styles) {
				if (String(source.@[s])!=null && String(source.@[s])!="") {
					target.setStyle(s,String(source.@[s]));
				}
			}
		}
	}
}