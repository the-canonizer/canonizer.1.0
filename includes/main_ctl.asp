

<%

sub main_ctl {

	my $uri = $ENV{'REQUEST_URI'};

%>

  <table border = 1 width = 180>
  <tr><td>
    <table border = 0 width = 100%>

	<%
	if (($uri eq '/') || ($uri =~ 'index.asp')) {
	    %>
	    <tr><td bgcolor=white>Main (Top 10)</td></tr>
	    <%
	} else {
	    %>
	    <tr><td><a href='http://<%=&func::get_host()%>/'>Main (Top 10)</a></td></tr>
	    <%
	}

	if ($uri =~ '/secure/profile_') {
	    %>
	    <tr><td bgcolor=white>Personal Info</td></tr>
	    <%
	} else {
	    %>
	    <tr><td><a href='https://<%=&func::get_host()%>/secure/profile_prefs.asp'>Personal Info</a></td></tr>
	    <%
	}


	if ($uri =~ m|^/topic\.asp\?topic_num=10|) {
	    %>
	    <tr><td bgcolor=white>What Is The Canonizer</td></tr>
	    <%
	} else {
	    %>
	    <tr><td><a href = 'http://<%=&func::get_host()%>/topic.asp?topic_num=10'>What Is The Canonizer <%=$uri%></a></td></tr>
	    <%
	}

	if ($uri =~ m|^/browse.asp|) {
		%>
		<tr><td bgcolor=white>Browse</td></tr>
		<%
	} else {
		%>
		<tr><td><a href = "http://<%=func::get_host()%>/browse.asp">Browse</a></td></tr>
		<%
	}

	if ($uri =~ 'new_topic.asp') {
	    %>
	    <tr><td bgcolor=white>Create New Topic</td></tr>
	    <%
	} else {
	    %>
	    <tr><td><a href='https://<%=&func::get_host()%>/secure/new_topic.asp'>Create New Topic</a></td></tr>
	    <%
	}
	%>

	<tr><td><a href="">Organizations</a></td></tr>
	<tr><td><a href="">Personal Pages</a></td></tr>

    </table>
  </td></tr>
  </table>

<%

}

%>
