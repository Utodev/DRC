<?php
// (C) Uto & Jose Manuel Ferrer 2019 - This code is released under the GPL v3 license
// To build the backend of DAAD reborn compiler I have had aid from Jose Manuel Ferrer Ortiz's DAAD database code,
// which he glently provided me. In some cases the code has been even copied and pasted, so that's why he is also
// in the copyright notice above. Thanks Jose Manuel for this invaluable aid. Also, thanks to Natalia Pujol, for 
// her invaluable help with the BEEP/XPLAY code, and for many ideas and proposals that whether they got to 
// production or not, helped make DRC what it is

global $adventure;
global $xMessageOffsets;
global $xMessageSize;
global $maxFileSizeForXMessages;

$xMessageSize = 0;

define('FAKE_DEBUG_CONDACT_CODE',220);
define('FAKE_USERPTR_CONDACT_CODE',256);    
define('XMES_OPCODE', 128);
define('XPICTURE_OPCODE',130);
define('XSAVE_OPCODE',131);
define('XLOAD_OPCODE',132);
define('XPART_OPCODE',133);
define('XPLAY_OPCODE',134);
define('XBEEP_OPCODE',135);
define('XSPLITSCR_OPCODE',136);
define('XUNDONE_OPCODE',137);
define('XNEXTCLS_OPCODE',138);
define('XNEXTRST_OPCODE',139);
define('XSPEED_OPCODE',140);
define('XDATA_OPCODE',142);
define('LET_OPCODE',51);


define('SFX_OPCODE',    18);
define('PAUSE_OPCODE',  35);
define('EXTERN_OPCODE', 61);
define('BEEP_OPCODE',   64);
define('AT_OPCODE', 0);
define('PROCESS_OPCODE',75);

define('XPLAY_OCTAVE', 0);
define('XPLAY_VOLUME', 1);
define('XPLAY_LENGTH', 2);
define('XPLAY_TEMPO',  3);

//================================================================= filewrite ========================================================

// Writes a byte value to file
function writeByte($handle, $byte)
{
    fputs($handle, chr($byte), 1);
}


// Writes a word value to file, will store as little endian or big endian depending on parameter
function writeWord($handle, $word, $littleEndian)
{
    $a = ($word & 0xff00) >> 8;
    $b = ($word & 0xff);
    if ($littleEndian)
    {
        $tmp = $b;
        $b = $a;
        $a = $tmp;
    }
    writeByte($handle, $b);
    writeByte($handle, $a);
}

// shortcut for writeByte($handle, 0)
function writeZero($handle) 
{
    $b =0;
    writeByte($handle, $b);
}

// shortcut for writeByte($handle, 0xFF)
function writeFF($handle) 
{
    $b =0xFF;
    writeByte($handle, $b);
}



// Writes $size bytes to file with value 0
function writeBlock($handle, $size)
{
    for ($i=0;$i<$size;$i++) writeZero($handle);
}

//================================================================= externs ========================================================

function generateExterns(&$adventure, &$currentAddress, $outputFileHandler)
{
    foreach($adventure->externs as $extern)
    {
        $externData = $extern->FilePath;
        $parts = explode('|',$externData);
        if (sizeof($parts)<2) $parts[] ='EXTERN'; // this is just to be able to process old version .JSON files
        $filePath = $parts[0];
        $fileType = $parts[1];
        if (!file_exists($filePath)) Error("File not found: ${filePath}");
        $externfileHandle = fopen($filePath, "r");
        $buffer = fread($externfileHandle, filesize($filePath));
        fclose($externfileHandle);
        fputs($outputFileHandler, $buffer);
        switch ($fileType) 
        {
            case 'EXTERN': $adventure->extvec[0] = $currentAddress; break;
            case 'SFX': $adventure->extvec[1] = $currentAddress; break;
            case 'INT':$adventure->extvec[2] = $currentAddress; break;
            default: Error("Invalid file type '$fileType' for file $filePath");
        }
        echo "$fileType $filePath loaded at " . prettyFormat($currentAddress) . "\n";
        $currentAddress+=filesize($filePath);
    }   
}

//================================================================= tokens ========================================================


// Tokens array is data is a JSON object with hexedecimal representation of several strings:
$compressionJSON_ES  = '{"compression": "advanced", "tokens": ["00","2071756520","6120646520","6f20646520","20756e6120","2064656c20","7320646520","206465206c","20636f6e20","656e746520","20706f7220","2065737415","7469656e65","7320756e20","616e746520","2070617261","206c617320","656e747261","6e20656c20","6520646520","61206c6120","6572696f72","6369186e20","616e646f20","69656e7465","20656c20","206c6120","20646520","20636f6e","20656e20","6c6f7320","61646f20","20736520","65737461","20756e20","6c617320","656e7461","20646573","20616c20","61646120","617320","657320","6f7320","207920","61646f","746520","616461","6c6120","656e74","726573","717565","616e20","6f2070","726563","69646f","732c20","616e74","696e61","696461","6c6172","65726f","6d706c","6120","6f20","6572","6573","6f72","6172","616c","656e","6173","6f73","6520","616e","656c","6f6e","696e","6369","756e","2e20","636f","7265","6469","2c20","7572","7472","6465","7375","6162","6f6c","616d","7374","6375","7320","6163","696c","6772","6164","7465","7920","696d","746f","7565","7069","6775","6368","6361","6c61","6e20","726f","7269","6c6f","6d69","6c20","7469","6f62","6d65","7369","7065","206e","7475","6174","6669","646f","656d","6179","222e","6c6c"] }';
$compressionJSON_PT  = '{"compression": "advanced", "tokens": ["00", "737461766120", "207061726120", "0e110f6f20", "20756d6120", "646f20", "646120", "20646520", "696120", "206e6f20", "206120", "206f20", "2071756520", "206d7569746f20", "617320", "206c75676172", "696e686120", "616f20", "616e746520", "657374", "617220", "726120756d20", "206520", "6e6120", "2e20416f20", "20636f", "707265636973", "706172", "6f7320", "6f2e20", "656e686f20", "2e2e2e0d", "20202020202020", "73736f20", "736520", "656d20", "657373", "66617a657220", "706f72746120", "6f2e0d", "6d656e74", "72746f20", "726120", "6964616465", "676172", "6361727265", "696f20", "656e64657220", "646520", "726573", "2e2e2e20", "6c6f63616c20", "61766120", "6e7465", "6f2c20", "726f20", "612e0d", "6e747261", "756d6120", "636f6e", "657220", "616c6775", "756d20", "2e204f20", "696e68", "2073656d707265", "20706f72", "6d616973", "6d6520", "736f627265", "657261", "617265", "73756120", "696361", "2074656d706f20", "20616c", "646573", "656920", "732e20", "6f726d61", "6f6d6f20", "45737461", "5f2e0d", "747261", "6f732e", "0b2d203a207175", "66657272", "6465706f6973", "6f2065", "70616c", "616e64", "71756520", "756172", "6e68656369", "636f6d", "6f727265", "70617373", "74696e", "652c20", "2e2041", "697373", "0b2d20", "6120", "6f20", "6f75", "656c", "6572", "6520", "616c", "6f630e160f20", "6974", "6f72", "616e", "6172", "656e", "696e", "6f73", "6369", "616d20", "2e0d", "2e20", "6973", "2c20", "6573", "6f6e", "6361", "6972", "6176", "7175"]}';
$compressionJSON_EN  = '{"compression": "advanced", "tokens": ["00","2074686520","20796f7520","2061726520","696e6720","20746f20","20616e64","20697320","596f7520","616e6420","54686520","6e277420","206f6620","20796f75","696e67","656420","206120","206f70","697468","6f7574","656e74","20746f","20696e","616c6c","207468","206974","746572","617665","206265","766572","686572","616e64","656172","596f75","206f6e","656e20","6f7365","6e6f","6963","6170","2062","6768","2020","6164","6973","2063","6972","6179","7572","756e","6f6f","2064","6c6f","726f","6163","7365","7269","6c69","7469","6f6d","626c","636b","4920","6564","6565","2066","6861","7065","6520","7420","696e","7320","7468","2c20","6572","6420","6f6e","746f","616e","6172","656e","6f75","6f72","7374","2e20","6f77","6c65","6174","616c","7265","7920","6368","616d","656c","2077","6173","6573","6974","2073","6c6c","646f","6f70","7368","6d65","6865","626f","6869","6361","706c","696c","636c","2061","6f66","2068","7474","6d6f","6b65","7665","736f","652e","642e","742e","7669","6c79","6964","7363","2070","656d","7220"] }';
$compressionJSON_DE  = '{"compression": "advanced", "tokens": ["00","2065696e6520","2064657220","2064696520","2064617320","2069737420","20766f6e20","2065696e20","20756e64","756e6420","44657220","44696520","44617320","20756e67","6c65696e","65727420","20647520","207a7520","2065696e","20766572","737420","6d6974","766f6e","68656e","617573","656e74","207a75","616c6c","206465","656e20","616265","697374","206265","766572","206475","447520","686572","756e64","696e67","736368","4475","6368","6965","6e6f","6963","6162","2062","6569","2020","6c6c","2063","6972","6572","7572","756e","2064","6c6f","726f","6172","7365","7269","6c69","7469","6f6d","7373","636b","4920","6564","6568","2066","6861","7065","6520","7420","696e","7320","6465","2c20","6572","6420","7a75","616e","6172","656e","6175","6f64","7374","2e20","686f","6c65","6174","616c","7265","7920","6368","616d","656c","2077","6173","6573","6974","2073","6c6c","6d61","6f70","6d65","6865","626f","6869","6b61","7565","6f65","6165","2061","2068","7474","6d6f","6b65","766f","736f","652e","642e","742e","7669","6d6d","7363","2070","656d"]}';
$compressionJSON_FR  = '{"compression": "advanced", "tokens": ["7f", "4a65206e6520", "706f72746520", "20646520", "4a6520", "782070617320", "666169726520", "746520", "2064616e7320", "205f2e0d", "4a27616920", "6e6520", "20706f757220", "6d61696e7465", "657220", "656e6c6576", "706575", "65722e0d", "61207269656e", "63656c612e", "0d51756520", "20706c65696e", "707579657a20", "20706173", "64166a0e100f", "652e0d", "6e616e74203f", "6c6520", "746f75636865", "73757220", "721665737361", "2e0d", "656e737569", "6c657a20", "6f7520", "65722e", "6d0e140f", "6e2761692072", "0d457420", "2074726f7020", "6c6965752e20", "496c206e2779", "6f6e74696e75", "657374", "7265", "6973717565", "6d6f69203a0d", "726f75", "6173736574", "6f737369", "69656e", "7320", "6669636869", "6572", "205f2e", "7572", "6f6d", "63656c61", "766f69", "73756973", "706f7274", "6e616e74", "0e160f74", "6169", "4c6520", "4020", "656374", "657a20", "452044", "7365", "617520", "0e140f", "6f6e", "202d20", "6575", "6f75", "6d70", "6574", "6170", "7061", "6e27", "616c", "6f69", "7573", "2e20", "7072", "2e2e", "6f72", "2064", "2063", "6369", "3a20", "6d65", "2056", "642e", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f", "7f"]}';

