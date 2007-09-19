<%
sub main_ctl {

	my $uri = $ENV{'REQUEST_URI'};
%>
  	<div class="main_ctl">
  	
  	<h1>Navigation</h1>
  	
  	<%
	if (($uri eq '/') || ($uri =~ 'index.asp')) {
	    %>
	    <p id="selected">Main (Top 10)</p>
	    <%
	} else {
	    %>
	    <p><a href='http://<%=&func::get_host()%>/'>Main (Top 10)</a></p>
	    <%
	}

	if ($uri =~ '/secure/profile_') {
	    %>
	    <p id="selected">Personal Info</p>
	    <%
	} else {
	    %>
	    <p><a href='https://<%=&func::get_host()%>/secure/profile_id.asp'>Personal Info</a></p>
	    <%
	}


	if ($uri =~ m|^/topic\.asp\?topic_num=10|) {
	    %>
	    <p id="selected">What Is The Canonizer</p>
	    <%
	} else {
	    %>
	   <p><a href = 'http://<%=&func::get_host()%>/topic.asp?topic_num=10'>What Is The Canonizer</a></p>
	    <%
	}

	if ($uri =~ m|^/browse.asp|) {
		%>
	<p id="selected">Browse</p>
		<%
	} else {
		%>
		<p><a href = "http://<%=func::get_host()%>/browse.asp">Browse</a>
		<%
	}

	if ($uri =~ 'new_topic.asp') {
	    %>
	    <p id="selected">Create New Topic</p>
	    <%
	} else {
	    %>
	    <p><a href='https://<%=&func::get_host()%>/secure/new_topic.asp'>Create New Topic</a></p>
	    <%
	}

	if ($uri =~ 'upload.asp') {
	    %>
	    <p id="selected">Upload File</p>
	    <%
	} else {
	    %>
	    <p><a href='https://<%=&func::get_host()%>/secure/upload.asp'>Upload File</a></p>
	    <%
	}


#	<a href="">Organizations</a>
#	<a href="">Personal Pages</a>


	%>
	</div>
	<%

}

%>
