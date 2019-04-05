<?php

// (C) Uto & Jose Manuel Ferrer 2019 - This code is released under the GPL v3 license
// To build the backend of DAAD reborn compiler I have had aid from Jos? Manuel Ferrer Ortiz's DAAD database code,
// which he glently provided me. In some cases the code has been even copied and pasted, so that's why he is also
// in the copyright notice above. Thanks Jose Manuel for this invaluable aid.


//================================================================= filewrite ========================================================

// Writes a byte value to file
function writeByte($handle, $byte)
{
    fputs($handle, chr($byte), 1);
}


// Writes a word value to file, will store as little endian or big endian depending on parameter
function writeWord($handle, $word, $littleEndian = false)
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





//================================================================= tokens ========================================================

function generateTokens($adventure, &$currentAddress, $outputFileHandler, $compression)
{

    if ($compression == 'none') 
    {
        $b = 0;
        writeByte($outputFileHandler, $b);
        $currentAddress++;
    }
    else
    {
        //TODO
    }
}
//================================================================= common ========================================================

define ('OFUSCATE_VALUE', 0xFF);
$daad_a_chr = array('ª', '¡', '¿', '«', '»', 'á', 'é', 'í', 'ó', 'ú', 'ñ', 'Ñ', 'ç', 'Ç', 'ü', 'Ü');
$version_hi = 0;
$version_lo = 1;


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
    if (isLittleEndianPlatform($target) && (($currentAddress % 2)==1)) 
    {
        writeZero($outputFileHandler); // Fill with one byte for padding
        $currentAddress++;       
    }
}

//================================================================= messages  ========================================================


function generateMessages($messageList, &$currentAddress, $outputFileHandler, $compression, $isLittleEndian)
{
    // Write the messages table
    $currentAddress += sizeof($messageList) * 2; 
    foreach ($messageList as $message)
    {
        writeWord($outputFileHandler, $currentAddress, $isLittleEndian);
        $currentAddress += strlen($message->Text) + 1; // +1 cause at the end of each message, there is \n mark
    }


    foreach ($messageList as $message)
    {
        for ($i=0;$i<strlen($message->Text);$i++)
         writeByte($outputFileHandler, ord($message->Text[$i]) ^ OFUSCATE_VALUE);
        writeByte($outputFileHandler,ord("\n") ^ OFUSCATE_VALUE ); //mark of end of string
        
    }
    
}


function generateMTX($adventure, &$currentAddress, $outputFileHandler, $compression, $isLittleEndian)
{
    generateMessages($adventure->messages, $currentAddress, $outputFileHandler,  $compression, $isLittleEndian);
}

function generateSTX($adventure, &$currentAddress, $outputFileHandler, $compression, $isLittleEndian)
{
    generateMessages($adventure->sysmess, $currentAddress, $outputFileHandler,  $compression, $isLittleEndian);
}

function generateLTX($adventure, &$currentAddress, $outputFileHandler, $compression, $isLittleEndian)
{
    generateMessages($adventure->locations, $currentAddress, $outputFileHandler,  $compression, $isLittleEndian);
}

function generateOTX($adventure, &$currentAddress, $outputFileHandler, $compression, $isLittleEndian)
{
    generateMessages($adventure->objects, $currentAddress, $outputFileHandler,  'none', $isLittleEndian); // Never compress object texts, no matter what is selected
}

//================================================================= connections ========================================================


