use v6;

use DBIish;
my $dbh = DBIish.connect('SQLite', :database<db.sqlite3>, :RaiseError);

sub select-one($statement, *@placeholders) {
    my $sth = $dbh.prepare($statement);
    $sth.execute(@placeholders>>.Str);
    my @res = $sth.fetchrow;
    $sth.finish;
    return |@res;
}

my %unit = (
    day     => day,
    month   => month,
    year    => year,
);

sub project-id(Cool $name) {
    state %cache;
    return %cache{$name} if %cache{$name}:exists;
    return %cache{$name} = +select-one('SELECT id FROM project WHERE name = ?', $name)
        or die "No such project '$name'";
}

sub balance(Int:D :$project!, Date:D :$to = Date.today) {
    my $from = Date.new(select-one('SELECT start_date FROM project where id = ?', $project));

    my sub do-balance($f = $from) {
        one-time-balance(:$project, :from($f), :$to)
          + recurring-balance(:$project, :from($f), :$to);
    }
    my ($old, $date) =  select-one('SELECT amount, balance_date FROM balance WHERE project = ? AND balance_date <= ? ORDER BY balance_date DESC LIMIT 1', $project, $to);
    my $balance = 0;
    if $date {
        return $old if $date eq $to;
        $balance = $old + do-balance(Date.new($date));
    }
    else {
        $balance = do-balance();
    }
    $dbh.do('INSERT INTO balance (project, balance_date, amount) VALUES (?, ?, ?)', $project, $to.Str, $balance);
    return $balance;
}

sub one-time-balance(Int:D :$project!, Date:D :$from!, Date:D :$to!) {
    select-one('SELECT SUM(amount) FROM one_time_transaction WHERE project = ? AND billing_date >= ? AND billing_date <= ?', $project, $from, $to) // 0;
}

sub recurring-balance(Int:D :$project!, Date:D :$from!, Date:D :$to!) {
    my $balance = 0;
    my $sth = $dbh.prepare('SELECT start_date, end_date, amount, interval_num, interval_unit FROM recurring_transaction WHERE project = ? AND start_date <= ? AND (end_date IS NULL OR end_date <= ?)');
    $sth.execute($project, $to.Str, $from.Str);
    while (my %h := $sth.fetchrow_hashref) {
        my $end   = defined(%h<end_date>) && Date.new(%h<end_date>) min $to;
        my $start = Date.new(%h<start_date>);
        my $unit  = %unit{%h<interval_unit>}
                    // die "Don't understand interval unit '%h<interval_unit>'!";
        $balance += %h<amount> * ($start, *.delta(+%h<interval_num>, $unit) ...^ *>$end).grep(* >= $from).elems;
    }
    $sth.finish;
    return $balance;
}

sub recurring-expectation(Int:D :$project!, Date:D :$from = Date.today) {
    my $to = $from.delta(1, year);
    return recurring-balance(:$project, :$from, :$to) / 12;
}

sub MAIN($project-name = 'irclog') {
    my $project = project-id($project-name);
    say balance(:$project);
    say recurring-expectation(:$project);
}

# vim: ft=perl6
