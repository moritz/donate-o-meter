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

sub project-id(Cool $name) {
    state %cache;
    return %cache{$name} if %cache{$name}:exists;
    return %cache{$name} = +select-one('SELECT id FROM project WHERE name = ?', $name)
        or die "No such project '$name'";
}

class Balance {
    has Int:D  $.project = die "Missing project ID";
    has Date:D $.from    = Date.new(select-one('SELECT start_date FROM project where id = ?', self.project));
    has Date:D $.to      = Date.today;

    method balance() {
        return self.one-time-balance + self.recurring-balance;
    }
    method one-time-balance() {
        select-one('SELECT SUM(amount) FROM one_time_transaction WHERE project = ? AND billing_date >= ? AND billing_date <= ?', $.project, $.from, $.to) // 0;
    }
    method recurring-balance() {
        say 'alive 2';
        my $sth = $dbh.prepare('SELECT start_date, end_date, amount, interval_num, interval_unit FROM recurring_transaction WHERE project = ? AND start_date <= ? AND (end_date IS NULL OR end_date <= ?)');
        $sth.execute($.project, $.to.Str, $.from.Str);
        while (my %h := $sth.fetchrow_hashref) {
            say %h.perl;
        }
        $sth.finish;
        return 0;
    }
}


sub MAIN($project = 'irclog') {
    say Balance.new(:project(project-id($project))).balance;

}

# vim: ft=perl6
