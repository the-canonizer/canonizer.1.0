

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
	<li>God
	  <ol>
	    <li><font size = -1>LDS</font></li>
	    <li><font size = -1>Catholic</font></li>
	    <li><font size = -1>Atheist</font></li>
	    <li><font size = -1>Extropian</font></li>
	  </ol>
	</li>
	<br>

	<li>Qualia
	  <ol>
	    <li><font size = -1>Are Phenomenal Properties of Matter</font></li>
	    <li><font size = -1>Do Not Exist (It just seems that they do.)</font></li>
	  </ol>
	</li>

      </ol>



	<%
}


########
# main #
########

my $header = 'CANONIZER <br><font size=5>Top 10</font>';

&display_page($header, [\&identity, \&search, \&main_ctl], [\&top_10]);

%>

