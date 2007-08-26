<%
if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect('https://' . &func::get_host() . $ENV{"SCRIPT_NAME"} . $qs);
}
%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/profile_tabs.asp"-->

<%

my $spacer = 30;

my $all_the_way = 3;

sub indent {
	$num = $_[0];

	my $index = 0;
	my $ret_val = '';
	for ($index = 0; $index < $num; $index++) {
		$ret_val .= '&nbsp; &nbsp;';
	}
	return($ret_val);
}

sub advert_for_guest {
%>

The "Profile Attributes" page is where you specify your
personal attributes, affiliations and other reputation information.
The canonizers will use this information to judge the amount of
support you are able to give to POV issues you support.

But of course you must first register (or login) before you can
specify these things and give support to POV issues.

You can register <a href = "http://<%=&func::get_host()%>/register.asp">here</a>.

<%
}

sub profile_attrib {

%>

Non-functional mock up page.

<form method = post action = "http://canonizer.com/cgi-bin/env.pl">

Personal Attributes: publish *
<input type = checkbox> all
Birthday (mm/dd/yyyy):
<input type = text size = 10 name = birthday value = "09/27/1959">
<input type = checkbox name = birthday_publish checked>
Gender:
Male
<input type = radio name = male_female value = m checked>
Female
<input type = radio name = male_female value = f>
<input type = checkbox name = male_female_publish checked>
Race:
<select name = race>
		<option value = ns></option>
		<option value = Asian>Asian</option>
		<option value = Black>Black</option>
		<option value = Caucasian selected>Caucasian</option>
		<option value = Hispanic>Hispanic</option>
		<option value = "Native_American">Native American</option>
</select>
<input type = checkbox name = male_female_publish checked>
Sexual Preference:
Male
<input type = checkbox name = male_sexual_preference>
Female
<input type = checkbox name = female_sexual_preference checked>
<input type = checkbox name = male_female_publish>
Beliefs, Ways of Life, Religious Affiliations
Atheist
<input type = checkbox name = "Atheist_Belief" checked>
Atheist Belief
<input type = checkbox name = Atheist_publish checked>
Christian
<input type = checkbox name = "Catholic">
Catholic
<input type = checkbox name = "Extropian" checked>
<a href = "http://extropy.org/">Extropian</a>
<input type = checkbox name = "Latter Day Saint" checked>
<a href = "http://lds.org">Latter Day Saint</a>
<input type = checkbox name = "Mormon Transhumanist Association" checked>
<a href = "http://transfigurism.org/">Mormon Transhumanist Association</a>
<input type = checkbox name = "World Transhumanist Association" checked>
<a href = "http://www.transhumanism.org">World Transhumanist Association</a>

Political Affiliations
<input type = checkbox name = "U.S. Democratic Party" Checked>
U.S. Democratic Party
<input type = checkbox name = "U.S. Green Party">
U.S. Green Party
<input type = checkbox name = "U.S. Libertarian Party">
U.S. Libertarian Party
<input type = checkbox name = "U.S. Republican Party">
U.S. Republican Party
<input type = submit name = submit value = update>

</form>

* If the publish box is not checked for the attribute, the information will
not be given to anyone except through the canonizers anonymously.

<%
}

########
# main #
########

if (! $Session->{'cid'}) { # browsing as guest.
	&display_page('Personal Info', [\&identity, \&search, \&main_ctl], [\&advert_for_guest], \&profile_tabs);
} elsif (! $Session->{'logged_in'}) { # must login to validate before going to this secure page.
	$Response->Redirect("login.asp?destination=/secure/profile_attrib.asp");
} else {
	&display_page('Personal Info', [\&identity, \&search, \&main_ctl], [\&profile_attrib], \&profile_tabs);
}

%>

