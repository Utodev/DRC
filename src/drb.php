<?php

// (C) Uto & Jose Manuel Ferrer 2019 - This code is released under the GPL v3 license
// To build the backend of DAAD reborn compiler I have had aid from Jose Manuel Ferrer Ortiz's DAAD database code,
// which he glently provided me. In some cases the code has been even copied and pasted, so that's why he is also
// in the copyright notice above. Thanks Jose Manuel for this invaluable aid.


define('FAKE_DEBUG_CONDACT_CODE',220);
define('FAKE_USERPTR_CONDACT_CODE',256);    

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
            case 'EXTERN': $adventure->extvec[0] = $currentAddress;
            case 'SFX': $adventure->extvec[1] = $currentAddress;
            case 'INT':$adventure->extvec[2] = $currentAddress;
            default: Error("Invalid file type '$fileType' for file $filePath");
        }
        $currentAddress+=filesize($filePath);
    }   
}

//================================================================= tokens ========================================================

$compressionJSON_ES  = '{ "compression": "advanced","tokenDetails": {"tokens": [{"saving":9,"hexToken":"0000"},{"saving":9,"hexToken":"2071756520"},{"saving":9,"hexToken":"6120646520"},{"saving":9,"hexToken":"6f20646520"},{"saving":9,"hexToken":"20756e6120"},{"saving":9,"hexToken":"2064656c20"},{"saving":9,"hexToken":"7320646520"},{"saving":9,"hexToken":"206465206c"},{"saving":9,"hexToken":"20636f6e20"},{"saving":9,"hexToken":"656e746520"},{"saving":9,"hexToken":"20706f7220"},{"saving":9,"hexToken":"2065737415"},{"saving":9,"hexToken":"7469656e65"},{"saving":9,"hexToken":"7320756e20"},{"saving":9,"hexToken":"616e746520"},{"saving":9,"hexToken":"2070617261"},{"saving":9,"hexToken":"206c617320"},{"saving":9,"hexToken":"656e747261"},{"saving":9,"hexToken":"6e20656c20"},{"saving":9,"hexToken":"6520646520"},{"saving":9,"hexToken":"61206c6120"},{"saving":9,"hexToken":"6572696f72"},{"saving":9,"hexToken":"6369186e20"},{"saving":9,"hexToken":"616e646f20"},{"saving":9,"hexToken":"69656e7465"},{"saving":9,"hexToken":"20656c20"},{"saving":9,"hexToken":"206c6120"},{"saving":9,"hexToken":"20646520"},{"saving":9,"hexToken":"20636f6e"},{"saving":9,"hexToken":"20656e20"},{"saving":9,"hexToken":"6c6f7320"},{"saving":9,"hexToken":"61646f20"},{"saving":9,"hexToken":"20736520"},{"saving":9,"hexToken":"65737461"},{"saving":9,"hexToken":"20756e20"},{"saving":9,"hexToken":"6c617320"},{"saving":9,"hexToken":"656e7461"},{"saving":9,"hexToken":"20646573"},{"saving":9,"hexToken":"20616c20"},{"saving":9,"hexToken":"61646120"},{"saving":9,"hexToken":"617320"},{"saving":9,"hexToken":"657320"},{"saving":9,"hexToken":"6f7320"},{"saving":9,"hexToken":"207920"},{"saving":9,"hexToken":"61646f"},{"saving":9,"hexToken":"746520"},{"saving":9,"hexToken":"616461"},{"saving":9,"hexToken":"6c6120"},{"saving":9,"hexToken":"656e74"},{"saving":9,"hexToken":"726573"},{"saving":9,"hexToken":"717565"},{"saving":9,"hexToken":"616e20"},{"saving":9,"hexToken":"6f2070"},{"saving":9,"hexToken":"726563"},{"saving":9,"hexToken":"69646f"},{"saving":9,"hexToken":"732c20"},{"saving":9,"hexToken":"616e74"},{"saving":9,"hexToken":"696e61"},{"saving":9,"hexToken":"696461"},{"saving":9,"hexToken":"6c6172"},{"saving":9,"hexToken":"65726f"},{"saving":9,"hexToken":"6d706c"},{"saving":9,"hexToken":"6120"},{"saving":9,"hexToken":"6f20"},{"saving":9,"hexToken":"6572"},{"saving":9,"hexToken":"6573"},{"saving":9,"hexToken":"6f72"},{"saving":9,"hexToken":"6172"},{"saving":9,"hexToken":"616c"},{"saving":9,"hexToken":"656e"},{"saving":9,"hexToken":"6173"},{"saving":9,"hexToken":"6f73"},{"saving":9,"hexToken":"6520"},{"saving":9,"hexToken":"616e"},{"saving":9,"hexToken":"656c"},{"saving":9,"hexToken":"6f6e"},{"saving":9,"hexToken":"696e"},{"saving":9,"hexToken":"6369"},{"saving":9,"hexToken":"756e"},{"saving":9,"hexToken":"2e20"},{"saving":9,"hexToken":"636f"},{"saving":9,"hexToken":"7265"},{"saving":9,"hexToken":"6469"},{"saving":9,"hexToken":"2c20"},{"saving":9,"hexToken":"7572"},{"saving":9,"hexToken":"7472"},{"saving":9,"hexToken":"6465"},{"saving":9,"hexToken":"7375"},{"saving":9,"hexToken":"6162"},{"saving":9,"hexToken":"6f6c"},{"saving":9,"hexToken":"616d"},{"saving":9,"hexToken":"7374"},{"saving":9,"hexToken":"6375"},{"saving":9,"hexToken":"7320"},{"saving":9,"hexToken":"6163"},{"saving":9,"hexToken":"696c"},{"saving":9,"hexToken":"6772"},{"saving":9,"hexToken":"6164"},{"saving":9,"hexToken":"7465"},{"saving":9,"hexToken":"7920"},{"saving":9,"hexToken":"696d"},{"saving":9,"hexToken":"746f"},{"saving":9,"hexToken":"7565"},{"saving":9,"hexToken":"7069"},{"saving":9,"hexToken":"6775"},{"saving":9,"hexToken":"6368"},{"saving":9,"hexToken":"6361"},{"saving":9,"hexToken":"6c61"},{"saving":9,"hexToken":"6e20"},{"saving":9,"hexToken":"726f"},{"saving":9,"hexToken":"7269"},{"saving":9,"hexToken":"6c6f"},{"saving":9,"hexToken":"6d69"},{"saving":9,"hexToken":"6c20"},{"saving":9,"hexToken":"7469"},{"saving":9,"hexToken":"6f62"},{"saving":9,"hexToken":"6d65"},{"saving":9,"hexToken":"7369"},{"saving":9,"hexToken":"7065"},{"saving":9,"hexToken":"206e"},{"saving":9,"hexToken":"7475"},{"saving":9,"hexToken":"6174"},{"saving":9,"hexToken":"6669"},{"saving":9,"hexToken":"646f"},{"saving":9,"hexToken":"656d"},{"saving":9,"hexToken":"6179"},{"saving":9,"hexToken":"222e"},{"saving":9,"hexToken":"6c6c"}], "saving": 99999}}';
$compressionJSON_EN  = '{ "compression": "advanced","tokenDetails": {"tokens": [{"saving":9,"hexToken":"0000"},{"saving":9,"hexToken":"2074686520"},{"saving":9,"hexToken":"20796f7520"},{"saving":9,"hexToken":"2061726520"},{"saving":9,"hexToken":"696e6720"},{"saving":9,"hexToken":"20746f20"},{"saving":9,"hexToken":"20616e64"},{"saving":9,"hexToken":"20697320"},{"saving":9,"hexToken":"596f7520"},{"saving":9,"hexToken":"616e6420"},{"saving":9,"hexToken":"54686520"},{"saving":9,"hexToken":"6e277420"},{"saving":9,"hexToken":"206f6620"},{"saving":9,"hexToken":"20796f75"},{"saving":9,"hexToken":"696e67"},{"saving":9,"hexToken":"656420"},{"saving":9,"hexToken":"206120"},{"saving":9,"hexToken":"206f70"},{"saving":9,"hexToken":"697468"},{"saving":9,"hexToken":"6f7574"},{"saving":9,"hexToken":"656e74"},{"saving":9,"hexToken":"20746f"},{"saving":9,"hexToken":"20696e"},{"saving":9,"hexToken":"616c6c"},{"saving":9,"hexToken":"207468"},{"saving":9,"hexToken":"206974"},{"saving":9,"hexToken":"746572"},{"saving":9,"hexToken":"617665"},{"saving":9,"hexToken":"206265"},{"saving":9,"hexToken":"766572"},{"saving":9,"hexToken":"686572"},{"saving":9,"hexToken":"616e64"},{"saving":9,"hexToken":"656172"},{"saving":9,"hexToken":"596f75"},{"saving":9,"hexToken":"206f6e"},{"saving":9,"hexToken":"656e20"},{"saving":9,"hexToken":"6f7365"},{"saving":9,"hexToken":"6e6f"},{"saving":9,"hexToken":"6963"},{"saving":9,"hexToken":"6170"},{"saving":9,"hexToken":"2062"},{"saving":9,"hexToken":"6768"},{"saving":9,"hexToken":"2020"},{"saving":9,"hexToken":"6164"},{"saving":9,"hexToken":"6973"},{"saving":9,"hexToken":"2063"},{"saving":9,"hexToken":"6972"},{"saving":9,"hexToken":"6179"},{"saving":9,"hexToken":"7572"},{"saving":9,"hexToken":"756e"},{"saving":9,"hexToken":"6f6f"},{"saving":9,"hexToken":"2064"},{"saving":9,"hexToken":"6c6f"},{"saving":9,"hexToken":"726f"},{"saving":9,"hexToken":"6163"},{"saving":9,"hexToken":"7365"},{"saving":9,"hexToken":"7269"},{"saving":9,"hexToken":"6c69"},{"saving":9,"hexToken":"7469"},{"saving":9,"hexToken":"6f6d"},{"saving":9,"hexToken":"626c"},{"saving":9,"hexToken":"636b"},{"saving":9,"hexToken":"4920"},{"saving":9,"hexToken":"6564"},{"saving":9,"hexToken":"6565"},{"saving":9,"hexToken":"2066"},{"saving":9,"hexToken":"6861"},{"saving":9,"hexToken":"7065"},{"saving":9,"hexToken":"6520"},{"saving":9,"hexToken":"7420"},{"saving":9,"hexToken":"696e"},{"saving":9,"hexToken":"7320"},{"saving":9,"hexToken":"7468"},{"saving":9,"hexToken":"2c20"},{"saving":9,"hexToken":"6572"},{"saving":9,"hexToken":"6420"},{"saving":9,"hexToken":"6f6e"},{"saving":9,"hexToken":"746f"},{"saving":9,"hexToken":"616e"},{"saving":9,"hexToken":"6172"},{"saving":9,"hexToken":"656e"},{"saving":9,"hexToken":"6f75"},{"saving":9,"hexToken":"6f72"},{"saving":9,"hexToken":"7374"},{"saving":9,"hexToken":"2e20"},{"saving":9,"hexToken":"6f77"},{"saving":9,"hexToken":"6c65"},{"saving":9,"hexToken":"6174"},{"saving":9,"hexToken":"616c"},{"saving":9,"hexToken":"7265"},{"saving":9,"hexToken":"7920"},{"saving":9,"hexToken":"6368"},{"saving":9,"hexToken":"616d"},{"saving":9,"hexToken":"656c"},{"saving":9,"hexToken":"2077"},{"saving":9,"hexToken":"6173"},{"saving":9,"hexToken":"6573"},{"saving":9,"hexToken":"6974"},{"saving":9,"hexToken":"2073"},{"saving":9,"hexToken":"6c6c"},{"saving":9,"hexToken":"646f"},{"saving":9,"hexToken":"6f70"},{"saving":9,"hexToken":"7368"},{"saving":9,"hexToken":"6d65"},{"saving":9,"hexToken":"6865"},{"saving":9,"hexToken":"626f"},{"saving":9,"hexToken":"6869"},{"saving":9,"hexToken":"6361"},{"saving":9,"hexToken":"706c"},{"saving":9,"hexToken":"696c"},{"saving":9,"hexToken":"636c"},{"saving":9,"hexToken":"2061"},{"saving":9,"hexToken":"6f66"},{"saving":9,"hexToken":"2068"},{"saving":9,"hexToken":"7474"},{"saving":9,"hexToken":"6d6f"},{"saving":9,"hexToken":"6b65"},{"saving":9,"hexToken":"7665"},{"saving":9,"hexToken":"736f"},{"saving":9,"hexToken":"652e"},{"saving":9,"hexToken":"642e"},{"saving":9,"hexToken":"742e"},{"saving":9,"hexToken":"7669"},{"saving":9,"hexToken":"6c79"},{"saving":9,"hexToken":"6964"},{"saving":9,"hexToken":"7363"},{"saving":9,"hexToken":"2070"},{"saving":9,"hexToken":"656d"},{"saving":9,"hexToken":"7220"}], "saving": 1000}}';

