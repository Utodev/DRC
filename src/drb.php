<?php

// (C) Uto & Jose Manuel Ferrer 2019 - This code is released under the GPL v3 license
// To build the backend of DAAD reborn compiler I have had aid from Jose Manuel Ferrer Ortiz's DAAD database code,
// which he glently provided me. In some cases the code has been even copied and pasted, so that's why he is also
// in the copyright notice above. Thanks Jose Manuel for this invaluable aid.


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

function generateExterns($adventure, &$currentAddress, $outputFileHandler)
{
    foreach ($adventure->externs as $extern)
    {
        $filePath = $extern->FilePath;
        if (!file_exists($filePath)) Error("Extern file not found: ${filePath}.");
        $externfileHandle = fopen($filePath, "r");
        $buffer = fread($externfileHandle, filesize($filePath));
        fclose($externfileHandle);
        fputs($outputFileHandler, $buffer);
        $currentAddress+=filesize($filePath);
    }   
}

//================================================================= tokens ========================================================

function generateTokens($adventure, &$currentAddress, $outputFileHandler, $compression)
{

    if ($compression == 'none') 
    {
        writeZero($outputFileHandler);
        $currentAddress++;
    }
    else
    {
        //TODO
    }
}
//================================================================= common ========================================================

define ('OFUSCATE_VALUE', 0xFF);

class daadToChr
{
var $conversions = array('ª', '¡', '¿', '«', '»', 'á', 'é', 'í', 'ó', 'ú', 'ñ', 'Ñ', 'ç', 'Ç', 'ü', 'Ü');
}
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
    if (isPaddingPlatform($target) && (($currentAddress % 2)==1)) 
    {
        writeZero($outputFileHandler); // Fill with one byte for padding
        $currentAddress++;       
    }
}

//================================================================= messages  ========================================================

function replaceEscapeChars($str)
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

