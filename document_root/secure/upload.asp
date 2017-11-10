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
local $namespace = '';
local $repository = '/var/www/canonizer/files';

if ($Request->Form('upload')) {

	$file_name   = $Request->Form('file_name');
	$file_rename = $Request->Form('file_rename');
	$namespace   = $Request->Form('namespace');
	if ($namespace eq 'general') {
		$namespace = '/';
	}

	my $source_file_name = $file_name;
	my $dest_file_name   = $file_rename;
	if (length($dest_file_name) < 1) {
		$dest_file_name = $source_file_name;
	}

	my $bad_message = bad_name($dest_file_name);
	my $bad_message .= bad_namespace($namespace);

	if (length($source_file_name) < 1) {
		$error_message = 'No upload file given.';
	} elsif ($bad_message) {
	  	$error_message = $bad_message;
	} else {

		my $dest_path = $repository . $namespace .$dest_file_name;

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
				$Response->Redirect('http://canonizer.com/files'. $namespace);
				$Response->End();
			} else {
				$error_message = "Unable to open $dest_file_name.";
				$error_message = "Unable to open $dest_path.";
			}
		}
	}
}

&display_page($header, $header, [\&identity, \&search, \&main_ctl], [\&upload]);

sub upload {

    my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

    my @namespaces = func::get_name_spaces($dbh);

    my $namespace_select_str = "<select name=\"namespace\">\n";

    my $cur_namespace;
    foreach $cur_namespace (@namespaces) {
	$namespace_select_str .= "\t<option value=\"$cur_namespace\" " . (($namespace eq $cur_namespace) ? 'selected' : '') . ">$cur_namespace</option>\n";
    }

    $namespace_select_str .= "</select>\n";

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
		<font color=red>
		Error: <%=$error_message%>
		</font><br><br>
		<%
	}
	%>

	<p>Click "Browse" to locate the file on your computer. Be sure to
	click "Upload" when you are done.  If you do not enter a name, your
	file's name will be used.</p>

	<form method=post enctype="multipart/form-data">
	<p>File:</p>
	<p><input type="file" size=80 name=file_name value=""></p>
	<p>Name:</p>
	<p><input type=text name=file_rename value="<%= $file_rename %>" size=50 maxlength=50></p>

	<p>Name space:</p>
	<p><%=$namespace_select_str%></p>

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


sub bad_name {
    $name = $_[0];

    if (length($name) < 1) {
       return('No name to save to.');
    }

    if (length($name) > 50) {
       return('File name can not be over 50 chars.');
    }

    if ($name =~ m|[^a-zA-Z0-9_\.]|) {
	return("\"$name\" is an invalid file name; can only have alpha, numeric, '_', and '.'.");
    }

    return(0);
}


sub bad_namespace {
    $name = $_[0];

    if (length($name) > 100) {
       return('bad name space specified.');
    }

    if ($name =+ m|\.\.|) { # no ..
       return('bad name space specified.');
    }

    if (! -d $repository . $namespace) {
    	return('no such name space repository yet.  Contact support@canonizer.com');
    }

    if ($name =~ m|[^a-zA-Z0-9_\.\/]|) {
       return('bad name space specified.');
    }

    return(0);
}

%>

