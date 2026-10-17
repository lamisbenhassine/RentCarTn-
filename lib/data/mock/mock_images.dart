/// Sources d'images distantes (Unsplash) utilisées par les données simulées.
///
/// Les photos sont génériques et choisies par type de carrosserie : elles
/// illustrent la catégorie du véhicule, pas le modèle exact. Chaque image a un
/// repli local dessiné en cas d'échec réseau (voir `CarImage`).
class Img {
  Img._();

  static String u(String id, {int w = 1200}) =>
      'https://images.unsplash.com/photo-$id?auto=format&fit=crop&w=$w&q=80';

  // Citadines et compactes
  static final cityCarBlue = u('1549317661-bd32c8ce0db2');
  static final coupeRed = u('1549399542-7e3f8b79c341');
  static final coupeBlue = u('1502877338535-766e1452684a');
  static final coupeDark = u('1494905998402-395d579af36f');

  // Berlines
  static final sedanWhite = u('1555215695-3004980ad54e');
  static final sedanTeal = u('1580273916550-e323be2ae537');
  static final sedanGrey = u('1621007947382-bb3c3994e3fb');
  static final sedanBlack = u('1485291571150-772bcfc10da5');
  static final sedanRed = u('1532974297617-c0f05fe48bff');

  // SUV, breaks et utilitaires
  static final suvWhite = u('1519641471654-76ce0107ad1b');
  static final suvTeal = u('1541899481282-d53bffe3c35d');
  static final suvDesert = u('1533473359331-0135ef1b58bf');
  static final wagonBlack = u('1606664515524-ed2f786a0bd6');
  static final pickupBlue = u('1551830820-330a71b99659');

  // Luxe et sport
  static final luxuryPorsche = u('1503376780353-7e6692767b70');
  static final sportBlue = u('1552519507-da3b142c6e3d');
  static final supercarRed = u('1583121274602-3e2820c69888');
  static final supercarYellow = u('1511919884226-fd3cad34687c');
  static final supercarWhite = u('1542362567-b07e54358753');
  static final supercarSilver = u('1617654112368-307921291f42');
  static final supercarOrange = u('1612825173281-9a193378527e');

  // Électriques
  static final evWhite = u('1617788138017-80ad40651399');
  static final evPlug = u('1593941707882-a5bba14938c7');

  // Détails et ambiances
  static final driving = u('1449965408869-eaa3f722e40d');
  static final engineBay = u('1486262715619-67b85e0b08d3');
  static final scenicRoad = u('1568605117036-5fe5e7bab0b7');
  static final roadDesert = u('1469854523086-cc02fe5d8800');
  static final coastRoad = u('1507525428034-b723cf961d3e');
}