function generateConnections($adventure, &$currentAddress, $outputFileHandler, $isLittleEndian)
{

    $connectionsTable = array();
    foreach($adventure->connections as $connection)
    {
        $FromLoc = $connection->FromLoc;
        $ToLoc = $connection->ToLoc;
        $Direction = $connection->Direction;
        if (array_key_exists($FromLoc, $connectionsTable)) $connectionsTable[$FromLoc][]=array($Direction,$ToLoc); else $connectionsTable[$FromLoc]=array(array($Direction,$ToLoc));
    }


    // Write the  table
    $currentAddress += (sizeof($adventure->locations) * 2); 
    $saveConnectionsStart = $currentAddress;
    for ($loc=0;$loc<sizeof($adventure->locations);$loc++)
    {
        writeWord($outputFileHandler, $currentAddress, $isLittleEndian);
        if (array_key_exists($loc, $connectionsTable)) $size = sizeof($connectionsTable[$loc]) * 2; else $size = 0;
        $currentAddress += ($size + 1);  // +1 cause after the connections for a location a 0xFF is stored
    }
    $currentAddress = $saveConnectionsStart;

    for ($loc=0;$loc<sizeof($adventure->locations);$loc++)
    {
        if (array_key_exists($loc, $connectionsTable))   
        {
            $connections = $connectionsTable[$loc];
            foreach ($connections as $connection)
            {
                    writeByte($outputFileHandler, $connection[0]);
                    writeByte($outputFileHandler, $connection[1]);
                    $currentAddress +=2;
            }
        }
        writeFF($outputFileHandler); //mark of end of connections
        $currentAddress ++;
    }
    
}

//================================================================= vocabulary ========================================================




function generateVocabulary($adventure, &$currentAddress, $outputFileHandler)
{
    foreach ($adventure->vocabulary as $word)
    {
        $vocWord = substr(str_pad($word->VocWord,5),0,5);
        for ($i=0;$i<5;$i++)
        {
            $character = $vocWord[$i];
            if (ord($character)>127) $character = array_search($character, $daad_a_chr) + 16;  else  $character = ord(strtoupper($character));
            $character = $character ^ OFUSCATE_VALUE;
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
    }
    $currentAddress+=(sizeof($adventure->object_data)*2);
}

function generateObjectInitially($adventure, &$currentAddress, $outputFileHandler)
{
    foreach($adventure->object_data as $object)
     writeByte($outputFileHandler, $object->InitialyAt);
    $currentAddress+=sizeof($adventure->object_data);
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
    }
    $currentAddress+=sizeof($adventure->object_data);

}

function generateObjectExtraAttr($adventure, &$currentAddress, $outputFileHandler, $isLittleEndian)
{
    foreach($adventure->object_data as $object)
     writeWord($outputFileHandler, $object->Flags, $isLittleEndian);
     $currentAddress+=(sizeof($adventure->object_data)*2);

}
//================================================================= processes ========================================================




function getEntryLength($entry)
{
    foreach ($entry->condacts as $condact)
        $length+=($condact->NumParams + 1); // params + one more for the opcode
    $length++; // last byte 0xFF at the en of each entry
    return $length;
}
            


function generateProcesses($adventure, &$currentAddress, $outputFileHandler, $isLittleEndian)
{
    // Write the pointers to processes table
    $currentAddress += sizeof($adventure->processes) * 2; // First process will start just after the processes table
    $firstProcessOffset = $currentAddress;
    foreach ($adventure->processes as $process)
    {
        writeWord($outputFileHandler, $currentAddress, $isLittleEndian);
        $currentAddress+= sizeof($process->entries)* 4 + 1;
    }

    $currentAddress = $firstProcessOffset;
    // calculate how much will require the entries pointer table
    foreach ($adventure->processes as $process)
    {
        foreach ($process->entries as $entry) $currentAddress += 4; // 4 bytes per entry
        $currentAddress++; // 1 byte per end of process
    }

    // $currentAddress is now pointing to the place where condacts wil really be
    // Let's create the entries pointers table
    $preserveCurrentAddress = $currentAddress;
    foreach ($adventure->processes as $process)
    {
        foreach ($process->entries as $entry)
        {
            writeByte($outputFileHandler, $entry->Verb);
            writeByte($outputFileHandler, $entry->Noun);
            writeWord($outputFileHandler, $currentAddress , $isLittleEndian); 
            $currentAddress += getEntryLength($entry);
        }
        writeZero($outputFileHandler); // mark of en of process, not incrementing currentAddress cause it has already been considered
    }

    // Restore the address where we shuld start dumping the condacts
    $currentAddress = $preserveCurrentAddress;
    

    // Dump the condacts

    foreach ($adventure->processes as $process)
    {
        foreach ($process->entries as $entry)
        {
            foreach ($entry->condacts as $condact)
            {
                $opcode = $condact->Opcode;
                if ($condact->Indirection1) $opcode = $opcode | 0x80; // Set indirection bit
                writeByte($outputFileHandler, $opcode);
                $currentAddress++;
                for($i=0;$i<$condact->NumParams;$i++) 
                {
                    switch ($i)
                    {
                        case 0: writeByte($outputFileHandler, $condact->Param1); break;
                        case 1: writeByte($outputFileHandler, $condact->Param2); break;
                    }
                }
                $currentAddress+= $condact->NumParams;
            }
            writeFF($outputFileHandler); // mark of end of entry
            $currentAddress++;
        }
    }
}
    

