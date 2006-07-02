<%

sub profile_tabs {

	my $uri = $ENV{'REQUEST_URI'};

	my $server_name = '';
	if (&func::get_test_target_host() eq $ENV{'SERVER_NAME'}) {
		$server_name = &func::get_test_target_host();
	} else {
		$server_name = &func::get_target_host();
	}

	%>

	<table cellpadding=10 border=1>
	    <tr>
		<%
		if ($uri =~ 'profile_prefs.asp') {
		    %>
		    <th bgcolor = white><font face=arial>Preferences</font></td>
		    <%
		} else {
		    %>
		    <th><font face=areal><a href = "profile_prefs.asp">Preferences</a></font></td>
		    <%
		}

		if ($uri =~ 'profile_id.asp') {
		    %>
		    <th bgcolor = white><font face=arial>Identity</font></td>
		    <%
		} else {
		    %>
		    <th><font face=arial><a href = "profile_id.asp">Identity</a></font></td>
		    <%
		}

		if ($uri =~ 'profile_attrib.asp') {
		    %>
		    <th bgcolor = white><font face=arial>Attributes</font></th>
		    <%
		} else {
		    %>
		    <th><font face-arial><a href = "profile_attrib.asp">Attributes</a></font></th>
		    <%
		}
		%>
	</table>
	<%
}

%>
