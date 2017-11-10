<%

# must define a local $destination before using this.

sub must_login {

	my $login_url = 'https://' . &func::get_host() . '/secure/login.asp?destination=' . $destination;
%>

<p>You must register and/or login before you can contribute.</p>
<p><a href="http://<%=&func::get_host()%>/secure/profile_id.asp?register=1">Register</a></p>
<p><a href="<%=$login_url%>">Login</a></p>

<%
}
%>