//================================================================= targets ========================================================



function isValidTarget($target)
{
    return ($target == 'zx') || ($target == 'cpc') ||  ($target == 'c64') ||  ($target == 'pcw') ||  ($target == 'msx') ||  ($target == 'amiga') ||  ($target == 'pc') ||  ($target == 'st');
}

function getMachineIDByTarget($target)
{
  if ($target=='zx') return 1; else
  if ($target=='c64') return 2; else
  if ($target=='cpc') return 3; else
  if ($target=='msx') return 4; else
  if ($target=='pc') return 5; else
  if ($target=='st') return 6; else
  if ($target=='amiga') return 7; else
  if ($target=='pcw') return 8;
};  

FUNCTION getBaseAddressByTarget($target)
{
  if ($target=='zx') return 0x8400; else
  if ($target=='msx') return 0x100; else
  return 0;
};

FUNCTION isPaddingPlatformByID($target)
{
    return (($target=='pc') || ($target=='st') || ($target=='amiga'));
};

FUNCTION isLittleEndianPlatform($target)
{
    return (($target=='pc') || ($target=='st') || ($target=='amiga')); 
};

//================================================================= main ========================================================



// Just for development, set to true for verbose info
$verbose = true;


function Syntax()
{
    echo("DRB {$version_hi}.{$version_lo}\n\n");
    
    echo("SYNTAX: DRB <target> <language> <compression> <inputfile> [outputfile]\n\n");
    echo("<target>: target machine, should be 'zx', 'cpc', 'c64', 'msx', 'pcw', 'pc', 'st' or 'amiga'.\n");
    echo("<language>: game language, should be 'EN' or 'ES' (english or spanish).\n");
    echo("<compression>: text compresion level, should be 'none', 'standard' or 'full'.\n");
    echo("<inputfile>: a json file generated by DRC.\n");
    echo("[outputfile] : (optional) name of output DDB file. If absent, same name of json file would be used, with DDB extension.\n");
    exit(1);
}

function Error($msg)
{
 echo("Error: $msg\n");
 exit(2);
}





//********************************************** MAIN **************************************************************** */
echo "DRB {$version_hi}.{$version_lo} (C) Uto 2019\n";

// Check params
if (sizeof($argv) < 4) Syntax();
$target = strtolower($argv[1]);
if (!isValidTarget($target)) Error('Invalid target machine.');
$language = strtolower($argv[2]);
if (($language!='es') && ($language!='en')) Error('Invalid target language.');
$compression = strtolower($argv[3]);
if (($compression!='none') && ($compression!='standard') && ($compression!='full')) Error('Invalid compression level.');
$inputFileName = $argv[4];
if (sizeof($argv) >5) $outputFileName = $argv[5];
   else $outputFileName = replace_extension($inputFileName, 'DDB');
if ($outputFileName==$inputFileName) Error('Input and output file name cannot be the same.');
if (!file_exists($inputFileName)) Error('File not found.');
$json = file_get_contents($inputFileName);
$adventure = json_decode($json);
if (!$adventure) Error('Invalid json file');
// Open output file
$outputFileHandler = fopen($outputFileName, "wr");
if (!$outputFileHandler) Error('Can\'t create output file.');
// **** DUMP DATA TO DDB ****

