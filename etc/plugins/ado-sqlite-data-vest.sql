/**
  This SQL script adds data, used by the plugin Vest in an 
  existing ado.sqlite database.
  The following pragmas must be already set by DSC plugin
  PRAGMA encoding = "UTF-8"; 
  PRAGMA foreign_keys = ON;
*/

/**
  To use any of the applications or widgets that come with this plugin,
  an Ado user needs to be in the group 'vest'. Being in that group a user can
  search for other users, belonging to the same group and add them to his
  own contacts.
  Each user will have his own group vest_contacts_$username and his contacts
  will be members of that group.
  A user can be added to the group 'vest' on the command line or programatically
  using the Ado command adduser.
  See http://localhost::3000/perldoc/Ado/Command/adduser
*/
INSERT INTO groups (name,description,created_by,changed_by,disabled)
VALUES ('vest','Group for all users that use the Ado::Plugin::Vest services',1,1,0);