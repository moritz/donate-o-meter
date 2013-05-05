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
        my $balance = 0;
        my $sth = $dbh.prepare('SELECT start_date, end_date, amount, interval_num, interval_unit FROM recurring_transaction WHERE project = ? AND start_date <= ? AND (end_date IS NULL OR end_date <= ?)');
        $sth.execute($.project, $.to.Str, $.from.Str);
        while (my %h := $sth.fetchrow_hashref) {
            $balance += self!recurring(
                :start(Date.new(%h<start_date>))
                :end(%h<end_date> ?? Date.new(%h<end_date>) !! Date),
                :amount(%h<amount>),
                :interval(%h<interval_num>),
                :unit(%unit{%h<interval_unit>}),
            );
        }
        $sth.finish;
        return 0;
    }

    method !recurring(:$start! is copy, :$amount!, :$interval!, :$unit!, :$end is copy){
        $end   min= $.to;
        $start max= $.from;
        return $amount * elems($start, *.delta($interval, $unit) ...^ *>$end);
    }

    method test-recurring() {
        self!recurring(:start(Date.new(2013, 1, 3)), :amount(3), :interval(1), :unit(month));
    }
}


sub MAIN($project = 'irclog') {
    say Balance.new(:project(project-id($project))).test-recurring;

}

# vim: ft=perl6
