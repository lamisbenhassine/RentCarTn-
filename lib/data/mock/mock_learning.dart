import 'package:flutter/material.dart';

import '../models/learning.dart';

/// Contenu pédagogique du module « Code de la route ».
///
/// Avertissement : ces contenus sont fournis à titre informatif pour une
/// démonstration. Ils ne remplacent pas le Code de la route tunisien officiel
/// et ne délivrent aucun permis ni certificat.
class MockLearning {
  MockLearning._();

  static const String disclaimer =
      "Contenu pédagogique de démonstration. Les règles présentées doivent "
      "être vérifiées auprès des textes officiels tunisiens en vigueur "
      "(Code de la route, Journal Officiel de la République Tunisienne). "
      "Ce module ne délivre aucun permis ni certificat officiel.";

  // ---------------------------------------------------------------- Panneaux

  static const List<RoadSign> signs = [
    // Danger
    RoadSign(
      id: 'sg-01',
      name: 'Virage dangereux à droite',
      category: SignCategory.danger,
      shape: SignShape.triangle,
      glyph: '⤷',
      meaning:
          "Annonce un virage serré vers la droite situé à faible distance.",
      advice:
          "Ralentissez avant d'aborder le virage, jamais pendant. Fréquent "
          "sur les routes de montagne vers Aïn Draham ou Zaghouan.",
    ),
    RoadSign(
      id: 'sg-02',
      name: 'Chaussée glissante',
      category: SignCategory.danger,
      shape: SignShape.triangle,
      glyph: '〰',
      meaning: "La chaussée peut devenir glissante, notamment par temps de pluie.",
      advice:
          "Les premières pluies d'automne rendent l'asphalte très glissant en "
          "Tunisie. Augmentez vos distances de sécurité.",
    ),
    RoadSign(
      id: 'sg-03',
      name: 'Passage d\'animaux',
      category: SignCategory.danger,
      shape: SignShape.triangle,
      glyph: '🐑',
      meaning: "Risque de traversée d'animaux domestiques ou de troupeaux.",
      advice:
          "Très courant sur les routes rurales du Centre et du Sud. Levez le "
          "pied et n'utilisez pas l'avertisseur sonore de façon agressive.",
    ),
    RoadSign(
      id: 'sg-04',
      name: 'Travaux',
      category: SignCategory.danger,
      shape: SignShape.triangle,
      glyph: '🚧',
      meaning: "Chantier en cours, circulation perturbée.",
      advice:
          "La signalisation temporaire prévaut sur la signalisation fixe. "
          "Respectez les limitations réduites du chantier.",
    ),
    RoadSign(
      id: 'sg-05',
      name: 'Passage pour piétons',
      category: SignCategory.danger,
      shape: SignShape.triangle,
      glyph: '🚶',
      meaning: "Annonce un passage piéton.",
      advice:
          "Dans les centres-villes tunisiens, les piétons traversent souvent "
          "hors passage : restez vigilant en permanence.",
    ),

    // Interdiction
    RoadSign(
      id: 'sg-06',
      name: 'Sens interdit',
      category: SignCategory.interdiction,
      shape: SignShape.cercle,
      glyph: '⊖',
      meaning: "Accès interdit à tout véhicule dans ce sens.",
      advice: "Ne jamais s'engager, même sur quelques mètres.",
    ),
    RoadSign(
      id: 'sg-07',
      name: 'Stationnement interdit',
      category: SignCategory.interdiction,
      shape: SignShape.cercle,
      glyph: '⊘',
      meaning: "Le stationnement est interdit du côté où le panneau est implanté.",
      advice:
          "L'arrêt momentané peut rester toléré selon le panneau : vérifiez "
          "s'il s'agit d'une interdiction de stationner ou de s'arrêter.",
    ),
    RoadSign(
      id: 'sg-08',
      name: 'Limitation de vitesse 50',
      category: SignCategory.interdiction,
      shape: SignShape.cercle,
      glyph: '50',
      meaning: "Vitesse maximale autorisée : 50 km/h.",
      advice:
          "La vitesse en agglomération est généralement limitée à 50 km/h, "
          "sauf indication contraire. À vérifier selon la signalisation locale.",
    ),
    RoadSign(
      id: 'sg-09',
      name: 'Dépassement interdit',
      category: SignCategory.interdiction,
      shape: SignShape.cercle,
      glyph: '⇄',
      meaning: "Interdiction de dépasser tout véhicule à moteur.",
      advice:
          "Souvent placé avant les sommets de côte sur la GP1 : la visibilité "
          "est insuffisante pour dépasser en sécurité.",
    ),
    RoadSign(
      id: 'sg-10',
      name: 'Arrêt au poste de péage',
      category: SignCategory.interdiction,
      shape: SignShape.octogone,
      glyph: 'STOP',
      meaning: "Marquer l'arrêt complet, puis céder le passage.",
      advice:
          "L'arrêt doit être total, roues immobiles, à la ligne d'effet du "
          "panneau. Un simple ralentissement est une infraction.",
    ),

    // Obligation
    RoadSign(
      id: 'sg-11',
      name: 'Direction obligatoire à droite',
      category: SignCategory.obligation,
      shape: SignShape.cercle,
      glyph: '→',
      meaning: "Vous devez tourner à droite.",
      advice: "Positionnez-vous à l'avance dans la bonne file.",
    ),
    RoadSign(
      id: 'sg-12',
      name: 'Carrefour à sens giratoire',
      category: SignCategory.obligation,
      shape: SignShape.cercle,
      glyph: '↻',
      meaning: "Obligation de contourner l'îlot central par la droite.",
      advice:
          "Les ronds-points tunisiens sont souvent chargés : anticipez votre "
          "sortie et signalez-la au clignotant droit.",
    ),
    RoadSign(
      id: 'sg-13',
      name: 'Vitesse minimale obligatoire',
      category: SignCategory.obligation,
      shape: SignShape.cercle,
      glyph: '70',
      meaning: "Vous devez rouler au moins à la vitesse indiquée.",
      advice:
          "Rencontré sur certaines voies rapides : rouler trop lentement gêne "
          "la circulation et peut être sanctionné.",
    ),

    // Priorité
    RoadSign(
      id: 'sg-14',
      name: 'Cédez le passage',
      category: SignCategory.priorite,
      shape: SignShape.triangle,
      glyph: '▽',
      meaning:
          "Vous devez céder le passage aux véhicules circulant sur la route "
          "abordée.",
      advice:
          "L'arrêt n'est pas obligatoire si la voie est libre, mais vous devez "
          "pouvoir vous arrêter.",
    ),
    RoadSign(
      id: 'sg-15',
      name: 'Route à caractère prioritaire',
      category: SignCategory.priorite,
      shape: SignShape.losange,
      glyph: '◆',
      meaning: "Vous circulez sur une route prioritaire.",
      advice:
          "La priorité à droite ne s'applique plus tant que ce panneau n'est "
          "pas barré.",
    ),
    RoadSign(
      id: 'sg-16',
      name: 'Priorité à la circulation venant en sens inverse',
      category: SignCategory.priorite,
      shape: SignShape.cercle,
      glyph: '⇅',
      meaning:
          "Dans un passage étroit, laissez passer les véhicules venant en "
          "face.",
      advice: "Fréquent sur les ponts étroits et dans les médinas.",
    ),

    // Indication
    RoadSign(
      id: 'sg-17',
      name: 'Parking',
      category: SignCategory.indication,
      shape: SignShape.carre,
      glyph: 'P',
      meaning: "Emplacement de stationnement autorisé.",
      advice:
          "Dans les grandes villes, privilégiez les parkings surveillés : le "
          "stationnement sauvage est fréquemment verbalisé.",
    ),
    RoadSign(
      id: 'sg-18',
      name: 'Station-service',
      category: SignCategory.indication,
      shape: SignShape.carre,
      glyph: '⛽',
      meaning: "Poste de distribution de carburant.",
      advice:
          "Faites le plein avant de partir vers le Sud : les stations "
          "s'espacent fortement au-delà de Douz.",
    ),
    RoadSign(
      id: 'sg-19',
      name: 'Poste de secours',
      category: SignCategory.indication,
      shape: SignShape.carre,
      glyph: '✚',
      meaning: "Centre de secours ou poste médical à proximité.",
      advice:
          "Numéros utiles : Police secours 197, Protection civile 198, "
          "SAMU 190. (À confirmer localement.)",
      trust: ContentTrust.aVerifier,
    ),
    RoadSign(
      id: 'sg-20',
      name: 'Autoroute',
      category: SignCategory.indication,
      shape: SignShape.carre,
      glyph: '🛣',
      meaning: "Début de section autoroutière.",
      advice:
          "L'A1 relie Tunis à Sfax, l'A3 vers Oued Zarga. Péages en espèces "
          "ou par badge.",
    ),
  ];

