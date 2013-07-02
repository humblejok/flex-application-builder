package org.jok.flex.application.security
{
	import com.eim.utility.ldap.model.LDAPUserInformation;
	
	import mx.collections.ArrayCollection;
	
	import org.jok.flex.application.controller.ApplicationController;

	public class LDAPGroupSecurityImpl implements ISecurityModel {
		
		private var authorizedGroupsList : ArrayCollection = null;
		
		public function LDAPGroupSecurityImpl() {
		}
		
		public function setSecurityToken(st : String) : void {
			if (st==null || st=="null") {
				authorizedGroupsList = null;
			} else {
				authorizedGroupsList = new ArrayCollection(st.split(/,/));
			}
		}
		
		public function isAuthorized() : Boolean {
			var controller : ApplicationController = ApplicationController.getInstance();
			var currentUser : LDAPUserInformation = controller.caches[ApplicationController.CURRENT_USER_SECURITY_DESCRIPTION];
			if (authorizedGroupsList==null) {
				return true;
			} else {
				for each(var g : String in authorizedGroupsList) {
					if (currentUser.groups.contains(g)) {
						return true;
					}
				}
			}
			return false;
		}
		
		public function needsLoginPasswordPrompt() : Boolean {
			return false;
		}
		
		public function checkLoginPassword(login : String, password : String) : void {
			// Nothing
		}
		
		public function getLoginButtonIcon() : Class {
			return null;
		}
		
		public function getLoginWindowTitle() : String {
			return null;
		}
		
		public function getGroups() : ArrayCollection {
			return authorizedGroupsList;
		}
		
	}
}