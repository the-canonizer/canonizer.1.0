

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%

sub top_10 {

	%>

      <ol>
	<li><b>Canonizer Colors</b>
	  <oL>
	    <li><font size = -1>Represents inclusion of all.</font></li>
	    <li><font size = -1>It's to gay.</font></li>
	  </ol>
	</li><br>

	<li><b>God</b>
	  <ol>
	    <li><font size = -1>Theist</font>
		<ol>
		    <li><font size = -1>Monotheism</font>
			<ol>
			    <li><font size = -1>Christian</font>
				<ol>
				    <li><font size = -1>Catholic</font></li>
				    <li><font size = -1>LDS</font>
					<ol>
						<li><font size = -1>Transhumanist</font>
					</ol>
				    </li>
				</ol>
			    </li>
			    <li><font size = -1>Muslim</font></li>
			    <li><font size = -1>Jewish</font></li>
			</ol>
		   </li>
		    <li><font size = -1>Polytheism</font></li>
		</ol>
	    </li>
	    <li><font size = -1>Atheist</font>
		<ol>
		    <li><font size = -1>Traditional</font></li>
		    <li><font size = -1>Extropian</font></li>
		</ol>
	    </li>
	  </ol>
	</li>
	<br>

	<li><b>Qualia</b>
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

