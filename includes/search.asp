<%

sub search {

%>

    	<div class="search">

    	<h1>Search</h1>

<!-- SiteSearch Google -->
<form method="get" action="http://www.google.com/custom" target="_top">
<table border="0" >
<tr><td nowrap="nowrap" valign="top" align="left" height="32">

</td>
<td nowrap="nowrap">
<input type="hidden" name="domains" value="canonizer.com"></input>
<label for="sbi" style="display: none">Enter your search terms</label>
<input type="text" name="q" size="20" maxlength="255" value="" id="sbi"></input>
</td></tr>
<tr>
<td>&nbsp;</td>
<td nowrap="nowrap">
<table>
<tr>
<td>
<input type="radio" name="sitesearch" value="" checked id="ss0"></input>
<label for="ss0" title="Search the Web"><font size="-1" color="black">Web</font></label></td>
<td>
<input type="radio" name="sitesearch" value="canonizer.com" id="ss1"></input>
<label for="ss1" title="Search canonizer.com"><font size="-1" color="black">canonizer.com</font></label></td>
</tr>
</table>
<label for="sbb" style="display: none">Submit search form</label>
<input type="submit" name="sa" value="Google Search" id="sbb"></input>
<input type="hidden" name="client" value="pub-6646446076038181"></input>
<input type="hidden" name="forid" value="1"></input>
<input type="hidden" name="ie" value="ISO-8859-1"></input>
<input type="hidden" name="oe" value="ISO-8859-1"></input>
<input type="hidden" name="cof" value="GALT:#0066CC;GL:1;DIV:#999999;VLC:336633;AH:center;BGC:FFFFFF;LBGC:FF9900;ALC:0066CC;LC:0066CC;T:000000;GFNT:666666;GIMP:666666;LH:43;LW:220;L:http://canonizer.com/images/CANONIZER.PNG;S:http://;FORID:1"></input>
<input type="hidden" name="hl" value="en"></input>
</td></tr></table>
</form>
<!-- SiteSearch Google -->
	</div>

<%

}

%>
