var f:file;
B: byte;
W :Word;
i :longint;


begin
 Assign(F, paramStr(1));
 Reset(F,1);
 W :=FileSize(F);
 Write('CONST F=array[0..', w-1,'] of byte = '#10'(');
 i:=0;
 While not eof (F) DO
 begin
  BlockRead(F,B,1);
  Write(B);
  if (i<>W-1) then Write(', ');
  if (i MOD 40 =39) then Writeln;
  i := i+ 1;
 end;
 WriteLn(');');
Close(f);
    
end.