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
-- Add the user Вест
INSERT OR IGNORE INTO `users` 
(group_id,login_name,login_password,first_name,last_name,email,description,created_by,changed_by,tstamp,reg_date,disabled) 
VALUES((SELECT g.id FROM groups g WHERE g.name='vest'),'vest',
  '9f1bd12057905cf4f61a14e3eeac06bf68a28e64',
'Application','Вест','vest@localhost',
'System user. Do not use!',
1,1,strftime('%s','now'),strftime('%s','now'),0);
INSERT OR IGNORE INTO user_group (user_id, group_id) 
  SELECT u.id, g.id FROM users u, groups g 
    WHERE u.login_name='vest' AND g.name='vest';

-- add test1 and test2 to this group
INSERT OR IGNORE INTO user_group (user_id, group_id) 
  SELECT u.id, g.id FROM users u, groups g 
    WHERE u.login_name='test1' AND g.name='vest';

INSERT OR IGNORE INTO user_group (user_id, group_id) 
  SELECT u.id, g.id FROM users u, groups g 
    WHERE u.login_name='test2' AND g.name='vest';

/**
  To have a list of contacts a user needs a group named vest_contacts_$id
  where $id == $user->id. 
  To add a new contacts to his group of contacts a user needs to add users to vest_contacts_$id.
*/
INSERT OR IGNORE INTO groups (name,description,created_by,changed_by,disabled)
  SELECT 'vest_contacts_'||id as name, 'Contacts of user test1', id, id,0 
    FROM users WHERE login_name='test1';
-- add test2 to vest_contacts_3
INSERT OR IGNORE INTO user_group (user_id, group_id)
VALUES(
  (SELECT id FROM users WHERE login_name='test2'), 
  (SELECT id FROM groups WHERE name='vest_contacts_'
    ||(SELECT id FROM users WHERE login_name='test1'))
);
INSERT OR IGNORE INTO groups (name,description,created_by,changed_by,disabled)
  SELECT 'vest_contacts_'||id, 'Contacts of user test2', id, id,0
    FROM users WHERE login_name='test2';

/**
 Translate some messages!
  INSERT OR IGNORE INTO i18n VALUES('bg','message key','lib/Path/To/File.pm:54,templates/controller/template.html.ep:12',
    'Преведен текст',0);

 */
INSERT OR IGNORE INTO i18n VALUES('en','Wellcome_have_a_chat','lib/Ado/Plugin/Vest.pm:54',
  'Wellcome [_1]! Click on the "[_2]" button to find users by name and have a chat.',0);
INSERT OR IGNORE INTO i18n VALUES('bg','Wellcome_have_a_chat','lib/Ado/Plugin/Vest.pm:54',
  'Добре дошли [_1]! Натиснете бутона "[_2]", за да намерите потребители по име и да си пишете.',0);
INSERT OR IGNORE INTO i18n VALUES('en','Search','templates/vest/contacts.html.ep:19',
  'Search',0);
INSERT OR IGNORE INTO i18n VALUES('en','Start talk witn [_1]','templates/vest/contacts.html.ep:50',
  'Start talk witn [_1]',0);
INSERT OR IGNORE INTO i18n VALUES('bg','Start talk witn [_1]','templates/vest/contacts.html.ep:50',
  'Започнете разговор с [_1]',0);
INSERT OR IGNORE INTO i18n VALUES('en','Continue talk','templates/vest/contacts.html.ep:56',
  'Continue talk',0);
INSERT OR IGNORE INTO i18n VALUES('bg','Continue talk','templates/vest/contacts.html.ep:56',
  'Продължаване на разговор',0);
INSERT OR IGNORE INTO i18n VALUES('en','Talks','templates/vest/menu.html.ep:14',
  'Talks',0);
INSERT OR IGNORE INTO i18n VALUES('bg','Talks','templates/vest/menu.html.ep:14',
  'Разговори',0);
INSERT OR IGNORE INTO i18n VALUES('en','Home','templates/vest/menu.html.ep:23',
  'Home',0);
INSERT OR IGNORE INTO i18n VALUES('bg','Home','templates/vest/menu.html.ep:23',
  'Начало',0);
INSERT OR IGNORE INTO i18n VALUES('en','Profile','templates/vest/menu.html.ep:24',
  'Profile',0);
INSERT OR IGNORE INTO i18n VALUES('bg','Profile','templates/vest/menu.html.ep:24',
  'За мен',0);
INSERT OR IGNORE INTO i18n VALUES('en','Signout','templates/vest/menu.html.ep:25',
  'Signout',0);
INSERT OR IGNORE INTO i18n VALUES('bg','Signout','templates/vest/menu.html.ep:25',
  'Отписване',0);
INSERT OR IGNORE INTO i18n VALUES('en','Contacts','lib/Ado/Plugin/Vest.pm:56,templates/vest/menu.html.ep:30',
  'Contacts',0);
INSERT OR IGNORE INTO i18n VALUES('bg','Contacts','lib/Ado/Plugin/Vest.pm:56,templates/vest/menu.html.ep:30',
  'Контакти',0);
INSERT OR IGNORE INTO i18n VALUES('en','Topik','templates/vest/messages.html.ep:12',
  'Topic',0);
INSERT OR IGNORE INTO i18n VALUES('bg','Topik','templates/vest/messages.html.ep:12',
  'Тема',0);
INSERT OR IGNORE INTO i18n VALUES('en','Message','templates/vest/messages.html.ep:30',
  'Message',0);
INSERT OR IGNORE INTO i18n VALUES('bg','Message','templates/vest/messages.html.ep:30',
  'Съобщение',0);
INSERT OR IGNORE INTO i18n VALUES('en','Submit','templates/vest/messages.html.ep:32',
  'Submit',0);
INSERT OR IGNORE INTO i18n VALUES('bg','Submit','templates/vest/messages.html.ep:32',
  'Изпращане',0);
INSERT OR IGNORE INTO i18n VALUES('en','Messaging services for an Ado system!','templates/vest/head.html.ep:2',
  'Messaging services for an Ado system!',0);
INSERT OR IGNORE INTO i18n VALUES('bg','Messaging services for an Ado system!','templates/vest/head.html.ep:2',
  'Услуга за съобщения в системи, изградени върху Суматоха!',0);

