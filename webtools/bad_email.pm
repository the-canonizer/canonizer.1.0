package bad_email;


%bad_email = (
   'leonmaurer@aol.com'          => '2011/06/19 died',
   'pancovenant@gmail.com'       => '2011/08/21 gmail reported: "User unknown"',
   'allen@mormonsite.org'        => '2012/05/06 mx01.1and1.com reported "User unknown"',
   'johnrgregg@comcast.net'      => '2012/07/10 reason: 554 imta02.westchester.pa.mail.comcast.net',
   'rkuehni@carolina.rr.com'     => '2013/10/09 reason: The user(s) account is temporarily over quota.',
   );

sub is_bad_email {
    my $email   = $_[0];

	# return(1); # disable all e-mail

	if (exists $bad_email{$email}) {
		return 1;
	} else {
		return 0;
	}
}


1;

