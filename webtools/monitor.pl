#! /usr/bin/perl -w -I /usr/local/webtools

use strict;



# my $glip = q{
# a(b)c
# d(e)f
# };
# $glip =~ s/[\(|\)]/\./g;
# print("glip: '$glip'.\n");
# exit;

# my $debug = 0; # no debug
# my $debug = 1; # just status
my $debug = 2; # output content.

my @entries = (

{'url' => 'http://en.wikipedia.org/wiki/Qualia',
 'str' => q{<p>This 3 Laws paper also was the first to propose the theoretical idea of 'effing' the ineffable .though they didn't call it such..<sup id="cite_ref-47" class="reference"><a href="#cite_note-47" title=""><span>.</span>48<span>.</span></a></sup> They proposed that the phenomenal nature of qualia could be communicated .as in "oh THAT is what salt tastes like". if brains could be appropriately connected with a "cable of neurons". If this turned out to be possible this would scientifically prove or objectively demonstrate the existence and the nature of qualia. This idea of effing the ineffable is being further developed in the <a href="http://test.canonizer.com/topic.asp/88/6" class="external text" title="http://test.canonizer.com/topic.asp/88/6" rel="nofollow">Consciousness is Representational and Real</a> camp at canonizer.com.</p>} },

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

{'url' => '',
 'str' => q{XXX} },


);

use LWP;
# use LWP::Debug qw(+);
my $browser = LWP::UserAgent->new;


foreach my $entry (@entries) {

	my $url = $entry->{'url'};

	die "finished\n" unless $url;

	my $response = $browser->get($url);

	die "Couldn't get OGC balance ($url) ", $response->status_line
		unless $response->is_success;

	my $content = $response->content;


	my $str = $entry->{'str'};


	$url =~ m|/([^/]*)$|;
	my $id = $1;

	if ($content =~ m|$str|) {
		if ($debug) {
			print("'$id' matched.\n");
		}
	} else {
		if ($debug) {
			print("'$id: NO MATCH!\n");
			if ($debug > 1) {
				$content =~ s/[^\x20-\x7E|\n]/\./g;
				$content =~ s/[\(|\)]/\./g;
				$content =~ s/[\[|\]]/\./g;
				$content =~ s/\?/\./g;
				print("content: $content.\n");
				exit(0);
			}
		}
	}
}


