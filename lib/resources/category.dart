import 'package:essentiel/game/cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

enum Category {
  VIE_FRATERNELLE,
  PRIERE,
  FORMATION,
  SERVICE,
  EVANGELISATION,
  ESSENTIELLES_PLUS
}

extension CategoryColor on Category {
  Color color() => {
        Category.VIE_FRATERNELLE: const Color(0xFFF7B900),
        Category.PRIERE: const Color(0xFF97205E),
        Category.FORMATION: const Color(0xFF12A0FF),
        Category.SERVICE: const Color(0xFF62D739),
        Category.EVANGELISATION: const Color(0xFFED2910),
        Category.ESSENTIELLES_PLUS: Colors.teal
      }[this];
}

extension Title on Category {
  String title() => const {
        Category.VIE_FRATERNELLE: "Vie fraternelle",
        Category.PRIERE: "Prière",
        Category.EVANGELISATION: "Évangélisation",
        Category.FORMATION: "Formation chrétienne",
        Category.SERVICE: "Service",
        Category.ESSENTIELLES_PLUS: "Essentielles+"
      }[this];
}

extension CategoryIcon on Category {
  IconData icon() => const {
        Category.VIE_FRATERNELLE: Icons.ac_unit,
        Category.PRIERE: Icons.ac_unit,
        Category.EVANGELISATION: Icons.ac_unit,
        Category.FORMATION: Icons.ac_unit,
        Category.SERVICE: Icons.ac_unit,
        Category.ESSENTIELLES_PLUS: Icons.ac_unit
      }[this];
}

extension EssentielCardsForCategory on Category {
  List<EssentielCard> essentielCards() => {
        Category.VIE_FRATERNELLE: [
          EssentielCard(
              category: this,
              question: "Comment je vis la vie fraternelle dans ma famille?"),
        ],
        Category.PRIERE: [
          EssentielCard(
              category: this,
              question: "Ai-je déjà prié pour mon/mes enfant(s)?"),
        ],
        Category.FORMATION: [
          EssentielCard(
              category: this,
              question: "Comment je pense aider mes enfants à grandir?"),
        ],
        Category.SERVICE: [
          EssentielCard(
              category: this,
              question: "Quelle grâce j'aimerais recevoir pour servir mieux?"),
        ],
        Category.EVANGELISATION: [
          EssentielCard(
              category: this,
              question:
                  "De quoi ai-je besoin pour oser témoigner de l'amour de Dieu autour de moi?"),
        ],
        Category.ESSENTIELLES_PLUS: [
          EssentielCard(
              category: this,
              question: "Je partage mon chant de louange préféré!"),
        ]
      }[this];
}
