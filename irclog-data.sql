INSERT INTO project (id, name, description, start_date, currency)
            VALUES  (1, 'irclog', 'IRC logs at http://irclog.perlgeek.de/', '2007-04-19', 'Euro');
INSERT INTO recurring_transaction (project, name, start_date, amount, interval_num, interval_unit)
            VALUES (1, 'Server hosting', '2013-05-03', -1500, 1, 'month');
-- TODO: domain costs

