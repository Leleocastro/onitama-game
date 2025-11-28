# Sound Assets

Add your audio files in this folder. The code currently expects the following default assets (update the filenames in
`lib/services/audio_service.dart` if you decide to use different names):

Background / ambience loops

- `ambience_temple.mp3`: calm temple ambience for the main menu.
- `ambience_garden.mp3`: zen garden ambience for the in-game screen.
- `bgm_temple_loop.mp3`: slow, meditative temple track used during matches.

Navigation and UI

- `screen_transition.wav`: subtle whoosh for screen transitions.
- `ui_select.wav`: soft bell tap for generic touches.
- `ui_confirm.wav`: light wooden knock for confirmations/buttons.
- `ui_card.wav`: short paper/card slide for card selections.

Piece movement set (any format works, `.wav` recommended)

- `move_1.wav`
- `move_2.wav`
- `move_3.wav`
- `move_4.wav`
- `move_5.wav`

Special cues

- `special_master_move.wav`: quick martial-arts style whoosh when a master piece moves.
- `special_win.wav`: short temple bell for victories.
