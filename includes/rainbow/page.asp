<%

sub display_page {
	my $title	 = $_[0];    
	my $page_header  = $_[1];
	my $bar_subs	 = $_[2];
	my $content_subs = $_[3];
	my $tab_sub	 = $_[4];

	my $url = "http://" . func::get_host() . "/topic.asp/4";
	my $copyright_info = 'Copyright owned by the <a href="' . $url . '">volunteers contributing to the system</a> and its contents (2006 - 2012)';
	my $support_email = 'support@canonizer.com';

	my $not_main_warning = '';

	my $not_main_file_name = $ENV{'DOCUMENT_ROOT'} . '/main_server';

	if (! -e $not_main_file_name) {
		$not_main_warning = qq{

<h1><font color="red">WARNING: This is only a test server.  Any submissions will
occasionally be overwritten with data copied from the main server.</font></h1>

		};
	}

%>

<%
print page_header($title);
%>

<div id="header">
    <table width="100%">
      <tr>
        <td><h1><%=$page_header%></h1></td>
	<td align=right><a href="/"><img border="0" src="/images/Canonizer_Logo_100x70.jpg"></a></td>
      </tr>
    </table>
</div>

<div id="block_tools">

<%
my $sub;
foreach $sub (@$bar_subs)
{
&$sub();
}
%>

</div>

<div id="block_adverts">

<%
if ($ENV{'HTTPS'} eq 'on') {
%>
&nbsp;
<%
} else {
%>

<script type="text/javascript"><!--
google_ad_client = "pub-6646446076038181";
//120x600, right bar
google_ad_slot = "5819006657";
google_ad_width = 120;
google_ad_height = 600;
//--></script>
<script type="text/javascript"
src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>

<%
}
%>

</div>

<div id="main_content">

<%= $not_main_warning %>

<%
foreach $sub (@$content_subs)
{
&$sub();
}
%>

</div>

<div class="clear_floats">&nbsp;</div>

<div id="footer">
<table width="100%">
    <tr><td align="left">
        <table>
            <tr><td><h1>Sponsors:</h1></td>
	    <td><a href="http://transfigurism.org">
	    	<img src="http://transfigurism.org/assets/3/mta-thumb.png">
		</a>
	    </td>
	</table>
        <td>
	    <h3><%=$copyright_info%></h3>
	    <h3>Comments and Questions: <a href = "mailto:<%=$support_email%>"><%=$support_email%></a></h3>
	</td>
    </tr>
</table>
</div>

<%
print page_footer();
}
%>
