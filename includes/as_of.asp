

<%

# modes:	selections:


local $as_of = 0;	# make this global so everyone can see it.


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

  <table border = 1 width = 180>
  <form name=as_of_form><tr><td>
  <table>
    <tr>
      <td colspan=2>
	Moral state of the art:<br>
      </td>
    </tr>
    <tr>
	<td><input type=radio value=review name=as_of <%=$review_checked%> onclick=javascript:change_as_of('review/'+document.as_of_form.as_of_date.value)></td><td>include review</td>
    </tr>
    <tr>
	<td><input type=radio value=default name=as_of <%=$default_checked%> onclick=javascript:change_as_of('default/'+document.as_of_form.as_of_date.value)></td><td>default</td>
    </tr>
    <tr>
	<td><input type=radio value=as_of name=as_of <%=$as_of_checked%> onclick=javascript:change_as_of('as_of/'+document.as_of_form.as_of_date.value)></td><td>as of (yy/mm/dd):<br>
		<input type=text name=as_of_date value='<%=$as_of_date_value%>' size=8 size=10></td>
    </tr>
  </table>
  </td></tr></form>
  </table>

<%

}

%>
