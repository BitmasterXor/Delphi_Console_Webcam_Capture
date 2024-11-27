# 📷 Delphi Console App DirectShow Webcam Capture
A minimalist Delphi application that demonstrates how to capture still images from a webcam using DirectShow, without displaying any preview windows. The application silently captures a frame and saves it directly to the desktop.

<p align="center">
  <img src="Preview.png" alt="Preview of webcam capture">
</p>

## 📋 Features
- **Silent Capture**: 
  - Captures webcam frames without displaying any preview windows of any kind.
- **DirectShow Integration**: 
  - Uses native Windows DirectShow for reliable webcam access
  - Implements Sample Grabber for direct frame capture
- **Efficient Processing**:
  - Automatically detects and uses the first available webcam (you can change this if you require ability to choose webcam based on name or index simply look over the code and im sure you will easily figure it out).
  - Optimized for 640x480 24-bit color capture
  - Minimal memory footprint
- **Console Feedback**:
  - Provides clear status updates during the capture process
  - Reports any errors or issues in real-time

## 🔍 Overview
The application follows these steps:
1. Initializes DirectShow
2. Locates the first available webcam
3. Sets up a capture pipeline using Sample Grabber
4. Captures a single frame
5. Converts the frame to BMP format
6. Saves the image to the desktop

## 🛠️ Requirements
### 🔧 Tools and Components
1. **DirectX SDK**:  
   - Required for DirectShow
   - Usually included with Windows SDK
   - Ensure DirectShow9 units are properly referenced in your project

### 📚 Required Units
```pascal
uses
  Winapi.Windows, 
  Winapi.ActiveX, 
  System.SysUtils, 
  DirectShow9, 
  Vcl.Graphics;
```

## 🧩 Usage
1. **Compilation**:
   * Ensure DirectShow9 units are available in your project path
   * Compile the project in Delphi RAD Studio

2. **Running the Application**:
   * Execute the compiled application
   * The program will automatically:
     - Detect your webcam
     - Capture a frame
     - Save it as 'webcam.bmp' on your desktop
   * Console output provides status updates

3. **Console Output Example**:
   ```
   DirectShow Webcam Capture Example By: BitmasterXor
   --------------------------------
   Initializing DirectShow...
   Searching for webcam...
   Webcam found! Setting up capture pipeline...
   Configuring image capture settings...
   Starting video capture...
   Waiting for frame...
   Frame captured, processing image...
   Converting to bitmap format (640x480)...
   Image saved successfully!
   ```

## 🔧 Technical Details
- **Resolution**: Fixed at 640x480
- **Color Depth**: 24-bit RGB
- **Output Format**: BMP
- **Capture Method**: DirectShow Sample Grabber
- **Frame Buffer**: 921,600 bytes (640 * 480 * 3)

## 📜 License
This project is open source and available under the MIT License. Feel free to use it in your own projects.

## 📧 Contact
Discord: bitmasterxor

## 🙏 Acknowledgments
- Thanks to Microsoft for the DirectShow framework
- Special thanks to the Delphi community for their ongoing support

---
**Note**: This project is intended as an educational example of using DirectShow in Delphi. For production use, consider adding error handling and configuration options.

Developed with ❤️ By: BitmasterXor using Delphi RAD Studio
