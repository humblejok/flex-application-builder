package org.jok.flex.application.security
{
	import de.aggro.utils.CookieUtil;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.managers.CursorManager;
	import mx.managers.PopUpManager;
	
	import org.jok.flex.application.controller.ApplicationController;
	import org.jok.flex.application.helper.AbstractHelper;
	import org.jok.flex.application.model.FaultToken;
	import org.jok.flex.application.model.RemoteHandlerDescription;
	
	public class DJangoSecurityImpl implements ISecurityModel {
		
		private var controller : ApplicationController = ApplicationController.getInstance();
		
		public function DJangoSecurityImpl() {
		}
		
		public function setSecurityToken(st : String) : void {
			
		}
		
		public function isAuthorized():Boolean {
			return true;
		}
		
		public function needsLoginPasswordPrompt():Boolean {
			return true;
		}
		
		public function checkLoginPassword(login : String, password : String):void {
			var csrfToken : String = CookieUtil.getCookie("csrftoken").toString();
			new AbstractHelper("DJANGO_LOGIN").callDjangoRemote("userLogin", null, onLoginCallSuccess, onLoginCallFault, csrfToken, login, password);
		}
		
		public function onLoginCallSuccess(result : Object, handler : RemoteHandlerDescription = null) : void {
			CursorManager.removeAllCursors();
			trace("Login response ok");
			var user : Object = (result as ArrayCollection).getItemAt(0);
			controller.caches[ApplicationController.CURRENT_USER_LOGIN] = user.fields.username;
			controller.caches[ApplicationController.CURRENT_USER_ID] = user.pk;
			controller.caches[ApplicationController.CURRENT_USER_PROFILE] = user;
			controller.caches[ApplicationController.CURRENT_USER_SECURITY_DESCRIPTION] = user;
			PopUpManager.removePopUp(controller.loginWindow);
			controller.buildCaches(true);
		}
		
		public function onLoginCallFault(fault : FaultToken, handler : RemoteHandlerDescription = null) : void {
			trace("Login response failed");
			CursorManager.removeAllCursors();
			Alert.show("Login/password could not be checked!","Security warning");
		}
		
		public function getLoginButtonIcon():Class {
			return null;
		}
		
		public function getLoginWindowTitle() : String {
			return "Login";
		}
		
		public function getGroups():ArrayCollection
		{
			return null;
		}
	}
}