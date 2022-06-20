UNIT UConstants;
{$MODE OBJFPC}

INTERFACE

CONST version_hi = 0;
	  version_lo = 28;

      LOC_CARRIED = 254;
      LOC_WORN = 253;       
      LOC_NOT_CREATED = 252;
      LOC_HERE = 255;
      NO_WORD = 255;
      MAX_FLAG_VALUE = 255;
      VOCABULARY_LENGTH = 5;
      MAX_DIRECTION_VOCABULARY = 13;
      MAX_CONVERTIBLE_NAME = 19;
      MAX_PROCESSES = 255;
      MAX_CONDACT_PARAMS  =3;
      MAX_PARAM_ACCEPTING_INDIRECTION = 1;
      MAX_MESSAGES_PER_TABLE = 255;
      MAX_WEIGHT = 63;

      MAX_PARAMETER_RANGE = 255;

      MAX_LABELS = 1024;

      NUM_CONDACTS  =128;
      NUM_FAKE_CONDACTS = 14;

      MESSAGE_OPCODE = 38;
      MES_OPCODE =77;
      SYSMESS_OPCODE = 54;
      XMES_OPCODE = 128;
      XMESSAGE_OPCODE = 129;
      XPICTURE_OPCODE = 130;
      PICTURE_OPCODE=84;
      XSAVE_OPCODE = 131;
      SAVE_OPCODE = 25;
      XLOAD_OPCODE =  132;
      LOAD_OPCODE = 26;
      XPLAY_OPCODE = 134;
      XBEEP_OPCODE = 135;
      XSPLITSCR_OPCODE = 136;
      XUNDONE_OPCODE=137;
      XNEXTCLS_OPCODE=138;
      XNEXTRST_OPCODE=139;
      XSPEED_OPCODE=140;
      BEEP_OPCODE = 64;

      DESC_OPCODE = 19;
      SKIP_OPCODE = 116;
      PENDINGSKIP_OPCODE = 141;

      SYNONYM_OPCODE = 36;
      PREP_OPCODE = 68;
      NOUN2_OPCODE = 69;
      ADJECT1_OPCODE = 16;
      ADVERB_OPCODE = 17;
      ADJECT2_OPCODE = 70;

      FAKE_DEBUG_CONDACT_CODE = 220; // the fake DEBUG Condact
      FAKE_DEBUG_CONDACT_TEXT = 'DEBUG';

      FAKE_USERPTR_CONDACT_CODE = 256;    

// Compile options
VAR ForceNormalMessages : Boolean;
    ForceXMessages : Boolean;
    NoSemantic : Boolean;
    SemanticWarnings : Boolean;
    Verbose: Boolean;

IMPLEMENTATION

BEGIN
       ForceNormalMessages := false;
       NoSemantic := false;
       SemanticWarnings := false;
       Verbose := false;
END.
