<?php

function str2hex($string)
{
    $hex='';

    for ($i=0; $i < strlen($string); $i++)
        $hex .= dechex(ord($string[$i]));

    return $hex;
}



$input = $argv[1];
$h = fopen($input, "r");
$lines = array();
while (!feof($h))
{
    $line = fgets($h);
    $line = str_replace(chr(10),'',$line);
    $line = str_replace(chr(0x0D),'',$line);
    $line = str_replace("\n",'',$line);
    $line = str_replace(' ','',$line);
    $line = str_replace('_',' ',$line);
    $lines[]=$line;
}
fclose($h);

$output ='';
for($i=0;$i<sizeof($lines);$i++)
{
    $line = $lines[$i];
    $hexline = str2hex($line);
    $output .= "{\"saving\":1000,\"hexToken\":\"$hexline\"}";
    if ($i<sizeof($lines)) $output.=",";
    $output.="\n";
}
$output = " \"compression\": \"full\",\"tokenDetails\": {\"tokens\": [" . $output . "], \"saving\": 99999}}";
file_put_contents($argv[2], $output);