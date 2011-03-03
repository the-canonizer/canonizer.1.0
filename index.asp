<%

use managed_record;
use camp;

if ($ENV{'HTTP_HOST'} eq 'www.canonizer.com') {
	# don't belong on a test server so go here:
	$Response->Redirect('http://canonizer.com');
}

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
my $header = '<table><tr><td class="topic">Canonizer Main Page</td><td>&nbsp &nbsp</td><td style="font-size: 70%">(This is a free open source beta system being developed by <a href="http://' . func::get_host() . '/topic.asp/4">volunteers</a>.<br>Please be patient with what we have so far and/or be willing to help.)</td></tr></table>';

&display_page($title, $header, [\&identity, \&canonizer, \&as_of, \&search, \&main_ctl], [\&canonized_list]);

##############
# start subs #
##############

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

	my $namespace_select_str = func::make_namespace_select_str($dbh, $namespace);

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

<br>

<h3>What is canonizer.com?</h3>
<br>
<p>This is a consensus building open survey system designed to
rigorously measure moral expert or scientific consensus.  It is a wiki
based system that eliminates edit wars by giving users the ability to
create, join, and develop camps.  It enables experts to control
collaboratively developed concise descriptions of the best moral or
scientific theories, in the most agreed on terminology.  It provides
relative quantitative measures of expert, non expert... consensus for
each.  Scientific data and better arguments eventually falsify
incorrect theories.  You can definitively know a theory has been
falsified to the degree the experts are abandoning the camps that
represent them and vice versa for good theories. </p>

<p>The camp tree structure and rules of operation, are set up to
encourage as much consensus as possible on any controversial or still
theoretical topic.  Most people think anti public sex education people
don't agree on much of anything with pro public sex education people.
Both camps believe the other camp is destroying their world.  But as
you can see in the public sex education topic below, there is
unanimous agreement by everyone that sex education is important.  They
only differ in that some think it should be taught in a more private
and personal way, while most others think public is ok.  Obviously,
what everyone is arguing about is far less important than the real
important issue - education.  This is typical of most everything
today.  Any time there is agreement, the conversation stops, and
people descend to ever less important areas till they find what they
disagree on.  This is the level where all the conversation takes place
in all the scientific journals, political forums, blogs, and most
everywhere.  It's an eternal yes, no, yes, no, childish debate that
blinds everyone to how much agreement there is on a great many
important things.  Most quickly tire of this, and therefore fail to
become informed. This is the obvious reason so many people are still
so poorly informed on issues of such critical moral importance. </p>

<p>Canonizer.com's camp structure encourages people to find the most
important issues, where most people can agree, so the emphasis can
stay at that much more important educational, actionable,
scientifically testable, law passing level.  The less important more
disagreeable issues can be pushed out of the way to lower level less
important sub camps.  It is possible to represent everyone's current
POV definitively, efficiently, concisely, quantitatively, and in real
time with history. </p>

<p>Filtering is flipped upside down.  Nothing is ever censored, and
the rules ensure all points of view are valued and maintained.  (In
other words, be wary of camps with little or no expert support)
Individuals are given the ability to select any prioritizing and
filtering canonization algorithm they wish.  In this way who the moral
or scientific experts are can be determined by you. </p><br>


<h3>Personal Canonized Values</h3><br>

<p>To find out what someone's beliefs and values are, click on their
ID to get to their personal canonized values page.  These personal
pages have a list of all supported camps.  When you meet a new person,
you can simply and easily share all your canonized values - comparing
and contrasting them.  Using the 'as of' box on the side bar, you can
find what people's canonized values were at any time in the past.  A
powerful way to easily testify of what you believe in and hope for, in
a collaborative way with all who share you beliefs.  You can also
create anonymous nick names and support camps anonymously if you
wish. </p> <br>


<h3>Eliminates problems of traditional petitions and surveys</h3><br>

<p>Do you have a grass roots effort trying to collect signatures on a
petition?  Would an online version, with a way to sign camps in a
reputable way help?  Do you want your effort to go viral?  Your
petition in a canonized camp statement is a very easy and free way to
do all this.  And of course, unlike traditional petitions, which can't
change once the first person has signed, statements here continueally
grow, progress, and adapt to the times.  Anyone can propose new
changes and any camp member can object to any changes - preventing
them from going live.  In this case it can always be added to a
competing sibling or supporting sub camp so you can find everyone that
agrees with you.  <p><br>

<h3>Canonized Feedback on Your Web Pages</h3><br>
<p>Do you have thousands of useless comments for feedback on your web
pages from the masses about products, beliefs, or anything?  Would you
like to get all the similar ones grouped, concisely stated,
quantitatively measured, or canonized on your web pages for free?  You
can now create a topic in the canonizer for such, and then add a
simple block of HTML to your web page to show the information on your
page as is done here: <a
href="http://home.comcast.net/~brent.allsop">http://home.comcast.net/~brent.allsop</a>.
</p><br>

<h3>Canonized Reputations Building</h3><br>

<p>Do you live in Nigeria, yet want to do business online?  Do you
have a professional service or product that is, in your POV, the best?
Do you have lots of happy customers willing to prove it?  Is everybody
ignoring your collection of testimonials?  Then you can get such
canonized.  Nobody puts much creed in a collection of testimonials,
but a canonized reputation is very reputable since it is an open
system where both pro and con customers can contribute.  For an
example, see this topic on <a href="
http://canonizer.com/topic.asp/18">who is the best family
dentist</a>.</p> <br>

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

	$Response->Write(topic::canonized_list($dbh, $sth, $Session->{'as_of_mode'}, $Session->{'as_of_date'}, $Session->{'canonizer'}, $Session->{'filter'}));

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

