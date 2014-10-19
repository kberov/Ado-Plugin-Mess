/**
  This SQL script creates the table vest in an 
  existing ado.sqlite database.
  The following pragmas must be already set by DSC plugin
  PRAGMA encoding = "UTF-8"; 
  PRAGMA foreign_keys = ON;
*/

-- 'This table stores the messages between users'
CREATE TABLE IF NOT EXISTS vest (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- A user id from which the message is sent. 
  from_uid INT(11) REFERENCES users(id) NOT NULL,
  -- A user id to which the message is sent. 
  -- Can be zero (0) in case the message is sent to the whole group.
  -- This way we can have group talks.
  to_uid INT(11) REFERENCES users(id) DEFAULT 0,
  -- A group id to which the message is sent.
  -- Can be zero (0). In this case the message is private to the user specified
  -- by to_uid. In case both to_uid and to_guid are zero, the sender 
  -- is talking to him self - Taking Notes.
  to_guid INT(11) REFERENCES groups(id) DEFAULT 0,
  -- Subject of the talk. Only the first message in a talk has a subject.
  subject VARCHAR(255) DEFAULT '',
  -- Id of the first message in a talk. Every next message !=0.
  -- This way a conversation can have a topic.
  -- The first message in a talk sets the topic.
  -- There can be many conversations in a group or between two users.
  subject_message_id INT(12) NOT NULL DEFAULT 0,
  -- Last modification time.
  -- All dates are stored as seconds since the epoch(1970). 
  -- In Perl we use a Time::Piece object.
  tstamp INTEGER NOT NULL DEFAULT 0,
  -- The message it self.
  message TEXT,
  -- File-paths (relative to app->home) of Files attached to this message - TODO
  message_assets TEXT DEFAULT NULL,
  -- Who can edit this message - usually only the owner.
  permissions VARCHAR(10) NOT NULL DEFAULT '-rw-r-----',
  -- Was this message seen by the "to_uid" user?
  seen INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS vest_subject ON vest(subject) WHERE subject !='';
CREATE INDEX IF NOT EXISTS vest_subject_message_id ON vest(subject_message_id);

