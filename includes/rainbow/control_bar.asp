

<%

sub display_bar {

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
	</select>
      </td>
    </tr>
    <tr>
      <td>
	Loged in as:<br>
	<center>
	Guest<br>
	<input type = button value = "Login">
	<input type = button value = "Profile">
	</center>
      </td>
    </tr>
    <tr>
      <td>
	<input type = text size = 16><br>
	<center>
	<input type = button value = "Search">
	</center>
	<a href = "">Advanced Search</a>
      </td>
    </tr>
    <tr>
      <td>
	Home<br>
	<a href = "">Browse Categories</a><br>
	<a href = "">Organizations</a><br>
	<a href = "">Personal Pages</a><br>
	<a href = "">Sign up</a><br>
      </td>
    </tr>

  </table>

<%

}

%>
