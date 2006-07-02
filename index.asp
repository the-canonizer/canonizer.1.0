

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%

sub top_10 {

%>
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
}

$Session->{'storage'} .= ($Session->{SessionID} . "<br>\n");

########
# main #
########

&display_page('CANONIZER', 'Top 10', [\&identity, \&search, \&main_ctl], [\&top_10]);

%>

