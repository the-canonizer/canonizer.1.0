<%

########
# main #
########

# my $query_string = $ENV{'QUERY_STRING'};

# $query_string =~ s|\&?destination=||;
# $query_string =~ s|\&?\??canonizer=(\d+)||;

my $canonizer = int($Request->Form('canonizer'));
unless ($canonizers::canonizer_array[$canonizer]) { $canonizer = 0 };

my $filter = $Request->Form('filter');
unless ((length($filter) > 0) && ($filter >= 0) && ($filter < 100)) { $filter = $Session->{'filter'} };

my $destination = $Request->Form('destination');

$Session->{'canonizer'} = $canonizer;
$Session->{'filter'}    = $filter;

$Response->Redirect($destination);

%>

<p>canonizer: <%=$Session->{'canonizer'}%></p>
<p>filter: <%=$Session->{'filter'}%></p>
<p>destination: <%=$destination%></p>

