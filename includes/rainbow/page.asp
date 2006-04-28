

<%

sub display_page {
	my $title	= $_[0];
	my $subtitle	= $_[1];
	my $bar_sub	= $_[2];
	my $content_sub = $_[3];
%>


<html>
<head>
<title><%=$title%></title>

<script language:javascript>

function change_canonizer(new_canonizer) {
	alert(new_canonizer);
	window.location = "index.asp?canonizer=" + new_canonizer;
}

</script>

</head>
<body bgcolor = white border = 0>
<table border = 0 cellspacing = 0 cellpadding = 0>
<tr>
  <td background = images/cp_t_l.jpg width = 200 height = 200></td>
  <td background = images/cp_t.jpg width = 500 height = 200 align = center>
	<font face = arial size = 7><b>
	<%=$title%></b></font><br>
	<font face = arial size = 5><b>
	<%=$subtitle%></b></font>
  </td>
  <td><img src = images/cp_t_r.jpg width = 200 height = 200></td>
</tr>
<tr>
  <td background = images/cp_l.jpg valign = top>

<%
	&$bar_sub();
%>

  </td>
  <td valign = top>

<%
	&$content_sub();
%>

  </td>
  <td background = images/cp_r.jpg></td>
</tr>
<tr>
  <td><img src = images/cp_b_l.jpg width = 200 height = 200></td>
  <td background = images/cp_b.jpg width = 500 height = 200 align = center>
    Comments: <a href = "mailto:support@canonizer.com">support@canonizer.com</a>
</td>
  <td><img src = images/cp_b_r.jpg width = 200 height = 200></td>
</tr>
</body>
</html>

<%
}
%>
