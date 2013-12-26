/**
  This SQL script creates the table mess in an 
  existing ado.sqlite database.
  The following pragmas should be set by DSC plugin
  PRAGMA encoding = "UTF-8"; 
  PRAGMA foreign_keys = ON;
*/

-- 'This table stores the messages between users'
CREATE TABLE IF NOT EXISTS mess (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_uid INT(11) REFERENCES users(id) NOT NULL,
  -- A comma separated list of user ids
  to_uid INT(11) REFERENCES users(id) NOT NULL,
  -- Subject of the talk. Only the first message in a talk has a subject
  subject VARCHAR(255) NOT NULL DEFAULT '',
  -- Id of the first message in a talk. Every next message has this !=0.
  subject_message_id INT(12) NOT NULL DEFAULT 0,
  --  'last modification time'
  --  'All dates are stored as seconds since the epoch(1970) in GMT. In Perl we use gmtime as object from Time::Piece'
  tstamp INTEGER NOT NULL DEFAULT 0,
  -- the message it self
  message TEXT,
  -- File-names of Files attached to this message - TODO
  message_assets TEXT DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS mess_subject ON mess(subject);
CREATE INDEX IF NOT EXISTS mess_subject_message_id ON mess(subject_message_id);

