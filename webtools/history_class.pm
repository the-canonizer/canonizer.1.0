package history_class;

use strict;
# use Carp;

# this will move to manage.asp right!!????
use managed_record;

use fields qw(type args record_array active manage_ident error_message);

$history_class::proposed_color = "proposed_record"; # Instead of passing specific colors like it was before, I'm passing CSS class names to the print_record sub. -Karolis.
$history_class::active_color   = "active_record";
$history_class::objected_color = "objected_record";
$history_class::history_color  = "history_record";


sub new {
    my ($caller, $dbh, $type, $args) = @_;
    my $class = ref($caller) || $caller;
    no strict "refs";
    my history_class $self = [ \%{"${class}::FIELDS"} ];
    bless $self, $class;

    $self->{type} = $type;
    $self->{args} = $args;
    $self->{active} = 0;

	my $selstmt;
	my $manage_ident;
    eval('($selstmt, $manage_ident) = ' . $type . '::get_record_info($dbh, $args)');
	# this eval hides errors, so if you are getting this error:
	# DBD::mysql::st execute failed: Query was empty
	# try hard coding one of the below, instead,to find the real error.
    # ($selstmt, $manage_ident) = camp::get_record_info($dbh, $args);
    # ($selstmt, $manage_ident) = statement::get_record_info($dbh, $args);

    $self->{manage_ident} = $manage_ident;

	if ($selstmt =~ m|error|i) {
		$self->{error_message} = $selstmt;
		return ($self);
	}

    my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";
    $sth->execute() || die "Failed to execute $selstmt";
    my $rs;

    my $rec_index = -1;

	my $now_time = time;

    # order starts with the first record.
    while ($rs = $sth->fetchrow_hashref()) {

 		my managed_record $record = new_rs $type ($rs);
		$rec_index++;
		$self->{record_array}->[$rec_index] = $record;

		if ((! $self->{active}) && ($record->{go_live_time} < $now_time) && (! $record->{objector})) {
			$self->{active} = $record;
		}
    }
    return($self);
}


sub print_history {
    my $self = $_[0];
    my $dbh = $_[1];

    my $rec_index = $#{$self->{record_array}};

    my $record;
	my $color;
	my $now_time = time;

    my $proposed_header_displayed = 0;
PROPOSED:
    while ($rec_index >= 0) {
		$record = $self->{record_array}->[$rec_index];
		$color = $history_class::proposed_color;

		if ($record->{'go_live_time'} > $now_time) { # then proposed
			if (! $proposed_header_displayed) {
				print("<h1>Proposed Versions of This Record</h1>\n");
				print("<p>Note: In order to view the latest proposed change to see what they will look like on a topic page when they go live, you can select the 'include review' option in the 'As Of' block on the side bar of the topic page. In the 'default' as of mode, only the current active record is shown.</p>\n");
				$proposed_header_displayed = 1;
			}
			if ($record->{objector}) {
				$color = $history_class::objected_color;
			}
			$record->print_record($dbh, $color);
		} else {
			last PROPOSED;
		}
		$rec_index--;
    }

    my $active_header_displayed = 0;
ACTIVE:
    while ($rec_index >= 0) {
		$record = $self->{record_array}->[$rec_index];

		if ($record->{'objector'}) {
			$record->print_record($dbh, $history_class::objected_color);
			$rec_index--;
		} else {
			if (! $active_header_displayed) {
				print("<h1>Currently Active Record</h1>\n");
				$proposed_header_displayed = 1;
			}
			$record->print_record($dbh, $history_class::active_color);
			$rec_index--;
			last ACTIVE;
		}
    }

    my $history_header_displayed = 0;
HISTORY:
    while ($rec_index >= 0) {
		if (! $history_header_displayed) {
			print("<h1>History</h1>\n");
			$history_header_displayed = 1;
		}
		$record = $self->{record_array}->[$rec_index];
		$color = $history_class::history_color;
		if ($record->{'objector'}) {
			$color = $history_class::objected_color;
		}
		$record->print_record($dbh, $color);
		$rec_index--;
    }

}


1;

