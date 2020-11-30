{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit userscript;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
  Result := 0;
end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
var 
  edid: String;
begin
  Result := 0;
  edid := GetElementEditValues(e, 'EDID');
  if StartsText('zk_LL_Blueprint_', edid) then begin
    RemoveElement(e, ElementByName(e, 'Leveled List Entries'));
  end;
end;

// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
begin
  Result := 0;
end;

end.