function extecho($message)
{
    $str = '';
    for($n=0;$n<strlen($message);$n++)
        if ((ord($message[$n])>127) || (ord($message[$n])<32)) $str .= ( '#('. ord($message[$n]) .')'); else $str .= ($message[$n]);

    return $str;

}

function generateTokens(&$adventure, &$currentAddress, $outputFileHandler, $hasTokens, $compressionData, &$savings)
{
    if (!$hasTokens) 
    {
        writeZero($outputFileHandler);
        $currentAddress++;
    }
    else
    {
        // Compress the message tables
        $totalSaving = 0;
        $usedTokens = array();
        $compressableTables = getCompressableTables($compressionData->compression,$adventure);
        for ($j=0;$j<sizeof($compressionData->tokenDetails->tokens);$j++)
        {
            $token = $compressionData->tokenDetails->tokens[$j];
            foreach ($compressableTables as $compressableTable)
                for ($i=0;$i<sizeof($compressableTable);$i++)
                {
                    $message = $compressableTable[$i]->Text;
                    $parts = explode($token->token, $message);
                    if (sizeof($parts)>1) $usedTokens[] = $j;
                    $newMessage = implode(chr($j+127), $parts);
                    if ($message!=$newMessage) extecho("$message   ==> $newMessage\n");
                    $totalSaving += (strlen($message) - strlen($newMessage));
                    $compressableTable[$i]->Text = $newMessage;;
                }
        }
        // Dump tokens to file
        for ($j=0;$j<sizeof($compressionData->tokenDetails->tokens);$j++)
        {
            $token = $compressionData->tokenDetails->tokens[$j];
            $tokenStr = $token->token;
            $tokenLength = strlen($tokenStr);
            // If a given token was not used at all cause the token was not included in any text, we dump a fake token with just one character (won't ever be used anyway) to save space
            if (!in_array($j, $usedTokens) && (!$adventure->classicMode))  $tokenLength=1;
            
            for ($i=0;$i<$tokenLength;$i++) 
            {
                $shift = ($i == $tokenLength-1) ? 128 : 0;
                $c = substr($tokenStr, $i, 1);
                writeByte($outputFileHandler, ord($c) + $shift);
                $currentAddress++;
            }
            $totalSaving -= $tokenLength;
        }
        $savings = $totalSaving;
        
    }
}
//================================================================= common ========================================================

