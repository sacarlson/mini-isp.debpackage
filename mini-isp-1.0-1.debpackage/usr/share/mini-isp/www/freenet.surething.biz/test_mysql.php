<?php


    include('./config.php');
    print ("username = $username  \n");
    #print (" password = $password \n");
    $con = mysql_connect("localhost",$username,$password,true);
  if (!$con)
  {
    die('Could not connect mysql in checkacc.php: ' . mysql_error());
  }
  echo "ok"

?>
