<%
if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect('https://' . &func::get_host() . $ENV{"SCRIPT_NAME"} . $qs);
}

########
# main #
########

&display_page('Personal Info', 'Personal Info', [\&identity, \&search, \&main_ctl], [\&profile_prefs], \&profile_tabs);



########
# subs #
########

sub profile_prefs {

%>

<p>This is where you set your preferences, such as what canonizers you'd like to use</p>

<%
}

%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/profile_tabs.asp"-->

