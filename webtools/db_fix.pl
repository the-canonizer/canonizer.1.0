#!/usr/bin/perl -w

use Time::Local;
use lib "/usr/local/webtools";

use DBI;
use func;

use POSIX qw(ceil floor);


print("Running test...\n");



my $escaped       = pack("C*", (195, 162, 226, 130, 172));
my $escaped_open  = pack("C*", (195, 162, 226, 130, 172, 197, 147));
my $escaped_close = pack("C*", (195, 162, 226, 130, 172, 194, 157));
my $escaped_poses = pack("C*", (195, 162, 226, 130, 172, 226, 132, 162));

# everything but 195 and , so we don't suck up the start of the second escaped quote that always starts with 195
my $all_str = $escaped . "[\x80|\x84|\xCB|\xC2|\xC5|\x93|\x9C|\x9D|\xA2|\xAC|\xE2]*";
# my $all_str = $escaped . "[\x80|\x84|\xCB|\xC2|\x9C|\x9D|\xA2|\xAC|\xE2]*([^\x80\x84\xCB\xC3\x9C\x9D\xA2\xAC\xE2]{0,5})";

#my $escaped_poses2 = pack("C*", (195, 162, 226, 130, 172, 226, 132, 162)) . "abcdef";
# if ($escaped_poses =~ m/[\x80|\xCB|\xC2|\x9C|\xE2|\xA2|\xC3\x9D]*([^\x80\xCB\xC2\x9C\xE2\xA2\xC3\x9D]{5})/) {
#if ($escaped_poses2 =~ m/([\x80|\xCB|\xC2|\x9C|\xE2|\xA2|\xC3\x9D]*)([^x]*)/) {
#	print("matched($1)($2).\n");
#}


# print("all_str: $all_str.\n");


my $count = 0;
my $fixed = 0;
my $still_bad = 0;

my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

fix_domain_name($dbh);
# fix_text($dbh);
# fix_statement_title($dbh);

print("found $count records.\n");
print("fixed $fixed.\n");
print("found $still_bad still bad records.\n");


# print("escaped_open: $escaped_open.\n");
# print("escaped_close: $escaped_close.\n");
# print("escaped_poses: $escaped_poses.\n\n");

print("Chars not covered:\n");
foreach $char (sort {$a <=> $b} keys %not_covered) {
	printf("\t$char(%X)[" . chr($char). "]: $not_covered{$char}.\n", $char);
}



sub fix_domain_name {

	print("fixing domain name in text...\n\n");

	$dbh = $_[0];

	# my $selstmt = 'select * from text where topic_num = 16 and statement_num = 2';
	my $selstmt = 'select * from text';

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;

	while ($rs = $sth->fetchrow_hashref()) {
		$count++;

		$value = $rs->{'value'};

		if ($value =~ m|test\.canonizer\.com|i) {

			# print("Found one: $value\n");

			$value =~ s|test\.canonizer\.com|canonier\.com|ig;

			$selstmt = 'update text set value = ? where record_id = ' . $rs->{'record_id'};

			my %dummy;

			$fixed++;

			print("$selstmt with $value.\n");
			# if ($dbh->do($selstmt, \%dummy, $value) eq '0E0') {
			# 	print('failed to update text record ' . $rs->{'record_id'} . ".\n");
			# }
		} else {
			# print("no need to fix $rs->{'record_id'}.\n");
		}
	}

	$sth->finish();

}



