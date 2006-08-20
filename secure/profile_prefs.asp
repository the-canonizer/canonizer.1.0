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

sub profile_prefs {

%>
<form>
<table border = 0>

<tr><th>This is where you set your preferences, such as what canonizers you'd like to use</th></tr>

</table>
</form>

<%
}

########
# main #
########

&display_page('CANONIZER', 'Personal Info', [\&identity, \&search, \&main_ctl], [\&profile_prefs], \&profile_tabs);

%>
