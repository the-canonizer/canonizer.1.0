<%

########
# main #
########

my $query_string = $ENV{'QUERY_STRING'};

$query_string =~ s|\&?destination=||;
$query_string =~ s|\&?\??canonizer=(\d+)||;
my $canonizer = int($1);

$Session->{'canonizer'} = $canonizer;

$Response->Redirect($query_string);

%>

<p><%=$query_string%></p>