// A .TOK alternative file can be placed together with input JSON file (just use same name, .TOK extension. It's content should a JSON object just like the ones above)


function generateTokens(&$adventure, &$currentAddress, $outputFileHandler, $hasTokens, $compressionData, &$savings)
{
    if (!$hasTokens) 
    {
        writeZero($outputFileHandler);
        $currentAddress++;
    }
    else
    {
        $compressableTables = getCompressableTables($compressionData->compression,$adventure);

        // *** FIRST PASS: determine which tokens it's worth to use:

        // Copy all strings to an array
        $stringList = array();
        foreach ($compressableTables as $compressableTable)
            for ($i=0;$i<sizeof($compressableTable);$i++)
                $stringList[] =  $compressableTable[$i]->Text;

        // Determine savings per token
        $tokenSavings = array();
        for ($j=0;$j<sizeof($compressionData->tokens);$j++)
        {
            $token = $compressionData->tokens[$j];
            for ($i=0;$i<sizeof($stringList);$i++)
            {
                $parts = explode($token, $stringList[$i]);
                if (sizeof($parts)>1)
                 for ($k=0;$k<sizeof($parts)-1;$k++)  // Once per each token replacement (number of parts minus 1)
                 {
                    if (array_key_exists($j, $tokenSavings)) $tokenSavings[$j] += strlen($token) - 1; else $tokenSavings["$j"] = -1; // First replacement of a token wastes 1 byte, next replacements save token length minus 1
                 }
                 $stringList[$i] = implode(chr($j+127), $parts);
            }
        }

        // Remove tokens which aren't worth to use
        $totalSaving = 0;
        $finalTokens = array($compressionData->tokens[0]); //never remove first token
        for ($j=1;$j<sizeof($compressionData->tokens);$j++) // $j=1 to start by second token
        {
            if (!array_key_exists($j, $tokenSavings)) $tokenSavings[$j] = 0;
            if ($tokenSavings[$j]>0)
            {
                $finalTokens[] = $compressionData->tokens[$j];
                $totalSaving += $tokenSavings[$j];
            } 
            else if ($adventure->verbose)
            {
                if ($tokenSavings[$j]==0) echo "Warning: token [" . $compressionData->tokens[$j] . "] won't be used cause it was not used by any text.\n";
                                     else echo "Warning: token [" . $compressionData->tokens[$j] . "] won't be used cause using it wont save any bytes, but waste ".abs($tokenSavings[$j])." byte.\n";
            } 
        }
        $savings = $totalSaving;

        // *** SECOND PASS: replace and dump only remaingin tokens

        if ($adventure->verbose) echo "Compression tokens used: " . sizeof($finalTokens) . ".\n";
        if ($adventure->classicMode)
        {
            while (sizeof($finalTokens)<128) $finalTokens[] = ' ';
            if ($adventure->verbose) echo "Filling tokens table up to 128 tokens for classic mode compatibility.\n";
        }


        // Replace tokens        
        for ($j=0;$j<sizeof($finalTokens);$j++)
        {
            $token = $finalTokens[$j];
            foreach ($compressableTables as $compressableTable)
                for ($i=0;$i<sizeof($compressableTable);$i++)
                {
                    $message = $compressableTable[$i]->Text;
                    $parts = explode($token, $message);
                    $newMessage = implode(chr($j+127), $parts);
                    $compressableTable[$i]->Text = $newMessage;;
                }
        }
    
        // Dump tokens to file
        for ($j=0;$j<sizeof($finalTokens);$j++)
        {
            $tokenStr = $finalTokens[$j];
            $tokenLength = strlen($tokenStr);          
            for ($i=0;$i<$tokenLength;$i++) 
            {
                $shift = ($i == $tokenLength-1) ? 128 : 0;
                $c = substr($tokenStr, $i, 1);
                writeByte($outputFileHandler, ord($c) + $shift);
                $currentAddress++;
            }
        }


        
        
    }
}
//================================================================= common ========================================================

define ('OFUSCATE_VALUE', 0xFF);

class daadToChr
{
var $conversions = array('ª', '¡', '¿', '«', '»', 'á', 'é', 'í', 'ó', 'ú', 'ñ', 'Ñ', 'ç', 'Ç', 'ü', 'Ü');
var $newConversions = array(16=>'à',17=>'ã',18=>'ä',19=>'â',20=>'è',21=>'ë',22=>'ê',23=>'ì',24=>'ï',25=>'î',26=>'ò',27=>'õ',28=>'ö',29=>'ô',30=>'ù',31=>'û',35=>'ß');

}
define('VERSION_HI',0);
define('VERSION_LO',29);


function summary($adventure)
{
    echo "\n";
    echo "Adventure Totals\n";
    echo "================\n";
    echo "Locations   : " . sizeof($adventure->locations) . "\n";
    echo "Objects     : " . sizeof($adventure->objects) . "\n";
    echo "Messages    : " . sizeof($adventure->messages) . "\n";
    echo "Sysmess     : " . sizeof($adventure->sysmess) . "\n";
    if (sizeof($adventure->xmessages)) echo "XMessages   : " . sizeof($adventure->xmessages) . "\n";
    echo "Connections : " . sizeof($adventure->connections) . "\n";
    echo "Processes   : " . sizeof($adventure->processes) . "\n";
    echo "\n";

}

function prettyFormat($value)
{
    $value = strtoupper(dechex($value));
    $value = str_pad($value,4,"0",STR_PAD_LEFT);
    $value = "0x$value";
    return $value;
}

function replace_extension($filename, $new_extension) {
    $info = pathinfo($filename);
    return ($info['dirname'] ? $info['dirname'] . DIRECTORY_SEPARATOR : '') 
        . $info['filename'] 
        . '.' 
        . $new_extension;
}

function addPaddingIfRequired($target, $outputFileHandler, &$currentAddress)
{
    if ($GLOBALS['adventure']->forcedNoPadding) exit;
    if (((isPaddingPlatform($target)) || ($GLOBALS['adventure']->forcedPadding)) && (($currentAddress % 2)==1)) 
    {
        writeZero($outputFileHandler); // Fill with one byte for padding
        $currentAddress++;
    }
}



function hex2str($hex)
{
    $string='';
    for ($i=0; $i < strlen($hex)-1; $i+=2)
        $string .= chr(hexdec($hex[$i].$hex[$i+1]));

    return $string;
}


function getCompressableTables($compression, &$adventure)
{
    $compressableTables = array();
    switch ($compression)
    {
     case 'basic': $compressableTables = array($adventure->locations); break;
     case 'advanced':  $compressableTables = array($adventure->locations, $adventure->messages, $adventure->sysmess, $adventure->xmessages); break;
    }
    return $compressableTables;
}




//================================================================= messages  ========================================================

function replaceChars($str)
{
    // replace special Spanish and other languages characters
    $daad_to_chr = new daadToChr();
    // Old standard Spanish characters
    for($i=0;$i<sizeof($daad_to_chr->conversions);$i++)
    {
        $spanishChar = $daad_to_chr->conversions[$i];
        if (strpos($str, $spanishChar)!==false)
        {
            $to = chr($i+16);
            $str = str_replace($spanishChar, $to, $str);
        } 
    }
    
    // New supported characters
    foreach($daad_to_chr->newConversions as $i=>$nonEnglishChar)
    {
        if (strpos($str, $nonEnglishChar)!==false)
        {
            $to = '#g'. chr($i) . '#t';
            $str = str_replace($nonEnglishChar, $to, $str);
        } 
    }
    // replace escape sequences
    $replacements = array('#g'=>0x0e, '#t'=>0x0f,'#b'=>0x0b, '#s'=>0x20, '#f'=>0x7f, '#k'=>0x0c, '#n'=>0x0D, '#r'=>0x0D);
    // Add #A to #P to replacements array
    for ($i=ord('A');$i<=ord('P');$i++) $replacements["#" . chr($i)]= $i + 0x10 - ord('A');

    $oldSequenceWarning = false;
    foreach ($replacements as $search=>$replace)
    {
        // Check the string does not contain old escape sequences using baskslash, print warning otherwise
        if ($search!='#n') 
        {
            $oldSequence = str_replace('#','\\', $search);
            if ((strpos($str, $oldSequence)!==false) && (!$oldSequenceWarning))
            {
                echo "Warning: DRC does not support escape sequences with backslash character, use sharp (#) instead. i.e: #g instead of \g";
                $oldSequenceWarning = true;
            } 
        }
        $str = str_replace($search, chr($replace), $str);
    }

    // Replace carriage retuns that may come by users writing \n and that going throuhg as chr(10) instead of '\n' string
    $str = str_replace(chr(10), chr(13),$str); 
    // this line must be last, to properly print # character
    $str = str_replace('##', "#",$str); 
    return $str;
}

function replaceEscapeChars(&$adventure)
{
    $tables = array($adventure->messages, $adventure->sysmess, $adventure->locations, $adventure->objects, $adventure->xmessages);
    foreach ($tables as $table)
     foreach($table as $message)
     {
        $message->originalText = $message->Text;
        // Although the following line is no longer needed, as DRF already generates the strings with all escape chars and special chars replaced
        // I'm keeping this code here so old JSON created with old DRF work.
        $message->Text = replaceChars($message->Text);
     }
}

function checkStrings($adventure)
{
    $tables = array($adventure->messages, $adventure->sysmess, $adventure->locations, $adventure->objects);
    $tableNames = array('user messages (MXT)','system messages(STX)','location texts(LTX)','object texts(OTX)');
    $messageNames = array('message','message','location','object');
    for ($tableID=0;$tableID<4;$tableID++)
    {
        $table = $tables[$tableID];
        for ($msgID=0;$msgID<sizeof($table);$msgID++)
        {
            $message = $table[$msgID];
            $text = $message->Text;
            for ($i=0;$i<strlen($text);$i++)
            {
                if (ord($text[$i])>127)
                {
                    $tableName = $tableNames[$tableID];
                    $messageName = $messageNames[$tableID];
                    $originalMessage = $message->originalText;
                    Error("Invalid character in $tableName, $messageName #$msgID (".($i+1).",#".ord($text[$i])."): '$originalMessage'");
                } 
            }
        }
    }
            
}


