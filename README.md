# Kairii - Your Personal AI Assistant

Kairii is an intelligent, voice-activated assistant built with Flutter and powered by Google's Gemini API. It is designed to understand natural language commands in both English and Hinglish (Hindi-English mix) to perform a wide range of tasks on your device hands-free.

## Features

- **Natural Language Understanding**: Powered by Gemini 1.5 Pro, Kairii understands complex intent and context.
- **Voice & Text Interaction**: Command your assistant using voice or typing.
- **Hinglish Support**: Native understanding of Indian users' conversational style (e.g., _"Kal ka plan batao"_).
- **Smart Actions**:
  - **Calls**: "Call [Name]" - Searches contacts and initiates calls.
  - **Payments**: "Pay [Amount]" - Scans UPI QR codes and extracts payment details.
  - **Web Search**:
    - "Search google for [query]"
    - "Search youtube for [query]"
  - **App Integration**:
    - Open common apps: YouTube, Maps, Gmail, Calendar, Calculator, Settings, Camera, Gallery.
  - **Calendar Management**:
    - "Add event [details]" - Smartly parses date, time, and title.
    - "View calendar for [date]" - Checks your schedule.
- **Floating Access**: Accessible from anywhere on your device via a floating widget.

## Getting Started

### Prerequisites

- Flutter SDK: `^3.7.0`
- Dart SDK: Compatible version

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/swayam-kothekar/ai-assistant.git
    cd ai-assistant
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Configure API Key:**
    - Get your API key from [Google AI Studio](https://aistudio.google.com/).
    - Open `lib/services/search_service.dart`.
    - Locate the `GeminiService` class and replace the empty `apiKey` string:
      ```dart
      final String apiKey = 'YOUR_GEMINI_API_KEY_HERE';
      ```

4.  **Run the app:**
    ```bash
    flutter run
    ```

## Usage

Tap the microphone icon or the floating widget and say a command:

- _"Call Rahul"_
- _"Pay 100 rupees"_ (Opens scanner)
- _"Open YouTube and search for Flutter tutorials"_
- _"Kal meeting hai boss ke saath at 10 AM"_ (Adds to calendar)
- _"Aaj ka plan batao"_ (Shows today's calendar)
- _"Open settings"_

## Permissions

The app requires the following permissions to function correctly:

- Microphone (for voice commands)
- Contacts (to find and call people)
- Phone (to initiate calls)
- Camera (for QR code scanning)
- Internet (for Gemini API and search)

## Tech Stack

- **Framework**: Flutter
- **AI Model**: Google Gemini 1.5 Pro
- **Plugins**:
  - `speech_to_text`: Voice recognition
  - `flutter_tts`: Text-to-speech feedback
  - `http`: API requests
  - `flutter_contacts`: Contact access
  - `mobile_scanner`: QR code scanning
  - `url_launcher` & `android_intent_plus`: App launching and intents
