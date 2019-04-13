<?php 

function str2hex($string)
{
    $hex='';

    for ($i=0; $i < strlen($string); $i++)
        $hex .= dechex(ord($string[$i]));

    return $hex;
}


function getCompressableTables($compression, &$adventure)
{
    switch ($compression)
    {
     case 'basic': $compressableTables = array($adventure->locations); break;
     case 'advanced':  $compressableTables = array($adventure->locations, $adventure->messages, $adventure->sysmess); break;
     case 'full': $compressableTables = array($adventure->locations, $adventure->messages, $adventure->sysmess, $adventure->objects); break;
    }
    return $compressableTables;
}

function getBestTokens($adventure, $maxLength, $compression)
{
    // Obtain strings to work with and their length
    $compressableTables = getCompressableTables($compression, $adventure);
    
    $originalLength = 0;
    $workStrings = array();
    foreach ($compressableTables as $compressableTable)
        foreach ($compressableTable as $message)
        {
            $string = $message->Text;
            $originalLength += strlen($string);
            $workStrings[] = $string;
        }
    $minTokenLength = 2;
    $bestTokens = array();
    // Check how many times every different substring appears
    for ($i=0;$i<128;$i++) // repeat this until we have 128 tokens
    {
        // Calculate how much saving would provide each different substring in the strings
        $potentialTokenSavings = array();
        $potentialTokenRepetitions = array();
        foreach($workStrings as $string)    
        {
            $stringLength = strlen($string);
            if ($stringLength < $minTokenLength) continue;
            for ($pos=0;$pos<($stringLength - $minTokenLength) + 1;$pos++)
            {
                for ($tokenLength=$minTokenLength;$tokenLength< min($maxLength, $stringLength - $pos) + 1;$tokenLength++)
                {
                    $potentialToken = substr($string, $pos, $tokenLength); 
                    $saving = strlen($potentialToken) - 1;

                    if (strlen($potentialToken)<$minTokenLength) continue;
                    if (array_key_exists("$potentialToken" ,$potentialTokenRepetitions))
                    {
                        $potentialTokenSavings["$potentialToken"] += $saving;
                        $potentialTokenRepetitions["$potentialToken"]++;
                    }
                    else    
                    {
                        $potentialTokenSavings["$potentialToken"] = -1;  
                        $potentialTokenRepetitions["$potentialToken"] = 1;
                    }
                }
            }
        }
        arsort($potentialTokenSavings);
        $bestToken = key($potentialTokenSavings);
        if ($bestToken == '') break;
        $bestTokenInfo = new StdClass();
        $bestTokenInfo->token = "$bestToken";
        $bestTokenInfo->saving = $potentialTokenSavings["$bestToken"];
        $bestTokens[] = $bestTokenInfo;
        // Now we update the workStrings, so the already selected one is not avaliable anymore
        $currentWorkStringsSize = sizeof($workStrings);
        for($s=0;$s<$currentWorkStringsSize;$s++)
        {
            $parts = explode($bestToken, $workStrings[$s]);
            if (sizeof($parts)>1) // If the token was present in the string
            {
                $workStrings[$s] = $parts[0]; // Replace the string itself with the text before the token
                for ($t=1;$t<sizeof($parts);$t++)  // Now ge the rest of parts separated by the token and add them as new strings to $workStrings
                {
                    $workStrings[] = $parts[$t]; 
                }
            }
        }
    } // for 0-127
    $totalSaving = 0;
    $finalBestTokens = array();
    $k = 0;
    foreach ($bestTokens as $tokenInfo)   
    {
        
        $tokenRealSaving = $tokenInfo->saving - strlen($tokenInfo->token);
        if ($tokenRealSaving>0) 
        {
            $totalSaving += $tokenRealSaving;
            $tokenInfo->hexToken = str2hex($tokenInfo->token);
            $tokenInfo->Index = $k;
            $k++;
            $finalBestTokens[] = $tokenInfo;
        }
    }
    unset($bestToken);
    $result = new StdClass();
    $result->tokens = $finalBestTokens;
    $result->saving = $totalSaving;
    return $result;
    
}


//  ************************************************ MAIN *******************************************



if (sizeof($argv) < 3) Syntax();
$compression = strtolower($argv[2]);
if (($compression!='basic') && ($compression!='advanced') && ($compression!='full')) Error('Invalid compression level');
$inputFileName = $argv[3];
if (sizeof($argv) >4) $outputFileName = $argv[4];
else $outputFileName = replace_extension($inputFileName, 'TOK');

if ($outputFileName==$inputFileName) Error('Input and output file name cannot be the same');
if (!file_exists($inputFileName)) Error('File not found');

$json = file_get_contents($inputFileName);
$adventure = json_decode(utf8_encode($json));
if (!$adventure) 
{
    $error = 'Invalid json file: ';
    switch (json_last_error()) 
    {
        case JSON_ERROR_DEPTH: $error.= 'Maximum stack depth exceeded'; break;
        case JSON_ERROR_STATE_MISMATCH: $error.= 'Underflow or the modes mismatch'; break;
        case JSON_ERROR_CTRL_CHAR: $error.= ' - Unexpected control character found'; break;
        case JSON_ERROR_SYNTAX: $error.= ' - Syntax error, malformed JSON'; break;
        case JSON_ERROR_UTF8: $error.= ' - Malformed UTF-8 characters, possibly incorrectly encoded'; break;
        default: $error.= 'Unknown error';
        break;
    }
    Error($error);
}


replaceEscapeChars($adventure);


echo "Compressing texts\n";
$progress = array('-','\\','|', '/','-','\\','|','/');
$bestSaving = 0;
$bestTokensDetails=null;
ini_set('memory_limit', '6000M');
set_time_limit(0);
for ($maxLength=3;$maxLength<33;$maxLength++)
{
    echo $progress[$maxLength % 8] .chr(8);
    $tokenDetails = getBestTokens($adventure,$maxLength, $compression); 
    if ($tokenDetails->saving > $bestSaving)
    {
        unset($bestTokensDetails);
        $bestSaving = $tokenDetails->saving;
        $bestTokensDetails = $tokenDetails;
    }
    unset($tokenDetails);
}
echo "\n";
if ($bestSaving == 0)
{
    echo "Unable to find tokens that could compress your game texts, won't be compressed.\n";
}
else
{
    $compressionData = new StdClass();
    $compressionData->compression = $compression;
    $compressionData->tokenDetails = $bestTokensDetails;
    $fileContents = json_encode($compressionData, JSON_PRETTY_PRINT|JSON_PARTIAL_OUTPUT_ON_ERROR );
    if (!$fileContents) echo "Err : ". json_last_error();
    file_put_contents($outputFileName, $fileContents);
    echo "Text compression saved $bestSaving bytes.\n";
} 
