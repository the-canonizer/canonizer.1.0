

<%

# modes:	selections:


my $as_of = 0;	# make this global so everyone can see it.


sub as_of {

	my $protocol = 'http';
	if ($ENV{'HTTPS'} eq 'on') {
		$protocol = 'https';
	}

	my $qs = '?';
	if ($ENV{'QUERY_STRING'}) {
		$qs .= ($ENV{'QUERY_STRING'} . '&');
	}

 	my $url = 'http://' . &func::get_host() . '/change_as_of.asp?destination=' . $protocol . '://' . &func::get_host() . $ENV{'SCRIPT_NAME'} . $qs . 'as_of=';

	if ($Request->QueryString('as_of_mode')) {
		$Session->{'as_of_mode'} = $Request->QueryString('as_of_mode');
	}
	if ($Request->QueryString('as_of_date')) {
		$Session->{'as_of_date'} = $Request->QueryString('as_of_date');
	}

	my $review_checked = '';
	my $default_checked = '';
	my $as_of_checked = '';
	my $as_of_date_value = '';
	if ($Session->{'as_of_date'}) {
		$as_of_date_value = $Session->{'as_of_date'};
	}
	if ($Session->{'as_of_mode'} eq 'review') {
		$review_checked = 'checked';
	} elsif ($Session->{'as_of_mode'} eq 'as_of') {
		$as_of_checked = 'checked';
	} else {
		$default_checked = 'checked';
	}

%>

<script language:javascript>
	function change_as_of(as_of) {
		window.location = '<%=$url%>' + as_of;
        }
</script>

<div class="as_of">

<h1>As Of</h1>

<form name=as_of_form>
<p><input type=radio value=review name=as_of <%=$review_checked%> onclick=javascript:change_as_of('review/'+document.as_of_form.as_of_date.value)>include review</p>
<p><input type=radio value=default name=as_of <%=$default_checked%> onclick=javascript:change_as_of('default/'+document.as_of_form.as_of_date.value)>default</p>
<p><input type=radio value=as_of name=as_of <%=$as_of_checked%> onclick=javascript:change_as_of('as_of/'+document.as_of_form.as_of_date.value)>as of (yy/mm/dd):</p>
<p><input type=text name=as_of_date value='<%=$as_of_date_value%>' size=8 maxlength=8 onchange=javascript:change_as_of('as_of/'+document.as_of_form.as_of_date.value)></p>
</form>

</div>

<%

}

%>
