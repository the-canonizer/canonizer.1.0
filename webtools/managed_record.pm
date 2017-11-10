package managed_record;

use strict;

# proposed and error_message are not stored in the DB
# proposed is passed through the edit form.
use fields qw( record_id note submit_time submitter go_live_time objector object_time object_reason proposed replacement error_message );


# this block markes static or class methods.
{

sub bad_managed_class {
	my $class = $_[0];

	if ($class eq 'topic') {
		return(0);
	} elsif ($class eq 'camp') {
		return(0);
	} elsif ($class eq 'statement') {
		return(0);
	}
	return(1);
}

}


1;

