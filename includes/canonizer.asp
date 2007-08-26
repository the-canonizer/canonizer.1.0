
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
	 
	<div class="canonizer">
	
	<h1>Canonizer</h1>

	<p>Canonizer:</p>
	<p><select name = canonizer onchange = javascript:change_canonizer(value)>
	  <option>Blind Popularity</option>
	  <option>not implemented yet</option>
	</select></p>
	
	</div>


<%
}
%>
