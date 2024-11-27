program WebcamCapture;
{$APPTYPE CONSOLE}
uses
  Winapi.Windows,system.Classes, Winapi.ActiveX, System.SysUtils, DirectShow9, Vcl.Graphics;

type
  ISampleGrabber = interface(IUnknown)
    ['{6B652FFF-11FE-4FCE-92AD-0266B5D7C78F}']
    function SetOneShot(OneShot: Boolean): HResult; stdcall;
    function SetMediaType(const pmt: TAMMediaType): HResult; stdcall;
    function GetConnectedMediaType(pmt: PAMMediaType): HResult; stdcall;
    function SetBufferSamples(BufferThem: Boolean): HResult; stdcall;
    function GetCurrentBuffer(var pBufferSize: integer; pBuffer: pointer): HResult; stdcall;
    function GetCurrentSample(out ppSample: IMediaSample): HResult; stdcall;
    function SetCallback(pCallback: IUnknown; WhichMethod: integer): HResult; stdcall;
  end;


  function GetAvailableCameras: TStringList;
var
  SysEnum: ICreateDevEnum;
  EnumMon: IEnumMoniker;
  Moniker: IMoniker;
  Fetched: ULONG;
  PropBag: IPropertyBag;
  CamName: OleVariant;
begin
  Result := TStringList.Create;
  try
    WriteLn('Enumerating available cameras...');
    CoCreateInstance(CLSID_SystemDeviceEnum, nil, CLSCTX_INPROC, ICreateDevEnum, SysEnum);
    SysEnum.CreateClassEnumerator(CLSID_VideoInputDeviceCategory, EnumMon, 0);

    if EnumMon = nil then
    begin
      WriteLn('No video capture devices found.');
      Exit;
    end;

    while EnumMon.Next(1, Moniker, @Fetched) = S_OK do
    begin
      // Get the property bag from the moniker
      if Succeeded(Moniker.BindToStorage(nil, nil, IPropertyBag, PropBag)) then
      begin
        // Get the friendly name of the device
        if Succeeded(PropBag.Read('FriendlyName', CamName, nil)) then
        begin
          Result.Add(string(CamName));
        end;
      end;
    end;

    if Result.Count > 0 then
    begin
      WriteLn('Found ', Result.Count, ' camera(s):');
      for var i := 0 to Result.Count - 1 do
      //  WriteLn(Format('[%d] %s', [i, Result[i]]));
    end
    else
      WriteLn('No cameras found.');

  except
    on E: Exception do
    begin
      WriteLn('Error enumerating cameras: ', E.Message);
      Result.Free;
      Result := nil;
    end;
  end;
end;

function CaptureImage(const SavePath: string; CameraIndex: Integer = 0): Boolean;
var
  GB: IGraphBuilder;
  CGB2: ICaptureGraphBuilder2;
  VideoInput, SGFilter, NullRender: IBaseFilter;
  SG: ISampleGrabber;
  MC: IMediaControl;
  mt: TAMMediaType;
  Buffer: array of Byte;
  BufSize: Integer;
  Bitmap: TBitmap;
  SysEnum: ICreateDevEnum;
  EnumMon: IEnumMoniker;
  Moniker: IMoniker;
  Fetched: ULONG;
  CurrentIndex: Integer;
  Cameras: TStringList;
