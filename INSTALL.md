Installation instructions
=========================

Create table 'content':

CREATE TABLE content(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id UNSIGNED BIG INT, language VARCHAR(12), title VARCHAR(255), teaser TEXT, body TEXT, created UNSIGNED BIG INT, changed UNSIGNED BIG INT, status BOOLEAN, sticky BOOLEAN, comment BOOLEAN, promote BOOLEAN);
CREATE INDEX idx_content_created ON content (created DESC);
CREATE INDEX idx_content_changed ON content (changed DESC);
CREATE INDEX idx_content_frontpage ON content (promote, status, sticky, created DESC);
CREATE INDEX idx_content_title ON content (title);
CREATE INDEX idx_content_user ON content (user_id);