  // ------------------------------------------------------------------ Règles

  static const List<RuleSection> rules = [
    RuleSection(
      id: 'rl-speed',
      title: 'Limitations de vitesse',
      icon: Icons.speed_rounded,
      summary:
          "Les vitesses maximales dépendent du type de route et des conditions "
          "météorologiques.",
      points: [
        'En agglomération : généralement 50 km/h.',
        'Route hors agglomération : généralement 90 km/h.',
        'Voies express : généralement 110 km/h.',
        'Autoroute : généralement 110 à 130 km/h selon la section.',
        'Par pluie ou visibilité réduite, les vitesses sont abaissées.',
        'Les jeunes conducteurs peuvent être soumis à des limites inférieures.',
        'La signalisation sur place prime toujours sur ces valeurs générales.',
      ],
    ),
    RuleSection(
      id: 'rl-priority',
      title: 'Priorités aux intersections',
      icon: Icons.alt_route_rounded,
      summary:
          "À défaut de signalisation, la priorité à droite s'applique en "
          "Tunisie comme dans la plupart des pays à conduite à droite.",
      points: [
        'Sans panneau ni feu : priorité au véhicule venant de votre droite.',
        'Un panneau « Stop » impose un arrêt complet avant de céder le passage.',
        'Un panneau « Cédez le passage » impose de laisser passer sans arrêt obligatoire.',
        'Les feux tricolores et les agents priment sur tous les panneaux.',
        'Les véhicules prioritaires en intervention (police, ambulance, pompiers) passent toujours en premier.',
        'En cas de panne de feu, revenir aux règles de priorité par panneaux puis à la priorité à droite.',
      ],
    ),
    RuleSection(
      id: 'rl-roundabout',
      title: 'Ronds-points et giratoires',
      icon: Icons.rotate_right_rounded,
      summary:
          "Les carrefours giratoires sont très répandus en Tunisie, notamment "
          "dans le Grand Tunis.",
      points: [
        'On contourne l\'îlot central par la droite (sens antihoraire).',
        'Sur un giratoire signalé « Cédez le passage », les véhicules déjà engagés sont prioritaires.',
        'Sur un ancien rond-point sans ce panneau, la priorité à droite peut s\'appliquer aux entrants : vérifiez la signalisation.',
        'Utilisez la voie de droite pour sortir à la première ou deuxième sortie.',
        'Signalez votre sortie au clignotant droit juste avant de quitter l\'anneau.',
        'Ne changez pas de file à l\'intérieur de l\'anneau sans visibilité.',
      ],
    ),
    RuleSection(
      id: 'rl-parking',
      title: 'Stationnement',
      icon: Icons.local_parking_rounded,
      summary:
          "Le stationnement est réglementé et souvent payant dans les centres "
          "urbains.",
      points: [
        'Interdiction de stationner sur les passages piétons, trottoirs et arrêts de bus.',
        'Le stationnement en double file est interdit, même brièvement.',
        'Les zones payantes sont signalées ; des horodateurs ou gardiens agréés encaissent le tarif.',
        'Les emplacements réservés aux personnes handicapées exigent une carte valide.',
        'Un véhicule gênant peut être mis en fourrière aux frais du propriétaire.',
        'Privilégiez les parkings surveillés dans les zones touristiques.',
      ],
    ),
    RuleSection(
      id: 'rl-safety',
      title: 'Ceinture et sécurité',
      icon: Icons.airline_seat_recline_normal_rounded,
      summary:
          "Les équipements de sécurité sont obligatoires pour le conducteur et "
          "les passagers.",
      points: [
        'La ceinture de sécurité est obligatoire à l\'avant ; son port à l\'arrière est fortement recommandé et exigé sur les véhicules équipés.',
        'Les enfants en bas âge doivent voyager dans un dispositif de retenue adapté.',
        'Le téléphone tenu en main au volant est interdit ; utilisez un kit mains libres.',
        'La conduite sous l\'emprise de l\'alcool est sévèrement sanctionnée.',
        'Le casque est obligatoire pour les deux-roues motorisés.',
        'Le véhicule doit comporter un triangle de présignalisation et un gilet réfléchissant.',
      ],
    ),
    RuleSection(
      id: 'rl-visitors',
      title: 'Conseils aux visiteurs étrangers',
      icon: Icons.travel_explore_rounded,
      summary:
          "Quelques habitudes locales à connaître avant de prendre le volant "
          "en Tunisie.",
      points: [
        'La conduite se fait à droite, le dépassement par la gauche.',
        'Un permis international est recommandé en complément de votre permis national.',
        'La circulation urbaine est dense et l\'usage du klaxon est courant : restez calme et prévisible.',
        'Les deux-roues et piétons se faufilent fréquemment : contrôlez vos angles morts.',
        'Hors des grands axes, l\'éclairage nocturne est faible et des véhicules peuvent rouler sans feux.',
        'Des contrôles routiers sont fréquents : gardez permis, carte grise, assurance et contrat de location à bord.',
        'Les animaux errants et les charrettes sont courants sur les routes rurales.',
      ],
      trust: ContentTrust.illustratif,
    ),
  ];

