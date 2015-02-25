



<meta name="oops" content="width=device-width, initial-scale=1.0">
<!-- Bootstrap -->
<link href="css/bootstrap.css" rel="stylesheet" media="screen">
<link href="css/customcss.css" rel="stylesheet" media="screen">


<title>Oops</title>

<meta charset="utf-8">

<script src="https://maps.googleapis.com/maps/api/js?v=3.exp"></script>
<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?libraries=places"></script>
<link href="http://fonts.googleapis.com/css?family=Source+Sans+Pro:200,300,400,600,700,900" rel="stylesheet" />


<link href="css/bootstrap-theme.css" rel="stylesheet">

<link href="css/registercustom.css" rel="stylesheet">
<link rel="stylesheet" type="text/css" href="css/bootstrap-select.css">
 

<script src="js/bootstrap.min.js"></script>
<script src="js/jquery-2.1.1.min.js"></script>
<script src="js/bootstrap-select.js"></script>

 <script type="text/javascript" src="js/moment.js"></script>
<script type="text/javascript" src="js/daterangepicker.js"></script>

</head>

<body onload="initialize()">

  <nav class="navbar navbar-default" role="navigation">
    <div class="container-fluid">
      <!-- Brand and toggle get grouped for better mobile display -->
      <div class="navbar-header">
        <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1">
          <span class="sr-only">Toggle navigation</span>
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
        </button>
        <a class="navbar-brand" href="main.php">Oops</a>
      </div>

      <!-- Collect the nav links, forms, and other content for toggling -->
      <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
        <ul class="nav navbar-nav">
          <li class="active"><a href="#">Link</a></li>
          <li class="dropdown">
            <a href="#" class="dropdown-toggle" data-toggle="dropdown">
             <span class="glyphicon glyphicon-list"></span>
             Menu 
             <span class="caret"></span>
           </a>
           <ul class="dropdown-menu" role="menu">
            <li><a href="new_event.php">New Event</a></li>
            <li class="divider"></li>
            <li><a href="new_pic.php">New image</a></li>
            
          </ul>
        </li>
      </ul>
      <form class="navbar-form navbar-left" onsubmit=" return false;">
        <div class="form-group">
         <input type="hidden" id="myInput" value=$username>
         <input type="text" id="autocomplete" class="form-control" placeholder="Enter a City">
         <select class="form-control" name="searchby" onchange="dropdownTest(this.value)">
           <option value="defaultopts" selected>--Search by--</option>
           <option value="events">Events</option>
           <option value="users">Users</option>
           <option value="pictures">Pictures</option>
         </select>
       </div>

       <!--<button type="button" class="btn btn-default btn-lg" onclick="testloc()">Loc test 1</button>
       <button type="button" class="btn btn-default brn-lg" onclick="hideMarkers()">Hide test</button>
       <button type="button" class="btn btn-default brn-lg" onclick="eventTest()">Event test</button>
     -->
   </form>
	<form class="navbar-form navbar-left" onsubmit="processFilter();return false;">
	  <b>Event filter:</b>
	  Select/Deselect all <input type="checkbox" onchange="checkAll(this)" id="dfchk" value="defaultcheck"></input>
	  Party <input type="checkbox" value="Party"></input>
	  Yard Sale <input type="checkbox" value="Yard Sale"></input>
	  Fellowship <input type="checkbox" value="Fellowship"></input>
	  Other <input type="checkbox" value="Other"></input>
	  <input type="submit" value="Filter"> </input>
	  </form>
   <ul class="nav navbar-nav navbar-right">
    <li><a href="HELP_PAGE.pdf">Help</a></li>
    <li class="dropdown">
      <a href="#" class="dropdown-toggle" data-toggle="dropdown" >
        <span class="glyphicon glyphicon-user"></span>
        $username
        <span class="caret"></span>
      </a>
      <ul class="dropdown-menu" role="menu"> 

        <li><a href="profile.php">My Profile</a></li>
        <li><a href="myevent.php">My Event</a></li>
        <li><a href="myphoto.php">My Photo</a></li>
        <li class="divider"></li>
        <li><a href="logout.php">Logout</a></li>
      </ul>
    </li>
  </ul>
</div><!-- /.navbar-collapse -->
</div><!-- /.container-fluid -->
</nav>

<script src="js/jquery-2.1.1.min.js"></script>
<script src="js/bootstrap.min.js"></script>

