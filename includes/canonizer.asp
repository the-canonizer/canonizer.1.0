
<%

use canonizers;


sub canonizer {

	my $protocol = 'http';

	if ($ENV{'HTTPS'} eq 'on') {
		$protocol = 'https';
	}

	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs .= '?' . $ENV{'QUERY_STRING'};
		$qs =~ s|\&?\??(canonizer=\d+)||; # if we change canonizer or filter,
		$qs =~ s|\&?\??(filter=\d+)||;    # we don't want old values in the qs to set them back.
	}

	my $canonizer_path_info = $ENV{'PATH_INFO'};
	if ($canonizer_path_info) {
		$qs = $canonizer_path_info . $qs;
	}

	my $url      = 'http://' . &func::get_host() . '/change_canonizer.asp';
	my $dest_url = $protocol . '://' . &func::get_host() . $ENV{'SCRIPT_NAME'} . $qs;

	my $filter = $Session->{'filter'};
	if (!((length($filter)>0) && ($filter >= 0) && ($filter < 100))) {
	   $filter = "0.001";
	   $Session->{'filter'} = $filter;
	}

%>

<script language:javascript>

function change_canonizer(new_canonizer) {
	// alert('<%=$url%>' + new_canonizer);
	// window.location = '<%=$url%>' + new_canonizer;
	document.canonizer_form.submit();
}

function change_filter(new_filter) {
	if ((new_filter >= 0) && (new_filter < 100)) {
            document.canonizer_form.submit();
	} else {
            alert(new_filter + " must start at 0 and be less than 100.");
  	}
}

</script>

	<div class="canonizer">

	<h1>Canonizer</h1>

	<p>Canonizer algorithm:</p>
	<form name="canonizer_form" action="<%=$url%>" method="post">

	<p><select class=bar name=canonizer onchange="javascript:change_canonizer(value)">

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

	<p>Filter &lt; <input type=text name=filter size=10 value="<%=$filter%>" onchange="javascript:change_filter(value)"></p>

	<input type="hidden" name="destination" value="<%=$dest_url%>">

	</form>

	</div>

<%
}
%>
