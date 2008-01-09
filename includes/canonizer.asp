
<%

use canonizers;


sub canonizer {

	my $protocol = 'http';

	if ($ENV{'HTTPS'} eq 'on') {
		$protocol = 'https';
	}

	my $qs = '?';
	if ($ENV{'QUERY_STRING'}) {
		$qs .= $ENV{'QUERY_STRING'};
		$qs =~ s|\&?\??(canonizer=\d+)||; # if we change canonizer, we don't want old canonizer values in the qs to set it back.
		$qs .= '&';
	}

	my $canonizer_path_info = $ENV{'PATH_INFO'};
	if ($canonizer_path_info) {
		$qs = $canonizer_path_info . $qs;
	}

	my $url = 'http://' . &func::get_host() . '/change_canonizer.asp?destination=' . $protocol . '://' . &func::get_host() . $ENV{'SCRIPT_NAME'} . $qs . 'canonizer=';




%>

<script language:javascript>

function change_canonizer(new_canonizer) {
	// alert('<%=$url%>' + new_canonizer);
	window.location = '<%=$url%>' + new_canonizer;
}

</script>

	<div class="canonizer">

	<h1>Canonizer</h1>

	<p>Canonizer:</p>
	<p><select class=bar name = canonizer onchange = javascript:change_canonizer(value)>

	<%
	my $canonizer;
	my $count = 0;
	my $session_canonizer = $Session->{'canonizer'};

	foreach $canonizer (@canonizers::canonizer_array) {
		my $selected_str = '';
		if ($count == $session_canonizer) {
			$selected_str = 'selected';
		}
		%>
		<option value=<%=$count++%> <%=$selected_str%>><%=$canonizer->{'name'}%></option>
		<%
	}
	%>

	</select></p>

	<p><a href='http://<%=&func::get_host()%>/topic.asp/53'>Algorithm Information</a></p>

	</div>

<%
}
%>
