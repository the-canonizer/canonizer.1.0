<%

use managed_record;
use camp;

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

	my @namespaces = func::get_name_spaces($dbh);

	if (length($cur_namespace) < 1) {
		$cur_namespace = 'general';
	}

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

<table>
<tr><td><h3>Vote for canonizer.com at Advanta's ideablob</h3>

If we win $10K, we could contract some professional documentation services and do more promotion.

</td>
<td>&nbsp</td>
<td>
<a href="http://ideablob.com/ideas/4087-Point-Of-View-Wiki">
<img width=100 height=75 src="http://ideablob.com/ideas/4087-Point-Of-View-Wiki;button"
target="_blank" alt="My Idea" /></a>
</td></tr></table>
<br>

<h3>Getting Started</h3>
<p>To get started, just scroll down and find a topic you are passionat
about.  It is like a survey, so select that camp you agree with, go to
the camp page, and join the camp.  If what you believe isn't yet
there, start a new camp so others that agree with you can join and
help further develop and promote it.  For a more complete description
of the Canonizer see the "What is the Canonizer" link in the
Navigation section of the side bar.  For more information on how to
canonize your point of view (POV) see the help link. For information
on the camp structure, its purpose, and where to place your camp
within the camp structure see <a
href="http://canonizer.com/topic.asp/89/2">this camp</a>.
</p><br>


<h3>What do you believe?</h3>
<p>Tired of fighting edit wars on Wikis?  Want to know concisely and
quantitatively how many people believe or value what?  Have you ever
been dissatisfied with the choices on a particular belief survey?
Tired of trying to digest thousands of testimonials or comments to get
an idea of what a trusted majority of people think?  Don't want to
waste your time adding the one thousand and first testimonial or
comment no one will ever get to?  Our goal is to make huge steps
forward in all these directions.

</p> <br>
<h3>Personal Canonized Values</h3> <p>To find out what someone's
beliefs and values are, click on their ID to get to their personal
canonized values page.  These personal pages have a list of all
supported camps.  When you meet a new person, you can simply and
easily share all you canonized values - compareing and contrasting
them.  Using the 'as of' box on the side bar, you can find what
people's canonized values were at any time in the past.  A powerful
way to easily testify of what you believe in and hope for, in a
colaberative way with all who share you beliefs.
</p> <br>


<h3>Canonized Science (concise and quantitative measures of
consensus)</h3>
<p>Are you researching an area of science with lots of competing
theories, like 18000+ publications documenting such, apparently no
consensus on anything whatsoever?  We bet there is more consensus than
you think, if someone would simply make some kind of effort to just
measure such.  In fact, there could even be one very good theory that
most experts agree on its just that nobody knows this.  And knowing
such quantitatively is likely critical to any scientific progress in
such fields.<p>

<p>Canonizer.com has been specifically developed to be a social tool
for experts to collaboratively developing concise descriptions of all
accepted theories, and quantitative measures of scientific consensus
for each.  Scientific Consensus canonizers can be developed using
topics like this one on <a href =
"http://canonizer.com/topic.asp/81">Mind Experts</a>.  An example
topic that is already showing some tentative evidence that there could
be significant scientific consensus after all for a very good theory
is this topic surveying <a
href="http://test.canonizer.com/topic.asp/88">Theories of
Conscoiusness</a>.</p><br>

<h3>Way Better than a Traditional Petition</h3>
<p>Do you have a grass roots effort trying to collect signatures on a
petition?  Would an online version, with a way to sign camps in a
reputable way help?  Do you want your effort to go viral?  Your
petition in a canonized camp statement is a very easy and free way to
do all this.  And of course, unlike traditional petitions, which can't
change once the first person has signed, statements here continueally
grow, progress, and adapt to the times.  Anyone can propose new
changes and any camp member can object to any changes - preventing
them from going live.
<p><br>

<h3>Canonized Feedback on Your Web Pages</h3>
<p>Do you have thousands of useless comments for feedback on your web
pages from the masses about products, beliefs, or anything?  Would you
like to get all the similar ones grouped, concisely stated,
quantitatively measured, or canonized on your web pages for free?  You
can now create a topic in the canonizer for such, and then add a
simple block of HTML to your web page to show the information on your
page as is done here: <a
href="http://home.comcast.net/~brent.allsop">http://home.comcast.net/~brent.allsop</a>.
</p><br>

<h3>Canonized Reputations Building</h3> <p>Do you live in Nigeria, yet
want to do business online?  Do you have a professional service or
product that is, in your POV, the best?  Do you have lots of happy
customers willing to prove it?  Is everybody ignoring your collection
of testimonials?  Then you can get such canonized.  Nobody puts much
creed in a collection of testimonials, but a canonized reputation is
very reputable since it is an open system where both pro and con
customers can contribute.  For an example, see this topic on <a href="
http://test.canonizer.com/topic.asp/18">who is the best family
dentist</a>.</p> <br>

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

<div class="camp_tree" id="camp_tree">

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