$baseAddress = getBaseAddressByTarget($target);
$currentAddress = $baseAddress;
$isLittleEndian = isLittleEndianPlatform($target);

// *********************************************
// 1 ************** WRITE HEADER ***************
// *********************************************

// DAAD version
$b = 2; 
writeByte($outputFileHandler, $b);

// Machine and language
$b = getMachineIDByTarget($target);
$b = $b << 4; // Move machine ID to high nibble
if ($language=='es') $b = $b | 1; // Set spanish language   
writeByte($outputFileHandler, $b);

// No idea what this byte is for, but all DDBs have same value
$b = 95;
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

// *********************************************
// 2 *************** DUMP DATA *****************
// *********************************************
// Dump compressed texts
$compressedTextOffset = $currentAddress;
if ($verbose) echo "Tokens            [" . prettyFormat($compressedTextOffset) . "]\n";
generateTokens($adventure, $currentAddress, $outputFileHandler, $compression);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Dump Processes
$processListOffset = $currentAddress;
if ($verbose) echo "Processes         [" . prettyFormat($processListOffset) . "]\n";
generateProcesses($adventure, $currentAddress, $outputFileHandler,  $isLittleEndian);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Dump Vocabulary
$vocabularyOffset = $currentAddress;
if ($verbose) echo "Vocabulary        [" . prettyFormat($vocabularyOffset) . "]\n";
generateVocabulary($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Messages
$messageLookupOffset = $currentAddress;
if ($verbose) echo "Messages          [" . prettyFormat($messageLookupOffset) . "]\n";
generateMTX($adventure, $currentAddress, $outputFileHandler, $compression, $isLittleEndian);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Sysmess
$sysmessLookupOffset = $currentAddress;
if ($verbose) echo "Sysmess           [" . prettyFormat($sysmessLookupOffset) . "]\n";
generateSTX($adventure, $currentAddress, $outputFileHandler, $compression, $isLittleEndian);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Location texts
$locationLookupOffset = $currentAddress;
if ($verbose) echo "Locations         [" . prettyFormat($locationLookupOffset) . "]\n";
generateLTX($adventure, $currentAddress, $outputFileHandler, $compression, $isLittleEndian);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Object Texts
$objectLookupOffset = $currentAddress;
if ($verbose) echo "Object texts      [" . prettyFormat($objectLookupOffset) . "]\n";
generateOTX($adventure, $currentAddress, $outputFileHandler, $compression, $isLittleEndian);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Object names
$objectNamesOffset = $currentAddress;
if ($verbose) echo "Object words      [" . prettyFormat($objectNamesOffset) . "]\n";
generateObjectNames($adventure, $currentAddress, $outputFileHandler);
// InitiallyAt
$initiallyAtOffset = $currentAddress;
if ($verbose) echo "Initially at      [" . prettyFormat($initiallyAtOffset) . "]\n";
generateObjectInitially($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);// Weight & standard Attr
$objectWeightAndAttrOffset = $currentAddress;
if ($verbose) echo "Weight & std attr [" . prettyFormat($objectWeightAndAttrOffset) . "]\n";
generateObjectWeightAndAttr($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Extra Attr
$objectExtraAttrOffset = $currentAddress;
if ($verbose) echo "Extra attr        [" . prettyFormat($objectExtraAttrOffset) . "]\n";
generateObjectExtraAttr($adventure, $currentAddress, $outputFileHandler, $isLittleEndian);
// Connections
$connectionsLookupOffset = $currentAddress;
if ($verbose) echo "Connections       [" . prettyFormat($connectionsLookupOffset) . "]\n";
generateConnections($adventure, $currentAddress, $outputFileHandler,$isLittleEndian);

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
$fileSize = $currentAddress - $baseAddress;
if ($verbose) echo "DDB size is " .$fileSize . " bytes.\n";
writeWord($outputFileHandler, $fileSize, $isLittleEndian);
fclose($outputFileHandler);
echo "OK.";