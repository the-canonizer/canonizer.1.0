

<%

# modes:	selections:


local $mode = 0;	# make this global so everyone can see it.


sub mode {

	my $script_name = $ENV{'SCRIPT_NAME'};
	my $login_url = 'https://' . &func::get_host() . "/secure/login.asp?destination=$script_name";
	my $logout_url = 'http://' . &func::get_host() . "/logout.asp?destination=$script_name";
	my $clear_url = 'http://' . &func::get_host() . "/logout.asp?clear=1&destination=$script_name";
	if ($ENV{'QUERY_STRING'}) {
		$login_url .= ('?' . $ENV{'QUERY_STRING'});
		$logout_url .= ('?' . $ENV{'QUERY_STRING'});
		$clear_url .= ('?' . $ENV{'QUERY_STRING'});
	}


%>

  <table border = 1 width = 180>
  <form><tr><td>
  <table>
    <tr>
      <td colspan=2>
	Moral state of the art:<br>
      </td>
    </tr>
    <tr>
	<td><input type=radio value=review name=mode></td><td>include review</td>
    </tr>
    <tr>
	<td><input type=radio value=default name=mode checked></td><td>default</td>
    </tr>
    <tr>
	<td><input type=radio value=review name=mode></td><td>as of (yy/mm/dd):<br>
		<input type=text name=mode_date size=8 size=10></td>
    </tr>
  </table>
  </td></tr></form>
  </table>

<%

}

%>
