<%
sub main_ctl {

	my $uri = $ENV{'REQUEST_URI'};
	%>

  	<div class="main_ctl">

  	<h1>Navigation</h1>

	<script language="JavaScript1.2">
	function open_help() {
		window.open("http://<%=&func::get_host()%>/help.asp", "_blank",
			"status=1, toolbar=1, location=1, menubar=1, directories=1, resizable, scrollbars=1, width=400, height=400");
	}
	</script>

	<p><a href="javascript: open_help()">Help</a></p>

  	<%
	if (($uri eq '/') || ($uri =~ 'index.asp')) {
	    %>
	    <p id="selected">Canonizer Main</p>
	    <%
	} else {
	    %>
	    <p><a href='http://<%=&func::get_host()%>/'>Canonizer Main</a></p>
	    <%
	}

	if ($Session->{'cid'}) { # mode 1 or 2
		if ($uri =~ '/secure/profile_') {
			    %>
			    <p id="selected">Account Info</p>
			    <%
		} else {
			    %>
			    <p><a href='https://<%=&func::get_host()%>/secure/profile_id.asp'>Account Info</a></p>
			    <%
		}
	}

	if ($uri =~ m|^/topic\.asp/10|) {
	    %>
	    <p id="selected">What Is Canonizer.com</p>
	    <%
	} else {
	    %>
	   <p><a href = 'http://<%=&func::get_host()%>/topic.asp/10'>What Is Canonizer.com</a></p>
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