sub fix_text {

	print("fixing text...\n\n");

	$dbh = $_[0];

	# my $selstmt = 'select * from text where topic_num = 16 and statement_num = 2';
	my $selstmt = 'select * from text';

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	my $no_data = 1;

	my @open_array;
	my @close_array;
	my @poses_array;
	my @excaped_array;

	my $char;
	my %not_covered = ();

	while ($rs = $sth->fetchrow_hashref()) {
		$count++;

		$value = $rs->{'value'};

	# if ($value =~ m|the term (.*?)friendliness(.*?), to be|) {
	# 	@open_array = unpack("C*", $1);
	# 	@close_array = unpack("C*", $2);
	# 
	# 	print("\topen : " . join('|', @open_array) . ".\n");
	# 	print("\tclose: " . join('|', @close_array) . ".\n\n");
	# }
	# 
	# if ($value =~ m|around Hitler(.*?)s time, |) {
	# 	@poses_array = unpack("C*", $1);
	# 
	# 	print("\tposes: " . join('|', @poses_array) . ".\n\n");
	# }

	# if ($value =~ m|Color (.*?) Label|) {
	# 	@poses_array = unpack("C*", $1);
	# 
	# 	print("\tposes: " . join('|', @poses_array) . ".\n\n");
	# }

#	$value =~ s|$escaped_open|\'|g;
#	$value =~ s|$escaped_close|\'|g;
#	$value =~ s|$escaped_poses|\'|g;


		$value = unescape_single($value);


		if ($value =~ m|($escaped.{0,5})|) {
			print("Found another one($1)!!!\n");

			# my @escaped_array = unpack("C*", $1);
			my @escaped_array = unpack("C*", $1);

			foreach $char (@escaped_array) {
				$not_covered{$char}++;
				# print("adding $char - $not_covered{$char}.\n")
			}

			for (my $idx = 0; $idx<=$#escaped_array; $idx++) {
				$escaped_array[$idx] = sprintf("%x", $escaped_array[$idx]);
			}

			print("\tescaped trailiers: " . join('|', @escaped_array) . ".\n\n");

			$still_bad++;

			# print("record: $rs->{'record_id'}, topic: $rs->{'topic_num'}, statement: $rs->{'statement_num'}\n$value\n\n");

		}

		$selstmt = 'update text set value = ? where record_id = ' . $rs->{'record_id'};

		my %dummy;

		print("$selstmt with $value.\n");
		# if ($dbh->do($selstmt, \%dummy, $value) eq '0E0') {
		# 	print('failed to update text record ' . $rs->{'record_id'} . ".\n");
		# }
	}

	$sth->finish();

}



sub fix_statement_title {
	$dbh = $_[0];

	my $selstmt = 'select * from statement';

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	my $no_data = 1;

	my $value;
	my $clean_value;

	while ($rs = $sth->fetchrow_hashref()) {
		$count++;

		$value = $rs->{'one_line'};

		$clean_value = unescape_single($value);

		if ($clean_value =~ m|($escaped.{0,5})|) {
			print("Found another one($1)!!!\n");

			# my @escaped_array = unpack("C*", $1);
			my @escaped_array = unpack("C*", $1);

			foreach $char (@escaped_array) {
				$not_covered{$char}++;
				# print("adding $char - $not_covered{$char}.\n")
			}

			for (my $idx = 0; $idx<=$#escaped_array; $idx++) {
				$escaped_array[$idx] = sprintf("%x", $escaped_array[$idx]);
			}

			print("\tescaped trailiers: " . join('|', @escaped_array) . ".\n\n");

			$still_bad++;

			# print("record: $rs->{'record_id'}, topic: $rs->{'topic_num'}, statement: $rs->{'statement_num'}\n$clean_value\n\n");
		}

		$selstmt = 'update statement set one_line = ? where record_id = ' . $rs->{'record_id'};

		my %dummy;

		if ($clean_value ne $value) {
			print("$selstmt with $clean_value.\n");
			# if ($dbh->do($selstmt, \%dummy, $clean_value) eq '0E0') {
			# 	print('failed to update text record ' . $rs->{'record_id'} . ".\n");
			# }
		}
	}

	$sth->finish();

}



sub unescape_single {
	my $value = $_[0];

	if ($value =~ s|($all_str)|\'|g) {
		$fixed++;
		# to review value after a change:
		# print("value: $value.\n")
	}
	return($value);
}


