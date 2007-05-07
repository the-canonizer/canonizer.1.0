<%

# ???? this 002 version is trying the new my (not local) asp organization.

use managed_record;
use topic;
use statement;
use support;

if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect('https://' . &func::get_host() . $ENV{"SCRIPT_NAME"} . $qs);
}
my $error_message = '';


my $destination = '';

if (!$Session->{'logged_in'} || !$Session->{'cid'}) {
	$destination = '/secure/support.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$destination .= ('?' . $query_string);
	}
	&display_page('Edit', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

my $topic_num = 0;
if ($Request->Form('topic_num')) {
	$topic_num = int($Request->Form('topic_num'));
} elsif ($Request->QueryString('topic_num')) {
	$topic_num = int($Request->QueryString('topic_num'));
}

if (!$topic_num) { # this is the only required one.
	$error_message .= "No topic specified to support<br>\n";
}

my $statement_num = 1; # 1 is the default ageement statement;
if ($Request->Form('statement_num')) {
	$statement_num = int($Request->Form('statement_num'));
} elsif ($Request->QueryString('statement_num')) {
	$statement_num = int($Request->QueryString('statement_num'));
}

my $deligate_id = 0; # 0 is direct support default.
if ($Request->Form('deligate_id')) {
	$deligate_id = int($Request->Form('deligate_id'));
} elsif ($Request->QueryString('deligate_id')) {
	$deligate_id = int($Request->QueryString('deligate_id'));
}

my $dbh = &func::dbh_connect(1) || die "support.asp unable to connect to database";

my topic $topic = new_topic_num topic ($dbh, $topic_num, $Session->{'as_of_mode'}, $Session->{'as_of_date'});
if ($topic->{error_message}) {
	$error_message .= $topic->{error_message};
}


# this nick stuff is used by both save_support and support_form
my %nick_names = &func::get_nick_name_hash($Session->{'cid'}, $dbh);
# ???? nick_clause is no longer used by support_form (%nick_names is) so move it into save_support
my $nick_clause = '';
my $nick_name;
foreach $nick_name (keys (%nick_names)) {
	$nick_clause .= "nick_name_id = $nick_name or ";
}
if (!$nick_clause) {
	$error_message .= "No nick name found for current user.<br>\n";
}
chop($nick_clause); # remove extra or
chop($nick_clause);
chop($nick_clause);
chop($nick_clause);


if ($error_message) {
	&display_page('Support Errorr', [\&identity, \&search, \&main_ctl], [\&error_page]);
} elsif ($Request->Form('submit')) {
	# does not return if successful (rederects to topic.asp for original statement.)
	&save_support();
} else {
	&display_page('Add Support<br>Topic: <font size=6>' . $topic->{name} . '</font><br>', [\&identity, \&search, \&main_ctl], [\&support_form]);
}







sub save_support {

	my $idx = 0;
	my $del_idx = 0;
	my $nick_name_id = $Request->Form('nick_name');
	my $support_num;
	my %form_support_hash = ();
	while ($support_num = $Request->Form('support_' . $idx)) {
		$form_support_hash{$del_idx} = $support_num;
		$idx++;
		if (! $Request->Form('delete_' . $support_order)) {
			$del_idx++;
		}
	}

	my $now_time = time;

	# end modified support
	my $selstmt = "select statement_num, nick_name_id, delegate_nick_name_id, support_order from support where topic_num = $topic_num and ((start < $now_time) and (end = 0 or end > $now_time)) and ($nick_clause)";

	my $sth = $dbh->prepare($selstmt) || die "save_support failed to prepair $selstmt";

	$sth->execute() || die "save_support failed to execute $selstmt";

	my $rs;
	my $statement_num;
	my $support_order;

	while ($rs = $sth->fetchrow_hashref()) {
		$statement_num = $rs->{'statement_num'};
		$support_order = $rs->{'support_order'};
		if (($rs->{'nick_name_id'} == $nick_name_id) &&
		    ($form_support_hash{$support_order} == $statement_num) ) {	# no change
			delete($form_support_hash{$support_order});
		} else {							# modify (terminate old, add new record);
			# ???? mark the old record terminated.
		}
	}
	$sth->finish();

	# add the new and replacement records
	# ???? got to add the delegate stuff ????
	foreach $support_order (keys %form_support_hash) {
		$support_id = &func::get_next_id($dbh, 'support', 'support_id');
		$statement_num = $form_support_hash{$support_order};
		$selstmt = 'insert into support ' .
			   '(support_id,  nick_name_id,  topic_num,  statement_num,  support_order,  start    ) values ' .
			   "($support_id, $nick_name_id, $topic_num, $statement_num, $support_order, $now_time)";
		# print(STDERR "save_support selstmt: $selstmt.\n");
		if (!$dbh->do($selstmt)) {
			die "Failed to insert support: $selstmt.\n";
		}
	}

	# save in db then redirect to statement page.
	# $Response->Redirect('http://' . &func::get_host() . "/topic.asp?=$topic_num&statement_num=$statement_num");

	# add new and modified support

	%>
	<h1>Submitted</h1>
	topic: <%=$topic_num%><br>
	nick id: <%=$nick_name_id%><br>
	New statement num: <%=$statement_num%><br>
	selstmt: <%=$selstmt%><br>
	Adding support for: 
	<%
	my $support_order;
	foreach $support_order (keys(%form_support_hash)) {
		$Response->Write("$support_order:$form_support_hash{$support_order}.\n");
	}

	$Response->End();
}


sub support_form {

	my statement $statement = new_tree statement ($dbh, $topic_num, $statement_num);
	if ($statement->{error_message}) {
		%>
		<br>
		<h1><font color=red><%=$statement->{error_message}%></font></h1>
		<br>
		<%
		return();
	}

	my $nick_name_id;
	my $support_array_ref = undef;
	foreach $nick_name_id (keys %nick_names) {
		$support_array_ref = $statement->{support_hash}->{$nick_name_id};
		if ($support_array_ref) {
			last;
		}
	}

	my $delegate_nick_name_id;
	my support $support;
	if (! $support_array_ref) {
		# wasn't yet supporting any statements.
	} else {
		$support = $support_array_ref->[0];
		$delegate_nick_name_id = $support->{delegate_nick_name_id};
		if ($delegate_nick_name_id) {
			$support_array_ref = $statement->{support_hash}->{$support->{support_order}};
			if (! $support_array_ref) {
				%>
				<br>
				<h1><font color=red>suppoert <%=$nick_name_id%> is delegated to non existant root support id: <%=$support->{support_order}%></font></h1>
				<br>
				<%
				return();
			}
		}
	}

	# the support_array_ref, if any, will be used for the old list in the deligated case
	# and the new support will be added to this ref, so the entire list order can be edited in the direct case:

	if ($delegate_id) {	# new delegated support (show old support if any.)
		my $new_support_array_ref = $statement->{support_hash}->{$delegate_id};
		if (! $new_support_array_ref) {
			%>
			<br>
			<h1><font color=red>Attempting to delegate support to non existant supporter: <%=$delegate_id%>.</font></h1>
			<br>
			<%
			return();
		}

		# this is where we display both lists!! ???? (after we check for delegate support to deref);

	} else {		# new direct (may change order) suport
		%>
		<script language=javascript>

		var support_array = new Array();
		var support_object;
		<%

		my $support_order_idx = 0;
		my $statement_info;

		my $replacement_str = ''; # build up this string with all replacements.
		my $replacement_idx = -1; # where to put the replacement.

		if ($support_array_ref) {
			my statement $old_statement;
			foreach $support (@{$support_array_ref}) {
				$old_statement = $statement->{statement_tree_hash}->{$support->{statement_num}};
				if ($statement->is_related($old_statement->{statement_num})) {
					if ($replacement_idx == -1) {
						$replacement_idx = $support_order_idx++;
						$replacement_str = '<br><br><font color=green>This new support will replace the existing support for the following related statements:</font>';
					}
					$replacement_str .= '<br>' . $old_statement->make_statement_path(1);
				} else {
					$Response->Write(&make_js_support_object_str($support_order_idx++, 0, $statement, '')); # 0: old
				}
			}
		}

		if ($replacement_idx == -1) {
			$Response->Write(&make_js_support_object_str($support_order_idx++, 1, $statement, '')); # 1: new
		} else {
			$Response->Write(&make_js_support_object_str($replacement_idx, 1, $statement, $replacement_str)); # 1: new
		}

		%>

		function move_up(idx) {
			var temp_object = support_array[idx - 1];
			support_array[idx - 1] = support_array[idx];
			support_array[idx] = temp_object;
			render_support();
		}


		function move_down(idx) {
			var temp_object = support_array[idx + 1];
			support_array[idx + 1] = support_array[idx];
			support_array[idx] = temp_object;
			render_support();
		}


		function render_support() {
			var render_str = "";
			render_str += "<br><br>\n";
			render_str += "<center>\n";
			render_str += "<form method=post>\n";
			render_str += "  <input type=hidden name=topic_num value=<%=$topic_num%>>\n";
			render_str += "  <input type=hidden name=statement_num value=<%=$statement_num%>>\n";
			render_str += "  <table border=1>\n";
			var idx;
			for (idx = 0; idx < support_array.length; idx++) {
				support_object = support_array[idx];
				render_str += "<tr>\n";
				render_str += "  <td>" + idx + "</td>\n";
				render_str += "  <td>" + support_object.statement_info + "</td>\n";
				if (support_array.length > 1) { // no move buttons if only supporting one.
					if (idx < (support_array.length - 1)) {
						render_str += "  <td><button onclick=move_down(" + idx + ")>v</button></td>";
					} else {
						render_str += "  <td>&nbsp;</td>";
					}
					if (idx > 0) {
						render_str += "  <td><button onclick=move_up(" + idx + ")>^</button></td>\n"; // the move buttons go here.
					} else {
						render_str += "  <td>&nbsp;</td>\n"; // the move buttons go here.
					}
				}
				render_str += "  <td align=center>Delete<br><input type=checkbox name=delete_" + idx + "></td>\n";
				render_str += "</tr>\n";
				render_str += "<input type=hidden name=support_" + idx + " value=" + support_object.statement_num + ">\n";
			}
			render_str += "  </table>\n";
			render_str += "  <br>\n";
			render_str += "  Support Nick Name: ";
			render_str += "  <select name=nick_name>";
			<%
			my $id;
			foreach $id (sort {$a <=> $b} (keys %nick_names)) {
				if ($id == -1) { # some day propegate the previous support nick selection????
					%>
					render_str += "<option value=<%=$id%> selected><%=$nick_names{$id}%>\n";
					<%
				} else {
					%>
					render_str += "<option value=<%=$id%>><%=$nick_names{$id}%>\n";
					<%
				}
			}
			%>
			render_str += "  </select><br><br>\n";
			render_str += "<input type=submit name=submit value=\"commit support\">\n";
			render_str += "</form>\n";
			render_str += "</center>\n";
			// alert(render_str);
			document.all.support_block.innerHTML = render_str;
		}
		</script>

		<span id = 'support_block'>
		</span>

		<script language=javascript>
		render_support();
		</script>

		<%
	}
}


sub make_js_support_object_str {
	my $support_order_idx   = $_[0];
	my $new			= $_[1];
	my statement $statement = $_[2];
	my $replacement_str     = $_[3];

	my $ret_str = '';

	my $statement_info = '';
	if ($new) {
		$statement_info .= "<font color=green>New Support:</font><br>";
	}
	$statement_info .= $statement->make_statement_path(1) . $replacement_str;

	$statement_info =~ s|"|\\"|g;

	$ret_str .= "support_object = new Object();\n";
	$ret_str .= "support_object.statement_num = $statement->{statement_num};\n";
	$ret_str .= "support_object.statement_info = \"$statement_info\";\n";
	$ret_str .= "support_array[$support_order_idx] = support_object;\n";

	return($ret_str);
}


%>

<!--#include file = "includes/default/page.asp"-->
<!--#include file = "includes/must_login.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/error_page.asp"-->

