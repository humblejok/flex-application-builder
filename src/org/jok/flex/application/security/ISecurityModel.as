package org.jok.flex.application.security
{
	import mx.collections.ArrayCollection;

	public interface ISecurityModel {
		
		function setSecurityToken(st : String) : void;
		function isAuthorized() : Boolean;
		function needsLoginPasswordPrompt() : Boolean;
		function checkLoginPassword(login : String, password : String) : void;
		function getLoginButtonIcon() : Class;
		function getLoginWindowTitle() : String;
		function getGroups() : ArrayCollection;
	}
}