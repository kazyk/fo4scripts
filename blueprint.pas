{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit userscript;

const
  IdPrefix = 'zk_';

var
  ToFile: IInterface;
  PerkProto: IwbMainRecord;
  MagProto: IwbMainRecord;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
var
  i: integer;
  frm: TForm;
  clb: TCheckListBox;
  baseFile: IwbFile;
begin
  Result := 0;
  if not Assigned(ToFile) then begin
    frm := frmFileSelect;
    try
      frm.Caption := 'Select a plugin';
      clb := TCheckListBox(frm.FindComponent('CheckListBox1'));
      clb.Items.Add('<new file>');
      for i := Pred(FileCount) downto 0 do
        // if GetFileName(e) <> GetFileName(FileByIndex(i)) then
          clb.Items.InsertObject(1, GetFileName(FileByIndex(i)), FileByIndex(i));
        // else
          // Break;
      if frm.ShowModal <> mrOk then begin
        Result := 1;
        Exit;
      end;
      for i := 0 to Pred(clb.Items.Count) do
        if clb.Checked[i] then begin
          if i = 0 then ToFile := AddNewFile else
            ToFile := ObjectToElement(clb.Items.Objects[i]);
          Break;
        end;
    finally
      frm.Free;
    end;
    if not Assigned(ToFile) then begin
      Result := 1;
      Exit;
    end;
  end;

  baseFile := FileByLoadOrder(0);
  PerkProto := MainRecordByEditorID(GroupBySignature(baseFile, 'PERK'), 'PerkMagPicket01');
  AddMessage('PerkProto: ' + GetEditValue(ElementByName(PerkProto, 'FULL - Name')));
  MagProto := MainRecordByEditorID(GroupBySignature(baseFile, 'BOOK'), 'PerkMagGunsAndBullets01');
  AddMessage('MagProto: ' + GetElementEditValues(MagProto, 'FULL'));
end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
begin
  Result := 0;

  // comment this out if you don't want those messages
  // AddMessage('Processing: ' + FullPath(e));

  // processing code goes here
  if Signature(e) = 'COBJ' then
    processCo(e);

end;

procedure processCo(e: IInterface);
var
  coId: String;
  weaponName: String;
  modd: IInterface;
  perk: IInterface;
  mag: IInterface;
  co: IInterface;
begin
  weaponName := modWeaponName(e);
  if weaponName = '' then
    exit;
  
  if weaponName <> 'NotCraftable' then begin
    modd := LinksTo(ElementByName(e, 'CNAM - Created Object'));

    coId := GetElementEditValues(e, 'EDID');
    AddRequiredElementMasters(e, ToFile, False);

    perk := wbCopyElementToFile(PerkProto, ToFile, True, True);
    SetElementEditValues(perk, 'EDID', IdPrefix + 'Perk_' + coId);
    SetElementEditValues(perk, 'FULL', 'Mod Blueprint');

    mag := wbCopyElementToFile(MagProto, ToFile, True, True);
    SetElementEditValues(mag, 'EDID', IdPrefix + 'PerkMag_' + coId);
    SetElementEditValues(mag, 'FULL', 'Blueprint: ' + weaponName + ' ' + GetElementEditValues(modd, 'FULL'));
    SetElementEditValues(mag, 'FIMD', '');
    SetEditValue(ElementByName(ElementByName(mag, 'DNAM - DNAM'), 'Perk'), ShortName(perk));

    co := wbCopyElementToFile(e, ToFile, False, True);
    addCondition(co, perk);
    addLeveledItem(mag);
  end
  else begin
    co := wbCopyElementToFile(e, ToFile, False, True);
    addUnavailable(co);
  end;
end;

function modWeaponName(e: IInterface): String;
var
  sl: TStringList;
  n: String;
  slot: String;
begin
  Result := '';
  sl := TStringList.Create;
  try
    sl.Delimiter := '_';
    sl.DelimitedText := GetElementEditValues(e, 'EDID');
    if sl[0] <> 'co' then
      exit;
    if sl[1] <> 'mod' then
      exit;
    if sl.Count < 4 then
      exit;
    n := sl[2];
    slot := sl[3];
    if (n = 'Pipe') or (n = 'PipeGun') then begin
      Result := 'Pipe Gun';
    end
    else if n = 'PipeRevolver' then begin
      Result := 'Pipe Revolver';
    end
    else if n = 'PipeBoltAction' then begin
      Result := 'Pipe Bolt Action';
    end
    else if n = 'LaserMusket' then begin
      Result := 'Laser Musket';
    end;
    if Result <> '' then
      exit;

    if (slot = 'Receiver') or (slot = 'Barrel') or (slot = 'BarrelShotgun') or (slot = 'BarrelLaser') then begin
      Result := 'NotCraftable';
      exit;
    end;

    if n = '10mm' then begin
      Result := '10mm';
    end
    else if n = '44' then begin
      Result := '.44';
    end
    else if n = 'DoubleBarrelShotgun' then begin
      Result := 'Shotgun';
    end
    else if n = 'HuntingRifle' then begin
      Result := 'Hunting Rifle';
    end
    else if n = 'CombatRifle' then begin
      Result := 'Combat Rifle';
    end
    else if n = 'CombatShotgun' then begin
      Result := 'Combat Shotgun';
    end
    else if n = 'InstituteLaserGun' then begin
      Result := 'Institute';
    end
    else if n = 'LaserGun' then begin
      Result := 'Laser Gun';
    end
    else if n = 'PlasmaGun' then begin
      Result := 'Plasma Gun';
    end
    else if n = 'SubmachineGun' then begin
      Result := 'Submachine Gun';
    end;
  finally
    sl.Free;
  end;
end;

procedure addCondition(co: IInterface; perk: IInterface);
var
  conditions: IInterface;
  condition: IInterface;
begin
  conditions := ElementByName(co, 'Conditions');
  if not Assigned(conditions) then begin
    conditions := Add(co, 'Conditions', False);
    condition := ElementByIndex(conditions, 0);
  end
  else begin
    condition := ElementAssign(conditions, HighInteger, nil, False);
  end;
  SetEditValue(ElementByPath(condition, 'CTDA - CTDA\Function'), 'HasPerk');
  SetEditValue(ElementByPath(condition, 'CTDA - CTDA\Perk'), ShortName(perk));
  SetEditValue(ElementByPath(condition, 'CTDA - CTDA\Comparison Value - Float'), '1.0');
end;

procedure addUnavailable(co: IInterface);
var
  unavailable: IInterface;
  conditions: IInterface;
  condition: IInterface;
begin;
  unavailable := MainRecordByEditorID(GroupBySignature(ToFile, 'PERK'), 'zk_Perk_NotCraftable');
  if not Assigned(unavailable) then begin
    AddMessage('Perk_NotCraftable not found');
    exit;
  end;
  conditions := ElementByName(co, 'Conditions');
  if not Assigned(conditions) then begin
    conditions := Add(co, 'Conditions', False);
    condition := ElementByIndex(conditions, 0);
  end
  else begin
    condition := ElementAssign(conditions, HighInteger, nil, False);
  end;
  SetEditValue(ElementByPath(condition, 'CTDA - CTDA\Function'), 'HasPerk');
  SetEditValue(ElementByPath(condition, 'CTDA - CTDA\Perk'), ShortName(unavailable));
  SetEditValue(ElementByPath(condition, 'CTDA - CTDA\Comparison Value - Float'), '1.0');
end;

procedure addLeveledItem(mag: IInterface);
var 
  weaponName: String;
  sl: TStringList;
  ll: IInterface;
  entries: IInterface;
  entry: IInterface;
  i: Integer;
begin
  sl := TStringList.Create;
  sl.Delimiter := '_';
  sl.DelimitedText := GetElementEditValues(mag, 'EDID');
  if sl.Count < 5 then
    exit;
  weaponName := sl[4];
  if weaponName = 'Pipe' then
    weaponName := 'PipeGun';
  ll := MainRecordByEditorID(GroupBySignature(ToFile, 'LVLI'), 'zk_LL_Blueprint_' + weaponName);
  if not Assigned(ll) then begin
    AddMessage('LeveledItem not found: ' + weaponName);
    exit;
  end;
  entries := ElementByName(ll, 'Leveled List Entries');
  if not Assigned(entries) then begin
    entries := Add(ll, 'Leveled List Entries', False);
    entry := ElementByIndex(entries, 0);
  end
  else begin
    for i := 0 to Pred(ElementCount(entries)) do begin
      entry := ElementByIndex(entries, i);
      if GetEditValue(ElementByPath(entry, 'LVLO - Base Data\Reference')) = ShortName(mag) then
        exit;
    end;
    entry := ElementAssign(entries, HighInteger, nil, False);
  end;
  SetEditValue(ElementByPath(entry, 'LVLO - Base Data\Reference'), ShortName(mag));
  SetEditValue(ElementByPath(entry, 'LVLO - Base Data\Level'), '1');
  SetEditValue(ElementByPath(entry, 'LVLO - Base Data\Count'), '1');
end;

// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
begin
  Result := 0;
end;

end.