<%

my $copyright_info = 'Copyright Canonizer LLC 2007';
my $support_email = 'support@canonizer.com';

my $test_results_str = '';
if ($Request->Cookies('canonizer', 'cid')) {
	$test_results_str .= 'Browser returned cid cookie: ' . int($Request->Cookies('canonizer', 'cid')) . "<br>\n";
}
if ($Request->Cookies('canonizer', 'gid')) {
	$test_results_str .= 'Browser returned gid cookie: ' . int($Request->Cookies('canonizer', 'gid')) . "<br>\n";
}

if ($test_results_str) {
	$test_results_str .= "<br>Cookies are working so you can contribute to the canonizer with this browser.<br>\n";
} else {
	$test_results_str = "Browser failed to return identity cookie.<br><br>\n" .
				"You must have a browser that can store and return cookies in order to contribute.<br>\n";
}

print page_header('Canonizer Cookie Test Page');

%>

<div id="help_content">

<div class="main_content_container">

  <div class="section_container">
    <div class="header_1">

      <span id="title">Canonizer Cookie Test Page</span>
    </div>

    <div id="section_container">
      <div class=content_1>
	<%= $test_results_str %>
      </div>
    </dev>

    <div class="footer_1">
	&nbsp;    
    </div>

  </div>
</div>

</div>

</div>

<div id="footer">
     <h3><%=$copyright_info%></h3>
     <h3>Comments: <a href = "mailto:<%=$support_email%>"><%=$support_email%></a></h3>
</div>


<%
print page_footer();
%>

<!--#include file = "includes/page_sections.asp"-->

