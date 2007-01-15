	<%
if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect("https://" . $ENV{"SERVER_NAME"} . $ENV{"SCRIPT_NAME"} . $qs);
}
%>
<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%


sub must_login {

	my $login_url = 'https://' . &func::get_host() . '/secure/login.asp?destination=/secure/upload.asp';
%>
	<br>
	<h2>You must register and or login before you can edit.</h2>
	<center>
	<h2><a href="http://<%=&func::get_host()%>/register.asp">Register</a><h2>
	<h2><a href="<%=$login_url%>">Login</a><h2>
	</center>
<%
}


sub upload {

	if ($error_message) {
		%>
		<h2><font color = red><%=$error_message%></font></h2>
		<%	
	}

	%>


	<table cellpadding=2 cellspacing=0 width="100%" border=0>

	<tr valign=top><td ><font size=-1 face="Arial,Helvetica">
	Click <b>Browse</b> to locate the file on your computer. Be sure to click <b>Upload</b> when you are done.
	If you do not enter a name, your file's name will be used.
	</font></td></tr>

	<tr height = 20></tr>


	<form method=post action = "https://test.canonizer.com/secure/upload.asp" enctype="multipart/form-data">

	  <tr><td nowrap><font face="Arial,Helvetica"  size="-1">
	    <b>File:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</b>
	    <input type="file" size=30 name=file_name value="*.jpg"><br>

	    <b>Name:</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			<input type=text name=file_rename value="" size=30 maxlength=30>
		  </td></tr>

	<tr><td  align=center><br>

	<input type="submit" name=upload value="upload">

	</table>

	</form>

	<br>
	<font size=-1 face="Arial,Helvetica">
	To see a list of files already uploaded (and file names already used)
	go <a href = http://canonizer.com/files>here.</a>
	</font>
	<%
}


########
# main #
########

if (!$Session->{'logged_in'}) {
	&display_page('Edit', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

local $error_message = '';
local $file_name = '';
local $file_rename = '';

if ($Request->Form('upload')) {
	my $repository = '/var/www/canonizer/files/';
	my $source_file_name = $Request->Form('file_name');
	my $dest_file_name   = $Request->Form('file_rename');
	if (!$dest_file_name) {
		$dest_file_name = $source_file_name;
	}

	if (! $source_file_name) {
		$error_message = 'No upload file given.';
	} else {
		my $dest_path = $repository . $dest_file_name;

		if (-f $dest_path) {
			$error_message = "The file name $dest_file_name already exists.<br>You must chose another.";
			$file_name = $Request->Form('file_name');
			if ($Request->Form('file_rename')) {
				$file_rename = $Request->Form('file_rename');
			}
		} else {
			if (open(OUTFILE, ">$dest_path")) {
				my $read_val;
				while ($read_val = <$source_file_name>) {
					print(OUTFILE $read_val);
				}
				close(OUTFILE);
				$Response->Redirect('http://canonizer.com/files');
				$Response->End();
			} else {
				$error_message = "Unable to open $dest_file_name.";
				$error_message = "Unable to open $dest_path.";
			}
		}
	}
}

my $header = 'File Upload Page<br><br>';

&display_page($header, [\&identity, \&search, \&main_ctl], [\&upload]);

%>