define ('OFUSCATE_VALUE', 0xFF);

class daadToChr
{
var $conversions = array('ª', '¡', '¿', '«', '»', 'á', 'é', 'í', 'ó', 'ú', 'ñ', 'Ñ', 'ç', 'Ç', 'ü', 'Ü');
}
define('VERSION_HI',0);
define('VERSION_LO',5);


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
    if (isPaddingPlatform($target) && (($currentAddress % 2)==1)) 
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
     case 'advanced':  $compressableTables = array($adventure->locations, $adventure->messages, $adventure->sysmess); break;
    }
    return $compressableTables;
}




//================================================================= messages  ========================================================

function replaceChars($str)
{
    // replace special spanish characters
    $daad_to_chr = new daadToChr();
    for($i=0;$i<sizeof($daad_to_chr->conversions);$i++)
    {
        $spanishChar = $daad_to_chr->conversions[$i];
        if (strpos($str, $spanishChar)!==false)
        {
            $to = chr($i+16);
            $str = str_replace($spanishChar, $to, $str);
        } 
    }
    // replace escape sequences
    $replacements = array('#g'=>0x0e, '#t'=>0x0f,'#b'=>0x0b, '#s'=>0x20, '#f'=>0x7f, '#k'=>0x0c, '#n'=>0x0D, '#r'=>0x0D);
    // Add #A to #P to replacements array
    for ($i=ord('A');$i<=ord('P');$i++) $replacements["#" . chr($i)]= $i + 0x10 - ord('A');

    $oldSequenceWarnRFing = false;
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
    $tables = array($adventure->messages, $adventure->sysmess, $adventure->locations, $adventure->objects);
    foreach ($tables as $table)
     foreach($table as $message)
     {
        $message->originalText = $message->Text;
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



function generateMessages($messageList, &$currentAddress, $outputFileHandler,  $isLittleEndian)
{

    $messageOffsets = array();
    for ($messageID=0;$messageID<sizeof($messageList);$messageID++)
    {
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
    for ($messageID=0;$messageID<sizeof($messageList);$messageID++)
    {
        writeWord($outputFileHandler, $messageOffsets[$messageID] , $isLittleEndian);
        $currentAddress += 2;
    }


    
    
}


function generateMTX($adventure, &$currentAddress, $outputFileHandler,  $isLittleEndian)
{
    generateMessages($adventure->messages, $currentAddress, $outputFileHandler,   $isLittleEndian);
}

function generateSTX($adventure, &$currentAddress, $outputFileHandler,  $isLittleEndian)
{
    generateMessages($adventure->sysmess, $currentAddress, $outputFileHandler,  $isLittleEndian);
}

function generateLTX($adventure, &$currentAddress, $outputFileHandler,  $isLittleEndian)
{
    generateMessages($adventure->locations, $currentAddress, $outputFileHandler,   $isLittleEndian);
}

function generateOTX($adventure, &$currentAddress, $outputFileHandler, $isLittleEndian)
{
    generateMessages($adventure->objects, $currentAddress, $outputFileHandler, $isLittleEndian); 
}

//================================================================= connections ========================================================


function generateConnections($adventure, &$currentAddress, $outputFileHandler, $isLittleEndian)
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
    for ($locID=0;$locID<sizeof($adventure->locations);$locID++)
    {
        writeWord($outputFileHandler, $connectionsOffset[$locID], $isLittleEndian);
        $currentAddress+=2;
    }
    
}

//================================================================= vocabulary ========================================================




function generateVocabulary($adventure, &$currentAddress, $outputFileHandler)
{
    
  //         16        18        20         22      24        26        28         30
    //array('ª', '¡', '¿', '«', '»', 'á', 'é', 'í', 'ó', 'ú', 'ñ', 'Ñ', 'ç', 'Ç', 'ü', 'Ü');
    $daad_to_chr = new daadToChr();
    foreach ($adventure->vocabulary as $word)
    {
        // Clean the string from unexpected, unwanted, UFT-8 characters which are valid for vocabualary. Convert to ISO-8859-1
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
            else if (ord($tempWord[$i])==195)  // Look for UTF enconded characters
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
                    default: echo "Warning: Found invalid 195-" . ord($tempWord[$i]) . " UTF encoding string in $tempWord.\n";
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
        if ($object->Container) $b = $b | 0x40;
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
        $hash .= ($opcode);
        if ($condact->NumParams>0)
        {
            $param1 = $condact->Param1;
            $hash .= ($param1);
            if ($condact->NumParams>1) 
            {
                $param2 = $condact->Param2;
                $hash .= ($param2);
            }
        }
    }
    return $hash;
}

function generateProcesses($adventure, &$currentAddress, $outputFileHandler, $isLittleEndian)
{     
    $terminatorOpcodes = array(22, 23,103, 116,117,108);  //DONE/OK/NOTDONE/SKIP/RESTART/REDO
    $condactsOffsets = array();
    // PASS ONE, GENERATE HASHES UNLESS CLASSICMODE IS ON
    $condactsHash = array();  
    if (!$adventure->classicMode)
    {
        for ($procID=0;$procID<sizeof($adventure->processes);$procID++)
        {
            $process = $adventure->processes[$procID];
            if ($adventure->verbose) echo "Process $procID has " . sizeof($process->entries) . " entries\n";
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
                        $condactsOffsets["${procID}_${entryID}"] = $condactsHash["$hash"]->offset; 
                        continue; // Avoid generating this entry condacts, as there is one which can be re-used
                    }
                    else 
                    {
                        $condactsHash["$hash"]->offset = $currentAddress;
                    }
                }
            }

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

                if (!$adventure->classicMode)
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
                                if ($param < 0) $param= 256 + $param;  // For SKIP
                                writeByte($outputFileHandler, $param); 
                                break;

                        case 1: $param = $condact->Param2;
                                writeByte($outputFileHandler, $param); 
                                break;
                    }
                }
                $currentAddress+= $condact->NumParams;
                if (!$adventure->classicMode) if (in_array($opcode, $terminatorOpcodes)) 
                {
                    $terminatorFound = true;
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
    }

    // Dump the processes table
    for ($procID=0;$procID<sizeof($adventure->processes);$procID++)
    {
        writeWord ($outputFileHandler, $processesOffsets["$procID"], $isLittleEndian);
        $currentAddress+=2;
    }
}
    

