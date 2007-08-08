<%

# must define a local $destination before using this.

sub must_login {

	my $login_url = 'https://' . &func::get_host() . '/secure/login.asp?destination=' . $destination;
%>
	<br>
	<h2>You must register and or login before you can edit.</h2>
	<center>
	<h2><a href="http://<%=&func::get_host()%>/register.asp">Register</a><h2>
	<h2><a href="<%=$login_url%>">Login</a><h2>
	</center>
<%
}
%>

