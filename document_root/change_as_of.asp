

<%

########
# main #
########

my $query_string = $ENV{'QUERY_STRING'};

$query_string =~ s|\&?destination=||;
$query_string =~ s|\&?\??(as_of=.*)||;
$as_of = $1;

my $as_of_mode = 'default';
my $as_of_date = '';

if ($as_of =~ m|([^=]*)/(\d\d)/(\d\d)/(\d\d)|) {
	$as_of_mode = $1;
	$as_of_date = "$2/$3/$4";
} elsif ($as_of =~ m|([^=]*)/|) {
	$as_of_mode = $1;
	if ($as_of_mode eq 'as_of') { # don't allow as of with no date.
		$as_of_mode = 'default';
	}
	$as_of_date = '';
}

$Session->{'as_of_mode'} = $as_of_mode;
$Session->{'as_of_date'} = $as_of_date;

$Response->Redirect($query_string);

%>

<p>env: <%=$ENV{'QUERY_STRING'}%></p>
<p>Request->QueryString<%=$Request->QueryString('as_of')%></p>
<p>as_of: <%=$as_of%></p>
<p>as_of_mode: <%=$as_of_mode%></p>
<p>as_of_date: <%=$as_of_date%></p>
<p><%=$query_string%>></p>