// Returns File Size
function getXMessageFileSizeByTarget($target, $subtarget, $adventure) 
{
    switch ($target) 
    {
        case 'ZX'  : return 64; 
        case 'MSX' : return 64; 
        case 'PCW' : return 64; 
        case 'MSX2': return 16; 
        case 'HTML': return 16; 
        case 'CPC' : return 2;
        case 'C64' : return 2;
        case 'CP4' : return 2;      
        case 'PC': if ($subtarget == 'VGA256') return 64;
        default: return 0;
    }
}


function generateXMessages($adventure, $target, $subtarget, $outputFileName)
{
    $currentOffset = 0;
    $currentFile = 0;
    $maxFileSize = getXMessageFileSizeByTarget($target, $subtarget, $adventure);
    $GLOBALS['maxFileSizeForXMessages'] = $maxFileSize;
    if (!$maxFileSize) Error("XMessages are not supported by target [ $target $subtarget ]");
    $maxFileSize *= 1024; // Convert K to byte
    if (($maxFileSize==2048) && ($currentFile<10)) $currentFile = "0$currentFile";
    $outputFileName = "$currentFile.XMB";
    $fileHandler = fopen($outputFileName, "w");
    for($i=0;$i<sizeof($adventure->xmessages);$i++)
    {
        $message = $adventure->xmessages[$i];
        $messageLength = strlen($message->Text);
        if ($messageLength + $currentOffset + 1  > $maxFileSize) // Won't fit, next File  , +1  for the end of message mark
        {
            if ($target=="MSX2") 
            {
                writeBlock($fileHandler, $maxFileSize - $currentOffset);
                $currentFile++;
                $currentOffset = 0;
            }
            else 
            {
                fclose($fileHandler);
                $currentFile++;
                $currentOffset = 0;
                if (($maxFileSize==2048) && ($currentFile<10)) $currentFile = "0$currentFile";
                $outputFileName = "$currentFile.XMB";
                $fileHandler = fopen($outputFileName, "w");
            }
        }
        $GLOBALS['xMessageOffsets'][$i] = $currentOffset + $currentFile * $maxFileSize;
        // Saving length as a truncated value to make it fit in one byte, the printing routine will have to recover the missing bit by filling with 1. That will provide 
        // a length which could be maximum 1 bytes longer than real, what is not really important cause the end of message mark will avoid that extra char being printed
        for ($j=0;$j<$messageLength;$j++)
        {   
            writeByte($fileHandler, ord($message->Text[$j]) ^ OFUSCATE_VALUE);
            $currentOffset++;
        }
        writeByte($fileHandler,ord("\n") ^ OFUSCATE_VALUE ); //mark of end of string
        $currentOffset++;
    }
    fclose($fileHandler);
    $GLOBALS['xMessageSize'] = $maxFileSize * $currentFile + $currentOffset;
}

function generateMessages($messageList, &$currentAddress, $outputFileHandler,  $isLittleEndian, $target)
{

    $messageOffsets = array();
    for ($messageID=0;$messageID<sizeof($messageList);$messageID++)
    {
        addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
        $messageOffsets[$messageID] = $currentAddress;
        $message = $messageList[$messageID];
        for ($i=0;$i<strlen($message->Text);$i++)
        {   
            writeByte($outputFileHandler, ord($message->Text[$i]) ^ OFUSCATE_VALUE);
            $currentAddress++;
        }
        writeByte($outputFileHandler,ord("\n") ^ OFUSCATE_VALUE ); //mark of end of string
        $currentAddress++;
        
    }
    // Write the messages table
    addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
    for ($messageID=0;$messageID<sizeof($messageList);$messageID++)
    {
        writeWord($outputFileHandler, $messageOffsets[$messageID] , $isLittleEndian);
        $currentAddress += 2;
    }


    
    
}


function generateMTX($adventure, &$currentAddress, $outputFileHandler,  $isLittleEndian, $target)
{
    generateMessages($adventure->messages, $currentAddress, $outputFileHandler,   $isLittleEndian, $target);
}

function generateSTX($adventure, &$currentAddress, $outputFileHandler,  $isLittleEndian, $target)
{
    generateMessages($adventure->sysmess, $currentAddress, $outputFileHandler,  $isLittleEndian, $target);
}

function generateLTX($adventure, &$currentAddress, $outputFileHandler,  $isLittleEndian, $target)
{
    generateMessages($adventure->locations, $currentAddress, $outputFileHandler,   $isLittleEndian, $target);
}

function generateOTX($adventure, &$currentAddress, $outputFileHandler, $isLittleEndian, $target)
{
    generateMessages($adventure->objects, $currentAddress, $outputFileHandler, $isLittleEndian, $target); 
}

//================================================================= connections ========================================================


function generateConnections($adventure, $target, &$currentAddress, $outputFileHandler, $isLittleEndian)
{

    $connectionsTable = array();
    for ($locID=0;$locID<sizeof($adventure->locations);$locID++) $connectionsTable[$locID] = array();
    foreach($adventure->connections as $connection)
    {
        $FromLoc = $connection->FromLoc;
        $ToLoc = $connection->ToLoc;
        $Direction = $connection->Direction;
        $connectionsTable[$FromLoc][]=array($Direction,$ToLoc);
    }


    // Write the connections
    $connectionsOffset = array();
    for ($locID=0;$locID<sizeof($adventure->locations);$locID++)
    {
        addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
        $connectionsOffset[$locID] = $currentAddress;
        $connections = $connectionsTable[$locID];
        foreach ($connections as $connection)
        {
            writeByte($outputFileHandler, $connection[0]);
            writeByte($outputFileHandler, $connection[1]);
            $currentAddress +=2;
        }
        writeFF($outputFileHandler); //mark of end of connections
        $currentAddress ++;
    }

    // Write the Lookup table
    addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
    for ($locID=0;$locID<sizeof($adventure->locations);$locID++)
    {
        writeWord($outputFileHandler, $connectionsOffset[$locID], $isLittleEndian);
        $currentAddress+=2;
    }
    
}

//================================================================= vocabulary ========================================================




function generateVocabulary($adventure, &$currentAddress, $outputFileHandler)
{
  
    $daad_to_chr = new daadToChr();
    foreach ($adventure->vocabulary as $word)
    {
        // Clean the string from unexpected, unwanted, UFT-8 characters which are valid for vocabulary. Convert them to ISO-8859-1
        $tempWord = $word->VocWord;
        $finalVocWord = '' ;
        $daad_to_chr = new daadToChr();
        for ($i = 0;$i<strlen($tempWord);$i++)
        {
            if (in_array($tempWord[$i], $daad_to_chr->conversions))
            {
                $tempWord[$i] = chr(16+array_search($tempWord[$i],$daad_to_chr->conversions));
            }
            else if (ord($tempWord[$i])<128) $finalVocWord.=$tempWord[$i];  
            else if (ord($tempWord[$i])==195)  // Look for UTF encoded characters
            {
                $i++;
                switch (ord($tempWord[$i]))
                {
                    case 161 : $finalVocWord.= chr(21); break; //á
                    case 169 : $finalVocWord.= chr(22); break; //é
                    case 173 : $finalVocWord.= chr(23); break; //í
                    case 179 : $finalVocWord.= chr(24); break; //ó
                    case 186 : $finalVocWord.= chr(25); break; //ú
                    case 129 : $finalVocWord.= chr(21); break; //Á
                    case 137 : $finalVocWord.= chr(22); break; //Ë
                    case 141 : $finalVocWord.= chr(23); break; //Í
                    case 147 : $finalVocWord.= chr(24); break; //Ó
                    case 154 : $finalVocWord.= chr(25); break; //ú

                    case 145 : $finalVocWord.= chr(27); break; //Ñ
                    case 177 : $finalVocWord.= chr(27); break; //ñ

                    case 156 : $finalVocWord.= chr(31); break; //Ü
                    case 188 : $finalVocWord.= chr(31); break; //ü

                    case 135 : $finalVocWord.= chr(29); break; //Ç
                    case 167 : $finalVocWord.= chr(29); break; //ç
                    
                    default: echo "Warning: Found invalid 195-" . ord($tempWord[$i]) . " UTF encoded string in $tempWord.\n";
                }
            } else 
            if (ord($tempWord[$i])>128) $finalVocWord.=$tempWord[$i];
        }
        // Now let's save it
        $vocWord = substr(str_pad($finalVocWord,5),0,5);
        for ($i=0;$i<5;$i++)
        {
            $character =$vocWord[$i];
            if ((ord($character)>=32) && (ord($character)<128)) $character = strtoupper($character);
            $character = ord($character) ^ OFUSCATE_VALUE;
            writeByte($outputFileHandler, $character);
        }
        writeByte($outputFileHandler, $word->Value);
        writeByte($outputFileHandler, $word->VocType);
        $currentAddress+=7;
    }
    writeZero($outputFileHandler); // store 0 to mark end of vocabulary
    $currentAddress++;
}
//================================================================= objects ========================================================
function generateObjectNames($adventure, &$currentAddress, $outputFileHandler)
{
    foreach($adventure->object_data as $object)
    {
        writeByte($outputFileHandler, $object->Noun);
        writeByte($outputFileHandler, $object->Adjective);
        $currentAddress+=2;
    }
}

function generateObjectInitially($adventure, &$currentAddress, $outputFileHandler)
{
    foreach($adventure->object_data as $object)
    {
     writeByte($outputFileHandler, $object->InitialyAt);
     $currentAddress++;
    }
    writeFF($outputFileHandler);
    $currentAddress++;  
}

function generateObjectWeightAndAttr($adventure, &$currentAddress, $outputFileHandler)
{
    foreach($adventure->object_data as $object)
    {
        $b = $object->Weight & 0x3F;
        if ($object->Container) 
        {
            $b = $b | 0x40;
            $locno = $object->Value;
            $text = $adventure->objects[$locno]->Text;
            if ($adventure->locations[$locno]->Text != '') echo "Warning: object #$locno ($text) is a container. You are supposed to reserve location #$locno to hold the objects in the container, but location #$locno has a description.\n";         
        }
        if ($object->Wearable) $b = $b | 0x80;
        writeByte($outputFileHandler, $b);
        $currentAddress++;
    }
}

