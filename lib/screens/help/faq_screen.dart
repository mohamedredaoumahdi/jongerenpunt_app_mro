import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  // List of FAQ items, each with a question and answer
  final List<Map<String, String>> _faqItems = [
    {
      'question': 'Wat is Jongerenpunt?',
      'answer': 'Jongerenpunt is een app speciaal voor jongeren, waar je snel betrouwbare informatie kunt vinden over geld, gezondheid, school, werk, wonen en meer.'
    },
    {
      'question': 'Moet ik een account aanmaken om de app te gebruiken?',
      'answer': 'Nee, dat hoeft niet. Je kunt ervoor kiezen om anoniem verder te gaan of een account aan te maken als je extra functies wilt gebruiken, zoals het opslaan van favorieten.'
    },
    {
      'question': 'Welke onderwerpen kan ik vinden in de app?',
      'answer': 'Je vindt informatie over 12 thema’s, waaronder Financiën, Gezondheid, Studie, Inkomen, Wonen, Vrije tijd, Veiligheid, Discriminatie, en meer.'
    },
    {
      'question': 'Hoe werkt de zoekfunctie?',
      'answer': 'Je kunt bovenaan het scherm zoeken op een woord of onderwerp. De app laat je dan meteen gerelateerde onderwerpen of tips zien.'
    },
    {
      'question': 'Kan ik met iemand praten via de app?',
      'answer': 'Ja, er is een chatfunctie beschikbaar. In sommige gevallen kun je ook direct met een medewerker chatten of gebruikmaken van de AI-chat voor snelle antwoorden.'
    },
    {
      'question': 'Is de informatie in de app betrouwbaar?',
      'answer': 'Ja, alle informatie komt van betrouwbare bronnen en wordt regelmatig gecontroleerd. De tips zijn praktisch en bedoeld om jou direct te helpen.'
    },
    {
      'question': 'Wat betekent het als er ‘Let op’ bij een onderwerp staat?',
      'answer': 'Dat betekent dat het onderwerp gevoelige of belangrijke informatie bevat, zoals juridische gevolgen, geldzaken of risico’s. Lees deze sectie goed door.'
    },
    {
      'question': 'Kan ik herinneringen instellen of informatie opslaan?',
      'answer': 'Niet in de anonieme versie. Als je een account aanmaakt, kun je extra functies gebruiken zoals het opslaan van informatie of het ontvangen van meldingen.'
    },
    {
      'question': 'Is de app gratis?',
      'answer': 'Ja, de app is volledig gratis te gebruiken. Je hoeft niets te betalen om toegang te krijgen tot de informatie of functies.'
    },
    {
      'question': 'Wat als ik iets niet kan vinden in de app?',
      'answer': 'Gebruik de zoekfunctie of stel je vraag in de chat. We breiden de app regelmatig uit, dus jouw feedback helpt ons verbeteren.'
    },
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veelgestelde vragen', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryStart,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Introduction text
          const Text(
            'Hier vind je antwoorden op veelgestelde vragen over de Jongerenpunt app. Staat je vraag er niet tussen? Neem dan contact met ons op via het contactformulier.',
            style: TextStyle(fontSize: 16),
          ),
          
          const SizedBox(height: 24),
          
          // FAQ items
          ...List.generate(_faqItems.length, (index) {
            return _buildFAQItem(_faqItems[index]['question']!, _faqItems[index]['answer']!);
          }),
          
          const SizedBox(height: 24),
          
          // Contact button
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to contact screen
              Navigator.pushNamed(context, '/contact');
            },
            icon: const Icon(Icons.email),
            label: const Text('Nog vragen? Neem contact op'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryStart,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppColors.primaryStart,
        textColor: AppColors.primaryStart,
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}