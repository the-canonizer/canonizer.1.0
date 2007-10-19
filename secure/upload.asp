	<%
if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect("https://" . $ENV{"SERVER_NAME"} . $ENV{"SCRIPT_NAME"} . $qs);
}

my $header = 'File Upload';
%>
<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/must_login.asp"-->

<%

sub upload {


%>

<div class="main_content_container">

<div class="section_container">
<div class="header_1">

     <span id="title"><%=$header%></span>

</div>

<div class="content_1">

<%




	if ($error_message) {
		%>
		<%=$error_message%>
		<%	
	}

	%>

<p>Click "Browse" to locate the file on your computer. Be sure to click "Upload" when you are done.
If you do not enter a name, your file's name will be used.</p>

<form method=post enctype="multipart/form-data">
<p>File:</p>
<p><input type="file" size=30 name=file_name value="*.jpg"></p>
<p>Name:</p>
<p><input type=text name=file_rename value="" size=50 maxlength=50></p>
<p><input type="submit" name=upload value="Upload"></p>
</form>
<p>To see a list of files already uploaded (and file names already used) go <a href = http://canonizer.com/files>here.</a></p>

</div>

     <div class="footer_1">
     <span id="buttons">
     

&nbsp;    
     
     </span>
     </div>

</div>

</div>

<%

}


########
# main #
########

local $destination = '';

if (!$Session->{'logged_in'}) {
	$destination = '/secure/upload.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$destination .= ('?' . $query_string);
	}
	&display_page('Upload File', 'Upload File', [\&identity, \&search, \&main_ctl], [\&must_login]);
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

&display_page($header, $header, [\&identity, \&search, \&main_ctl], [\&upload]);

%>

