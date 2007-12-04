<%

use managed_record;
use text;

my $dbh = func::dbh_connect(1) || die "unable to connect to database";

my text $help_text = new_num text ($dbh, 38, 2);

my $help_text_str = func::wikitext_to_html($help_text->{value});

my $copyright_info = 'Copyright Canonizer LLC 2007';
my $support_email = 'support@canonizer.com';

print page_header('Canonizer Help Page');

%>

<div id="help_content">

<div class="main_content_container">

  <div class="section_container">
    <div class="header_1">

      <span id="title">Canonizer Help Page</span>
    </div>

    <div id="section_container">
      <div class=content_1>
	<%=$help_text_str%>
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

