{
  Serialize forms in YAML format
  It produces mostly valid YAML, with a few exceptions, such as unknown Structs having the unknown key for multiple entries.
  A few names might also produce invalid YAML.
}

unit SerializeLib;

const
  varSmallint = 2;
  varInteger = 3;
  varSingle = 4;
  varDouble = 5;
  varBoolean = 11;
  varShortInt = 16;
  varByte = 17;
  varWord = 18;
  varLongWord = 19;
  varString =  256;
  varUString = 258;

var
  _tabIndex: Integer;

// -------------- typeOf --------------

function typeOf(e: IInterface): String;
var
  dt: TwbDefType;
  et: TwbElementType;
  vt: Integer;
  editValue, nativeStringValue: String;
  nativeValue: Variant;
begin
  dt := DefType(e);
  et := ElementType(e);

  if (dt = dtEmpty) then begin
    Result := 'Empty';
    exit;
  end;

  if (et = etMainRecord) then begin
    Result := 'Main';
    exit;
  end;

  if (et = etGroupRecord) then begin
    Result := 'Group';
    exit;
  end;

  if (et = etUnion) then begin
    // hacky

    if (ElementCount(e) > 0) then begin
      Result := 'Object';
      exit;
    end;

    nativeValue := GetNativeValue(e);
    vt := VarType(nativeValue);

    if (vt = varDouble) then dt := dtFloat
    else if (vt = varSmallint) or (vt = varLongWord) or (vt = varInteger) then dt := dtInteger
    else if (vt = varByte) then et := etFlag
    else if (vt = 8209) or (vt = varUString) then dt := dtString;
  end;

  if (et = etFlag) then begin
    Result := 'Boolean';
    exit;
  end;

  if (et = etStruct) or (et = etSubRecordStruct) or (dt = dtStruct) then begin
    Result := 'Object';
    exit;
  end;

  if (et = etSubRecordArray) or (dt = dtArray) then begin
    Result := 'Array';
    exit;
  end;

  if (dt = dtInteger) then begin

    if (ElementCount(e) > 0) then begin
      Result := 'Object';
      exit;
    end;

    editValue := GetEditValue(e);
    // ?? dammit xEdit
    if (editValue = 'FFFF - None Reference [FFFFFFFF]') then nativeValue := 0
    else nativeValue := GetNativeValue(e);

    nativeStringValue := IntToStr(nativeValue);

    if (editValue <> nativeStringValue) then begin
      if (editValue = 'NULL - Null Reference [00000000]') then
        Result := 'NullRef'
      // no better way to check for empty flag container? eeek!.
      else if (editValue = '0000000000000000000000000000000000000000000000000000000000000000') then
        Result := 'Object'
      else if (LinksTo(e) <> nil) then
        Result := 'Link'
      else
        Result := 'String';

      exit;
    end;

    Result := 'Number';

    exit;
  end;

  if (dt = dtFloat) then begin
    Result := 'Number';
    exit;
  end;

  if (dt = dtString) or (dt = dtLString) or (dt = dtLenString) then begin
    Result := 'String';
    exit;
  end;

  if (dt = dtByteArray) then begin
    Result := 'ByteArray';
    exit;
  end;

  Result := '';
end;

function _tab: String;
var
  n: Integer;
begin
  Result := '';
  for n := 0 to _tabIndex -1 do begin
    Result := Result + '  ';
  end;

  Result := #13#10 + Result;
end;

// -------------- Serializators --------------

function _SerializeName(e: IInterface): String;
var
  nom: String;
begin
  nom := Name(e);

  if (Pos('#', nom) > 0) then Result := '"' + nom + '"'
  else Result := nom;
end;

function _SerializeComment(e: IInterface): String;
var fullName: String;
begin
  Result := ' #' + GetElementEditValues(e, 'EDID') + ' ';
  fullName := GetElementEditValues(e, 'Full - Name');
  if (fullName <> '') then Result := Result + '"' + fullName + '" ';
  Result := Result + '[' + Signature(e) + ']';
end;

function _SerializeHeader(header, e: IInterface): String;
var
  n: Integer;
  ei: IInterface;
begin
  Result := _SerializeName(header) + ':'; // Record Header

  _tabIndex := _tabIndex + 1;
  Result := Result + _tab() + 'Signature: ' + Signature(e);
  Result := Result + _tab() + _SerializeObject(ElementByPath(header, 'Record Flags'));
  Result := Result + _tab() + 'FormID: "' + IntToHex(FixedFormID(e), 8) + '"';

  _tabIndex := _tabIndex - 1;

