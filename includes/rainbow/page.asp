<%

sub display_page {
	my $page_header	     = $_[0];
	my $bar_subs	     = $_[1];
	my $content_subs     = $_[2];
	my $tab_sub	     = $_[3];


	my $title = $page_header;
	   $title =~ s|\<[^\>]*\>||g;
	my $copyright_info = 'Copyright Canonizer LLC 2007';
	my $support_email = 'support@canonizer.com'

%>

<%
print page_header($title);
%>

<div id="header">
     <h1><%=$page_header%></h1>
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
     <h1>Advertisement Space</h1>
</div>

<div id="main_content">

<%
foreach $sub (@$content_subs)
{
&$sub();
}
%>

</div>

<div class="clear_floats">&nbsp;</div>

<div id="footer">
     <h3><%=$copyright_info%></h3>
     <h3>Comments: <a href = "mailto:<%=$support_email%>"><%=$support_email%></a></h3>
</div>

<%
print page_footer();
}
%>
