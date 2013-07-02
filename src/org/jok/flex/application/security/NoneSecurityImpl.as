package org.jok.flex.application.security
{
	import mx.collections.ArrayCollection;

	public class NoneSecurityImpl implements ISecurityModel
	{
		public function NoneSecurityImpl() {
		}
		
		public function setSecurityToken(st : String) : void {
		}
		
		public function isAuthorized() : Boolean {
			return true;
		}
		
		public function needsLoginPasswordPrompt() : Boolean {
			return false;
		}
		
		public function checkLoginPassword(login:String, password:String) : void {
		}
		
		public function getLoginButtonIcon() : Class {
			return null;
		}
		
		public function getLoginWindowTitle() : String {
			return null;
		}
		
		public function getGroups() : ArrayCollection {
			return new ArrayCollection();
		}
	}
}