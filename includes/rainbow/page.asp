
<%

sub display_page {
	my $header	 = $_[0];
	my $bar_subs	 = $_[1];
	my $content_subs = $_[2];
	my $tab_sub	 = $_[3];


my $title = $header;
$title =~ s|\<[^\>]*\>||g;

%>


<html>
<head>
<title>CANONIZER: <%=$title%></title>

</script>

</head>
<body bgcolor = white border = 0>
<table border = 0 cellspacing = 0 cellpadding = 0>
<tr>
  <!-- td background = images/cp_t_l.jpg width = 200 height = 200></td -->
  <td valign=bottom><img src=images/cp_t_l.jpg width=200 height=200></td>
  <td background = images/cp_t.jpg width = 500 height = 200 align = center valign = bottom>
	<center>
	<font face = arial size = 7><b>
	<%=$header%></b></font><br>
	<br><br>
	<%
	if ($tab_sub) {
		&$tab_sub();
	} else {
	}
	%>
	</center>
  </td>
  <td valign=bottom><img src = images/cp_t_r.jpg width = 200 height = 200></td>
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

    <font face = arial size = 6><b>CANONIZER</b></font><br>

    Comments: <a href = "mailto:support@canonizer.com">support@canonizer.com</a><br>
    <font face = arial size = 1>Copyright Canonizer LLC 2006</font>
</td>
  <td><img src = images/cp_b_r.jpg width = 200 height = 200></td>
</tr>
</body>
</html>

<%
}
%>