function generateMessages($messageList, &$currentAddress, $outputFileHandler, $compression, $isLittleEndian)
{

    $messageOffsets = array();
    for ($messageID=0;$messageID<sizeof($messageList);$messageID++)
    {
        $messageOffsets[$messageID] = $currentAddress;
        $message = $messageList[$messageID];
        $message->Text = replaceEscapeChars($message->Text);
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
    generateMessages($adventure->objects, $currentAddress, $outputFileHandler, 'none', $isLittleEndian); // Never compress object texts, no matter what is selected
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
    $daad_to_chr = new daadToChr();
    foreach ($adventure->vocabulary as $word)
    {
        $vocWord = substr(str_pad($word->VocWord,5),0,5);
        for ($i=0;$i<5;$i++)
        {
            $character = $vocWord[$i];
            if (ord($character)>127) $character = array_search($character, $daad_to_chr->conversions) + 16;  else  $character = ord(strtoupper($character));
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


function getCondactsHash($condacts, $from)
{
    $hash = '';
    for ($i=$from; $i<sizeof($condacts);$i++)
    {
        $condact = $condacts[$i];
        $opcode = $condact->Opcode;
        if ($condact->Indirection1) $opcode = $opcode | 0x80; // Set indirection bit
        $hash .= chr($opcode);
        if ($condact->NumParams>0)
        {
            $param1 = $condact->Param1;
            $hash .= chr($param1);
            if ($condact->NumParams>1) 
            {
                $param2 = $condact->Param2;
                $hash .= chr($param2);
            }
        }
    }
    return $hash;
}

function generateProcesses($adventure, &$currentAddress, $outputFileHandler, $isLittleEndian)
{
    

    $terminatorOpcodes = array(22, 23,103, 116,117,108);  //DONE/OK/NOTDONE/SKIP/RESTART/REDO

    $condactsOffsets = array();
    $condactsHash = array();  

    // Dump  all condacts and store which address each entry condacts
    for ($procID=0;$procID<sizeof($adventure->processes);$procID++)
    {
        $process = $adventure->processes[$procID];

        for ($entryID=0;$entryID<sizeof($process->entries);$entryID++)
        {
            $condactsOffsets["${procID}_${entryID}"] = $currentAddress;
            $entry = $process->entries[$entryID];
            $terminatorFound = false;
            if (!$adventure->classicMode)
            {
                $hash = getCondactsHash($entry->condacts, 0);
                if ($hash!='')
                {
                    if (array_key_exists("$hash", $condactsHash))
                    {
                        $condactsOffsets["${procID}_${entryID}"] = $condactsHash["$hash"]->offset;
                        if ($adventure->verbose) echo "Saved ". strlen($hash) . " bytes from entry ".$condactsHash["$hash"]->origin." to ${procID}_${entryID}]  \n" ;
                        continue;
                    }
                    else 
                    {
                        $offsetData = new stdClass();
                        $offsetData->origin = "${procID}_${entryID}";
                        $offsetData->offset = $currentAddress;
                        $condactsHash["$hash"] = $offsetData;
                    }
                }
            }
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
                        case 0: 
                        {
                            $param = $condact->Param1;
                            if ($param < 0) $param= 256 + $param;  // For SKIP
                            writeByte($outputFileHandler, $param); break;
                        }
                        case 1: writeByte($outputFileHandler, $condact->Param2); break;
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

function getBaseAddressByTarget($target)
{
  if ($target=='zx') return 0x8400; else
  if ($target=='msx') return 0x100; else
  if ($target=='cpc') return 0x2880; else
  if ($target=='c64') return 0x3880; else return 0;
};

function isPaddingPlatform($target)
{
    return (($target=='pc') || ($target=='st') || ($target=='amiga'));
};

function isLittleEndianPlatform($target)
{
    return (($target=='pc') || ($target=='st') || ($target=='amiga'));
};

//================================================================= main ========================================================




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
echo "DAAD Reborn Compiler Backend {$version_hi}.{$version_lo} (C) Uto 2019\n";

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

// Check settings in JSON
$adventure->classicMode = $adventure->settings[0]->classic_mode;
if ($adventure->classicMode) echo "Warning: Compiling in classic mode, optimization disabled.\n";
// Just for development, set to true for verbose info
$adventure->verbose = true;


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
writeBlock($outputFileHandler, 26);  // Los punteros varios, en principio a 0x000
$currentAddress+=26;


// *********************************************
// 2 *************** DUMP DATA *****************
// *********************************************

// DumpExterns
generateExterns($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Dump Vocabulary
$vocabularyOffset = $currentAddress;
if ($adventure->verbose) echo "Vocabulary        [" . prettyFormat($vocabularyOffset) . "]\n";
generateVocabulary($adventure, $currentAddress, $outputFileHandler);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Dump compressed texts
if ($compression<>'none') $compressedTextOffset = $currentAddress; $compressedTextOffset = 0; // If no compression, the header should have 0x0000 in the compression pointer
if ($adventure->verbose) echo "Tokens            [" . prettyFormat($compressedTextOffset) . "]\n";
generateTokens($adventure, $currentAddress, $outputFileHandler, $compression);
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Sysmess
generateSTX($adventure, $currentAddress, $outputFileHandler, $compression, $isLittleEndian);
$sysmessLookupOffset = $currentAddress - 2 * sizeof($adventure->sysmess);;
if ($adventure->verbose) echo "Sysmess           [" . prettyFormat($sysmessLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Messages
generateMTX($adventure, $currentAddress, $outputFileHandler, $compression, $isLittleEndian);
$messageLookupOffset = $currentAddress - 2 * sizeof($adventure->messages);
if ($adventure->verbose) echo "Messages          [" . prettyFormat($messageLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Object Texts
generateOTX($adventure, $currentAddress, $outputFileHandler, $compression, $isLittleEndian);
$objectLookupOffset = $currentAddress - 2 * sizeof($adventure->object_data);
if ($adventure->verbose) echo "Object texts      [" . prettyFormat($objectLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Location texts
generateLTX($adventure, $currentAddress, $outputFileHandler, $compression, $isLittleEndian);
$locationLookupOffset =  $currentAddress - 2 * sizeof($adventure->locations);
if ($adventure->verbose) echo "Locations         [" . prettyFormat($locationLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Connections
generateConnections($adventure, $currentAddress, $outputFileHandler,$isLittleEndian);
$connectionsLookupOffset = $currentAddress - 2 * sizeof($adventure->locations) ;
if ($adventure->verbose) echo "Connections       [" . prettyFormat($connectionsLookupOffset) . "]\n";
addPaddingIfRequired($target, $outputFileHandler, $currentAddress);
// Object names
$objectNamesOffset = $currentAddress;
if ($adventure->verbose) echo "Object words      [" . prettyFormat($objectNamesOffset) . "]\n";
generateObjectNames($adventure, $currentAddress, $outputFileHandler);
// Weight & standard Attr
$objectWeightAndAttrOffset = $currentAddress;
if ($adventure->verbose) echo "Weight & std attr [" . prettyFormat($objectWeightAndAttrOffset) . "]\n";
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
// Dump Processes
generateProcesses($adventure, $currentAddress, $outputFileHandler,  $isLittleEndian);
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
$fileSize = $currentAddress;
writeWord($outputFileHandler, $fileSize, $isLittleEndian);
fclose($outputFileHandler);
echo "Done. DDB size is " . ($fileSize - $baseAddress) . " bytes.\n Database ends at address $currentAddress (". prettyFormat($currentAddress). ")\n";

