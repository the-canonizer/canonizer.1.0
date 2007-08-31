<%

sub page_header
{

  ($page_title)=@_;
    
  my $pageHeader = 
  
  qq(
  
<!-- This is important / affects the way the website is rendered by browsers -->
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>

		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<title>$page_title</title>

        <!-- CSS / The way website will appear on the screen -->        
		<link href="css/karolis_screen.css" rel="stylesheet" type="text/css" media="screen">
        
        <!-- CSS / The way website will appear when printed -->
		<link href="css/karolis_print.css" rel="stylesheet" type="text/css" media="print">        

</head>

<body>

<div id="container">

  );
  
  return $pageHeader;
}

sub page_footer
{
  my $pageFooter = 
  
  qq(

</div>  
</body>
</html>

  );
  
  return $pageFooter;
}

%>
