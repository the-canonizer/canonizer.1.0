<%

########
# main #
########

# my $query_string = $ENV{'QUERY_STRING'};

# $query_string =~ s|\&?destination=||;
# $query_string =~ s|\&?\??canonizer=(\d+)||;

my $canonizer = int($Request->Form('canonizer'));
if (length($Request->QueryString('canonizer')) > 0) {
	$canonizer = int($Request->QueryString('canonizer'));
}
unless ($canonizers::canonizer_array[$canonizer]) { $canonizer = 0 };

my $filter = $Request->Form('filter');
if (length($Request->QueryString('filter')) > 0) {
	$filter = int($Request->QueryString('filter'));
}
unless ((length($filter) > 0) && ($filter >= 0) && ($filter < 100)) { $filter = $Session->{'filter'} };

my $destination = $Request->Form('destination');
if (length($Request->QueryString('destination')) > 0) {
	$destination = $Request->QueryString('destination');
}

$Session->{'canonizer'} = $canonizer;
$Session->{'filter'}    = $filter;

$Response->Redirect($destination);

%>

<p>canonizer: <%=$Session->{'canonizer'}%></p>
<p>filter: <%=$Session->{'filter'}%></p>
<p>destination: <%=$destination%></p>

