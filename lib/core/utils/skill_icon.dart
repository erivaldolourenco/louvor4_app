const Map<String, String> skillIconLabels = {
  'ACOUSTIC_GUITAR': 'Violão',
  'ELECTRIC_GUITAR': 'Guitarra',
  'PIANO': 'Piano',
  'KEYBOARD': 'Teclado',
  'DRUMS': 'Bateria',
  'MIC_VOCAL': 'Vocal',
  'BASS_GUITAR': 'Baixo',
  'MUSIC': 'Música',
};

const Map<String, String> skillIconAssets = {
  'ACOUSTIC_GUITAR': 'assets/icons/acoustic-guitar.svg',
  'ELECTRIC_GUITAR': 'assets/icons/electric-guitar.svg',
  'PIANO': 'assets/icons/piano.svg',
  'KEYBOARD': 'assets/icons/keyboard.svg',
  'DRUMS': 'assets/icons/drum.svg',
  'MIC_VOCAL': 'assets/icons/mic-vocal.svg',
  'BASS_GUITAR': 'assets/icons/bass-guitar.svg',
  'MUSIC': 'assets/icons/music.svg',
};

String skillIconAsset(String? iconKey) {
  if (iconKey == null) return 'assets/icons/music.svg';
  return skillIconAssets[iconKey] ?? 'assets/icons/music.svg';
}
