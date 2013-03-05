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

<p>Canonizer.com solves the critical problems suffered by Wikipedia.
It solves edit wars by providing contributors the ability to create
and join camps and it provides a measure of information reliability by
providing relative measures of user selectable expert consensus.
Unlike other information sources, such as peer reviewed documents,
where there is far too much information for any individual to fully
comprehend (We just blew past 20K documents in the field of
consciousness) this open survey system provides real time concise and
quantitative descriptions of the current and emerging leading
theories.  Theories being falsified by any new scientific data can be
instantly measured to the degree experts abandon those theories for
newer better ones.  The non repetitive, continually ratcheting up
process significantly accelerates and amplifies the education and
wisdom of the entire crowd.</p>

<p>Leading minority experts can first find each other, and then build
a concisely defined consensus in a consistent language by pushing
lesser important disagreeable issues that inevitably emerge and are
traditionally focused on, out of the way into lower sub camps.  This
allows a consensus to be negotiated and built around and the focus to
stay on the most important actionable issues.  Since anyone can
contribute (even high school students have made significant
contributions) and everyone can choose (selecting a canonizer
algorithm) who they think are the experts, it enables the emerging
experts to have a concise and quantitative measure of what the
primitive popular crowd still believes, comparable to what the
emerging experts believe, so they can know, concisely and
quantitatively, what kind of evidence is working and what isn't, with
a focus on discovering what evidence would be required to convert
more.</p>

<p>When an expert publishes a morally important paper, possibly
containing arguments that convince only the author, they need to know
who and how many people agree, how many don't, and why.  In most all
sources today, there tends to be infinitely repetitive and painful yes
/ no assertions on all sides, on lesser important issues, all making
everyone afraid of such topics, preventing good communication.  This
situation with no clear concise descriptions of the best scientific
theories, leads everyone to believe there is or may not be any expert
consensus.  In this environment the still mistaken crowd tends to
easily drown out any emerging minority experts.  With Canonizer.com
diversity is valued and drives the system forward, rather than
destroying it.  Knowing concisely and quantitatively, what everyone
currently believes, can eliminate all these communication prevention
issues and fears - even making still 'religious' issues quite
enjoyable for all.  Such can finally enable emerging expert minorities
to make progress at being heard above the bleating noise of the crowd
at a measurably accelerating rate.</p>



<p>That which you can measure, improves.</p>

<p>Knowing, concisely and quantitatively, everyone else who wants what
you do, and what is still standing in your way, is the hardest part.
Once you know enough people that want the same thing you do, it will
just happen.</p>

<p><b>James Carroll is the author of this Tech Report:
<ul>
<li>
<a
href="http://canonizer.com/files/2012_amplifying_final.pdf"><font style="font-size:20px">Amplifying
the Wisdom of the Crowd,</font><br>Building and Measuring for Expert and Moral
Consensus</a>
</li>
</ul>
</b>
</p>


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

