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

<p>The <b>Profile Attributes</b> page is where you specify your
personal attributes, affiliations and other reputation information.
The canonizers will use this information to judge the amount of
support you are able to give to POV issues you support.</p>

<p>But of course you must first register (or login) before you can
specify these things and give support to POV issues.</p>

You can register <a href = "http://<%=&func::get_host()%>/register.asp">here</a>.

<%
}

sub profile_attrib {

%>
<form method = post action = "http://canonizer.com/cgi-bin/env.pl">

<table border = 0>
  <tr><th align = left colspan = 2>Personal Attributes:</th><td>publish*<br>(<input type = checkbox> all)</td></tr>
  <tr><td>Birthday (mm/dd/yyyy):</td><td><input type = text size = 10 name = birthday value = "09/27/1959"><td align = center><input type = checkbox name = birthday_publish checked></td></tr>
  <tr><td>Gender:</td><td>Male <input type = radio name = male_female value = m checked>, Female <input type = radio name = male_female value = f></td><td align = center><input type = checkbox name = male_female_publish checked></td></tr>
  <tr><td>Race:</td><td><select name = rece>
		<option value = ns></option>
		<option value = Asian>Asian</option>
		<option value = Black>Black</option>
		<option value = Caucasian selected>Caucasian</option>
		<option value = Hispanic>Hispanic</option>
		<option value = "Native_American">Native American</option>
		</select></td><td align = center><input type = checkbox name = male_female_publish checked></td></tr>
  <tr><td>Sexual Preference:</td><td>Male <input type = checkbox name = male_sexual_preference>, Female<input type = checkbox name = female_sexual_preference checked></td><td align = center><input type = checkbox name = male_female_publish></td></tr>

  <tr><td height = <%=$spacer%> colspan = 2></td></tr>


  <tr><th align = left colspan = 3>Beliefs, Ways of Life, Religious Affiliations</th></tr>

  <tr><th align = left colspan = 3><%=&indent(1)%>Atheist</th></tr>
  <tr><td colspan = 2><%= indent(2)%><input type = checkbox name = "Atheist_Belief" checked> Atheist Belief</td><td align = center><input type = checkbox name = Atheist_publish checked></td></tr>


  <tr><th align = left colspan = 3><%=&indent(1)%>Christian</th></tr>
  <tr><td><input type = checkbox name = "Catholic"></td><td>Catholic</td></tr>



  <tr><td><input type = checkbox name = "Extropian" checked></td><td><a href = "http://extropy.org/">Extropian</a></td></tr>
  <tr><td><input type = checkbox name = "Latter Day Saint" checked></td><td><a href = "http://lds.org">Latter Day Saint</a></td></tr>
  <tr><td><input type = checkbox name = "Mormon Transhumanist Association" checked></td><td><a href = "http://transfigurism.org/">Mormon Transhumanist Association</a></td></tr>
  <tr><td><input type = checkbox name = "World Transhumanist Association" checked></td><td><a href = "http://www.transhumanism.org">World Transhumanist Association</a></td></tr>
  <tr><td height = <%=$spacer%> colspan = 2></td></tr>
  <tr><th align = left colspan = 2>Political Affiliations</th></tr>
  <tr><td><input type = checkbox name = "U.S. Democratic Party" Checked></td><td>U.S. Democratic Party</td></tr>
  <tr><td><input type = checkbox name = "U.S. Green Party"></td><td>U.S. Green Party</td></tr>
  <tr><td><input type = checkbox name = "U.S. Libertarian Party"></td><td>U.S. Libertarian Party</td></tr>
  <tr><td><input type = checkbox name = "U.S. Republican Party"></td><td>U.S. Republican Party</td></tr>

  <tr><td height = <%=$spacer%> colspan = 2></td></tr>

  <tr><td colspan = 2 align = center><input type = submit name = submit value = update></td></tr>

</table>
</form>

<p>* If the publish box is not checked for the attribute, the information will
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