//================================================================= targets ========================================================



function isValidTarget($target)
{
    return ($target == 'ZX') || ($target == 'CPC') ||  ($target == 'C64') ||  ($target == 'PCW') ||  ($target == 'MSX') ||  ($target == 'AMIGA') ||  ($target == 'PC') ||  ($target == 'ST') || ($target == 'MSX2');
}

function isValidSubtarget($target, $subtarget)
{
    if (($target!='MSX2') && ($target!='PC')) return false;
    if ($target=='MSX2') return ($subtarget == '5_6') || ($subtarget == '5_8') ||  ($subtarget == '6_6') ||  ($subtarget == '6_8') ||  ($subtarget == '7_6') ||  ($subtarget == '7_8') ||  ($target == '8_6') ||  ($target == '8_8');
    // In fact, drb doesn't care about PC subtargets, but just for coherence with drf, we make sure they are correct, despite we will not use them
    if ($target=='PC') return ($subtarget == 'VGA') || ($subtarget == 'CGA') ||  ($subtarget == 'EGA') ||  ($subtarget == 'TEXT');

}

function getSubMachineIDByTarget($target, $subtarget)
{
    if ($target=='MSX2')
    {
        $subtarget_parts = explode('_',$subtarget);
        $mode = $subtarget_parts[0];
        $charWidth = $subtarget_parts[1];
        $submachineID = $mode - 5; // mode goes from 0 to 3 (for 5 to 8)
        if ($charWidth == 8) $submachineID+=128; // Set bit 7
        return $submachineID;
    }
    return 95; //Default value for legacy interpreters
}


