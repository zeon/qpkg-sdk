<?
$debugging = true;

define("QNAP_WEB_FOLDER",	exec("/sbin/getcfg SHARE_DEF defWeb -d Qweb -f /etc/config/def_share.info"));	
define("QWEB_DIR",			"/share/".QNAP_WEB_FOLDER."");
define("HELLO_QNAP_WEBDIR",	QWEB_DIR."/hello_qnap/");	

if ($debugging)
	define("WRITE_LOG",		"\" -O ".HELLO_QNAP_WEBDIR."debug.log");
else 
	define("WRITE_LOG",		"\"");	
		
define("THTTPD_PORT",		exec("/sbin/getcfg SYSTEM \"Web Access Port\" -f /etc/config/uLinux.conf"));
define("EXEC_ADMIN_HTTP",	"/usr/bin/wget \"http://127.0.0.1:".THTTPD_PORT."/hello_qnap.cgi?");

define("RUNNING",			"Proftpd is running.");
define("STOPPED",			"Proftpd is not running.");

if ($_GET['restart'] == 1) exec(EXEC_ADMIN_HTTP."ftp=start".WRITE_LOG);
if ($_GET['restart'] == 2) exec(EXEC_ADMIN_HTTP."ftp=stop".WRITE_LOG);
if (isset($_GET['restart'])) sleep(7);

// Check if Proftpd is running
$output = null; exec("/bin/pidof proftpd", $output);
if ($output[0] != "") $is_running = RUNNING; else $is_running  = STOPPED;

$viewconfig = $_POST['viewconfig'];
$save_it = $_POST['save_it'];
$action = 'save';

$loadcontent = HELLO_QNAP_WEBDIR."settings.conf";

// Write to the settings.conf
if ($save_it == "1") {
	$savecontent = stripslashes($viewconfig);
	$fp = @fopen($loadcontent, "w");
	if ($fp) {
		fwrite($fp, $savecontent);
		fclose($fp);
	} else $msg = "Cannot save! Check if the file has global write permission &nbsp; ";
}

// Read the content of settings.conf
if (!file_exists($loadcontent)) {
	$action = "";
	$loadcontent = "File does not exist!";
} else {
	$fp = @fopen($loadcontent, "r");
	$loadcontent = fread($fp, filesize($loadcontent));
	$loadcontent = htmlspecialchars($loadcontent);
	fclose($fp);
}
?>

<html>
<head>
<title> - This is the web interface for Hello_QNAP - </title>

</head>

<body> 
<h2>This is the web-based demo for Hello_QNAP QPKG</h2>
<br />
Below's an example list of actions you can do from the web interface:
<br />
<font size='2'>(Note: Check the log file <a href='debug.log' target='_blank'>debug.log</a> under the hello_qnap web root for more info if needed.)</font>
<br />
<br />
<?
$output = null; 
exec("/usr/bin/hello_qnap", $output);
echo "1. Output from executing /usr/bin/hello_qnap<br />";
echo "<span style='color: #ff0000;'>$output[0]</span>";

?>
<br />
<br />
<?
$output = null; 
exec("/bin/date", $output);
echo "2. The current system time<br />";
echo "<span style='color: #ff0000;'>$output[0]</span>";
?>

<br />
<br />
<?
echo "
<form method='get' action='index.php'>
	3. <input class='button' type='submit' name='restart' value='1'><label>Start</label>
	<input class='button' type='submit' name='restart' value='2'><label>Stop</label>
	Proftpd daemon (which requires admin rights)<br />
	<span style='color: #ff0000;'>$is_running</span>
</form>";
?>

<?
echo "4. Read/Write to a local configuration file;";
echo "
<form method='post' action=''>
	<table cellspacing='0' width='400' style='height: 32px; padding: 0;'>
		<tr>
			<td><span style='color: #ff0000;'>File location: [&nbsp;".HELLO_QNAP_WEBDIR."settings.conf]</span>
			</td>
		</tr>
	</table>
	<textarea name=\"viewconfig\" id=\"viewconfig\">$loadcontent</textarea>	<br />
	<input type=\"hidden\" name=\"save_it\" value=\"1\">
	<input class='button' type='submit' name='save_file' value='Save'>&nbsp; 
</form>";
?>
</body>

</html>