function generateObjectExtraAttr($adventure, &$currentAddress, $outputFileHandler, $isLittleEndian)
{
    foreach($adventure->object_data as $object)
    {
     writeWord($outputFileHandler, $object->Flags, $isLittleEndian);
     $currentAddress+=2;
    }

}
//================================================================= processes ========================================================


function getCondactsHash($adventure, $condacts, $from)
{
    $hash = '';
    for ($i=$from; $i<sizeof($condacts);$i++)
    {
        $condact = $condacts[$i];
        $opcode = $condact->Opcode;
        if (($opcode==FAKE_DEBUG_CONDACT_CODE) && (!$adventure->debugMode)) continue;
        if (($opcode==FAKE_USERPTR_CONDACT_CODE)) continue;
        if (($condact->NumParams>0) && ($condact->Indirection1)) $opcode = $opcode | 0x80; // Set indirection bit
        $hash .= "$condact->Opcode ";
        if ($condact->NumParams>0)
        {
            $param1 = $condact->Param1;
            $hash .= "$param1 ";
            if ($condact->NumParams>1) 
            {
                $param2 = $condact->Param2;
                $hash .= "$param2 ";
                if ($condact->NumParams>2) 
                {
                    $param3 = $condact->Param3;
                    $hash .= "$param3 ";
                    if ($condact->NumParams>3) 
                    {
                        $param4 = $condact->Param4;
                        $hash .= "$param4 ";
                    }
                }
            }
        }
    }
    return $hash;
}

function checkMaluva($adventure)
{
    $count = 0;
    foreach ($adventure->externs as $extern)
    {
        if (strrpos($extern->FilePath, ('MLV_')) !== false) $count++;
    }
    return $count;
}

