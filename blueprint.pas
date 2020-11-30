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
  WeaponName: String;
  WeaponTier: integer;
  Craftable: Boolean;

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
  modd: IInterface;
  perkId: String;
  perk: IInterface;
  magId: String;
  mag: IInterface;
  co: IInterface;
begin
  modWeaponName(e);
  
  if Craftable then begin
    if WeaponName = '' then
      exit;
    modd := LinksTo(ElementByName(e, 'CNAM - Created Object'));

    coId := GetElementEditValues(e, 'EDID');
    AddRequiredElementMasters(e, ToFile, False);

    perkId := IdPrefix + 'Perk_' + coId;
    perk := MainRecordByEditorID(GroupBySignature(ToFile, 'PERK'), perkId);
    if not Assigned(perk) then
      perk := wbCopyElementToFile(PerkProto, ToFile, True, True);
    SetElementEditValues(perk, 'EDID', perkId);
    SetElementEditValues(perk, 'FULL', 'Mod Blueprint');

    magId := IdPrefix + 'PerkMag_' + coId;
    mag := MainRecordByEditorID(GroupBySignature(ToFile, 'BOOK'), magId);
    if not Assigned(mag) then
      mag := wbCopyElementToFile(MagProto, ToFile, True, True);
    SetElementEditValues(mag, 'EDID', magId);
    SetElementEditValues(mag, 'FULL', 'Blueprint: ' + WeaponName + ' ' + GetElementEditValues(modd, 'FULL'));
    SetElementEditValues(mag, 'FIMD', '');
    SetEditValue(ElementByName(ElementByName(mag, 'DNAM - DNAM'), 'Perk'), ShortName(perk));

    co := MainRecordByEditorID(GroupBySignature(ToFile, 'COBJ'), coId);
    if not Assigned(co) then
      co := wbCopyElementToFile(e, ToFile, False, True);
    addCondition(co, perk);
    addLeveledItem(mag);
  end
  else begin
    co := MainRecordByEditorID(GroupBySignature(ToFile, 'COBJ'), coId);
    if not Assigned(co) then
      co := wbCopyElementToFile(e, ToFile, False, True);
    addNotCraftable(co);
  end;
end;


procedure modWeaponName(e: IInterface);
var
  sl: TStringList;
  n: String;
  slot: String;
begin
  WeaponName := '';
  WeaponTier := 0;
  Craftable := True;
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
      WeaponName := 'Pipe Gun';
    end
    else if n = 'PipeRevolver' then begin
      WeaponName := 'Pipe Revolver';
    end
    else if n = 'PipeBoltAction' then begin
      WeaponName := 'Pipe Bolt Action';
    end
    else if n = 'LaserMusket' then begin
      WeaponName := 'Laser Musket';
    end;
    if WeaponName <> '' then
      exit;

    if (slot = 'Receiver') or (slot = 'Barrel') or (slot = 'BarrelShotgun') or (slot = 'BarrelLaser') then begin
      Craftable := False;
      exit;
    end;

    if n = '10mm' then begin
      WeaponName := '10mm';
    end
    else if n = '44' then begin
      WeaponName := '.44';
    end
    else if n = 'DoubleBarrelShotgun' then begin
      WeaponName := 'Shotgun';
    end
    else if n = 'HuntingRifle' then begin
      WeaponName := 'Hunting Rifle';
    end
    else if n = 'CombatRifle' then begin
      WeaponName := 'Combat Rifle';
    end
    else if n = 'CombatShotgun' then begin
      WeaponName := 'Combat Shotgun';
    end
    else if n = 'InstituteLaserGun' then begin
      WeaponName := 'Institute';
    end
    else if n = 'LaserGun' then begin
      WeaponName := 'Laser Gun';
    end
    else if n = 'PlasmaGun' then begin
      WeaponName := 'Plasma Gun';
    end
    else if n = 'SubmachineGun' then begin
      WeaponName := 'Submachine Gun';
    end;
  finally
    sl.Free;
  end;
end;

procedure addCondition(co: IInterface; perk: IInterface);
var
  conditions: IInterface;
  condition: IInterface;
  i: integer;
begin
  conditions := ElementByName(co, 'Conditions');
  if not Assigned(conditions) then begin
    conditions := Add(co, 'Conditions', False);
    condition := ElementByIndex(conditions, 0);
  end
  else begin
    for i := 0 to Pred(ElementCount(conditions)) do begin
      condition := ElementByIndex(conditions, i);
      if GetEditValue(ElementByPath(condition, 'CTDA - CTDA\Perk')) = ShortName(perk) then
        exit;
    end;
    condition := ElementAssign(conditions, HighInteger, nil, False);
  end;
  SetEditValue(ElementByPath(condition, 'CTDA - CTDA\Function'), 'HasPerk');
  SetEditValue(ElementByPath(condition, 'CTDA - CTDA\Perk'), ShortName(perk));
  SetEditValue(ElementByPath(condition, 'CTDA - CTDA\Comparison Value - Float'), '1.0');
end;

procedure addNotCraftable(co: IInterface);
var
  item: IInterface;
  conditions: IInterface;
  components: IInterface;
  component: IInterface;
  i: integer;
begin;
  item := MainRecordByEditorID(GroupBySignature(ToFile, 'MISC'), 'zk_misc_not_craftable');
  if not Assigned(item) then begin
    AddMessage('misc_not_craftable not found');
    exit;
  end;

  conditions := ElementByName(co, 'Conditions');
  if Assigned(conditions) then
    Remove(conditions);
  components := ElementByName(co, 'FVPA - Components');
  if not Assigned(components) then
    components := Add(co, 'FVPA - Components', False);

  for i := 1 to Pred(ElementCount(components)) do begin
    component := ElementByIndex(components, 1);
    Remove(component);
  end;
  component := ElementByIndex(components, 0);
  SetEditValue(ElementByPath(component, 'Component'), ShortName(item));
  SetEditValue(ElementByPath(component, 'Count'), '1');
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

procedure addMagazine(co: IInterface; edid: String; n: String; tier: integer);
var
  mag: IInterface;
begin
  mag := MainRecordByEditorID(GroupBySignature(ToFile, 'BOOK'), edid);
  if not Assigned(mag) then begin
    mag := wbCopyElementToFile(MagProto, ToFile, True, True);
  end;
  SetElementEditValues(mag, 'FULL', n);
end;

// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
begin
  Result := 0;
end;

end.
