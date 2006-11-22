
<%
sub canonizer {
%>
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
      </td>
    </tr>
  </table>

<%
}
%>