function generateProcesses($adventure, &$currentAddress, $outputFileHandler, $isLittleEndian, $target, $subtarget)
{     
    //PASS ZERO, CHECK THE PROCESSES AND REPLACE SOME CONDACTS LIKE XMESSAGE WITH PROPER EXTERN CALLS. MAKE SURE MALUVA IS INCLUDED
    //           ALSO FIX SOME BUGS LIKE ZX BEEP CONDACT WRONG ORDER
    for ($procID=0;$procID<sizeof($adventure->processes);$procID++)
    {
        $process = $adventure->processes[$procID];
        for ($entryID=0;$entryID<sizeof($process->entries);$entryID++)
        {
            $entry = $process->entries[$entryID];
            for($condactID=0;$condactID<sizeof($entry->condacts); $condactID++)
            {
                $condact = $entry->condacts[$condactID];
                if ($condact->Opcode == PROCESS_OPCODE)
                {
                    // Check if process called does exist, in case it's not indirect call
                    if (!$condact->Indirection1)
                     if ($condact->Param1 >= sizeof($adventure->processes)) Error('Invalid call to process #'.$condact->Param1.". Specified process does not exist");
                }
                else if  ($condact->Opcode == XMES_OPCODE)  // Convert XMESS in a Maluva CALL, XMESSAGE does not actually get to drb, as drf already converts all XMESSAGE into XMESS with a \n added to the string
                {
                    $condact->Opcode = EXTERN_OPCODE;
                    $messno = $condact->Param1;
                    $offset = $GLOBALS['xMessageOffsets'][$messno];
                    if ($offset>0xFFFF) Error('Size of xMessages exceeds the 64K limit');
                    $condact->NumParams = 3;
                    $condact->Param2 = 3; // Maluva's function 3
                    $condact->Param1 = $offset & 0xFF; // Offset LSB
                    $condact->Param3 = ($offset & 0xFF00) >> 8; // Offset MSB
                    $condact->Condact = 'EXTERN';
                }
                else if ($condact->Opcode == XPICTURE_OPCODE)
                {
                    $condact->Opcode = EXTERN_OPCODE;
                    $condact->NumParams=2;
                    $condact->Param2 = 0; // Maluva function 0
                    $condact->Condact = 'EXTERN';
                    if ((!CheckMaluva($adventure)) && ($target!='HTML') && ($target!='MSX2') && !(($target=='PC') && ($subtarget=='VGA256'))) Error("XPICTURE condact requires Maluva Extension $target $subtarget");
                }
                else if ($condact->Opcode == XUNDONE_OPCODE)
                {
                    $condact->Opcode = EXTERN_OPCODE;
                    $condact->NumParams=2;
                    $condact->Param1 = 0; // Useless but it must be set
                    $condact->Param2 = 7; // Maluva function 7
                    $condact->Indirection1 = 0; // Also useless, but it must be set
                    $condact->Condact = 'EXTERN';
                    if ((!CheckMaluva($adventure)) && ($target!='MSX2') && ($target!='HTML') && !(($target=='PC') && ($subtarget=='VGA256')))  Error('XUNDONE condact requires Maluva Extension');
                }
                else if ($condact->Opcode == XNEXTCLS_OPCODE)
                {
                    $condact->Opcode = EXTERN_OPCODE;
                    $condact->NumParams=2;
                    $condact->Param1 = 0; // Useless but it must be set
                    $condact->Param2 = 8; // Maluva function 8
                    $condact->Indirection1 = 0; // Also useless, but it must be set
                    $condact->Condact = 'EXTERN';
                    if (!CheckMaluva($adventure)) Error('XNEXTCLS condact requires Maluva Extension');
                    if (($target!='ZX') || ($subtarget!='NEXT'))  // If target does not support XNEXTCLS_OPCODE replace by always true condition "AT @38"
                    {
                        $condact->Opcode = AT_OPCODE;
                        $condact->Condact = 'AT';
                        $condact->Indirection1 = 1;
                        $condact->Param1 = 38;
                        $condact->NumPrams=1;
                    }
                }
                else if ($condact->Opcode == XNEXTRST_OPCODE)
                {
                    $condact->Opcode = EXTERN_OPCODE;
                    $condact->NumParams=2;
                    $condact->Param1 = 0; // Useless but it must be set
                    $condact->Param2 = 9; // Maluva function 9
                    $condact->Indirection1 = 0; // Also useless, but it must be set
                    $condact->Condact = 'EXTERN';
                    if (!CheckMaluva($adventure)) Error('XNEXTRST  condact requires Maluva Extension');
                    if (($target!='ZX') || ($subtarget!='NEXT'))  // If target does not support XNEXTRST_OPCODE replace by always true condition "AT @38"
                    {
                        $condact->Opcode = AT_OPCODE;
                        $condact->Condact = 'AT';
                        $condact->Indirection1 = 1;
                        $condact->Param1 = 38;
                        $condact->NumPrams=1;
                    }
                }
                else if ($condact->Opcode == XSPEED_OPCODE)
                {
                    $condact->Opcode = EXTERN_OPCODE;
                    $condact->NumParams=2;
                    $condact->Param2 = 10; // Maluva function 10
                    $condact->Condact = 'EXTERN';
                    if (!CheckMaluva($adventure)) Error('XSPEED condact requires Maluva Extension');
                    $targetSubtarget = "${target}${subtarget}";
                    if (($targetSubtarget!='ZXNEXT') && ($targetSubtarget!='ZXUNO'))  // If target does not support XSPEED_OPCODE replace by always true condition "AT @38"
                    {
                        $condact->Opcode = AT_OPCODE;
                        $condact->Condact = 'AT';
                        $condact->Indirection1 = 1;
                        $condact->Param1 = 38;
                        $condact->NumPrams=1;
                    }
                }
                else if ($condact->Opcode == XSAVE_OPCODE)
                {
                    $condact->Opcode = EXTERN_OPCODE;
                    $condact->NumParams=2;
                    $condact->Param2 = 1; // Maluva function 1 
                    $condact->Condact = 'EXTERN';
                    if ((!CheckMaluva($adventure)) && ($target!='HTML') && ($target!='MSX2') && !(($target=='PC') && ($subtarget=='VGA256')))  Error('XSAVE condact requires Maluva Extension');
                }
                else if ($condact->Opcode == XLOAD_OPCODE)
                {
                    $condact->Opcode = EXTERN_OPCODE;
                    $condact->NumParams=2;
                    $condact->Param2 = 2; // Maluva function 2
                    $condact->Condact = 'EXTERN';
                    if ((!CheckMaluva($adventure)) && ($target!='HTML') && ($target!='MSX2') && !(($target=='PC') && ($subtarget=='VGA256')))  Error('XLOAD condact requires Maluva Extension');
                }
                else if ($condact->Opcode == XPART_OPCODE)
                {
                    $condact->Opcode = EXTERN_OPCODE;
                    $condact->NumParams=2;
                    $condact->Param2 = 4; // Maluva function 4
                    $condact->Condact = 'EXTERN';
                    if ((!CheckMaluva($adventure))  && ($target!='HTML') && ($target!='MSX2') && !(($target=='PC') && ($subtarget=='VGA256')))  Error('XPART condact requires Maluva Extension');
                }
                else if ($condact->Opcode == XBEEP_OPCODE)
                {
                    if (($condact->Param2<48) || ($condact->Param2>238)) 
                    {
                        $condact->Opcode = PAUSE_OPCODE;
                        $condact->Condact = 'PAUSE';
                        $condact->NumParams = 1;
                    }
                    else
                    {
                        $condact->Opcode = EXTERN_OPCODE;
                        $condact->NumParams=3;
                        $condact->Param3 = $condact->Param2; 
                        $condact->Param2 = 5; // Maluva function 5
                        $condact->Condact = 'EXTERN'; // XBEEP A B  ==> EXTERN A 5 B  (3 parameters)
                        if ((!CheckMaluva($adventure))  && ($target!='HTML') && ($target!='MSX2') && !(($target=='PC') && ($subtarget=='VGA256')))  Error('XBEEP condact requires Maluva Extension');
                    }
                }
                else if ($condact->Opcode == BEEP_OPCODE)
                {
                    
                    // Out of range values, replace BEEP with PAUSE
                    if (($condact->Param2<48) || ($condact->Param2>238)) 
                    {
                        $condact->Opcode = PAUSE_OPCODE;
                        $condact->Condact = 'PAUSE';
                        $condact->NumParams = 1;
                    }
                    else
                    if ($target=='ZX')  // Zx Spectrum interpreter expects BEEP parameters in opposite order
                    {
                        $tmp = $condact->Param1;
                        $condact->Param1 = $condact->Param2;
                        $condact->Param2 = $tmp;
                    }
                    else
                    if (($target=='MSX') || ($target=='CPC')) // Convert BEEP to XBEEP
                    {
                        $condact->Opcode = EXTERN_OPCODE;
                        $condact->NumParams=3;
                        $condact->Param3 = $condact->Param2; 
                        $condact->Param2 = 5; // Maluva function 5
                        $condact->Condact = 'EXTERN'; // XBEEP A B  ==> EXTERN A 5 B  (3 parameters)
                        if ((!CheckMaluva($adventure)) && ($target!='MSX2') && !(($target=='PC') && ($subtarget=='VGA256')))  Error('XBEEP condact requires Maluva Extension');
                    }
                }
                else if ($condact->Opcode == XPLAY_OPCODE)
                {
                    // Default values
                    $values = array(XPLAY_OCTAVE => 4, XPLAY_VOLUME => 8, XPLAY_LENGTH =>4, XPLAY_TEMPO => 120);
                    $xplay = array();
                    $mml = strtoupper($adventure->other_strings[$condact->Param1]->Text);

                    while ($mml) {
                        $next = strpbrk(substr($mml, 1), "ABCDEFGABLNORTVSM<>&");
                        if ($next!==false)
                            $note = substr($mml, 0, strlen($mml)-strlen($next));
                        else 
                            $note = $mml;
                        $beep = mmlToBeep($note, $values, $target, $subtarget);
                        if ($beep!==NULL) $xplay[] = $beep;
                        $mml = $next;
                    }
                    if (sizeof($xplay)) 
                    {
                        array_splice($entry->condacts, $condactID, 1, $xplay);
                        $condactID --; // As the current condact has been replaced with a sequentia of BEEPs, we move the pointer one step back to make sure the changes made for BEEP in ZX Spectrum applies
                    }
                }
                else if ($condact->Opcode == XDATA_OPCODE)
                {
                    $lets = array();
                    $dataString = strtoupper($adventure->other_strings[$condact->Param1]->Text);
                    $dataArray = explode(',', $dataString);

                    if (sizeof($dataArray)<2) Error('There is not data enough in XDATA condact');               

                    foreach ($dataArray as $i=>$element)
                    {
                        $element = trim($dataArray[$i]);
                        $var = filter_var($element, FILTER_VALIDATE_INT, array());
                        if (!$var) Error("Non integer value in XDATA condact element #$i '$element'");
                        if (($element < 0) || ($element > 255)) Error("XDATA values must be in the 0-255 range, element #$i is not ($element)");
                    }

                    $baseFlagno = $dataArray[0];
                    for ($i=1;$i<sizeof($dataArray);$i++)
                    {
                        if ($baseFlagno>255) Error('XDATA condact went over flag 255');
                        $element = trim($dataArray[$i]);
                        $let = dataToLet($baseFlagno, $element);
                        $lets[]= $let;
                        $baseFlagno++;
                    }

                    if (sizeof($lets)) 
                    {
                        array_splice($entry->condacts, $condactID, 1, $lets);
                        $condactID --; // As the current condact has been replaced with a sequentia of LETs, we move the pointer one step back 
                    }
                }
                else if ($condact->Opcode == XSPLITSCR_OPCODE)
                {
                    $condact->Opcode = EXTERN_OPCODE;
                    $condact->NumParams=2;
                    $condact->Param2 = 6; // Maluva function 6. Notice in case this condact is generated for a machine not supporting split screen it will just do nothing
                    $condact->Condact = 'EXTERN'; // XSPLITSCR X  ==> EXTERN X 6 
                    $targetSubtarget ="${target}${subtarget}";
                    if ((CheckMaluva($adventure)<2) && ($target=='CPC')) Error('XSPLITSCR condact requires Maluva Standard Extension and CPC Interrupt Extension for running under CPC');               
                    if ((CheckMaluva($adventure)<2) && ($targetSubtarget=='ZXUNO')) Error('XSPLITSCR condact requires Maluva Standard Extension and ZX-UNO Interrupt Extension for running under ZX-Uno');               
                    if ((CheckMaluva($adventure)<1) && ($target=='C64')) Error('XSPLITSCR condact requires Maluva extension');               

                    if  ( ($target!='MSX2') && ($target!='CPC')  && ($target!='C64') && ($targetSubtarget!='ZXUNO'))  // If target does not support XSPLITSCR, replaces condact with "AT @38" (always true)
                    {
                        $condact->Opcode = AT_OPCODE;
                        $condact->Condact = 'AT';
                        $condact->Indirection1 = 1;
                        $condact->Param1 = 38;
                        $condact->NumPrams=1;
                    }
                }
            }
        }
    }


    $terminatorOpcodes = array(22, 23,103, 116,117,108);  //DONE/OK/NOTDONE/SKIP/RESTART/REDO
    $condactsOffsets = array();
    // PASS ONE, GENERATE HASHES UNLESS CLASSICMODE IS ON
    $condactsHash = array();  
    if (!$adventure->classicMode)
    {
        for ($procID=0;$procID<sizeof($adventure->processes);$procID++)
        {
            $process = $adventure->processes[$procID];
            for ($entryID=0;$entryID<sizeof($process->entries);$entryID++)
            {
                $entry = $process->entries[$entryID];
                for($condactID=0;$condactID<sizeof($entry->condacts); $condactID++)
                {
                    $hash = getCondactsHash($adventure,$entry->condacts, $condactID);
                    if (($hash!='') && (!array_key_exists("$hash", $condactsHash)))
                    {
                        $hashInfo = new StdClass();
                        $hashInfo->offset = -1; // Not yet calculated
                        $hashInfo->details = new StdClass();
                        $hashInfo->details->process = $procID;
                        $hashInfo->details->entry = $entryID;
                        $hashInfo->details->condact = $condactID;
                        $condactsHash["$hash"] = $hashInfo;
                    }
                }
            }
        }
    }
    // Dump  all condacts and store which address each entry condacts
    for ($procID=0;$procID<sizeof($adventure->processes);$procID++)
    {
        $process = $adventure->processes[$procID];
        for ($entryID=0;$entryID<sizeof($process->entries);$entryID++)
        {
            // Check entry condacts hashes (unless classicMode is on)
            $entry = $process->entries[$entryID];
            if (!$adventure->classicMode)
            {
                $hash = getCondactsHash($adventure,$entry->condacts, 0);
                if ($hash!='')
                {
                    if ($condactsHash["$hash"]->offset != -1)
                    {
                        $offset = $condactsHash["$hash"]->offset;
                        $condactsOffsets["${procID}_${entryID}"] = $offset;
                        continue; // Avoid generating this entry condacts, as there is one which can be re-used
                    }
                    else 
                    {
                        addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
                        $condactsHash["$hash"]->offset = $currentAddress;
                    }
                }
            } else addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
  
            $condactsOffsets["${procID}_${entryID}"] = $currentAddress;
            $entry = $process->entries[$entryID];
            $terminatorFound = false;
            for($condactID=0;$condactID<sizeof($entry->condacts);$condactID++)
            {
                $condact = $entry->condacts[$condactID];

                $opcode = $condact->Opcode;
                if (($opcode==FAKE_DEBUG_CONDACT_CODE) && (!$adventure->debugMode)) continue; // Not saving fake DEBUG condact if debug mode is not on.
                if ($opcode==FAKE_USERPTR_CONDACT_CODE) 
                {
                    $usrextvec = $condact->Param1;
                    $adventure->extvec[$usrextvec] = $currentAddress;
                    echo "UserPtr #$usrextvec set to " . prettyFormat($currentAddress).  "\n";
                    continue; // Just save the extvec, do not save the fake condact
                }

                if ((!$adventure->classicMode))
                    if (($currentAddress%2 == 0) || (!isPaddingPlatform($target))) // We can only partially re-use an entry if its word aligned or the platform does not require word alignment
                    {
                        $hash = getCondactsHash($adventure,$entry->condacts, $condactID);
                        if ($condactsHash["$hash"]->offset == -1) $condactsHash["$hash"]->offset = $currentAddress;
                    }

                if (($condact->NumParams>0) && ($condact->Indirection1)) $opcode = $opcode | 0x80; // Set indirection bit
                if (($opcode == FAKE_DEBUG_CONDACT_CODE) && ($adventure->verbose)) echo "Debug condact found, inserted.\n";
                writeByte($outputFileHandler, $opcode);
                $currentAddress++;
                for($i=0;$i<$condact->NumParams;$i++) 
                {
                    switch ($i)
                    {
                        case 0: $param = $condact->Param1;
                                writeByte($outputFileHandler, $param); 
                                break;

                        case 1: $param = $condact->Param2;
                                writeByte($outputFileHandler, $param); 
                                break;

                        case 2: $param = $condact->Param3;
                                writeByte($outputFileHandler, $param); 
                                break;
                         case 3: $param = $condact->Param4;
                                writeByte($outputFileHandler, $param); 
                                break;
                    }
                }
                $currentAddress+= $condact->NumParams;
                if (!$adventure->classicMode) if (in_array($opcode, $terminatorOpcodes)) 
                {
                    $terminatorFound = true;
                    if ($adventure->verbose)
                    {
                        if ($condactID != sizeof($entry->condacts) -1 ) // Terminator found, but additional condacts exists in the entry
                        {
                            $humanEntryID =$entryID + 1; // entryID increased so for human readability entries are from #1 to #n, not from #0 to #n
                            $verb = $entry->Verb;
                            $noun = $entry->Noun;
                            $condactName = $entry->condacts[$condactID+1]->Condact;
                            $terminatorName = $entry->condacts[$condactID]->Condact;
                            $entryText = $entry->Entry;
                            $dumped = ($adventure->classicMode) ? "has been" : "hasn't been";
                            echo "Warning: Condact '$condactName' found after a terminator '$terminatorName' in entry #$humanEntryID ($entryText) at process #$procID . Condact $dumped dumped to DDB file.\n";
                        }
                    }
                    break; // If a terminator condact found, no more condacts in the entry will be ever executed, so we break the loop (normally there won't be more condacts anyway)
                }
            }
            if  (($adventure->classicMode) || (!$terminatorFound)) // If no terminator condact found, ad termination fake condact 0xFF
            {
                writeFF($outputFileHandler); // mark of end of entry
                $currentAddress++;
            }
        }
    }

    addPaddingIfRequired($target, $outputFileHandler, $currentAddress); 
    // Dump the entries tables
    $processesOffsets = array();
    for ($procID=0;$procID<sizeof($adventure->processes);$procID++)
    {
        $process = $adventure->processes[$procID];
        $processesOffsets["$procID"] = $currentAddress;
        for ($entryID=0;$entryID<sizeof($process->entries);$entryID++)
        {
            $entry = $process->entries[$entryID];
            writeByte($outputFileHandler, $entry->Verb);
            writeByte($outputFileHandler, $entry->Noun);
            writeWord($outputFileHandler, $condactsOffsets["${procID}_${entryID}"] , $isLittleEndian); 
            $currentAddress += 4;
        }
        WriteZero($outputFileHandler); // Marca de fin de proceso, doble 00
        $currentAddress++;
        addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
    }

    // Dump the processes table
    addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
    for ($procID=0;$procID<sizeof($adventure->processes);$procID++)
    {
        writeWord ($outputFileHandler, $processesOffsets["$procID"], $isLittleEndian);
        $currentAddress+=2;
    }
}
    

