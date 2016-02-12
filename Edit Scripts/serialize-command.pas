{
  Serialize the selected forms in YAML format
  Will write to ProgramPath + output.yml
  Hotkey: Ctrl+Y
}

unit SerializeCommand;

uses 'lib\Serialize';

var
  inputPathList: TStringList;
  outputYMLList: TStringList;
  outputPath: String;

function Initialize: integer;
begin
  inputPathList := TStringList.Create;
  outputYMLList := TStringList.Create;

  try
    inputPathList.LoadFromFile(ProgramPath + 'serialize_path.txt');
    outputPath := Trim(inputPathList.Text);
  except
    outputPath := ProgramPath + 'output.yml';
  end;

end;

function Process(e: IInterface): integer;

begin
  outputYMLList.Add(Serialize(e));
end;

function Finalize: integer;

begin
  AddMessage('Saving list to ' + outputPath);
  outputYMLList.SaveToFile(outputPath);

  outputYMLList.Free;
  inputPathList.Free;
end;

end.
