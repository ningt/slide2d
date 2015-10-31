<?php
	if (isset($_POST['data'])) {
		// $myfile = fopen("/Users/tang/Web/testfile.txt", "w") or die("Unable to open file!");
		// $myfile = fwrite($myfile, "") or die('fwrite failed');
		// fclose($myfile);

		$myfile = fopen("../Slider2d/data/data.txt", "w") or die("Unable to open file!");
		$data = "";
		for ($i = 0; $i < 5; $i++) {
			$line = $_POST['data'][$i];
			$data .= $line . "\n";
			
		}
		fwrite($myfile, $data) or die('fwrite failed');
		fclose($myfile);

		echo true;
	}
	echo false;
?>