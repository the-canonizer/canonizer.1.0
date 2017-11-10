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

		<%
		if ($uri =~ 'profile_prefs.asp') {
		    %>
			<p>Preferences</p>
		    <%
		} else {
		    %>
			<p>Preferences</p>
		    <%
		}

		if ($uri =~ 'profile_id.asp') {
		    %>
			<p>Identity</p>
		    <%
		} else {
		    %>
			<p>Identity</p>
		    <%
		}

		if ($uri =~ 'profile_attrib.asp') {
		    %>
			<p>Attributes</p>
		    <%
		} else {
		    %>
			<p>Attributes</p>
		    <%
		}
		%>

	<%
}

%>
