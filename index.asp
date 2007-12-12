<%

use managed_record;
use statement;

my $path_info = $ENV{'PATH_INFO'};
my $pi_namespace = '';
if (length($path_info) > 0) {
	$pi_namespace = $path_info;
}

my $namespace = '';
if ($Request->Form('namespace')) {
	$namespace = $Request->Form('namespace');
} elsif (length($pi_namespace) > 0) {
	$namespace = $pi_namespace;
} elsif ($Request->QueryString('namespace')) {
	$namespace = $Request->QueryString('namespace');
}


my $header = 'Canonizer Main Page';

&display_page($header, $header, [\&identity, \&canonizer, \&as_of, \&search, \&main_ctl], [\&canonized_list]);

##############
# start subs #
##############

sub make_namespace_select_str {
	my $dbh           = $_[0];
	my $cur_namespace = $_[1];

	my $selstmt = 'select namespace from topic group by namespace order by namespace';

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";
	$sth->execute() || die "Failed to execute $selstmt";
	my $rs;

	my @namespaces = ();

	while ($rs = $sth->fetch()) {
		push(@namespaces, $rs->[0]);
	}

	if (length($cur_namespace) < 1) {
		$cur_namespace = 'general';
	}

	$namespaces[0] = 'general';

	my $namespace_select_str = "<select name=\"namespace\" onchange=\"javascript:change_namespace(value)\">\n";

	my $namespace;
	foreach $namespace (@namespaces) {
		$namespace_select_str .= "\t<option value=\"$namespace\" " . (($namespace eq $cur_namespace) ? 'selected' : '') . ">$namespace</option>\n";
	}

	$namespace_select_str .= "</select>\n";

	return($namespace_select_str);
}


sub canonized_list {

	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

	my $as_of_mode = $Session->{'as_of_mode'};
	my $as_of_date = $Session->{'as_of_date'};
	my $as_of_clause = '';
	if ($as_of_mode eq 'review') {
		# no as_of_clause;
	} elsif ($as_of_mode eq 'as_of') {
		$as_of_clause = 'and go_live_time < ' . &func::parse_as_of_date($as_of_date);
	} else {
		$as_of_clause = 'and go_live_time < ' . time;
	}

	my $namespace_select_str = make_namespace_select_str($dbh, $namespace);

	my $selstmt = "select topic_num, topic_name from topic where namespace = ? and objector is null $as_of_clause and go_live_time in (select max(go_live_time) from topic where objector is null $as_of_clause group by topic_num)";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";
	$sth->execute($namespace) || die "Failed to execute $selstmt";

%>

<script language:javascript>

function change_namespace(namespace) {
	if (namespace == 'general') {
		namespace = '';
	}
	window.location = "/index.asp" + namespace;
}

</script>


<div class="main_content_container">

<div class="section_container">
<div class="header_1">

     <span id="title">Canonizer News</span>

</div>

<div class="content_1">

<p>For a brief description of the Canonizer see the "What is the
Canonizer" link on the side bar.</p>

<p>Enough of the canonization process is now completed to do "Blind
Popularity" (one person, one vote) canonization.  Once a user
attribute system is completed, along with more canonizers using these
attributes you will be able to canonize this page in different ways
giving more influence to people you choose to respect.</p>

<p>There is a canonizers yahoo group where the developement and goals
of the Canonizer are descussed.  Anyone interested in folowing this
project or earning Canonizer LLC shares is envited to join this group
<a href =
"http://finance.groups.yahoo.com/group/canonizers/">here</a>.</p>

</div>

     <div class="footer_1">
     <span id="buttons">
	&nbsp;
     </span>
     </div>

</div>

<div class="section_container">
<div class="header_1">

     <span id="title">Canonized list for <%=$namespace_select_str%> namespace:</span>

</div>

<div class="statement_tree" id="statement_tree">

<%

	$Response->Write(topic::canonized_list($dbh, $sth, $Session->{'as_of_mode'}, $Session->{'as_of_date'}, $namespace));

%>

</div>

     <div class="footer_1">
     <span id="buttons">
     

&nbsp;  
     
     </span>
     </div>

</div>

</div>
	
<%

}

%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/canonizer.asp"-->
<!--#include file = "includes/as_of.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

