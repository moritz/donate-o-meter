-- all "amount" fields are in cents, that is 1/100th of whatever currency you
-- use. Positive amounts are stuff you get (donations, revenue), negative
-- are expenses.

DROP TABLE IF EXISTS one_time_transaction;
DROP TABLE IF EXISTS recurring_transaction;
DROP TABLE IF EXISTS project;
CREATE TABLE project (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL,
    description TEXT,
    start_date  TEXT NOT NULL DEFAULT(date('now')),
    currency    TEXT NOT NULL DEFAULT('Euro'),
    UNIQUE(name)
);

CREATE TABLE one_time_transaction (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    project         INTEGER NOT NULL REFERENCES project (id),
    name            TEXT    NOT NULL,
    billing_date    TEXT    NOT NULL DEFAULT(date('now')),
    amount          INTEGER NOT NULL
    -- TODO: attribution
);

CREATE TABLE recurring_transaction (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    project         INTEGER NOT NULL REFERENCES project (id),
    name            TEXT    NOT NULL,
    start_date      TEXT    NOT NULL DEFAULT(date('now')),
    end_date        TEXT,
    amount          INTEGER NOT NULL,
    interval_num    INTEGER NOT NULL,
    interval_unit   TEXT    NOT NULL DEFAULT('month')
    -- TODO: attribution
);

CREATE TABLE balance (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    project         INTEGER NOT NULL REFERENCES project (id),
    balance_date    TEXT NOT NULL DEFAULT(date('now')),
    amount          INTEGER NOT NULL
);

