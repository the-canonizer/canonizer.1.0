
<%
sub canonizer {
%>

<script language:javascript>

function change_canonizer(new_canonizer) {
	alert('Only Blind Popularity is completed');
	// alert(new_canonizer);
	// window.location = "index.asp?canonizer=" + new_canonizer;
}

</script>

  <table border = 1 width = 180>
    <tr>
      <td>
	Canonizer:<br>
	<select name = canonizer onchange = javascript:change_canonizer(value)>
	  <option>Blind Popularity</option>
	  <option>MTA</option>
	  <option>Atheist Popularity</option>
	  <option>LDS</option>
	  <option>Canonizer Canonizer</option>
	</select>
	(Not Yet Implemented)
      </td>
    </tr>
  </table>

<%
}
%>