//================================================================= targets ========================================================



function isValidTarget($target)
{
    return ($target == 'HTML') || ($target == 'ZX') || ($target == 'CPC') ||  ($target == 'C64') ||  ($target == 'PCW') ||  ($target == 'MSX') ||  ($target == 'AMIGA') ||  ($target == 'PC') ||  ($target == 'ST') || ($target == 'MSX2') || ($target=='CP4');
}

function isValidSubtarget($target, $subtarget)
{
    if (($target!='MSX2') && ($target!='PC') && ($target!='ZX')) return false;
    if ($target=='MSX2') return ($subtarget == '5_6') || ($subtarget == '5_8') || ($subtarget == '6_6') || ($subtarget == '6_8') || ($subtarget == '7_6') || ($subtarget == '7_8') || ($subtarget == '8_6') || ($subtarget == '8_8') || ($subtarget == '10_6') || ($subtarget == '10_8') || ($subtarget == '12_6') || ($subtarget == '12_8');
    if ($target=='ZX') return ($subtarget == 'PLUS3') || ($subtarget == 'ESXDOS') ||  ($subtarget == 'NEXT') ||  ($subtarget == 'UNO');
// In fact, drb doesn't care about PC subtargets, but just for coherence with drf, we make sure they are correct, despite we will not use them. 
    if ($target=='PC') return ($subtarget == 'VGA256') || ($subtarget == 'VGA') || ($subtarget == 'CGA') ||  ($subtarget == 'EGA') ||  ($subtarget == 'TEXT');
    
}

function getSubMachineIDByTarget($target, $subtarget)
{
    if ($target=='MSX2')
    {
        $subtarget_parts = explode('_',$subtarget);
        $mode = $subtarget_parts[0];
        $charWidth = $subtarget_parts[1];
        $submachineID = $mode - 5; // mode goes from 0 to 7 (for SCREEN 5 to 12)
        if ($charWidth == 8) $submachineID+=128; // Set bit 7
        return $submachineID;
    }
    
    return 95; //Default value for legacy interpreters
}


function getMachineIDByTarget($target, $subtarget)
{
  if (($target=='PC') && ($subtarget=='VGA256')) return 0x0D;  // New target for PCDAAD VGA 256 interpreterº
  if ($target=='PC')    return 0x00; 
  if ($target=='ZX')    return 0x01; 
  if ($target=='C64')   return 0x02; 
  if ($target=='CPC')   return 0x03; 
  if ($target=='MSX')   return 0x04; 
  if ($target=='ST')    return 0x05; 
  if ($target=='AMIGA') return 0x06; 
  if ($target=='PCW')   return 0x07; 
  if ($target=='HTML')  return 0x0D;   // New target for jDAAD html/js interpreter
  if ($target=='CP4')   return 0x0E;    // New target for Commodore Plus/4 interpreter
  if ($target=='MSX2')  return 0x0F;   // New target for @ishwin MSX2 interpreter
  return 0x00; // Default in case of error
};  

function getBaseAddressByTarget($target)
{
  if ($target=='ZX')  return 0x8400; else
  if ($target=='MSX') return 0x0100; else
  if ($target=='CPC') return 0x2880; else
  if ($target=='PCW') return 0x100; else
  if ($target=='CP4') return 0x7080; else
  if ($target=='C64') return 0x3880; else return 0;
};

function isPaddingPlatform($target)
{
    return (($target=='PC') || ($target=='ST') || ($target=='AMIGA') || ($target=='HTML'));
};

function isLittleEndianPlatform($target)
{
    return (($target=='ST') || ($target=='AMIGA'));
};

//================================================================= other ========================================================




function Syntax()
{
    
    echo("SYNTAX: php drb <target> [subtarget] <language> <inputfile> [outputfile] [options]\n\n");
    echo("+ <target>: target machine, should be 'ZX', 'CPC', 'C64', 'CP4', 'MSX', 'MSX2', 'PCW', 'PC', 'ST', 'AMIGA' or 'HTML'. Just to clarify, CP4 stands for Commodore Plus/4\n");
    echo("+ [subtarget]: some targets need to specify a subtarget.\n\tFor MSX2 target: 5_6, 5_8, 6_6, 6_8, 7_6, 7_8, 8_6, 8_8, 10_6, 10_8, 12_6 ad 12_8 (being video mode and character width in pixels).\n\tFor PC target: VGA256, VGA, EGA, CGA and TEXT.\n\tFor ZX target: PLUS3, NEXT; UNO and ESXDOS.\n");
    echo("+ <language>: game language, should be 'EN', 'ES', 'DE', 'FR' or 'PT' (English, Spanish, German, French or Portuguese).\n");
    echo("+ <inputfile>: a json file generated by DRF.\n");
    echo("+ [outputfile] : (optional) name of output file. If absent, same name of json file would be used, with DDB extension.\n");
    echo("+ [options]: one or more of the following:\n");
    echo ("          -v  : verbose output\n");
    echo ("          -ch : Prepend C64 or CP4 header to DDB file (ch stands for 'Commodore header')\n");
    echo ("          -3h : Prepend +3 header to DDB file (3h stands for 'Three header')\n");
    echo ("          -c  : Forced classic mode\n");
    echo ("          -d  : Forced debug mode\n");
    echo ("          -np : Forced no padding on padding platforms\n");
    echo ("          -p  : Forced padding on non padding platforms\n");
    echo "\n";
    echo "Examples:\n";
    echo "php drb zx es game.json\n";
    echo "php drb c64 en game.json mygame.ddb -ch\n";
    echo "php drb pc vga en game.json mygame.ddb -c -v\n";
    echo "\n";
    echo "Text compression will use the built in tokens for each language. In case you want to provide your own tokens just place a file with same name as the JSON file but with .TOK extension in the same folder. To know about the TOK file content format look for the default tokens array in DRB source code.\n";
    echo "\n";
    echo "Please notice forcing no padding in a padding platforma may create incompatibility for smaller CPUs as 68000 or 8088\n";
    exit(1);
}

function Error($msg)
{
 echo("Error: $msg.\n");
 exit(2);
}


function parseOptionalParameters($argv, $nextParam, &$adventure)
{
    $result = '';
    while ($nextParam<sizeof($argv))
    {
        $currentParam = $argv[$nextParam]; $nextParam++;
        if (substr($currentParam,0,1)=='-')
        {
            $currentParam = strtoupper($currentParam);
            switch ($currentParam)
            {
                case "-CH" : $adventure->prependC64Header = true; break;
                case "-3H" : $adventure->prependPlus3Header = true; break;
                case "-V" : $adventure->verbose = true; break;
                case "-C" : $adventure->forcedClassicMode = true; break;
                case "-D" : $adventure->forcedDebugMode = true; break;
                case "-NP" : $adventure->forcedNoPadding = true; break;
                case "-P" : $adventure->forcedPadding = true; break;
                default: Error("$currentParam is not a valid option");
            }
        } 
        else
        {
            if ($result == '') $result = $currentParam; else Error("Bad parameter: $currentParam");
        } 
    }
    return $result; // output file name
}


function generateJDDB($outputFileName)
{
    echo "Converting DDB to JDDB\n";
    $outputFileNameJDDB = strtolower($outputFileName);
    $outputFileNameJDDB = str_replace('.ddb','.jddb', $outputFileNameJDDB);
    $inputHandle = fopen($outputFileName, 'r');
    $outputHandle = fopen($outputFileNameJDDB, "w");

    fputs($outputHandle, "var DDBDATA = [\n");
    $i= 0;
    while (!feof($inputHandle))
    {
        $c = fgetc($inputHandle);
        $val = '0x' . dechex(ord($c));
        fputs($outputHandle,$val);
        if (!feof($inputHandle)) fputs($outputHandle,',');
        $offset = '0x' . str_pad(dechex($i),4,'0',STR_PAD_LEFT);
        if ($i % 10 == 9) fputs($outputHandle, "// $offset\n");
        
        $i++;
    }
    fputs($outputHandle, "\n];");
    fclose($inputHandle);
    fclose($outputHandle);

}

function prependPlus3HeaderToDDB($outputFileName)
{
    
    $fileSize = filesize($outputFileName) + 128; // Final file size wit header
    $inputHandle = fopen($outputFileName, 'r');
    $outputHandle = fopen("prepend.tmp", "w");

    $header = array();
    $header[]= ord('P');
    $header[]= ord('L');
    $header[]= ord('U');
    $header[]= ord('S');
    $header[]= ord('3');
    $header[]= ord('D');
    $header[]= ord('O');
    $header[]= ord('S');
    $header[]= 0x1A; // Soft EOF
    $header[]= 0x01; // Issue
    $header[]= 0x00; // Version
    $header[]= $fileSize & 0XFF;  // Four bytes for file size
    $header[]= ($fileSize & 0xFF00) >> 8;
    $header[]= ($fileSize & 0xFF0000) >> 16;
    $header[]= ($fileSize & 0xFF000000) >> 24;  
    $header[]= 0x03; // Bytes:
    $fileSize -= 128; // Get original size
    $header[]= $fileSize & 0x00FF;  // Two bytes for data size
    $header[]= ($fileSize & 0xFF00) >> 8;
    $header[]= 0x00; // Two Bytes for load addres 0x8400
    $header[]= 0x84; 
    while (sizeof($header)<127) $header[]= 0; // Fillers
    $checksum = 0;
    for ($i=0;$i<127;$i++)  $checksum+=$header[$i];
    $header[]= $checksum & 0xFF; // Checksum
    
    // Dump header
    for ($i=0;$i<128;$i++) fputs($outputHandle, chr($header[$i]), 1);

    // Dump original DDB
    while (!feof($inputHandle))
    {
        $c = fgetc($inputHandle);
        fputs($outputHandle,$c,1);
    }
    fclose($inputHandle);
    fclose($outputHandle);
    unlink($outputFileName);
    rename("prepend.tmp" ,$outputFileName);
}

