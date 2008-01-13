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


my $title = 'Canonizer Main Page';
my $header = '<table><tr><td class="topic">Canonizer Main Page</td><td>&nbsp &nbsp</td><td class="label">beta</td></tr></table>';

&display_page($title, $header, [\&identity, \&canonizer, \&as_of, \&search, \&main_ctl], [\&canonized_list]);

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

     <span id="title">Canonizer Information</span>

</div>

<div class="content_1">
<h3>Description</h3>
<p>For a more complete description of the Canonizer see the "What is
the Canonizer" link in the Navigation section of the side bar.  For
more information on how to canonize your point of view (POV) see the
help link.</p>
<br>


<h3>What does Everyone Want?</h3>
<p>What does everyone value?  What does everyone believe?  What is the
gospel according to you?  There are a quickly approaching infinite set
of individual testimonials about all such contained in books, op / ed
pieces, blogs, comments to such, product review sites, web pages, and
so on.  As much as you'd like to know quantitatively what the masses
are saying in all this you probably don't have time to read, let alone
digest and tally it all right?  So lets all work together to get it all
canonized so we can know it concisely, quantitatively, and in
everyone's preferred words.</p>
<br>

<h3>Canonized Feedback on Your Web Pages</h3>
<p>Would you like to have free and easy canonized feedback from the
masses on your web pages about a product, a company, a belief or
anything?  You can now create a topic in the canonizer for such, and
then add a simple block of HTML to your web page to show the information on your
page as is done here: <a
href="http://home.comcast.net/~brent.allsop">http://home.comcast.net/~brent.allsop</a>.</p>
<br>

<h3>Canonized Yellow Pages / Product Reviews.</h3>
<p>Do you have a professional service or product that is, in your POV,
the best?  And do you have lots of happy customers willing to prove
it?  Then you can get such canonized.  For an example, see this topic
on <a href=" http://test.canonizer.com/topic.asp/18">who is the best
family dentist</a>.</p>
<br>

<h3>Canonized Science</h3>
<p>Are you researching an area of science with lots of competing
theories, yet still no consensus on what theory will turn out right?
Do you wonder just how accurate certain claims of consensus on such
topics as global warming are?  Would you like to have some kind of
quantitative measure to help know such?  Then get it canonized as has
started with this very controversial scientific topic on the <a
href="http://test.canonizer.com/topic.asp/23">Hard Problem of
Consciousness</a>.</p>
<br>

<h3>Canonizers Yahoo Group</h3>
<p>canonizer.com is being developed by a grass roots group of
volunteers.  We all communicate on this <a href =
"http://finance.groups.yahoo.com/group/canonizers/">Canonizers Yahoo
Group</a>.  Of course everyone is invited to join, especially if the
Canonizer isn't yet what you'd like it to be.</p>


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

	$Response->Write(topic::canonized_list($dbh, $sth, $Session->{'as_of_mode'}, $Session->{'as_of_date'}, $Session->{'canonizer'}));

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

