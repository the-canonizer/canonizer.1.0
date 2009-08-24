<% 

use LWP;
# use LWP::Debug qw(+);
my $browser = LWP::UserAgent->new;

my $only_x = 0;

$Response->{Buffer} = 0;

my @entries = (

{'url' => 'http://en.wikipedia.org/wiki/Qualia',
 'str' => q{<p>John Smytheis is currently concisely stating, collaboratively developing, and definitively declaring his current beliefs on this issue in the <a href="http://canonizer.com/topic.asp/88/14" class="external text" title="http://canonizer.com/topic.asp/88/14" rel="nofollow">Smythies-Carr Hypothesis camp</a> on the Theories of Mind and Consciousness topic at <a href="http://canonizer.com" class="external text" title="http://canonizer.com" rel="nofollow">canonizer.com</a>. (User id: <a href="http://canonizer.com/support_list.asp?nick_name_id=97" class="external text" title="http://canonizer.com/support_list.asp?nick_name_id=97" rel="nofollow">john lock</a>) His beliefs also include that which is contained in and he has helped develop the <a href="http://canonizer.com/topic.asp/88/6" class="external text" title="http://canonizer.com/topic.asp/88/6" rel="nofollow">Consciousness is Representational and Real</a> camp, and all other parent camps above it. As ever more experts continue to contribute to this open survey on the best theories of consciousness the <a href="http://canonizer.com/topic.asp/88/6" class="external text" title="http://canonizer.com/topic.asp/88/6" rel="nofollow">Representational and Real camp</a> continues to extend its lead in the amount of <a href="http://canonizer.com/topic.asp/53/11" class="external text" title="http://canonizer.com/topic.asp/53/11" rel="nofollow">scientific consensus</a> it has compared to all other theories of consciousness. Though John is in the current consensus camp at this level, his particular valid theories about what qualia are and where they are located diverge from the majority. The <a href="http://canonizer.com/topic.asp/88/14" class="external text" title="http://canonizer.com/topic.asp/88/14" rel="nofollow">Smythies-Carr Hypothesis camp</a> is a competitor to the more well accepted <a href="http://canonizer.com/topic.asp/88/17" class="external text" title="http://canonizer.com/topic.asp/88/17" rel="nofollow">Mind-Brain Identity Theory camp</a>. The experts in that camp believe the best theory is that qualia are something in our brain in a growing set of diverse, possible, and concisely stated ways. The people in John's camp believe qualia are a property of something causally connected to, yet contained in the higher dimensional space described in string theory.</p>} },

{'url' => 'http://en.wikipedia.org/wiki/Qualia',
 'str' => q{<p>This 3 Laws paper also was the first to propose the theoretical idea of 'effing' the ineffable .though they didn't call it such..<sup id="cite_ref-\d+" class="reference"><a href="#cite_note-\d+"><span>.</span>\d+<span>.</span></a></sup> They proposed that the phenomenal nature of qualia could be communicated .as in "oh THAT is what salt tastes like". if brains could be appropriately connected with a "cable of neurons". If this turned out to be possible this would scientifically prove or objectively demonstrate the existence and the nature of qualia. This idea of effing the ineffable is being further developed in the <a href="http://test.canonizer.com/topic.asp/88/6" class="external text" title="http://test.canonizer.com/topic.asp/88/6" rel="nofollow">Consciousness is Representational and Real</a> camp at canonizer.com.</p>} },

{'X' => 0,
 'url' => 'http://en.wikipedia.org/wiki/User_talk:Jw2035',
 'str' => q{<h2><span class="editsection">[<a href="/w/index.php?title=User_talk:Jw2035&amp;action=edit&amp;section=1" title="Edit section: New Proposal for using canonizer.com?">edit</a>]</span> <span class="mw-headline">New Proposal for using canonizer.com?</span></h2>
<p>Hi Jw2035. It's me, Brent Allsop, possibly still one of your less liked Wikipedia editors. I think we got off to a bad start, possibly both of us, or at least me, not initially fully understanding the other. I'd like to apologize for doing so.</p>
<p>Also, there has been quite a bit of dialog by several people on the issues we started about using <a href="http://canonizer.com" class="external text" title="http://canonizer.com" rel="nofollow">canonizer.com</a> as a trusted reference in wikipedia in certain situations. Some of it has been scattered across a bunch of talk pages of various articles and most of it has been consolidated in a <a href="http://canonizer.com/topic.asp/104" class="external text" title="http://canonizer.com/topic.asp/104" rel="nofollow">topic</a> we created at canoniazer.com for this purpose.</p>
<p>Also, in particular, there has been a request to <a href="http://en.wikipedia.org/wiki/Talk:Qualia#Smythies_section_needs_rewriting" class="external text" title="http://en.wikipedia.org/wiki/Talk:Qualia#Smythies_section_needs_rewriting" rel="nofollow">rewrite the John Smythies section</a> in the article on Qualia. We've made a proposal to do this, definitively and in a trusted way by referring to his beliefs being supported or signed by him <a href="http://canonizer.com/topic.asp/88/14" class="external text" title="http://canonizer.com/topic.asp/88/14" rel="nofollow">here</a>. Some experts, such David Chalmers, many claim don't still believe some of what they've argued for in their publications long ago. But there is no more trusted and definitive way to document someone's current beliefs than a 'camp' which they've basically signed (can be removed at any time), or are currently supporting, definitively and concisely indicating what they believe, as is being done here right?</p>
<p>Anyway, I apologize for this post here if it is not welcome. Feel free to remove it once you read it. I just wanted to be sure you were aware of what has been proposed as a change to the John Smythies section in the article on qualia, before one of us adds it to the article. I didn't know of any other way to contact you to be sure this would be OK with you before one of us make this change?</p>
<p>Thanks for all you do to make Wikipedia data high quality -- <a href="/w/index.php?title=User:Brent_Allsop&amp;action=edit&amp;redlink=1" class="new" title="User:Brent Allsop (page does not exist)">Brent.Allsop</a> (<a href="/wiki/User_talk:Brent_Allsop" title="User talk:Brent Allsop">talk</a>) 17:08, 15 August 2009 (UTC)</p>} },

{'url' => 'http://en.wikipedia.org/wiki/Philosophy_of_mind',
 'str' => q {<li><a href="http://canonizer.com/topic.asp/88" class="external text" title="http://canonizer.com/topic.asp/88" rel="nofollow">Canonizer.com open survey topic on theories of consciousness</a>. Anyone can participate in the survey or .*canonize.*their beliefs. Expertise of participators is determined by a <a href="http://canonizer.com/topic.asp/81" class="external text" title="http://canonizer.com/topic.asp/81" rel="nofollow">Peer Ranking Process</a> that can be used to produce a quantitative measure of scientific consensus for each theory.</li>} },

{'url' => 'http://psychology.wikia.com/wiki/Psychology_Wiki:Tasks_To_Do_List',
 'str' => q{</li><li>For controversial topics, it would be great to know how much scientific consensus there is at any time for all sides of an issue.  <a href="http://canonizer.com" class="external text" title="http://canonizer.com" rel="nofollow">Canonizer.com</a> is being developed with the goal of measuring scientific consensus on such issues.  If survey topics have not yet been created for particular controversial issues, they can be created, and links to them added on related articles showing the current measure of scientific consensus on all sides of any issue.} },

{'url' => 'http://psychology.wikia.com/wiki/Qualia#Scientific_Consensus_for_Qualia.3F',
 'str' => q{<a rel="nofollow" name="Scientific_Consensus_for_Qualia.3F" id="Scientific_Consensus_for_Qualia.3F"></a><h2><span class="editsection">.<a href="/index.php.title=Qualia&amp;action=edit&amp;section=7" title="Edit section: Scientific Consensus for Qualia." rel="nofollow">edit</a>.</span> <span class="mw-headline">Scientific Consensus for Qualia.</span></h2>
<p>There are lots of famous people that have argued for and against the importance of the idea of qualia.  But is there a significant amount of scientific consensus on either side of this issue.  The open survey system at <a href="http://canonizer.com" class="external text" title="http://canonizer.com" rel="nofollow">canonizer.com</a> is being developed by a growing grass roots group of people to rigorously measure <a href="http://canonizer.com/topic.asp/81" class="external text" title="http://canonizer.com/topic.asp/81" rel="nofollow">scientific consensus</a>.
</p><p>There is a topic on <a href="http://canonizer.com/topic.asp/88/6" class="external text" title="http://canonizer.com/topic.asp/88/6" rel="nofollow">theories of consciousness</a> getting started.  All experts and non experts are invited to quantitatively communicate to everyone what they currently think on this issue.
</p><p>Out of the gate the scientific consensus is clearly in the pro qualia <a href="http://canonizer.com/topic.asp/88/6" class="external text" title="http://canonizer.com/topic.asp/88/6" rel="nofollow">Consciousness is representational and real</a> camp  with such distinguished supporters as <a href="http://canonizer.com/topic.asp/81/4" class="external text" title="http://canonizer.com/topic.asp/81/4" rel="nofollow">Steven Lehar</a>, <a href="http://canonizer.com/topic.asp/81/17" class="external text" title="http://canonizer.com/topic.asp/81/17" rel="nofollow">John Smythies</a> and a growing number of others.  The supporters of that camp believe no other theory of consciousness will ever be able to match the amount of scientific consensus this camp will be able to maintain going forward, and also that eventually there will be demonstrable scientific proof that will convert all others to this camp.
</p>} },

{'url' => 'http://psychology.wikia.com/wiki/Representative_realism#Scientific_Consensus_for_Representative_Realism.3F',
 'str' => q{<a rel="nofollow" name="Scientific_Consensus_for_Representative_Realism.3F" id="Scientific_Consensus_for_Representative_Realism.3F"></a><h2><span class="editsection">.<a href="/index.php.title=Representative_realism&amp;action=edit&amp;section=8" title="Edit section: Scientific Consensus for Representative Realism." rel="nofollow">edit</a>.</span> <span class="mw-headline">Scientific Consensus for Representative Realism.</span></h2>
<p>The debate for and against representative realism has likely been raging for as long as there have been philosophers.  How has the amount of consensus amongst experts for one side or the other changed over history.  Could a revolution be taking place and one side significantly breaking out in the lead amongst experts during the last few decades.
</p><p>There is a tool being developed at <a href="http://canonizer.com" class="external text" title="http://canonizer.com" rel="nofollow">canonizer.com</a> with the goal of rigorously measuring <a href="http://canonizer.com/topic.asp/81" class="external text" title="http://canonizer.com/topic.asp/81" rel="nofollow">scientific consensus</a> going forward.  There is a new topic getting started on <a href="http://canonizer.com/topic.asp/88/6" class="external text" title="http://canonizer.com/topic.asp/88/6" rel="nofollow">theories of consciousness</a>.  All experts and non experts are invited to quantitatively communicate to everyone what they currently think on this issue.  The more people that get involved, the more comprehensive the survey data will be.
</p><p>Out of the gate the scientific consensus is clearly in the <a href="http://canonizer.com/topic.asp/88/6" class="external text" title="http://canonizer.com/topic.asp/88/6" rel="nofollow">Consciousness is representational and real</a> camp with such distinguished supporters as <a href="http://canonizer.com/topic.asp/81/4" class="external text" title="http://canonizer.com/topic.asp/81/4" rel="nofollow">Steven Lehar</a>, <a href="http://canonizer.com/topic.asp/81/17" class="external text" title="http://canonizer.com/topic.asp/81/17" rel="nofollow">John Smythies</a> and a growing number of others.  But perhaps this early lead is just because supporters of some other more well accepted theory of consciousness haven't yet started supporting their ideas here.  
</p><p>There is obviously always the possibility that demonstrable scientific results are about to be achieved that will convert everyone to the 'true' camp.  Surely such, the scientific discovery of what the mind truly is, would be amongst the greatest scientific achievements of all time.  Or maybe the camps that claim we will never know are the ones that are right.
</p>} },

{'X' => 0,
 'url' => '',
 'str' => q{XXX} },

);

%>

<html>
<head>
<title>Web Monitor Page</title>
</head>
<body>

<h1>Web Monitor Page</h1>

<ul>
<%

foreach my $entry (@entries) {

	if ($only_x) {
	   next unless $entry->{'X'};
	}

	%>
	<li>Checking URL: <a href="<%=$entry->{'url'}%>"><%=$entry->{'url'}%></a>
	<hr>
	<%=$entry->{'str'}%>
	<hr>
	<%

	my $url = $entry->{'url'};

	last unless $url;

	my $response = $browser->get($url);

	die "Couldn't get OGC balance ($url) ", $response->status_line
		unless $response->is_success;

	my $content = $response->content;

	my $str = $entry->{'str'};

	$str =~ s|\(|.|g;
	$str =~ s|\)|.|g;
	$str =~ s|\[|.|g;
	$str =~ s|\]|.|g;
	$str =~ s|\?|.|g;

	$url =~ m|/([^/]*)$|;
	my $id = $1;

	if ($content =~ m|$str|) {
		%>
		<font color="green">Matched.</font><br>
		<%
	} else {
		%>
		<font size=4 color="red">NO MATCH!!!!</font><br>
		<%
	}

	%>
	</li><br><br><br>
	<%

}


%>
</ul>

</body>
</html>
