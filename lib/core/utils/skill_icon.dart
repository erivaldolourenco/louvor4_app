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
  'ACOUSTIC_GUITAR': 'assets/icons/skills-icons/acoustic-guitar.svg',
  'ELECTRIC_GUITAR': 'assets/icons/skills-icons/electric-guitar.svg',
  'PIANO': 'assets/icons/skills-icons/piano.svg',
  'KEYBOARD': 'assets/icons/skills-icons/keyboard.svg',
  'DRUMS': 'assets/icons/skills-icons/drum.svg',
  'MIC_VOCAL': 'assets/icons/skills-icons/mic-vocal.svg',
  'BASS_GUITAR': 'assets/icons/skills-icons/bass-guitar.svg',
  'MUSIC': 'assets/icons/music.svg',
};

String skillIconAsset(String? iconKey) {
  if (iconKey == null) return 'assets/icons/music.svg';
  return skillIconAssets[iconKey] ?? 'assets/icons/music.svg';
}