function prependC64HeaderToDDB($outputFileName, $target)
{
    $inputHandle = fopen($outputFileName, 'r');
    $outputHandle = fopen("prepend.tmp", "w");
    $baseAddress = getBaseAddressByTarget($target);
    fputs($outputHandle, chr($baseAddress & 0xFF), 1);
    fputs($outputHandle, chr(($baseAddress>>8) & 0XFF), 1); 
    while (!feof($inputHandle))
    {
        $c = fgetc($inputHandle);
        fputs($outputHandle,$c,1);
    }
    fclose($inputHandle);
    fclose($outputHandle);
    unlink($outputFileName);
    rename("prepend.tmp" ,$outputFileName);
}


function dataToLet($flagno, $value)
{
    $condact = new stdClass();
    $condact->NumParams = 2;
    $condact->Indirection1 = 0;
    $condact->Param1 = $flagno;
    $condact->Param2 = $value;
    $condact->Condact ='LET';
    $condact->Opcode = LET_OPCODE;
    return $condact;
}

//********************************************** XPLAY *************************************************************** */

function mmlToBeep($note, &$values, $target, $subtarget)
{
    // These targets don't support BEEP condact
    if (($target=='ST') || ($target=='AMIGA') || ($target=='PCW') || ($target=='PCW') || (($target=='PC') && ($subtarget!='VGA256'))) return NULL;

    $condact = NULL;
    $noteIdx = array('C'=>0, 'C#'=>1, 'D'=>2, 'D#'=>3, 'E'=>4,  'F'=>5, 'F#'=>6, 'G'=>7, 'G#'=>8, 'A'=>9, 'A#'=>10, 'B'=>11,
                     'C+'=>1,         'D+'=>3,         'E+'=>5, 'F+'=>6,         'G+'=>8,         'A+'=>10,         'B+'=>12,
                     'C-'=>-1,        'D-'=>1,         'E-'=>3, 'F-'=>4,         'G-'=>6,         'A-'=>8,          'B-'=>10);
    switch ($target)
    {
        case 'ZX': $baseLength = 195; break;
        case 'C64':
        case 'CP4': $baseLength = 205; break;
        case 'PC':  
        case 'HTML':  
	    case 'MSX': 
	    case 'MSX2': $baseLength = 200; break;
        default: $baseLength = 200; // Full note (1 sec)
    }
    

    $cmd = $note[0];
    // ############ Note: [A-G][#:halftone][num:length][.:period]
    if ($cmd>='A' && $cmd<='G') {
        $period = 1;                        //Period increase length
        while (substr($note, -1)=='.') {
            $period *= 1.5;
            $note = substr($note, 0, strlen($note)-1); 
        }
        $length = $values[XPLAY_LENGTH] / $period;
        
        $end = 1;                           //Note index
        if (@$note[1]=='#' || @$note[1]=='-' || @$note[1]=='+') $end++;
        $idx = $noteIdx[substr($note, 0, $end)];
        
        if ($end<strlen($note))             //Length
            $length = intval(substr($note, $end)) / $period;

        $condact = new stdClass();
        if (($target=='MSX') || ($target=='CPC')) $condact->Opcode = XBEEP_OPCODE; else $condact->Opcode = BEEP_OPCODE;
        $condact->NumParams = 2;
        if ($length==0) Error('Wrong length at note ' . $note);
        $condact->Param1 = intval(round($baseLength * (120 / $values[XPLAY_TEMPO]) / $length));
        $condact->Param2 = 24 + $values[XPLAY_OCTAVE]*24 + $idx*2;
        if (($target == 'C64') || ($target == 'CP4')) $condact->Param2 -= 24; // C64/CP4 interpreter pitch it's too high otherwise
        $condact->Indirection1 = 0;
        if (($target=='MSX') ||($target=='CPC')) $condact->Condact = 'XBEEP'; else $condact->Condact = 'BEEP';
    } else
    // ############ Note lenght [1-64] (1=full note, 2=half note, 3=third note, ..., default:4)
    if ($cmd=='L') {
        $values[XPLAY_LENGTH] = intval(substr($note, 1));
    } else
    // ############ Pause [1-64] (1=full pause, 2=half pause, 3=third pause, ...)
    if ($cmd=='R') {
        $period = 1;
        while (substr($note, -1)=='.') {
            $period *= 1.5;
            $note = substr($note, 0, strlen($note)-1);
        }
        $length = $values[XPLAY_LENGTH] / $period;

        if (strlen($note)>1)
            $length = intval(substr($note, 1)) / $period;

        $condact = new stdClass();
        $condact->Opcode = PAUSE_OPCODE;
        $condact->NumParams = 1;
        $condact->Param1 = intval(round($baseLength * (120 / $values[XPLAY_TEMPO]) / $length));
        $condact->Indirection1 = 0;
        $condact->Condact = 'PAUSE';
    } else
    // ############ Note Pitch [0-96]
    if ($cmd=='N') {
        $period = 1;                        //Period increase length
        while (substr($note, -1)=='.') {
            $period *= 1.5;
            $note = substr($note, 0, strlen($note)-1);
        }
        $length = $values[XPLAY_LENGTH] / $period;

        $idx = intval(@substr($note, 1));    //Note index

        $condact = new stdClass();
        if (($target=='MSX') || ($target=='CPC')) $condact->Opcode = XBEEP_OPCODE; else $condact->Opcode = BEEP_OPCODE;
        $condact->NumParams = 2;
        $condact->Param1 = intval(round($baseLength * (120 / $values[XPLAY_TEMPO]) / $length));
        $condact->Param2 = 48 + $idx*2;
        $condact->Indirection1 = 0;
        if (($target=='MSX') ||($target=='CPC')) $condact->Condact = 'XBEEP'; else $condact->Condact = 'BEEP';
    } else
    // ############ Octave [1-8] (default:4)
    if ($cmd=='O') {
        $values[XPLAY_OCTAVE] = intval(substr($note, 1));
    } else
    // ############ Tempo [32-255] (indicates the number of quarter notes per minute, default:120)
    if ($cmd=='T') {
        $values[XPLAY_TEMPO] = (intval(substr($note, 1)) & 255);
    } else
    // ############ Volume [0-15] (default:8)
    if ($cmd=='V') {
        $values[XPLAY_VOLUME] = intval(substr($note, 1)) & 15;  //Volume can be changed using SFX (direct access to PSG registers).
        if ($target=='MSX2') {
            $condact = new stdClass();
            $condact->Opcode = SFX_OPCODE;
            $condact->NumParams = 2;
            $condact->Param1 = $values[XPLAY_VOLUME];
            $condact->Param2 = 8;
        }
    } else
    // ############ Decreases one octave
    if ($cmd=='<') {
        if ($values[XPLAY_OCTAVE]>1) $values[XPLAY_OCTAVE]--;
    } else
    // ############ Increases one octave
    if ($cmd=='>') {
        if ($values[XPLAY_OCTAVE]<8) $values[XPLAY_OCTAVE]++;
    }
    return $condact;
}


//********************************************** MAIN **************************************************************** */


if (intval(date("Y"))>2018) $extra = '-'.date("Y"); else $extra = '';
echo "DAAD Reborn Compiler Backend ".VERSION_HI.".".VERSION_LO. " (C) Uto 2018$extra\n";

if (!function_exists ('utf8_encode')) Error('This software requires php-xml package, please use yum or apt-get to install it.');
// Check params
if (sizeof($argv) < 4) Syntax();
$target = strtoupper($argv[1]);
if (!isValidTarget($target)) Error("Invalid target machine '$target'");
$nextParam =2;
$subtarget = '';
if (($target=='MSX2') || ($target=='PC') || ($target=='ZX'))
{
    $subtarget = strtoupper($argv[$nextParam]);
    $nextParam++;
    if (!isValidSubtarget($target, $subtarget)) Error("Invalid subtarget '$subtarget'");
}
$language = strtoupper($argv[$nextParam]); $nextParam++;
if (($language!='ES') && ($language!='EN') && ($language!='DE') && ($language!='PT') && ($language!='FR')) Error('Invalid target language');
$inputFileName = $argv[$nextParam]; $nextParam++;
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

$tokensFilename = replace_extension($inputFileName, 'tok');
if (!file_exists($tokensFilename)) {
    if (file_exists(strtolower($tokensFilename))) $tokensFilename = strtolower($tokensFilename);
    else {
        $tokensFilename = replace_extension($inputFileName, 'TOK');
        if (file_exists(strtolower($tokensFilename))) $tokensFilename = strtolower($tokensFilename);
    }
}

// Parse optional parameters
$adventure->verbose = false;
$adventure->prependC64Header = false;
$adventure->prependPlus3Header = false;
$adventure->forcedClassicMode = false;
$adventure->forcedDebugMode = false;
$adventure->forcedNoPadding = false;
$adventure->forcedPadding = false;
$outputFileName = parseOptionalParameters($argv, $nextParam, $adventure);
if ($outputFileName=='') $outputFileName = replace_extension($inputFileName, 'DDB');
if ($outputFileName==$inputFileName) Error('Input and output file name cannot be the same');

if (($adventure->forcedPadding) && ($adventure->forcedNoPadding)) Error("You can't force padding and no padding at the same time");

if ($adventure->verbose) echo ("Verbose mode on\n");


// Check parameters
if ( ($target!='C64')&&($target!='CP4') && ($adventure->prependC64Header)) Error('Adding C64 header was requested but target is not C64 or CP4');
if (($target!='ZX')  && ($adventure->prependPlus3Header)) Error('Adding +3DOS header was requested but target is not ZX Spectrum');

// Create the vectors for extens and USRPTR
$adventure->extvec = array();
for ($i=0;$i<13;$i++) $adventure->extvec[$i] = 0;

// Replace special characters over ASCII 127 and escape chars.
replaceEscapeChars($adventure);
checkStrings($adventure);

// Open output file
$outputFileHandler = fopen($outputFileName, "wr");
if (!$outputFileHandler) Error('Can\'t create output file');
    // Check settings in JSON
$adventure->classicMode = $adventure->settings[0]->classic_mode;
if ($adventure->forcedClassicMode) $adventure->classicMode = true;
$adventure->debugMode = $adventure->settings[0]->debug_mode;
if ($adventure->forcedDebugMode) $adventure->debugMode = true;
if (($adventure->debugMode) && ($target!='ZX') && ($target!='CPC'))
{
    echo "Debug mode active, but target is not ZX. Debug mode deactivated.";
    $adventure->debugMode = false;
} 



