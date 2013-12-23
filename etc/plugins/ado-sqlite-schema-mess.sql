/**
  This SQL script creates the table mess in an 
  existing ado.sqlite database.
*/
PRAGMA encoding = "UTF-8"; 
PRAGMA foreign_keys = ON;

-- 'This table stores the messages between users'
DROP TABLE IF EXISTS mess;
CREATE TABLE IF NOT EXISTS mess (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_uid INTEGER REFERENCES users(id),
  -- A comma separated list of user ids
  to_uid INTEGER REFERENCES users(id),
  subject VARCHAR(255),
  --  'last modification time'
  --  'All dates are stored as seconds since the epoch(1970) in GMT. In Perl we use gmtime as object from Time::Piece'
  tstamp INTEGER NOT NULL DEFAULT 0,
  -- the message it self
  message TEXT,
  -- File-names of Files attached to this message - TODO
  message_assets TEXT DEFAULT NULL
);
CREATE INDEX mess_subject ON mess(subject);

