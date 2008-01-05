<%

use managed_record;
use topic;
use statement;
use support;

if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect('https://' . func::get_host() . $ENV{"SCRIPT_NAME"} . $qs);
}
my $error_message = '';


my $destination = '';

if (!$Session->{'logged_in'} || !$Session->{'cid'}) {
	$destination = '/secure/support.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$destination .= ('?' . $query_string);
	}
	display_page('Edit', 'Edit', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

my $dbh = func::dbh_connect(1) || die "support.asp unable to connect to database";

my $topic_num = 0;
if ($Request->Form('topic_num')) {
	$topic_num = int($Request->Form('topic_num'));
} elsif ($Request->QueryString('topic_num')) {
	$topic_num = int($Request->QueryString('topic_num'));
}

if (!$topic_num) { # this is the only required one.
	$error_message .= "No topic specified to support\n";
}

my $statement_num = 1; # 1 is the default ageement statement;
if ($Request->Form('statement_num')) {
	$statement_num = int($Request->Form('statement_num'));
} elsif ($Request->QueryString('statement_num')) {
	$statement_num = int($Request->QueryString('statement_num'));
}

# this nick stuff is used by both save_support and support_form
# nick_clause is used in both save and delete support.
my $cid = $Session->{'cid'};
my %nick_names = func::get_nick_name_hash($cid, $dbh);
if ($nick_names{'error_message'}) {
	$error_message .= $nick_names{error_message};
}

my $nick_clause = func::get_nick_name_clause(\%nick_names);

if ($Request->QueryString('delete_id')) {
	# does not return if successful (rederects to topic.asp for original statement.)
	delete_support();
}

my $delegate_id = 0; # 0 is direct support default.
if ($Request->Form('delegate_id')) {
	$delegate_id = int($Request->Form('delegate_id'));
} elsif ($Request->QueryString('delegate_id')) {
	$delegate_id = int($Request->QueryString('delegate_id'));
}

my topic $topic = new_topic_num topic ($dbh, $topic_num, $Session->{'as_of_mode'}, $Session->{'as_of_date'});
if ($topic->{error_message}) {
	$error_message .= $topic->{error_message};
}


my statement $statement = new_tree statement ($dbh, $topic_num, $statement_num);
if ($statement->{error_message}) {
	%>
	<%=$statement->{error_message}%>
	<%
	return();
}


if ($error_message) {
	display_page('Support Errorr', 'Support Errorr', [\&identity, \&search, \&main_ctl], [\&error_page]);
} elsif ($Request->Form('submit')) {
	# does not return if successful (rederects to topic.asp for original statement.)
	save_support();
} else {
	display_page('Add Support Topic: ' . $topic->{topic_name}, 'Add Support Topic: ' . $topic->{topic_name}, [\&identity, \&search, \&main_ctl], [\&support_form]);
}





sub delete_support {
	# some day I should reorder (create new ones) the lessor support records.
	# it is a mess till I do this since support numberings will show up all wrong.

	# add the nick clause just to make sure someone isn't deleteing some unowned support record.
	my $now_time = time;
	my $delete_id = $Request->QueryString('delete_id');
	my $selstmt = "update support set end = $now_time where support_id = $delete_id and ($nick_clause)";
	my %dummy;
	if ($dbh->do($selstmt) eq '0E0') {
		%>
		Failed to delete support <%=$delete_id%>.
		<%
	} else {
		func::send_email("Deleting support", "Deleting support id $delete_id with nick_clause $nick_clause.\nfrom support.asp.\n");
		sleep(1);
	        $Response->Redirect('http://' . func::get_host() . "/topic.asp/$topic_num/$statement_num");
	}
	$Response->End();
}



sub save_support {


	my $idx = 0;
	my $del_idx = 0;
	my $nick_name_id = $Request->Form('nick_name');
	my $support_statement_num;
	my support $delegate_support = undef;
	while ($support_statement_num = $Request->Form('support_' . $idx)) {
		if (! $Request->Form('delete_' . $idx)) {
			if ($delegate_id) { # use delegate's primary (0 order) support
				$delegate_support = $statement->{support_hash}->{$delegate_id}->[0];
				if ($delegate_support) {
					# $support_statement_num = $delegate_support->{statement_num};
					# no need to change this to the deligate's primary.
					# this is never used for a delegator's support so might as well not change it.
					# (And it must be this way so when the deligates primary changes
					# this doesn't have to.)
					# but we should still do this below check just for saftey.
					# and we need this support record below.
				} else {
					%>
					Can't find delegate <%=$delegate_id%> on this topic.
					<%
					return();
				}
			}
			$form_support_hash{$del_idx} = $support_statement_num;
			$del_idx++;
		}
		$idx++;
	}

	my $now_time = time;

	# end any modified support
	my $selstmt = "select support_id, statement_num, nick_name_id, delegate_nick_name_id, support_order from support where topic_num = $topic_num and ((start < $now_time) and (end = 0 or end > $now_time)) and ($nick_clause)";

	my $sth = $dbh->prepare($selstmt) || die "save_support failed to prepair $selstmt";

	$sth->execute() || die "save_support failed to execute $selstmt";

	my $rs;
	my $statement_num;
	my $support_order;
	my $support_id;

	while ($rs = $sth->fetchrow_hashref()) {
		$statement_num = $rs->{'statement_num'};
		$support_order = $rs->{'support_order'};
		$support_id = $rs->{'support_id'};
		if (($rs->{'nick_name_id'} == $nick_name_id)               &&
		    ($form_support_hash{$support_order} == $statement_num) &&
		    ($rs->{'delegate_nick_name_id'} == $delegate_id)           ) { # no change
			delete($form_support_hash{$support_order});
		} else {							# modify (terminate old, add new record);
			$selstmt = "update support set end=$now_time where support_id = $support_id";
			if (!$dbh->do($selstmt)) {
				die "Failed to terminate support: $selstmt.\n";
			}
		}
	}
	$sth->finish();

	# add the new and replacement records
	# ? got to add the delegate stuff ?
	foreach $support_order (keys %form_support_hash) {
		$support_id = func::get_next_id($dbh, 'support', 'support_id');
		$statement_num = $form_support_hash{$support_order};
		my $real_support_order = $support_order;
		if ($delegate_id) {
			if ($delegate_support->{delegate_nick_name_id}) { # get root delegate id
				$real_support_order = $delegate_support->{support_order};
			} else {					  # this is root delegate
				$real_support_order = $delegate_id;
			}
		}

		$selstmt = 'insert into support ' .
			   '(support_id,  nick_name_id,  topic_num,  statement_num,  support_order,       delegate_nick_name_id, start    ) values ' .
			   "($support_id, $nick_name_id, $topic_num, $statement_num, $real_support_order, $delegate_id, $now_time)";
		# print(STDERR "save_support selstmt: $selstmt.\n");
		if (!$dbh->do($selstmt)) {
			die "Failed to insert support: $selstmt.\n";
		}
	}

	func::send_email("Adding support", "Nick name id $nick_name_id is adding support for topic $topic_num, statement: $statement_num.\nfrom support.asp.\n");
	sleep(1);
        $Response->Redirect('http://' . func::get_host() . "/topic.asp/$topic_num");
	$Response->End();

	%>
	Submitted
	topic: <%=$topic_num%>
	nick id: <%=$nick_name_id%>
	New statement num: <%=$statement_num%>
	selstmt: <%=$selstmt%>
	Adding support for: 
	<%
	my $support_order;
	foreach $support_order (keys(%form_support_hash)) {
		$Response->Write("$support_order:$form_support_hash{$support_order}.\n");
	}

	$Response->End();
}


sub support_form {

	%>
	<div class="main_content_container">
	<%

	my $nick_name_id;
	my $old_support_array_ref = undef;
	foreach $nick_name_id (keys %nick_names) {
		$old_support_array_ref = $statement->{support_hash}->{$nick_name_id};
		if ($old_support_array_ref) {
			last;
		}
	}

	my $old_delegate_nick_name_id;
	my support $old_support;
	if (! $old_support_array_ref) {
		# wasn't yet supporting any statements.
	} else {
		$old_support = $old_support_array_ref->[0];
		if ($old_support) {
			$old_delegate_nick_name_id = $old_support->{delegate_nick_name_id};
			if ($old_delegate_nick_name_id) {
				$old_support_array_ref = $statement->{support_hash}->{$old_support->{support_order}};
				if (! $old_support_array_ref) {
					%>
					support <%=$nick_name_id%> is delegated to non existant root support id: <%=$old_support->{support_order}%>
					<%
					return();
				}
			}
		}
	}

	# the support_array_ref, if any, will be used for the old list in the delegated case
	# and the new support will be added to this ref, so the entire list order can be edited in the direct case:

	if ($delegate_id) {	# new delegated support (show old support if any.)
		my $new_support_array_ref = $statement->{support_hash}->{$delegate_id};
		my support $delegate_support = $new_support_array_ref->[0];
		if ($delegate_support->{delegate_nick_name_id}) { # lookup root support array.
			$new_support_array_ref = $statement->{support_hash}->{$delegate_support->{support_order}};
		}

		if (! $new_support_array_ref) {
			%>
			Attempting to delegate support to non existant supporter: <%=$delegate_id%>.
			<%
			return();
		}


		if ($old_support_array_ref) {
			my $old_plural = '';
			if ($#{$old_support_array_ref} > 0) {
				$old_plural = 's';
			}
			if ($old_delegate_nick_name_id) {
				my $old_delegate_name = $statement->{support_hash}->{$old_delegate_nick_name_id}->[0]->{nick_name};
				%>
				Previously, you were delegating the following support from <%=$old_delegate_name%>.
				<%
			} else {
				%>
				Previously, you were directly supporting the folowing statement<%=$old_plural%>.
				<%
			}
			%>
			<br>
			<br>
			<center>
			<table class=support_table>
			<%
			my $idx;
			for ($idx = 0; $idx <= $#{$old_support_array_ref}; $idx++) {
				if ($old_support_array_ref->[$idx]) { # may be null if deleted.
					%>
					<tr><td><%=$idx%></td>
					<td><%=$statement->{statement_tree_hash}->{$old_support_array_ref->[$idx]->{statement_num}}->make_statement_path(1)%></td></tr>
					<%
				}
			}
			%>
			</table>
			</center>
			<br>
			<%
		}

		my $delegate_name = $statement->{support_hash}->{$delegate_id}->[0]->{nick_name};
		my $new_plural = '';
		if ($#{$new_support_array_ref} > 0) {
			$new_plural = 's';
		}

		%>
		After committing this delegated support to <%=$delegate_name%> you will be supporting the below statement<%=$new_plural%>.  If <%=$delegate_name%> changes camps your support will follow as long as it is so delegated.
                <form method=post>
		<input type=hidden name=support_0 value=<%=$statement_num%>>
		<input type=hidden name=delegate_id value=<%=$delegate_id%>>
		<br>
		<center>
		<table class=support_table>
		<%
		my $idx;
		for ($idx = 0; $idx <= $#{$new_support_array_ref}; $idx++) {
			%>
			<tr><td><%=$idx%></td>
			<td><%=$statement->{statement_tree_hash}->{$new_support_array_ref->[$idx]->{statement_num}}->make_statement_path(1)%></td></tr>
			<%
		}
		%>
		</table>
		</center>
		<br>
		Support Nick Name: 
		<select name=nick_name>
		<%
		my $id;
		foreach $id (sort {$a <=> $b} (keys %nick_names)) {
			if ($id == -1) { # some day propegate the previous support nick selection?
				%>
				<option value=<%=$id%> selected><%=$nick_names{$id}->{'nick_name'}%>
				<%
			} else {
				%>
				<option value=<%=$id%>><%=$nick_names{$id}->{'nick_name'}%>
				<%
			}
		}
		%>
		</select>
		<br>
		<br>
		<input type=submit name=submit value="Commit Delegated Support">
		</form>
		<%
		# this is where we display both lists!! ? (after we check for delegate support to deref);

	} else {		# new direct (may change order) suport
		%>
		<script language=javascript>

		var support_array = new Array();
		var support_object;
		<%

		my $support_order_idx = 0;

		my $replacement_hdr = ''; # configure or new
		my $replacement_str = ''; # build up this string with all replacements.
		my $replacement_idx = -1; # where to put the replacement.

		if ($old_support_array_ref) {
			my statement $old_statement;
			foreach $old_support (@{$old_support_array_ref}) {
				if ($old_support) {
					if ($statement->{statement_num} == $old_support->{statement_num}) { # modify support
						$replacement_idx = $support_order_idx++;
						$replacement_hdr = 'Modify Support';
					} else {
						$old_statement = $statement->{statement_tree_hash}->{$old_support->{statement_num}};
						if ($statement->is_related($old_statement->{statement_num})) {
							if ($replacement_idx == -1) {
								$replacement_idx = $support_order_idx++;
								$replacement_str = '<br>This new support will replace the existing support for the following related statements:';
							}
							$replacement_str .= '<br>' . $old_statement->make_statement_path(1);
						} else {
							$Response->Write(make_js_support_object_str($support_order_idx++, $old_statement, '', ''));
						}
					}
				}
			}
		}

		if ($replacement_idx == -1) {
			$Response->Write(make_js_support_object_str($support_order_idx++, $statement, '<font color=green>New Support:</font><br>'));
		} else {
			$Response->Write(make_js_support_object_str($replacement_idx, $statement, $replacement_hdr, $replacement_str));
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
			render_str += "  <table class=support_table>\n";

			var idx;

			for (idx = 0; idx < support_array.length; idx++) {
				if (! support_array[idx]) {
					alert('in: ' + idx);
					// shouldn't happen, but bad data (i.e. related support.) has happened.
					continue;
				}

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
				if ($id == -1) { # some day propegate the previous support nick selection?
					%>
					render_str += "<option value=<%=$id%> selected><%=$nick_names{$id}->{'nick_name'}%>\n";
					<%
				} else {
					%>
					render_str += "<option value=<%=$id%>><%=$nick_names{$id}->{'nick_name'}%>\n";
					<%
				}
			}
			%>
			render_str += "  </select><br><br>\n";
			render_str += "<input type=submit name=submit value=\"Commit Direct Support\">\n";
			render_str += "</form>\n";
			render_str += "</center>\n";
			// alert(render_str);
			document.getElementById("support_block").innerHTML = render_str;
		}

		function render_support_karolis_version() {
			var render_str = "";
			render_str += "\n";
			render_str += "\n";
			render_str += "<form method=post>\n";
			render_str += "  <input type=hidden name=topic_num value=<%=$topic_num%>>\n";
			render_str += "  <input type=hidden name=statement_num value=<%=$statement_num%>>\n";
			render_str += "\n";
			var idx;

			for (idx = 0; idx < support_array.length; idx++) {
				if (! support_array[idx]) {
					alert('in: ' + idx);
					// shouldn't happen, but bad data (i.e. related support.) has happened.
					continue;
				}

				support_object = support_array[idx];
				render_str += "\n";
				render_str += "" + idx + "\n";
				render_str += "" + support_object.statement_info + "\n";
				if (support_array.length > 1) { // no move buttons if only supporting one.
					if (idx < (support_array.length - 1)) {
						render_str += "  <button onclick=move_down(" + idx + ")>v</button>";
					} else {
						render_str += "  ";
					}
					if (idx > 0) {
						render_str += "  <button onclick=move_up(" + idx + ")>^</button>\n"; // the move buttons go here.
					} else {
						render_str += "  \n"; // the move buttons go here.
					}
				}
				render_str += "Delete <input type=checkbox name=delete_" + idx + ">\n";
				render_str += "\n";
				render_str += "<input type=hidden name=support_" + idx + " value=" + support_object.statement_num + ">\n";

			}
			render_str += "  \n";
			render_str += "  \n";
			render_str += "  Support Nick Name: ";
			render_str += "  <select name=nick_name>";
			<%
			my $id;
			foreach $id (sort {$a <=> $b} (keys %nick_names)) {
				if ($id == -1) { # some day propegate the previous support nick selection?
					%>
					render_str += "<option value=<%=$id%> selected><%=$nick_names{$id}->{'nick_name'}%>\n";
					<%
				} else {
					%>
					render_str += "<option value=<%=$id%>><%=$nick_names{$id}->{'nick_name'}%>\n";
					<%
				}
			}
			%>
			render_str += "</select>\n";
			render_str += "<input type=submit name=submit value=\"Commit Direct Support\">\n";
			render_str += "</form>\n";
			render_str += "\n";
			// alert(render_str);

			document.getElementById("support_block").innerHTML = render_str;
		}

		</script>

		<span id = 'support_block'></span>

		<script language=javascript>
		render_support();
		</script>

		</div>
		<%
	}
}


sub make_js_support_object_str {
	my $support_order_idx   = $_[0];
	my statement $statement = $_[1];
	my $header		= $_[2];
	my $replacement_str     = $_[3];

	my $ret_str = '';

	my $statement_info .= $header . $statement->make_statement_path(1) . $replacement_str;

	$statement_info =~ s|"|\\"|g;

	$ret_str .= "support_object = new Object();\n";
	$ret_str .= "support_object.statement_num = $statement->{statement_num};\n";
	$ret_str .= "support_object.statement_info = \"$statement_info\";\n";
	$ret_str .= "support_array[$support_order_idx] = support_object;\n";

	return($ret_str);
}


%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/must_login.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/error_page.asp"-->