end;

function _SerializeMain(e: IInterface): String;
var
  n: Integer;
  ei: IInterface;
begin
  Result := IntToHex(FixedFormID(e), 8) + ':' + _SerializeComment(e);

  _tabIndex := _tabIndex + 1;

  for n := 0 to ElementCount(e) - 1 do begin
    ei := ElementByIndex(e, n);
    if (Name(ei) = 'Record Header') then Result := Result + _tab() + _SerializeHeader(ei, e)
    else Result := Result + _tab() + _Serialize(ei);
  end;

  _tabIndex := _tabIndex - 1;

end;

function _SerializeObject(e: IInterface): String;
var
  n: Integer;
  ei: IInterface;
  s: String;
begin
  Result := _SerializeName(e) + ':';
  _tabIndex := _tabIndex + 1;

  for n := 0 to ElementCount(e) - 1 do begin
    ei := ElementByIndex(e, n);
    s := _Serialize(ei);
    if (s <> '') then Result := Result + _tab() + s;
  end;

  _tabIndex := _tabIndex - 1;

end;

function _SerializeArray(e: IInterface): String;
var
  n: Integer;
  ei: IInterface;
begin
  Result := _SerializeName(e) + ':';

  _tabIndex := _tabIndex + 1;

  for n := 0 to ElementCount(e) - 1 do begin
    ei := ElementByIndex(e, n);
    Result := Result + _tab() + '- ';
    _tabIndex := _tabIndex + 1;
    Result := Result + _Serialize(ei);
    _tabIndex := _tabIndex - 1;
  end;

  _tabIndex := _tabIndex - 1;

end;

function _SerializeString(e: IInterface): String;
begin
  Result := _SerializeName(e) + ': ' + StringReplace(GetEditValue(e), '"', '\"', [rfReplaceAll]);
end;

function _SerializeBoolean(e: IInterface): String;
var
  vt: Integer;
  nativeValue: Variant;
begin
  Result := _SerializeName(e) + ': ';
  nativeValue := GetNativeValue(e);
  vt := VarType(nativeValue);

  if (vt = varByte and nativeValue = 1) or (vt = varBoolean and nativeValue) then
    Result := Result + 'true'
  else if (vt = varByte and nativeValue = 0) or (vt = varBoolean and not nativeValue) then
    Result := Result + 'false';

end;

function _SerializeByteArray(e: IInterface): String;
begin
  Result := _SerializeName(e) + ': "' + GetEditValue(e) + '"';
end;

function _SerializeNumber(e: IInterface): String;
begin
  Result := _SerializeName(e) + ': ' + GetEditValue(e);
end;

function _SerializeLink(e: IInterface): String;
var
  ln: IInterface;
begin
  ln := LinksTo(e);
  Result := _SerializeName(e) + ': "' + IntToHex(FixedFormID(ln), 8) + '"' + _SerializeComment(ln);
end;

function _SerializeNullRef(e: IInterface): String;
begin
  Result := _SerializeName(e) + ': "000000" #Null';
end;

function _SerializeEmpty(e: IInterface): String;
begin
  Result := _SerializeName(e) + ': #Empty';
end;

function _SerializeUnknown(e: IInterface): String;
var
  x: Variant;
  n, vt: Integer;
begin
  Result := Name(e) + ': "' + GetEditValue(e) + '" # Unknown type';
end;

// ..

function _Serialize(e: IInterface): String;
var
  t: String;
begin

  t := typeOf(e);

  if (t = 'Main') then
    Result := _SerializeMain(e)
  else if (t = 'Array') then
    Result := _SerializeArray(e)
  else if (t = 'Object') then
    Result := _SerializeObject(e)
  else if (t = 'Number') then
    Result := _SerializeNumber(e)
  else if (t = 'Boolean') then
    Result := _SerializeBoolean(e)
  else if (t = 'Link') then
    Result := _SerializeLink(e)
  else if (t = 'ByteArray') then
    Result := _SerializeByteArray(e)
  else if (t = 'String') then
    Result := _SerializeString(e)
  else if (t = 'NullRef') then
    Result := _SerializeNullRef(e)

  else if (t = 'Empty') then
    // Result := _SerializeEmpty(e)
  else
    Result := _SerializeUnknown(e);

end;

// Public

function Serialize(e: IInterface): String;

begin
  _tabIndex := 0;
  Result := _Serialize(e);
end;

end.