  // ------------------------------------------------------------------ Quiz

  static const List<Quiz> quizzes = [
    Quiz(
      id: 'qz-signs',
      title: 'Panneaux de signalisation',
      description: 'Reconnaître les principaux panneaux et leur signification.',
      icon: Icons.signpost_rounded,
      color: Color(0xFFDC2626),
      questions: [
        QuizQuestion(
          id: 'q-s1',
          question:
              "Un panneau triangulaire à bordure rouge signale généralement :",
          options: [
            'Une obligation',
            'Un danger',
            'Une indication touristique',
            'Une fin d\'interdiction',
          ],
          correctIndex: 1,
          explanation:
              "Le triangle à bordure rouge est la forme des panneaux de "
              "danger : il prévient d'un risque à venir.",
        ),
        QuizQuestion(
          id: 'q-s2',
          question: "Le panneau octogonal rouge « STOP » impose :",
          options: [
            'Un simple ralentissement',
            "Un arrêt complet puis la priorité aux autres véhicules",
            'Un arrêt uniquement la nuit',
            'Rien si la route est vide',
          ],
          correctIndex: 1,
          explanation:
              "L'arrêt doit être total, roues immobiles, avant la ligne "
              "d'effet, même si la voie semble libre.",
        ),
        QuizQuestion(
          id: 'q-s3',
          question: "Un panneau rond à fond bleu avec une flèche blanche est :",
          options: [
            'Un panneau d\'interdiction',
            'Un panneau de danger',
            'Un panneau d\'obligation',
            'Un panneau de fin de prescription',
          ],
          correctIndex: 2,
          explanation:
              "Les panneaux ronds bleus imposent une obligation, par exemple "
              "une direction à suivre.",
        ),
        QuizQuestion(
          id: 'q-s4',
          question:
              "Un losange jaune bordé de blanc signifie que vous circulez :",
          options: [
            'Sur une route prioritaire',
            'Dans une zone piétonne',
            'Sur une voie réservée aux bus',
            'À l\'approche d\'un péage',
          ],
          correctIndex: 0,
          explanation:
              "Le losange jaune indique une route à caractère prioritaire ; "
              "le même panneau barré en marque la fin.",
        ),
        QuizQuestion(
          id: 'q-s5',
          question: "Le panneau « Cédez le passage » a la forme :",
          options: [
            'D\'un cercle rouge',
            'D\'un triangle pointe en bas',
            'D\'un carré bleu',
            'D\'un octogone',
          ],
          correctIndex: 1,
          explanation:
              "C'est un triangle inversé (pointe vers le bas) à bordure rouge.",
        ),
      ],
    ),
    Quiz(
      id: 'qz-priority',
      title: 'Priorités et intersections',
      description: 'Savoir qui passe en premier dans chaque configuration.',
      icon: Icons.alt_route_rounded,
      color: Color(0xFFD97706),
      questions: [
        QuizQuestion(
          id: 'q-p1',
          question:
              "À une intersection sans panneau ni feu, qui est prioritaire ?",
          options: [
            'Le véhicule le plus rapide',
            'Le véhicule venant de la gauche',
            'Le véhicule venant de la droite',
            'Le véhicule le plus gros',
          ],
          correctIndex: 2,
          explanation:
              "La priorité à droite s'applique en l'absence de signalisation.",
        ),
        QuizQuestion(
          id: 'q-p2',
          question:
              "Un agent de la circulation fait un geste contraire au feu vert. "
              "Que faites-vous ?",
          options: [
            'Je suis le feu',
            "Je suis l'agent",
            'Je klaxonne',
            'Je m\'arrête au milieu du carrefour',
          ],
          correctIndex: 1,
          explanation:
              "Les indications d'un agent priment sur les feux et sur toute "
              "la signalisation.",
        ),
        QuizQuestion(
          id: 'q-p3',
          question:
              "Une ambulance en intervention arrive derrière vous, sirène "
              "activée :",
          options: [
            'Je garde ma trajectoire',
            'J\'accélère pour la laisser passer plus loin',
            'Je me range dès que possible en sécurité pour la laisser passer',
            'Je m\'arrête net sur place',
          ],
          correctIndex: 2,
          explanation:
              "Il faut faciliter le passage des véhicules prioritaires en se "
              "rabattant de manière sûre, sans freinage brutal.",
        ),
        QuizQuestion(
          id: 'q-p4',
          question:
              "Vous abordez un giratoire signalé « Cédez le passage ». Qui est "
              "prioritaire ?",
          options: [
            'Les véhicules qui entrent',
            'Les véhicules déjà engagés sur l\'anneau',
            'Celui qui arrive par la droite',
            'Les deux-roues uniquement',
          ],
          correctIndex: 1,
          explanation:
              "Avec ce panneau, les véhicules circulant déjà dans l'anneau "
              "sont prioritaires.",
        ),
        QuizQuestion(
          id: 'q-p5',
          question: "Les feux tricolores sont en panne. Vous devez :",
          options: [
            'Passer en premier si vous êtes arrivé en premier',
            'Appliquer la signalisation par panneaux, sinon la priorité à droite',
            'Traverser au ralenti sans regarder',
            'Faire demi-tour',
          ],
          correctIndex: 1,
          explanation:
              "En cas de feu hors service, on applique les panneaux présents "
              "et, à défaut, la priorité à droite.",
        ),
      ],
    ),
    Quiz(
      id: 'qz-speed',
      title: 'Vitesse et sécurité',
      description: 'Limitations, distances de sécurité et équipements.',
      icon: Icons.speed_rounded,
      color: Color(0xFF2563EB),
      questions: [
        QuizQuestion(
          id: 'q-v1',
          question:
              "En agglomération, la vitesse maximale est généralement de :",
          options: ['30 km/h', '50 km/h', '70 km/h', '90 km/h'],
          correctIndex: 1,
          explanation:
              "50 km/h est la valeur usuelle en agglomération, sauf "
              "signalisation contraire. À confirmer selon la réglementation "
              "en vigueur.",
        ),
        QuizQuestion(
          id: 'q-v2',
          question: "Par temps de pluie, les vitesses maximales :",
          options: [
            'Restent identiques',
            'Sont abaissées',
            'Sont augmentées',
            'Ne concernent que les poids lourds',
          ],
          correctIndex: 1,
          explanation:
              "Les limitations sont réduites lorsque l'adhérence et la "
              "visibilité diminuent.",
        ),
        QuizQuestion(
          id: 'q-v3',
          question: "Le téléphone tenu en main au volant est :",
          options: [
            'Autorisé à l\'arrêt dans la circulation',
            'Autorisé en dessous de 30 km/h',
            'Interdit',
            'Autorisé avec les feux de détresse',
          ],
          correctIndex: 2,
          explanation:
              "Tenir un téléphone en main en conduisant est interdit ; seul "
              "un dispositif mains libres est envisageable.",
        ),
        QuizQuestion(
          id: 'q-v4',
          question: "La distance de sécurité correcte se mesure :",
          options: [
            'En nombre de voitures',
            'En temps (environ 2 secondes par temps sec)',
            'En mètres fixes quelle que soit la vitesse',
            'Elle n\'est pas réglementée',
          ],
          correctIndex: 1,
          explanation:
              "La règle des 2 secondes (doublée par temps de pluie) s'adapte "
              "automatiquement à la vitesse.",
        ),
        QuizQuestion(
          id: 'q-v5',
          question: "À bord, vous devez disposer au minimum :",
          options: [
            'D\'un extincteur et d\'une trousse à outils',
            'D\'un triangle de présignalisation et d\'un gilet réfléchissant',
            'D\'une roue de secours uniquement',
            'D\'aucun équipement obligatoire',
          ],
          correctIndex: 1,
          explanation:
              "Le triangle et le gilet permettent de se signaler en cas "
              "d'immobilisation.",
        ),
      ],
    ),
    Quiz(
      id: 'qz-parking',
      title: 'Stationnement et circulation urbaine',
      description: 'Les bons réflexes en ville.',
      icon: Icons.local_parking_rounded,
      color: Color(0xFF0F766E),
      questions: [
        QuizQuestion(
          id: 'q-k1',
          question: "Stationner en double file est :",
          options: [
            'Toléré quelques minutes',
            'Interdit',
            'Autorisé avec les feux de détresse',
            'Autorisé le week-end',
          ],
          correctIndex: 1,
          explanation:
              "Le stationnement en double file gêne la circulation et reste "
              "interdit, même brièvement.",
        ),
        QuizQuestion(
          id: 'q-k2',
          question:
              "Vous vous garez devant un passage piéton pour deux minutes :",
          options: [
            'C\'est permis si vous restez dans le véhicule',
            'C\'est interdit',
            'C\'est permis la nuit',
            'C\'est permis hors heures de pointe',
          ],
          correctIndex: 1,
          explanation:
              "Stationner sur un passage piéton met en danger les usagers "
              "vulnérables et est interdit.",
        ),
        QuizQuestion(
          id: 'q-k3',
          question: "Un emplacement réservé aux personnes handicapées :",
          options: [
            'Est libre si aucune voiture adaptée n\'est visible',
            'Nécessite une carte de stationnement valide',
            'Est payant pour tout le monde',
            'Peut être utilisé 15 minutes',
          ],
          correctIndex: 1,
          explanation:
              "Seuls les titulaires d'une carte valide peuvent y stationner.",
        ),
        QuizQuestion(
          id: 'q-k4',
          question: "Votre véhicule gêne la circulation. Il risque :",
          options: [
            'Rien du tout',
            'Un simple avertissement oral',
            'Une amende et une mise en fourrière',
            'Une immobilisation de 24 h sur place',
          ],
          correctIndex: 2,
          explanation:
              "Un stationnement gênant peut entraîner l'enlèvement du "
              "véhicule aux frais du propriétaire.",
        ),
      ],
    ),
    Quiz(
      id: 'qz-final',
      title: 'Examen blanc final',
      description:
          'Test de synthèse reprenant l\'ensemble des thèmes abordés.',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFF7C3AED),
      isFinalTest: true,
      questions: [
        QuizQuestion(
          id: 'q-f1',
          question: "La conduite en Tunisie se fait :",
          options: [
            'À gauche',
            'À droite',
            'Au centre sur les routes étroites',
            'Selon la région',
          ],
          correctIndex: 1,
          explanation:
              "La Tunisie applique la conduite à droite, les dépassements se "
              "font par la gauche.",
        ),
        QuizQuestion(
          id: 'q-f2',
          question:
              "Vous arrivez à un carrefour sans signalisation, une voiture "
              "arrive à votre droite :",
          options: [
            'Vous passez en premier',
            'Vous lui cédez le passage',
            'Vous klaxonnez puis passez',
            'Vous reculez',
          ],
          correctIndex: 1,
          explanation: "La priorité à droite s'applique.",
        ),
        QuizQuestion(
          id: 'q-f3',
          question: "Un panneau rond bordé de rouge affichant « 90 » signifie :",
          options: [
            'Vitesse conseillée 90 km/h',
            'Vitesse minimale 90 km/h',
            'Vitesse maximale 90 km/h',
            'Distance de 90 m avant le danger',
          ],
          correctIndex: 2,
          explanation:
              "Le cercle rouge marque une interdiction : ici dépasser 90 km/h.",
        ),
        QuizQuestion(
          id: 'q-f4',
          question: "Sur un giratoire, vous sortez à la deuxième sortie :",
          options: [
            'Clignotant gauche en entrant, droit avant la sortie',
            'Aucun clignotant nécessaire',
            'Clignotant droit dès l\'entrée',
            'Feux de détresse',
          ],
          correctIndex: 0,
          explanation:
              "On signale son intention de contourner, puis la sortie au "
              "clignotant droit.",
        ),
        QuizQuestion(
          id: 'q-f5',
          question: "Le port de la ceinture à l'avant est :",
          options: [
            'Facultatif en ville',
            'Obligatoire',
            'Obligatoire seulement sur autoroute',
            'Réservé au conducteur',
          ],
          correctIndex: 1,
          explanation:
              "La ceinture est obligatoire à l'avant quelles que soient la "
              "route et la distance.",
        ),
        QuizQuestion(
          id: 'q-f6',
          question:
              "Vous louez une voiture : quels documents gardez-vous à bord ?",
          options: [
            'Uniquement votre passeport',
            'Permis, carte grise, assurance et contrat de location',
            'Seulement le contrat de location',
            'Aucun document n\'est exigé',
          ],
          correctIndex: 1,
          explanation:
              "Les contrôles routiers sont fréquents : ces documents doivent "
              "pouvoir être présentés.",
        ),
        QuizQuestion(
          id: 'q-f7',
          question: "Un troupeau traverse la route devant vous :",
          options: [
            'Je force le passage au klaxon',
            'Je m\'arrête et j\'attends le passage',
            'Je double par le bas-côté',
            'J\'accélère',
          ],
          correctIndex: 1,
          explanation:
              "Sur les routes rurales, il faut s'arrêter et laisser passer "
              "les animaux en sécurité.",
        ),
        QuizQuestion(
          id: 'q-f8',
          question: "Par forte pluie, la distance de sécurité doit être :",
          options: [
            'Réduite de moitié',
            'Identique',
            'Au moins doublée',
            'Sans importance à faible vitesse',
          ],
          correctIndex: 2,
          explanation:
              "L'adhérence chute : la règle des 2 secondes passe à 4 secondes.",
        ),
        QuizQuestion(
          id: 'q-f9',
          question: "Le dépassement est interdit :",
          options: [
            'Uniquement la nuit',
            'En sommet de côte et dans les virages sans visibilité',
            'Sur autoroute',
            'Quand on est pressé',
          ],
          correctIndex: 1,
          explanation:
              "Toute manœuvre sans visibilité suffisante est proscrite, et "
              "souvent signalée par un panneau dédié.",
        ),
        QuizQuestion(
          id: 'q-f10',
          question:
              "Vous constatez une panne sur une route hors agglomération :",
          options: [
            'Je reste dans le véhicule sur la chaussée',
            'Je mets le gilet, je place le triangle et je me mets en sécurité',
            'Je pousse la voiture jusqu\'à la prochaine ville',
            'Je laisse le véhicule sans signalisation',
          ],
          correctIndex: 1,
          explanation:
              "Gilet réfléchissant, triangle de présignalisation et mise à "
              "l'abri derrière la glissière sont les bons réflexes.",
        ),
      ],
    ),
  ];

  static Quiz? quizById(String id) {
    for (final q in quizzes) {
      if (q.id == id) return q;
    }
    return null;
  }

  static List<RoadSign> signsByCategory(SignCategory category) =>
      signs.where((s) => s.category == category).toList();
}
