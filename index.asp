

<!--#include file = "includes/default/test.inc"-->

<html>
<head>
<title>Canonizer</title>


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
	CANONIZER</b></font><br>
	<font face = arial size = 5><b>
	Top 10</b></font>
  </td>
  <td><img src = images/cp_t_r.jpg width = 200 height = 200></td>
</tr>
<tr>
  <td background = images/cp_l.jpg valign = top>
  <table border = 0 width = 180 cellspacing = 0 cellpadding = 2>

    <tr height = 4 bgcolor = black><td colspan = 3></td></tr>

    <tr>
      <td bgcolor = black width = 4><img src = images/clear.gif width = 1></td>
      <td>
	Canonizer:<br>
	<select name = canonizer onchange = javascript:change_canonizer(value)>
	  <option>Blind Popularity</option>
	  <option>MTA</option>
	  <option>Atheist Popularity</option>
	  <option>LDS</option>
	</select>
      </td>
      <td bgcolor = black><img src = images/clear.gif width = 1></td>
    </tr>
    <tr height = 4 bgcolor = black><td colspan = 3></td></tr>
    <tr>
      <td bgcolor = black><img src = images/clear.gif width = 1></td>
      <td>
	Loged in as:<br>
	<center>
	Guest<br>
	<input type = button value = "Login">
	<input type = button value = "Profile">
	</center>
      </td>
      <td bgcolor = black><img src = images/clear.gif width = 1></td>
    </tr>
    <tr height = 4 bgcolor = black><td colspan = 3></td></tr>
    <tr>
      <td bgcolor = black><img src = images/clear.gif width = 1></td>
      <td>
	<input type = text size = 16><br>
	<center>
	<input type = button value = "Search">
	</center>
	<a href = "">Advanced Search</a>
      <td bgcolor = black><img src = images/clear.gif width = 1></td>
      </td>
    </tr>
    <tr height = 4 bgcolor = black><td colspan = 3></td></tr>
    <tr>
      <td bgcolor = black><img src = images/clear.gif width = 1></td>
      <td>
	Home<br>
	<a href = "">Browse Categories</a><br>
	<a href = "">Organizations</a><br>
	<a href = "">Personal Pages</a><br>
	<a href = "">Sign up</a><br>
      </td>
      <td bgcolor = black><img src = images/clear.gif width = 1></td>
    </tr>

    <tr height = 4 bgcolor = black><td colspan = 3></td></tr>

  </table>
  </td>
  <td valign = top>
      <ol>
	<li>Canonizer Colors
	  <oL>
	    <li><font size = -1>Represents inclusion of all.</font></li>
	    <li><font size = -1>It's to gay.</font></li>
	  </ol>
	</li><br>
	<li>Is there a God?
	  <ol>
	    <li><font size = -1>Yes.</font></li>
	    <li><font size = -1>No.</font></li>
	    <li><font size = -1>God is Everything.</font></li>
	  </ol>
	</li>
      </ol>

<%
# &page_top("Top 10");
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
