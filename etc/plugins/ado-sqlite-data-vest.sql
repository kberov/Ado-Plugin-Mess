/**
  This SQL script adds data, used by the plugin Vest in an 
  existing ado.sqlite database.
  The following pragmas must be already set by DSC plugin
  PRAGMA encoding = "UTF-8"; 
  PRAGMA foreign_keys = ON;
*/

/**
  To use any of the applications or widgets that come with this plugin,
  an Ado user needs to be in the group 'vest'. This is checked in each route of this plugin and is implemented as an 'over' condition. Being in that group a user can
  search for other users, belonging to the same group and add them to his own contacts.
  
  A user can be added to the group 'vest' on the command line or programatically
  using the Ado command adduser.
  See http://localhost::3000/perldoc/Ado/Command/adduser
*/

INSERT OR IGNORE INTO groups (name,description,created_by,changed_by,disabled)
VALUES ('vest','Users in this group can use the Ado::Plugin::Vest services',1,1,0);

 -- add test1 and test2 to this group
INSERT OR IGNORE INTO user_group (user_id, group_id) 
  SELECT u.id, g.id FROM users u, groups g 
    WHERE u.login_name='test1' AND g.name='vest';

INSERT OR IGNORE INTO user_group (user_id, group_id) 
  SELECT u.id, g.id FROM users u, groups g 
    WHERE u.login_name='test2' AND g.name='vest';

/**
  To have a list of contacts a user needs a group named vest_contacts_$username. 
  To add a new contacts to his group of contacts a user needs to add users to vest_contacts_for_$username.
*/
INSERT OR IGNORE INTO groups (name,description,created_by,changed_by,disabled)
  SELECT 'vest_contacts_for_test1', 'Contacts of user test1', id, id,0 
    FROM users WHERE login_name='test1';
-- add test2 to vest_contacts_for_test1
INSERT OR IGNORE INTO user_group (user_id, group_id) 
  SELECT u.id, g.id FROM users u, groups g 
    WHERE u.login_name='test2' AND g.name='vest_contacts_for_test1';

INSERT OR IGNORE INTO groups (name,description,created_by,changed_by,disabled)
  SELECT 'vest_contacts_for_test2', 'Contacts of user test2', id, id,0 
    FROM users WHERE login_name='test1';
-- add test1 to vest_contacts_for_test2
INSERT OR IGNORE INTO user_group (user_id, group_id) 
  SELECT u.id, g.id FROM users u, groups g 
    WHERE u.login_name='test1' AND g.name='vest_contacts_for_test2';