function getMachineIDByTarget($target)
{
  if ($target=='PC')    return 0x00; else
  if ($target=='ZX')    return 0x01; else
  if ($target=='C64')   return 0x02; else
  if ($target=='CPC')   return 0x03; else
  if ($target=='MSX')   return 0x04; else
  if ($target=='ST')    return 0x05; else
  if ($target=='AMIGA') return 0x06; else
  if ($target=='PCW')   return 0x07; else
  if ($target=='MSX2')  return 0x0F;        // New target for @ishwin interpreter
};  

function getBaseAddressByTarget($target)
{
  if ($target=='ZX')  return 0x8400; else
  if ($target=='MSX') return 0x0100; else
  if ($target=='CPC') return 0x2880; else
  if ($target=='PCW') return 0x100; else
  if ($target=='C64') return 0x3880; else return 0;
};

function isPaddingPlatform($target)
{
    return (($target=='PC') || ($target=='ST') || ($target=='AMIGA'));
};

function isLittleEndianPlatform($target)
{
    return (($target=='ST') || ($target=='AMIGA'));
};

//================================================================= other ========================================================




function Syntax()
{
    
    echo("SYNTAX: php drb <target> [subtarget] <language> <inputfile> [outputfile]\n\n");
    echo("<target>: target machine, should be 'ZX', 'CPC', 'C64', 'MSX', 'MSX2', 'PCW', 'PC', 'ST' or 'AMIGA'.\n");
    echo ("[subtarget]: some targets need to specify a subtarget. MSX2 target have the following: 5_6, 5_8, 6_6, 6_8, 7_7  and 7_8 (being the video mode and the character with in pixels), and PC has VGA, EGA, CGA and TEXT as avaliable options.");
    echo("<language>: game language, should be 'EN' or 'ES' (english or spanish).\n\n");
    echo("<inputfile>: a json file generated by DRF.\n");
    echo("[outputfile] : (optional) name of output file. If absent, same name of json file would be used, with DDB extension.\n\n\n");
    echo "Examples:\n";
    echo "php drb zx es game.json\n";
    exit(1);
}

