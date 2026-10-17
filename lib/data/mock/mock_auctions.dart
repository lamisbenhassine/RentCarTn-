import '../models/auction.dart';
import '../models/car.dart';
import 'mock_images.dart';

/// Enchères simulées sur les véhicules sortis de la flotte de location.
class MockAuctions {
  MockAuctions._();

  /// Pseudonymes publics utilisés par le panneau de simulation.
  static const List<String> pseudos = [
    'Amine_TN',
    'SouhaDrive',
    'KarimSfax',
    'MehdiAuto',
    'LinaHammamet',
    'TarekBiz',
    'Yassine_92',
    'NaderDjerba',
    'RymTunis',
    'GarageElManar',
  ];

  static DateTime _in({int days = 0, int hours = 0, int minutes = 0}) =>
      DateTime.now().add(
        Duration(days: days, hours: hours, minutes: minutes),
      );

  static DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) =>
      DateTime.now().subtract(
        Duration(days: days, hours: hours, minutes: minutes),
      );

  static List<Auction> build() => [
    Auction(
      id: 'auc-01',
      brand: 'Volkswagen',
      model: 'Golf 7',
      year: 2017,
      mileage: 148000,
      condition: VehicleCondition.bon,
      description:
          "Golf 7 1.6 TDI issue de notre flotte de Tunis. Entretien réalisé "
          "exclusivement en atelier agréé, carnet complet. Quelques rayures "
          "d'usage sur le pare-chocs arrière, mécanique saine.",
      images: [Img.sedanGrey, Img.driving, Img.engineBay],
      startingPrice: 24000,
      minIncrement: 500,
      startAt: _ago(days: 2),
      endAt: _in(hours: 6, minutes: 40),
      city: 'Tunis',
      fuel: FuelType.diesel,
      transmission: Transmission.manuelle,
      reservePrice: 27000,
      inspectionNotes: [
        'Distribution remplacée à 140 000 km',
        'Pneus avant neufs (mars 2026)',
        'Climatisation fonctionnelle',
        'Rayures légères sur bouclier arrière',
      ],
      bids: [
        Bid(
          id: 'b-01-1',
          auctionId: 'auc-01',
          bidderName: 'Amine_TN',
          amount: 24500,
          date: _ago(days: 1, hours: 20),
        ),
        Bid(
          id: 'b-01-2',
          auctionId: 'auc-01',
          bidderName: 'KarimSfax',
          amount: 25500,
          date: _ago(days: 1, hours: 4),
        ),
        Bid(
          id: 'b-01-3',
          auctionId: 'auc-01',
          bidderName: 'Vous',
          amount: 26500,
          date: _ago(hours: 9),
          isCurrentUser: true,
        ),
        Bid(
          id: 'b-01-4',
          auctionId: 'auc-01',
          bidderName: 'MehdiAuto',
          amount: 27500,
          date: _ago(hours: 2),
        ),
      ],
    ),
    Auction(
      id: 'auc-02',
      brand: 'Renault',
      model: 'Clio 4',
      year: 2016,
      mileage: 192000,
      condition: VehicleCondition.moyen,
      description:
          "Citadine de l'agence de Sousse, idéale comme première voiture ou "
          "pour un usage urbain. Kilométrage élevé mais moteur 1.5 dCi "
          "réputé endurant.",
      images: [Img.cityCarBlue, Img.driving],
      startingPrice: 13500,
      minIncrement: 300,
      startAt: _ago(days: 3),
      endAt: _in(days: 1, hours: 3),
      city: 'Sousse',
      fuel: FuelType.diesel,
      transmission: Transmission.manuelle,
      inspectionNotes: [
        'Embrayage à prévoir',
        'Carrosserie : impact portière conducteur',
        'Visite technique valide 8 mois',
      ],
      bids: [
        Bid(
          id: 'b-02-1',
          auctionId: 'auc-02',
          bidderName: 'Yassine_92',
          amount: 13800,
          date: _ago(days: 2, hours: 6),
        ),
        Bid(
          id: 'b-02-2',
          auctionId: 'auc-02',
          bidderName: 'Vous',
          amount: 14400,
          date: _ago(hours: 30),
          isCurrentUser: true,
        ),
      ],
    ),
    Auction(
      id: 'auc-03',
      brand: 'Toyota',
      model: 'Hilux Double Cabine',
      year: 2018,
      mileage: 211000,
      condition: VehicleCondition.bon,
      description:
          "Pick-up utilisé pour nos excursions désert au départ de Tozeur. "
          "Révisé tous les 10 000 km, châssis traité anti-corrosion.",
      images: [Img.pickupBlue, Img.suvDesert, Img.engineBay],
      startingPrice: 52000,
      minIncrement: 1000,
      startAt: _ago(days: 1),
      endAt: _in(days: 3, hours: 5),
      city: 'Tozeur',
      fuel: FuelType.diesel,
      transmission: Transmission.manuelle,
      reservePrice: 58000,
      inspectionNotes: [
        'Boîte de transfert 4x4 opérationnelle',
        'Benne équipée d\'un hard-top',
        'Amortisseurs renforcés remplacés en 2025',
      ],
      bids: [
        Bid(
          id: 'b-03-1',
          auctionId: 'auc-03',
          bidderName: 'GarageElManar',
          amount: 53000,
          date: _ago(hours: 18),
        ),
        Bid(
          id: 'b-03-2',
          auctionId: 'auc-03',
          bidderName: 'NaderDjerba',
          amount: 55000,
          date: _ago(hours: 5),
        ),
      ],
    ),
    Auction(
      id: 'auc-04',
      brand: 'Peugeot',
      model: '301',
      year: 2019,
      mileage: 134000,
      condition: VehicleCondition.excellent,
      description:
          "Berline tricorps très bien entretenue, utilisée uniquement pour "
          "les transferts aéroport. Intérieur impeccable, aucun sinistre.",
      images: [Img.sedanBlack, Img.driving],
      startingPrice: 29000,
      minIncrement: 500,
      startAt: _ago(hours: 20),
      endAt: _in(minutes: 48),
      city: 'Tunis',
      fuel: FuelType.diesel,
      transmission: Transmission.manuelle,
      inspectionNotes: [
        'Aucun sinistre déclaré',
        'Révision complète effectuée avant mise en vente',
        'Quatre pneus récents',
      ],
      bids: [
        Bid(
          id: 'b-04-1',
          auctionId: 'auc-04',
          bidderName: 'RymTunis',
          amount: 29500,
          date: _ago(hours: 12),
        ),
        Bid(
          id: 'b-04-2',
          auctionId: 'auc-04',
          bidderName: 'TarekBiz',
          amount: 30500,
          date: _ago(hours: 3),
        ),
        Bid(
          id: 'b-04-3',
          auctionId: 'auc-04',
          bidderName: 'Vous',
          amount: 31500,
          date: _ago(minutes: 40),
          isCurrentUser: true,
        ),
      ],
    ),
    Auction(
      id: 'auc-05',
      brand: 'Dacia',
      model: 'Duster',
      year: 2017,
      mileage: 176000,
      condition: VehicleCondition.moyen,
      description:
          "SUV compact robuste ayant servi sur nos liaisons intérieures. "
          "Quelques traces d'usage, mécanique fiable.",
      images: [Img.suvTeal, Img.engineBay],
      startingPrice: 21000,
      minIncrement: 500,
      startAt: _ago(days: 4),
      endAt: _in(days: 5, hours: 2),
      city: 'Sfax',
      fuel: FuelType.diesel,
      transmission: Transmission.manuelle,
      inspectionNotes: [
        'Suspension arrière à contrôler',
        'Peinture ternie sur le toit',
        'Moteur 1.5 dCi sans fuite',
      ],
      bids: [],
    ),
    Auction(
      id: 'auc-06',
      brand: 'Citroën',
      model: 'Berlingo',
      year: 2015,
      mileage: 243000,
      condition: VehicleCondition.aRenover,
      description:
          "Utilitaire de service en fin de vie, vendu en l'état. Convient "
          "pour pièces ou pour une remise en état par un professionnel.",
      images: [Img.coupeDark, Img.engineBay],
      startingPrice: 7500,
      minIncrement: 250,
      startAt: _ago(days: 6),
      endAt: _in(days: 2, hours: 9),
      city: 'Bizerte',
      fuel: FuelType.diesel,
      transmission: Transmission.manuelle,
      inspectionNotes: [
        'Vendu en l\'état, sans garantie',
        'Embrayage HS',
        'Corrosion sur bas de caisse',
      ],
      bids: [
        Bid(
          id: 'b-06-1',
          auctionId: 'auc-06',
          bidderName: 'GarageElManar',
          amount: 7750,
          date: _ago(days: 1),
        ),
      ],
    ),
    Auction(
      id: 'auc-07',
      brand: 'Seat',
      model: 'Leon ST',
      year: 2018,
      mileage: 159000,
      condition: VehicleCondition.bon,
      description:
          "Break familial sorti de la flotte d'Hammamet. Grand coffre, "
          "entretien suivi, prêt à rouler.",
      images: [Img.wagonBlack, Img.driving],
      startingPrice: 26500,
      minIncrement: 500,
      startAt: _in(days: 2),
      endAt: _in(days: 9),
      city: 'Hammamet',
      fuel: FuelType.diesel,
      transmission: Transmission.automatique,
      inspectionNotes: [
        'Boîte DSG révisée',
        'Vitres teintées homologuées',
      ],
      bids: [],
    ),
    Auction(
      id: 'auc-08',
      brand: 'Ford',
      model: 'Fiesta',
      year: 2016,
      mileage: 167000,
      condition: VehicleCondition.bon,
      description:
          "Citadine agréable à conduire, vendue à l'issue de son cycle de "
          "location. Enchère clôturée — exemple de vente réussie.",
      images: [Img.coupeRed, Img.driving],
      startingPrice: 15000,
      minIncrement: 300,
      startAt: _ago(days: 10),
      endAt: _ago(days: 2),
      city: 'Monastir',
      fuel: FuelType.essence,
      transmission: Transmission.manuelle,
      inspectionNotes: ['Véhicule livré avec double des clés'],
      bids: [
        Bid(
          id: 'b-08-1',
          auctionId: 'auc-08',
          bidderName: 'LinaHammamet',
          amount: 15300,
          date: _ago(days: 6),
        ),
        Bid(
          id: 'b-08-2',
          auctionId: 'auc-08',
          bidderName: 'Vous',
          amount: 16200,
          date: _ago(days: 4),
          isCurrentUser: true,
        ),
      ],
    ),
    Auction(
      id: 'auc-09',
      brand: 'Opel',
      model: 'Corsa',
      year: 2015,
      mileage: 198000,
      condition: VehicleCondition.moyen,
      description:
          "Petite citadine clôturée sans enchère atteignant le prix de "
          "départ. Sera remise en vente prochainement.",
      images: [Img.coupeBlue, Img.driving],
      startingPrice: 11000,
      minIncrement: 250,
      startAt: _ago(days: 12),
      endAt: _ago(days: 5),
      city: 'Nabeul',
      fuel: FuelType.essence,
      transmission: Transmission.manuelle,
      inspectionNotes: ['Aucune offre reçue lors de la première mise en vente'],
      bids: [],
    ),
    Auction(
      id: 'auc-10',
      brand: 'Hyundai',
      model: 'i10',
      year: 2019,
      mileage: 121000,
      condition: VehicleCondition.excellent,
      description:
          "Mini-citadine en excellent état, parfaite pour la ville. Enchère "
          "remportée par un autre acheteur — illustre le statut « Perdue ».",
      images: [Img.cityCarBlue, Img.driving],
      startingPrice: 17000,
      minIncrement: 300,
      startAt: _ago(days: 9),
      endAt: _ago(days: 1),
      city: 'Ariana',
      fuel: FuelType.essence,
      transmission: Transmission.manuelle,
      inspectionNotes: ['Entretien constructeur à jour'],
      bids: [
        Bid(
          id: 'b-10-1',
          auctionId: 'auc-10',
          bidderName: 'Vous',
          amount: 17600,
          date: _ago(days: 5),
          isCurrentUser: true,
        ),
        Bid(
          id: 'b-10-2',
          auctionId: 'auc-10',
          bidderName: 'SouhaDrive',
          amount: 18500,
          date: _ago(days: 3),
        ),
      ],
    ),
  ];
}
