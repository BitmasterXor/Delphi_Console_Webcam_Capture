program WebcamCapture;
{$APPTYPE CONSOLE}
uses
  Winapi.Windows, Winapi.ActiveX, System.SysUtils, DirectShow9, Vcl.Graphics;

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

function CaptureImage(const SavePath: string): Boolean;
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
begin
  Result := False;
  WriteLn('Initializing DirectShow components...');
  CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC, IGraphBuilder, GB);
  CoCreateInstance(CLSID_CaptureGraphBuilder2, nil, CLSCTX_INPROC, ICaptureGraphBuilder2, CGB2);
  CGB2.SetFiltergraph(GB);

  WriteLn('Searching for webcam...');
  CoCreateInstance(CLSID_SystemDeviceEnum, nil, CLSCTX_INPROC, ICreateDevEnum, SysEnum);
  SysEnum.CreateClassEnumerator(CLSID_VideoInputDeviceCategory, EnumMon, 0);
  if (EnumMon <> nil) and (EnumMon.Next(1, Moniker, @Fetched) = S_OK) then
  begin
    WriteLn('Webcam found! Setting up capture pipeline...');
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
  end
  else
    WriteLn('Error: No webcam found!');
end;

begin
  WriteLn('DirectShow Webcam Capture Example By: BitmasterXor');
  WriteLn('--------------------------------');
  WriteLn('This example demonstrates capturing a single frame from a webcam');
  WriteLn('using DirectShow and saving it as a bitmap file.');
  WriteLn;

  CoInitialize(nil);
  try
    CaptureImage(IncludeTrailingPathDelimiter(GetEnvironmentVariable('USERPROFILE')) + 'Desktop\webcam.bmp');
  finally
    CoUninitialize;
  end;

  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.