function Error($msg)
{
 echo("Error: $msg.\n");
 exit(2);
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
if (($target=='MSX2') || ($target=='PC'))
{
    $subtarget = strtoupper($argv[$nextParam]);
    $nextParam++;
    if (!isValidSubtarget($target, $subtarget)) Error("Invalid subtarget '$subtarget'");
}
$language = strtoupper($argv[$nextParam]); $nextParam++;
if (($language!='ES') && ($language!='EN')) Error('Invalid target language');
$inputFileName = $argv[$nextParam]; $nextParam++;
if (sizeof($argv) > $nextParam) $outputFileName = $argv[$nextParam]; else $outputFileName = replace_extension($inputFileName, 'DDB');
if ($outputFileName==$inputFileName) Error('Input and output file name cannot be the same');
if (!file_exists($inputFileName)) Error('File not found');
$tokensFilename = replace_extension($inputFileName, 'TOK');

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

// Create the vectors for extens and USRPTR
$adventure->extvec = array();
for ($i=0;$i<13;$i++) $adventure->extvec[$i] = 0;

// Replace characters over ASCII 127 with those below. Replace also escape chars.
replaceEscapeChars($adventure);
checkStrings($adventure);

// Open output file
$outputFileHandler = fopen($outputFileName, "wr");
if (!$outputFileHandler) Error('Can\'t create output file');
    // Check settings in JSON
$adventure->classicMode = $adventure->settings[0]->classic_mode;
$adventure->debugMode = $adventure->settings[0]->debug_mode;
if (($adventure->debugMode) && ($target!='ZX') && ($target!='CPC'))
{
    echo "Debug mode active, but target is not ZX. Debug mode deactivated.";
    $adventure->debugMode = false;
} 
if ($adventure->classicMode) echo "Classic mode ON, optimizations disabled.\n"; else echo "Classic mode OFF, optimizations enabled.\n";
if ($adventure->debugMode) echo "Debug mode ON, generating DEBUG information for ZesarUX debugger.\n";
                            
// Just for development, set to true for verbose info
$adventure->verbose = false;


// **** DUMP DATA TO DDB ****

$baseAddress = getBaseAddressByTarget($target);
$currentAddress = $baseAddress;
$isLittleEndian = isLittleEndianPlatform($target);

if ($adventure->verbose) 
{
    echo $isLittleEndian? "Little endian":"Big endian";
    echo "\nBase address      [" . prettyFormat($baseAddress) . "]\n";
}

// *********************************************
// 1 ************** WRITE HEADER ***************
// *********************************************

// DAAD version
$b = 2; 
writeByte($outputFileHandler, $b);

// Machine and language
$b = getMachineIDByTarget($target);
$b = $b << 4; // Move machine ID to high nibble
if ($language=='ES') $b = $b | 1; // Set spanish language   
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
// extern - vectors
for($i=0;$i<13;$i++)
    writeWord($outputFileHandler, $adventure->extvec[$i],$isLittleEndian);
$currentAddress+=26;


// *********************************************
// 2 *************** DUMP DATA *****************
// *********************************************

// Replace all escape and spanish chars in the input strings with the ASCII codes used by DAAD interpreters
$compressionData = null;
$bestTokensDetails = null;

if (file_exists(strtolower($tokensFilename))) $tokensFilename = strtolower($tokensFilename);
if (file_exists($tokensFilename)) 
{
    if ($adventure->verbose) echo "Loading $tokensFilename.\n";
    $compressionJSON = file_get_contents($tokensFilename);
}
else 
{
    if ($adventure->verbose) echo "Loading default compression tokens for '$language'.\n";
    switch ($language)
    {
        case 'EN': $compressionJSON = $compressionJSON_EN; break;
        default : $compressionJSON = $compressionJSON_ES; break;
    }
}
  
$compressionData = json_decode($compressionJSON);


if (!$compressionData) Error('Invalid tokens file');
$hasTokens = ($compressionData->compression!='none');

for ($j=0;$j<sizeof($compressionData->tokenDetails->tokens);$j++)
{
    $token = $compressionData->tokenDetails->tokens[$j]->hexToken;
    $token = hex2str($token);
    $compressionData->tokenDetails->tokens[$j]->token = $token;
}

// DumpExterns
generateExterns($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Dump Vocabulary
$vocabularyOffset = $currentAddress;
echo "Vocabulary        [" . prettyFormat($vocabularyOffset) . "]\n";
generateVocabulary($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Dump tokens for compression and compress text sections (if possible)
if ($hasTokens) $compressedTextOffset = $currentAddress; else $compressedTextOffset = 0; // If no compression, the header should have 0x0000 in the compression pointer
echo "Tokens            [" . prettyFormat($compressedTextOffset) . "]\n";
generateTokens($adventure , $currentAddress, $outputFileHandler, $hasTokens, $compressionData, $textSavings);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Sysmess
generateSTX($adventure, $currentAddress, $outputFileHandler,  $isLittleEndian);
$sysmessLookupOffset = $currentAddress - 2 * sizeof($adventure->sysmess);;
echo "Sysmess           [" . prettyFormat($sysmessLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Messages
generateMTX($adventure, $currentAddress, $outputFileHandler,  $isLittleEndian);
$messageLookupOffset = $currentAddress - 2 * sizeof($adventure->messages);
echo "Messages          [" . prettyFormat($messageLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Object Texts
generateOTX($adventure, $currentAddress, $outputFileHandler,  $isLittleEndian);
$objectLookupOffset = $currentAddress - 2 * sizeof($adventure->object_data);
echo "Object texts      [" . prettyFormat($objectLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Location texts
generateLTX($adventure, $currentAddress, $outputFileHandler,  $isLittleEndian);
$locationLookupOffset =  $currentAddress - 2 * sizeof($adventure->locations);
echo "Locations         [" . prettyFormat($locationLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Connections
generateConnections($adventure, $currentAddress, $outputFileHandler,$isLittleEndian);
$connectionsLookupOffset = $currentAddress - 2 * sizeof($adventure->locations) ;
echo "Connections       [" . prettyFormat($connectionsLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Object names
$objectNamesOffset = $currentAddress;
echo "Object words      [" . prettyFormat($objectNamesOffset) . "]\n";
generateObjectNames($adventure, $currentAddress, $outputFileHandler);
// Weight & standard Attr
$objectWeightAndAttrOffset = $currentAddress;
"Weight & std attr [" . prettyFormat($objectWeightAndAttrOffset) . "]\n";
generateObjectWeightAndAttr($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Extra Attr
$objectExtraAttrOffset = $currentAddress;
echo "Extra attr        [" . prettyFormat($objectExtraAttrOffset) . "]\n";
generateObjectExtraAttr($adventure, $currentAddress, $outputFileHandler, $isLittleEndian);
// InitiallyAt
$initiallyAtOffset = $currentAddress;
echo "Initially at      [" . prettyFormat($initiallyAtOffset) . "]\n";
generateObjectInitially($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Dump Processes
generateProcesses($adventure, $currentAddress, $outputFileHandler, $isLittleEndian);
$processListOffset = $currentAddress - sizeof($adventure->processes) * 2;
echo "Processes         [" . prettyFormat($processListOffset) . "]\n";


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
$fileSize = $currentAddress;
writeWord($outputFileHandler, $fileSize, $isLittleEndian);
fclose($outputFileHandler);
echo "$outputFileName for $target created.\n";
if ($currentAddress>0xFFFF) echo "Warning: DDB file goes over the 65535 memory address boundary.\n";
echo "DDB size is " . ($fileSize - $baseAddress) . " bytes.\nDatabase ends at address $currentAddress (". prettyFormat($currentAddress). ")\n";
if ($textSavings>0) echo "Text compression saving: $textSavings bytes.\n";



 