begin
  Result := False;
  WriteLn('Initializing DirectShow components...');
  CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC, IGraphBuilder, GB);
  CoCreateInstance(CLSID_CaptureGraphBuilder2, nil, CLSCTX_INPROC, ICaptureGraphBuilder2, CGB2);
  CGB2.SetFiltergraph(GB);

  WriteLn('Searching for webcam index ', CameraIndex, '...');
  CoCreateInstance(CLSID_SystemDeviceEnum, nil, CLSCTX_INPROC, ICreateDevEnum, SysEnum);
  SysEnum.CreateClassEnumerator(CLSID_VideoInputDeviceCategory, EnumMon, 0);

  if EnumMon = nil then
  begin
    WriteLn('Error: No video capture devices found.');
    Exit;
  end;

  CurrentIndex := 0;
  while EnumMon.Next(1, Moniker, @Fetched) = S_OK do
  begin
    if CurrentIndex = CameraIndex then
    begin
      WriteLn('Found requested camera! Setting up capture pipeline...');
      Moniker.BindToObject(nil, nil, IBaseFilter, VideoInput);
      GB.AddFilter(VideoInput, 'Video');

      WriteLn('Configuring image capture settings...');
      CoCreateInstance(CLSID_SampleGrabber, nil, CLSCTX_INPROC, IBaseFilter, SGFilter);
      GB.AddFilter(SGFilter, 'Grab');
      SGFilter.QueryInterface(ISampleGrabber, SG);

      FillChar(mt, SizeOf(mt), 0);
      mt.majortype := MEDIATYPE_Video;
      mt.subtype := MEDIASUBTYPE_RGB24;
      SG.SetMediaType(mt);
      SG.SetOneShot(True);
      SG.SetBufferSamples(True);

      CoCreateInstance(CLSID_NullRenderer, nil, CLSCTX_INPROC, IBaseFilter, NullRender);
      GB.AddFilter(NullRender, 'Null');

      WriteLn('Starting video capture...');
      CGB2.RenderStream(@PIN_CATEGORY_PREVIEW, @MEDIATYPE_Video, VideoInput, SGFilter, NullRender);
      GB.QueryInterface(IMediaControl, MC);
      MC.Run;

      WriteLn('Waiting for frame...');
      while True do
      begin
        BufSize := 0;
        if Succeeded(SG.GetCurrentBuffer(BufSize, nil)) and (BufSize > 0) then Break;
        Sleep(100);
      end;

      WriteLn('Frame captured, processing image...');
      SetLength(Buffer, BufSize);
      SG.GetCurrentBuffer(BufSize, @Buffer[0]);
      MC.Stop;

      Bitmap := TBitmap.Create;
      try
        WriteLn('Converting to bitmap format (640x480)...');
        Bitmap.PixelFormat := pf24bit;
        Bitmap.Width := 640;
        Bitmap.Height := 480;

        for var y := 0 to 479 do
        begin
          Move(Buffer[y * 1920], Bitmap.ScanLine[479 - y]^, 1920);
        end;

        WriteLn('Saving image to: ', SavePath);
        Bitmap.SaveToFile(SavePath);
        Result := True;
        WriteLn('Image saved successfully!');
      finally
        Bitmap.Free;
      end;

      Exit;
    end;
    Inc(CurrentIndex);
  end;

  WriteLn('Error: Camera index ', CameraIndex, ' not found!');
end;

var
  Cameras: TStringList;
  I: Integer;
begin
WriteLn('DirectShow Webcam Capture Example By: BitmasterXor');
  WriteLn('--------------------------------');
  WriteLn('This example demonstrates capturing a single frame from a webcam');
  WriteLn('using DirectShow and saving it as a bitmap file.');
  WriteLn;

  CoInitialize(nil);  // Initialize COM
  try
    Cameras := GetAvailableCameras;
    try
      if (Cameras <> nil) and (Cameras.Count > 0) then
      begin
        for I := 0 to Cameras.Count - 1 do
        begin
          WriteLn('Camera Name:',Cameras[I]);
        end;
      end else
        WriteLn('No camera devices found.');
    finally
      WriteLn('----------------------------------');
    end;
  CaptureImage(IncludeTrailingPathDelimiter(GetEnvironmentVariable('USERPROFILE')) + 'Desktop\webcam.bmp',0); // << guys the 0 represends the cameras index so lets say you have 2 cameras one would be index 0 and the next 1 see.. Super simple :)
  //In this example i have put the camera index to 0 .... so Your first / Default camera which you should have plugged in via USB or whatever to your PC.
   Cameras.Free;
  finally
    CoUninitialize;
  end;
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
