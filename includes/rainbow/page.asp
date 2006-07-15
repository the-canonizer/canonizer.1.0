
<%

sub display_page {
	my $title	 = $_[0];
	my $subtitle	 = $_[1];
	my $bar_subs	 = $_[2];
	my $content_subs = $_[3];
	my $tab_sub	 = $_[4];
%>


<html>
<head>
<title><%=$title%> : <%=$subtitle%></title>

</script>

</head>
<body bgcolor = white border = 0>
<table border = 0 cellspacing = 0 cellpadding = 0>
<tr>
  <td background = images/cp_t_l.jpg width = 200 height = 200></td>
  <td background = images/cp_t.jpg width = 500 height = 200 align = center valign = bottom>
	<center>
	<font face = arial size = 7><b>
	<%=$title%></b></font><br>
	<font face = arial size = 5><b>
	<%=$subtitle%></b></font><br><br>
	<%
	if ($tab_sub) {
		&$tab_sub();
	} else {
		%>
		<br><br>
		<%
	}
	%>
	</center>
  </td>
  <td><img src = images/cp_t_r.jpg width = 200 height = 200></td>
</tr>
<tr>
  <td background = images/cp_l.jpg valign = top>

<%
	my $sub;

	foreach $sub (@$bar_subs) {
		&$sub();
	}
%>

  </td>
  <td valign = top>

<%
	foreach $sub (@$content_subs) {
		&$sub();
	}
%>

  </td>
  <td background = images/cp_r.jpg></td>
</tr>
<tr>
  <td><img src = images/cp_b_l.jpg width = 200 height = 200></td>
  <td background = images/cp_b.jpg width = 500 height = 200 align = center>
    Comments: <a href = "mailto:support@canonizer.com">support@canonizer.com</a><br>
    <font face = arial size = 1>eCANONIZER is a trademark of CANONIZER DBA</font>
</td>
  <td><img src = images/cp_b_r.jpg width = 200 height = 200></td>
</tr>
</body>
</html>

<%
}
%>