if ($adventure->verbose) 
{
    if ($adventure->classicMode) echo "Classic mode ON, optimizations disabled.\n"; else echo "Classic mode OFF, optimizations enabled.\n";
    if ($adventure->debugMode) echo "Debug mode ON, generating DEBUG information for ZesarUX debugger.\n";
    if ($adventure->forcedNoPadding) echo "No padding has been forced.\n";
    if ($adventure->forcedPadding) echo "Padding has been forced.\n";
}                            


// **** DUMP DATA TO DDB ****

$baseAddress = getBaseAddressByTarget($target);
$currentAddress = $baseAddress;
$isLittleEndian = isLittleEndianPlatform($target);

if ($adventure->verbose) 
{
    echo  "Endianness is " . ($isLittleEndian? "little":"big")  ." endian";
    echo "\nBase address      [" . prettyFormat($baseAddress) . "]\n";
}

// *********************************************
// 1 ************** WRITE HEADER ***************
// *********************************************

// DAAD version
$b = 2; 
writeByte($outputFileHandler, $b);

// Machine and language
$b = getMachineIDByTarget($target, $subtarget);
$b = $b << 4; // Move machine ID to high nibble
if (($language=='ES') || ($language=='PT')) $b = $b | 1; // Set spanish language  (DE and EN keep English)
writeByte($outputFileHandler, $b);

// This byte stored the null character, usually underscore, as set in /CTL section. That's why all classic  DDBs have same value: 95. For new targets (MSX2) we use that byte for subtarget information.
$b = getSubMachineIDByTarget($target, $subtarget);
writeByte($outputFileHandler, $b);

// Number of object descriptions
$numberOfObjects = sizeof($adventure->object_data);
writeByte($outputFileHandler, $numberOfObjects);
// Number of location descriptions
$numberOfLocations = sizeof($adventure->locations);
writeByte($outputFileHandler, $numberOfLocations);
// Number of user messages
$numberOfMessages = sizeof($adventure->messages);
writeByte($outputFileHandler, $numberOfMessages);
// Number of system messages
$numberOfSysmess = sizeof($adventure->sysmess);
writeByte($outputFileHandler, $numberOfSysmess);
// Number of processes
$numberOfProcesses = sizeof($adventure->processes);
writeByte($outputFileHandler, $numberOfProcesses);
// Fill the rest of the header with zeros, as we don't know yet the offset values. Will comeupdate them later.
writeBlock($outputFileHandler, 26); 
$currentAddress+=34;
// extern - vectors // fill with default values
for($i=0;$i<13;$i++)
    writeWord($outputFileHandler, $adventure->extvec[$i],$isLittleEndian);
$currentAddress+=26;


// *********************************************
// 2 *************** DUMP DATA *****************
// *********************************************

// Replace all escape and spanish chars in the input strings with the ASCII codes used by DAAD interpreters
$compressionData = null;
$bestTokensDetails = null;

if (file_exists($tokensFilename)) 
{
    if ($adventure->verbose) echo "Loading tokens from $tokensFilename.\n";
    $compressionJSON = file_get_contents($tokensFilename);
}
else 
{
    if ($adventure->verbose) echo "Loading default compression tokens for '$language'.\n";
    switch ($language)
    {
        case 'EN': $compressionJSON = $compressionJSON_EN; break;
        case 'PT': $compressionJSON = $compressionJSON_PT; break;
        case 'DE': $compressionJSON = $compressionJSON_DE; break;
        case 'FR': $compressionJSON = $compressionJSON_FR; break;
        default : $compressionJSON = $compressionJSON_ES; break;
    }
}
  
$compressionData = json_decode($compressionJSON);


if (!$compressionData) Error('Invalid tokens file');
$hasTokens = ($compressionData->compression!='none');

for ($j=0;$j<sizeof($compressionData->tokens);$j++)
{
    $token = $compressionData->tokens[$j];
    $token = hex2str($token);
    $compressionData->tokens[$j] = $token;
}

// DumpExterns
generateExterns($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Dump Vocabulary
$vocabularyOffset = $currentAddress;
if ($adventure->verbose) echo "Vocabulary        [" . prettyFormat($vocabularyOffset) . "]\n";
generateVocabulary($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Dump tokens for compression and compress text sections (if possible)
if ($hasTokens) $compressedTextOffset = $currentAddress; else $compressedTextOffset = 0; // If no compression, the header should have 0x0000 in the compression pointer
if ($adventure->verbose) echo "Tokens            [" . prettyFormat($compressedTextOffset) . "]\n";
generateTokens($adventure , $currentAddress, $outputFileHandler, $hasTokens, $compressionData, $textSavings);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Sysmess
generateSTX($adventure, $currentAddress, $outputFileHandler,  $isLittleEndian, $target);
$sysmessLookupOffset = $currentAddress - 2 * sizeof($adventure->sysmess);;
if ($adventure->verbose) echo "Sysmess           [" . prettyFormat($sysmessLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Messages
generateMTX($adventure, $currentAddress, $outputFileHandler,  $isLittleEndian, $target);
$messageLookupOffset = $currentAddress - 2 * sizeof($adventure->messages);
if ($adventure->verbose) echo "Messages          [" . prettyFormat($messageLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Object Texts
generateOTX($adventure, $currentAddress, $outputFileHandler,  $isLittleEndian, $target);
$objectLookupOffset = $currentAddress - 2 * sizeof($adventure->object_data);
if ($adventure->verbose) echo "Object texts      [" . prettyFormat($objectLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Location texts
generateLTX($adventure, $currentAddress, $outputFileHandler,  $isLittleEndian, $target);
$locationLookupOffset =  $currentAddress - 2 * sizeof($adventure->locations);
if ($adventure->verbose) echo "Locations         [" . prettyFormat($locationLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Connections
generateConnections($adventure, $target, $currentAddress, $outputFileHandler,$isLittleEndian);
$connectionsLookupOffset = $currentAddress - 2 * sizeof($adventure->locations) ;
if ($adventure->verbose) echo "Connections       [" . prettyFormat($connectionsLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Object names
$objectNamesOffset = $currentAddress;
if ($adventure->verbose) echo "Object words      [" . prettyFormat($objectNamesOffset) . "]\n";
generateObjectNames($adventure, $currentAddress, $outputFileHandler);
// Weight & standard Attr
$objectWeightAndAttrOffset = $currentAddress;
if ($adventure->verbose) "Weight & std attr [" . prettyFormat($objectWeightAndAttrOffset) . "]\n";
generateObjectWeightAndAttr($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Extra Attr
$objectExtraAttrOffset = $currentAddress;
if ($adventure->verbose) echo "Extra attr        [" . prettyFormat($objectExtraAttrOffset) . "]\n";
generateObjectExtraAttr($adventure, $currentAddress, $outputFileHandler, $isLittleEndian);
// InitiallyAt
$initiallyAtOffset = $currentAddress;
if ($adventure->verbose) echo "Initially at      [" . prettyFormat($initiallyAtOffset) . "]\n";
generateObjectInitially($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Dump XMessagess if avaliable
if (sizeof($adventure->xmessages))
{
    if ((!CheckMaluva($adventure)) && ($target!='MSX2') && !(($target=='PC') && ($subtarget=='VGA256')))  Error('XMESSAGE condact requires Maluva Extension');
    generateXmessages($adventure, $target, $subtarget, $outputFileName);
}

// Dump Processes
generateProcesses($adventure, $currentAddress, $outputFileHandler, $isLittleEndian, $target, $subtarget);
$processListOffset = $currentAddress - sizeof($adventure->processes) * 2;
if ($adventure->verbose) echo "Processes         [" . prettyFormat($processListOffset) . "]\n";


// *********************************************
// 3 **** PATCH HEADER WITH OFFSET VALUES ******
// *********************************************
fseek($outputFileHandler, 8);
// Compressed text position
writeWord($outputFileHandler, $compressedTextOffset, $isLittleEndian); 
// Process list position
writeWord($outputFileHandler, $processListOffset, $isLittleEndian);
// Objects lookup list position
writeWord($outputFileHandler, $objectLookupOffset, $isLittleEndian);
// Locations lookup list position
writeWord($outputFileHandler, $locationLookupOffset, $isLittleEndian);
// User messages lookup list position
writeWord($outputFileHandler, $messageLookupOffset, $isLittleEndian);
// System messages lookup list position
writeWord($outputFileHandler, $sysmessLookupOffset, $isLittleEndian);
// Connections lookup list position
writeWord($outputFileHandler, $connectionsLookupOffset, $isLittleEndian);
// Vocabulary
writeWord($outputFileHandler, $vocabularyOffset, $isLittleEndian);
// Objects "initialy at" list position
writeWord($outputFileHandler, $initiallyAtOffset, $isLittleEndian);
// Object names positions
writeWord($outputFileHandler, $objectNamesOffset, $isLittleEndian);
// Object weight and container/wearable attributes
writeWord($outputFileHandler, $objectWeightAndAttrOffset, $isLittleEndian);
// Extra object attributes 
writeWord($outputFileHandler, $objectExtraAttrOffset, $isLittleEndian);
// File length 
$fileSize = $currentAddress;// - $baseAddress;
writeWord($outputFileHandler, $fileSize, $isLittleEndian);
for($i=0;$i<13;$i++)
    writeWord($outputFileHandler, $adventure->extvec[$i],$isLittleEndian);
fclose($outputFileHandler);
if ($adventure->verbose) summary($adventure);
if ($adventure->verbose) echo "$outputFileName for $target created.\n";
if ($currentAddress>0xFFFF) echo "Warning: DDB file goes " . ($currentAddress - 0xFFFF) . " bytes over the 65535 memory address boundary.\n";
echo "DDB size is " . ($fileSize - $baseAddress) . " bytes.\nDatabase ends at address $currentAddress (". prettyFormat($currentAddress). ")\n";
if ($xMessageSize) echo "XMessages size is $xMessageSize bytes in files of ". $maxFileSizeForXMessages. "K.\n";
if ($textSavings>0) echo "Text compression saving: $textSavings bytes.\n";
if ($adventure->prependC64Header)
{
    if ($adventure->verbose) echo ("Adding Commodore header\n");
    prependC64HeaderToDDB($outputFileName, $target);
} 

if ($adventure->prependPlus3Header)
{
    prependPlus3HeaderToDDB($outputFileName);
    if ($adventure->verbose) echo ("+3DOS header added\n");
} 

if ($target == 'HTML')
{
    generateJDDB($outputFileName);
}


