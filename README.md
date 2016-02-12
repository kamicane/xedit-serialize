#xEdit Serialize

Serialize [xEdit](https://github.com/TES5Edit/TES5Edit) forms in [YAML](http://yaml.org) format.

Drop into the xEdit installation folder, select the forms you want to serialize, press `CTRL+Y` and go get a coffee.
An `output.yml` file will eventually be created.

Forms will look like this:

```yml
0012B91D: #Armor_Synth_Underarmor "Synth Uniform" [ARMO]
  Record Header:
    Signature: ARMO
    Record Flags:
    FormID: "0012B91D"
  EDID - Editor ID: Armor_Synth_Underarmor
  PTRN - Transform: "002490C2" #ArmorTorsoSynthUnderarmor [TRNS]
  FULL - Name: Synth Uniform
  EITM - Object Effect: "00192193" #EnchClothingPerception "Fortify Perception" [ENCH]
  Male world model:
    MOD2 - Model Filename: Clothes\SynthUniform\SynthUniformGO.nif
  BOD2 - Biped Body Template:
    First Person Flags:
      33 - BODY: true
      36 - [U] Torso: true
      37 - [U] L Arm: true
      38 - [U] R Arm: true
      39 - [U] L Leg: true
      40 - [U] R Leg: true
  RNAM - Race: "00013746" #HumanRace "Human" [RACE]
  KSIZ - Keyword Count: 1
  KWDA - Keywords:
    - Keyword: "0007820B" #DogmeatNoVisualsOnRetrieve [KYWD]
```

This is still very much a work in progress, and might produce invalid YAML for some forms.

Works for Fallout4 as well as Skyrim, though I havent tested Skyrim much.
