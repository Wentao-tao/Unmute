# Unmute

Real-time speech transcription app with speaker diarization.

## Features

- 🎤 Real-time audio capture and transcription
- 👥 Speaker diarization (distinguish multiple speakers)
- 🔄 Live transcription with partial results
- 📝 Endpoint detection for natural text segmentation
- 🌐 Powered by Soniox Speech-to-Text API

## Setup

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd unmute
```

### 2. Configure API Keys

The project uses API keys that need to be configured locally:

1. Navigate to the `unmute` directory
2. Copy the template file:
   ```bash
   cp unmute/Secrets.swift.template unmute/Secrets.swift
   ```
3. Open `Secrets.swift` and replace `YOUR_SONIOX_API_KEY_HERE` with your actual Soniox API key
4. **Important:** Never commit `Secrets.swift` to Git (it's already in `.gitignore`)

### 3. Get Your Soniox API Key

1. Sign up at [https://soniox.com/](https://soniox.com/)
2. Navigate to your dashboard
3. Copy your API key
4. Paste it into `Secrets.swift`

### 4. Open in Xcode

```bash
open unmute.xcodeproj
```

### 5. Build and Run

- Select your target device or simulator
- Press `Cmd + R` to build and run

## Project Structure

```
unmute/
├── Services/
│   ├── OnlineTransciberService.swift  # Soniox WebSocket integration
│   └── AvAudioService.swift            # Audio capture
├── ViewModel/
│   └── OnlineViewModel.swift           # Business logic
├── Views/
│   └── TestView.swift                  # UI
├── Model/
│   └── TranscriberModel.swift          # Data model
└── Secrets.swift                       # ⚠️ API keys (not in Git)
```

## Security

- ⚠️ **Never commit API keys to version control**
- The `Secrets.swift` file is excluded from Git via `.gitignore`
- Always use `Secrets.swift.template` as a reference for team members
- If you accidentally commit secrets, immediately revoke and regenerate them

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Soniox API account

## License

[Your License Here]

## Credits

Created by Wentao Guo at Apple Academy.

