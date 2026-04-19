# Kevin Voice Expression Implementation

## Overview
Kevin now features emotionally expressive voice responses using ElevenLabs' eleven_v3 model with Audio Tags support. The AI dynamically adds emotional cues, delivery directions, and natural reactions to create human-like conversations.

## Key Features

### 1. **Dual System Prompts**
- **Text Mode**: Standard responses without audio tags
- **Voice Mode**: Responses enriched with ElevenLabs Audio Tags for emotional expression

### 2. **Audio Tags Support**
Kevin's AI uses square-bracketed tags to control voice delivery:

**Emotion Tags:**
- `[excited]`, `[sad]`, `[angry]`, `[happily]`, `[sorrowful]`, `[tired]`, `[awe]`, `[dramatic tone]`

**Delivery Tags:**
- `[whispers]`, `[shouts]`, `[sighs]`, `[clears throat]`, `[pause]`, `[rushed]`, `[drawn out]`

**Reaction Tags:**
- `[laughs]`, `[giggles]`, `[chuckles]`, `[gasps]`, `[groans]`

**Accent Tags:**
- `[American accent]`, `[British accent]`, `[Australian accent]`, etc.

### 3. **Context-Aware Voice Selection**
The system automatically selects the most appropriate voice based on conversation context:

| Context | Voice | Character | Use Case |
|---------|-------|-----------|----------|
| Conversational | Rachel | Calm, personable woman | Casual chat, general queries |
| Narration | Adam | Deep, authoritative male | Storytelling, descriptions |
| News | Drew | Well-rounded male | Factual information, announcements |
| Meditation | Emily | Calm, soothing female | Relaxation, calming responses |
| Video Games | Clyde | War veteran, hoarse | Energetic, character-like |
| Audiobook | Matilda | Warm, expressive female | Long-form reading |
| Children | Gigi | Childish, enthusiastic | Playful, simple responses |
| Dramatic | George | Raspy, intense male | Theatrical, emotional delivery |

### 4. **Intelligent Tag Stripping**
- Voice mode: Full tagged text sent to ElevenLabs TTS
- Text mode: Tags automatically stripped for clean display
- Display bubbles: Show clean text without tags

## Example Responses

### Scary Story Request
**User:** "Tell me a scary story"

**AI Response (Voice Mode):**
```
[whispers] In the ancient ruins of Eldoria, [pause] where shadows dance and secrets hide, [dramatic tone] lived a creature no one dared to name. [gasps] Even the bravest warriors [pause] fell silent when it stirred.
```

**Voice:** George (Dramatic context)
**Result:** Whispered opening, dramatic pauses, gasps for effect

### Weather Query
**User:** "How's the weather today?"

**AI Response (Voice Mode):**
```
[cheerfully] Let me check that for you! [pause] It looks like it's a beautiful sunny day outside. [excited] Perfect weather for a walk!
```

**Voice:** Rachel (Conversational context)
**Result:** Cheerful, upbeat delivery with natural enthusiasm

### Emotional Support
**User:** "I'm feeling sad"

**AI Response (Voice Mode):**
```
[softly] I'm sorry to hear you're feeling down. [pause] [warmly] Remember that it's okay to feel this way sometimes. [gently] Would you like to talk about what's bothering you, or would you prefer a distraction?
```

**Voice:** Emily (Meditation context)
**Result:** Soft, warm, comforting tone

### OS Action
**User:** "Open Spotify"

**AI Response (Voice Mode):**
```
[happily] Opening Spotify for you right now! [excited] Time for some great music!
```

**Voice:** Rachel (Conversational context)
**Result:** Happy, energetic confirmation

## Technical Implementation

### Files Modified/Created

1. **`lib/services/ai_engine.dart`**
   - Added `isVoiceMode` parameter to `process()` method
   - Created `_voiceSystemPrompt` with detailed audio tag instructions
   - Added `VoiceContext` parsing

2. **`lib/core/models/ai_response.dart`**
   - Added `VoiceContext` enum
   - Added `voiceContext` field to `AIResponse`

3. **`lib/services/voice_selector.dart`** (NEW)
   - Maps `VoiceContext` to ElevenLabs voice IDs
   - Provides `stripAudioTags()` utility
   - Documents all 8 premade voices

4. **`lib/services/elevenlabs_client.dart`**
   - Updated to use `eleven_v3` model
   - Added `language_code: 'en'` parameter

5. **`lib/features/chat/conversation_screen.dart`**
   - Passes `isVoiceMode` to AI Engine
   - Uses `VoiceSelector` for voice selection
   - Strips tags for text display

## ElevenLabs Voice IDs Reference

```dart
Rachel (Conversational):    21m00Tcm4TlvDq8ikWAM
Adam (Narration):           pNInz6obpgDQGcFmaJgB
Drew (News):                29vD33N1CtxCmqQRPOHJ
Emily (Meditation):         LcfcDJNUP1GQjkzn1xUU
Clyde (Video Games):        2EiwWnXFnvU5JabPnv8n
Matilda (Audiobook):        XrExE9yKIg1WjnnlVkGX
Gigi (Children):            jBpfuIE2acCO8z3wKNLl
George (Dramatic):          JBFqnCBsd6RMkjVDRZzb
```

## Usage

### For Users
1. Toggle Response Mode to "Voice" in the app
2. Ask Kevin anything - the AI will automatically:
   - Select the appropriate voice for the context
   - Add emotional expressions where natural
   - Deliver responses with human-like intonation

### For Developers
```dart
// AI Engine automatically handles voice mode
final response = await aiEngine.process(
  userText,
  isVoiceMode: true, // Enables audio tags
);

// Voice selection is automatic based on context
final voiceId = VoiceSelector.selectVoice(response.voiceContext);

// Strip tags for text display
final displayText = VoiceSelector.stripAudioTags(response.responseText);
```

## Benefits

1. **Natural Conversations**: Emotional cues make Kevin feel more human
2. **Context Awareness**: Voice automatically matches the situation
3. **Expressive Storytelling**: Perfect for reading stories, jokes, or dramatic content
4. **Emotional Intelligence**: Responds with appropriate tone to user's mood
5. **Seamless Fallback**: Text mode strips tags automatically

## Future Enhancements

- User-selectable voice preferences
- Custom voice cloning support
- Multi-language audio tag support
- Voice emotion intensity controls
- Real-time emotion detection from user input
