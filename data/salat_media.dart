import 'package:sajda/models/salat_course.dart';

class SalatMediaRepository {
  // Stable, curated photo URLs per position (generated)
  static final Map<SalatStepType, List<String>> stepImages = {
    SalatStepType.standing: [
      'assets/images/Takbir_prayer_standing_hands_raised_green_1761734513655.jpg',
      'assets/images/Muslim_prayer_qiyam_hands_folded_chest_white_1761734518393.jpg',
      'assets/images/Muslim_prayer_standing_after_bowing_hands_down_green_1761734535116.jpg',
      'assets/images/Muslim_prayer_dua_istiftah_hands_raised_turquoise_1761734556405.jpg',
      'https://pixabay.com/get/g64f022dc3c221e6b145e193834e37d341356c61240f064a6061d480b1d4d4f91b8aaec2731e5ffd8877b6b52d969f23ddcea8489e7de2699e9bd21be2a98b570_1280.jpg',
      'https://pixabay.com/get/g3c85248365fe12fec159759baf8ef16206030e90c2884c4e95e3ca84d1f70f210858a7b8af9e04ded25c184b2547ccadf67ae5bce1641831bd12f4f1c952ea7e_1280.jpg',
      'https://pixabay.com/get/g67a82f63000a45c92e5e7c82c68b124d7c5c518b214e169a43442e00e961e337b4b4f79984798276060b77e227f50f54f339d1808441ca80874c3fe93d383a97_1280.jpg',
    ],
    SalatStepType.bowing: [
      // Rukûʼ: dos droit, mains sur les genoux
      'https://pixabay.com/get/g0c4671295bc0bbd82f1464b0cf4ac9df352b8994e7cf68abf5ab828c0ecfbed30f6b17008bca14bf73384cf7a984c0643d34d70a3b1c3d488708b425e79c42f0_1280.jpg',
      'https://pixabay.com/get/g596f7953f8a7bc0cd67d1c3898613080cd52684995f767cb2b475a1f14999f0a8c252a214e4f464a6e09ecde7dc0b3d65fbaae7eb6771f9de2d9e40db7f01785_1280.jpg',
      'https://pixabay.com/get/g2c3a83d03ccc5cc2d96939b4283b9c9b6b0a680775faf301cc0e619b2c297c01890c084b42b4aa82d9c117f6fee3b62add3cf431bf1c4ee6ec8e1dee1bd50a74_1280.jpg',
    ],
    SalatStepType.prostration: [
      'assets/images/Muslim_prayer_sujud_prostration_carpet_brown_1761734538664.jpg',
      'https://pixabay.com/get/gc2f73bcdc69ee8c91af25c9e9518d20cc6cfefe36ca0c9b7a69205b7b79bf24dde74bc67644f418d0425af2de32935d138e8cacc91e3fc92d992eff398448c59_1280.jpg',
      'https://pixabay.com/get/g42f40743fead50c49f717ff1f50cacfe3d587116ae1a49378532892fc9d99a2af8dfe1f56d263702bfaebbccb75488548ffc9f6553fe5edd37d1a06cd9caae22_1280.jpg',
      'https://pixabay.com/get/g4ee36e511636726fab8f94fc2e3aba7087d9b7d5e8731b9daddbd3246fde7dbdaaed095b98d88b2f31aa9c06d611b6bc46213357aa665bccff654b0f097e88be_1280.jpg',
    ],
    SalatStepType.sitting: [
      // Julûs: assise entre deux prosternations / Tashahhud (index levé)
      'https://pixabay.com/get/g516265aaecb5d6398e71f9444744ad184517ef2523ef8c0358935175664f412ddf0ae91477739a64dce11a1a8baa4c2c1a201e1f13299e25d0954db6d1a9043e_1280.jpg',
      'https://pixabay.com/get/ga3cc7e72e3eec2c504f26261f486dac509490f32c5b90b7389fc9bd63feae20883b0f4f7e828b5c77a3bbd58f2d543bf910ab98ede37c89cb45f7cb313d7fa92_1280.jpg',
      'https://pixabay.com/get/gd06c1a8dd0bd969d6bae28d1e999542577ea9401b5be66352578a7c1903920a2d9b53a72ca6c0b8104402a592c075af5d60929155f5e41329a61d7fff8eea65f_1280.jpg',
    ],
  };
}
