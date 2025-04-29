import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'info@jongerenpuntovervecht.nl',
      query: 'subject=Privacy vraag&body=Beste Jongerenpunt team,',
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      print('Could not launch email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacyverklaring', 
          style: TextStyle(color: Colors.white)
        ),
        backgroundColor: AppColors.primaryStart,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Privacyverklaring Jongerenpunt'),
            _buildSubtitle('Laatst bijgewerkt: april 2025'),
            
            _buildParagraph(
              'Bij Jongerenpunt hechten we veel waarde aan jouw privacy. In deze privacyverklaring leggen we uit welke gegevens we verzamelen, waarom we dat doen, en hoe we met jouw informatie omgaan.',
            ),
            
            _buildSectionHeader('1. Wie zijn wij?'),
            _buildParagraph(
              'Jongerenpunt is een informatieve app gericht op jongeren, waarin je betrouwbare informatie kunt vinden over onderwerpen zoals wonen, financiën, gezondheid, studie en meer. Je kunt de app anoniem gebruiken of een account aanmaken.',
            ),
            
            _buildSectionHeader('2. Welke gegevens verzamelen we?'),
            _buildBulletList([
              'E-mailadres (indien je registreert)',
              'Inloggegevens (versleuteld opgeslagen)',
              'App-gebruik: bekeken onderwerpen, categorieën, zoektermen',
              'Feedback of berichten via de chat',
              'Technische informatie: apparaat, besturingssysteem, crashlogs',
            ]),
            _buildParagraph(
              'Bij anoniem gebruik wordt er geen account aangemaakt en zijn de gegevens niet herleidbaar tot een persoon.',
            ),
            
            _buildSectionHeader('3. Waarom verzamelen we deze gegevens?'),
            _buildBulletList([
              'Om je relevante informatie te tonen',
              'Om je op de hoogte te houden van nieuwe onderwerpen of belangrijke updates (via pushmeldingen)',
              'Voor het verbeteren van de app door analyses van gebruiksgedrag (geanonimiseerd)',
              'Om je toegang te geven tot extra functies, zoals favorieten of meldingen',
              'Om jouw vragen te beantwoorden via de chat',
            ]),
            
            _buildSectionHeader('4. Worden mijn gegevens gedeeld met derden?'),
            _buildParagraph(
              'Nee, wij verkopen jouw gegevens niet aan derden. We werken wel met vertrouwde technologiepartners zoals Firebase en analytische tools (zoals Google Analytics voor Firebase) om de app te laten functioneren. Deze partijen voldoen aan de AVG.',
            ),
            
            _buildSectionHeader('5. Hoe lang worden gegevens bewaard?'),
            _buildBulletList([
              'Bij anoniem gebruik: tijdelijk (tot het einde van je sessie of een korte bewaartermijn voor analytische doeleinden)',
              'Bij registratie: zolang je account actief is. Je kunt je account op elk moment verwijderen',
            ]),
            
            _buildSectionHeader('6. Wat zijn mijn rechten?'),
            _buildBulletList([
              'Inzage in jouw gegevens',
              'Wijzigen of verwijderen van gegevens',
              'Bezwaar maken tegen gegevensverwerking',
              'Gegevensoverdracht',
            ]),
            _buildParagraph(
              'Stuur ons een verzoek via de instellingenpagina of neem contact op via het e-mailadres onderaan deze verklaring.',
            ),
            
            _buildSectionHeader('7. Beveiliging van gegevens'),
            _buildParagraph(
              'We gebruiken versleuteling, beveiligde verbindingen (SSL) en veilige opslag via Firebase om jouw gegevens te beschermen.',
            ),
            
            _buildSectionHeader('8. Pushmeldingen en communicatie'),
            _buildParagraph(
              'Als je toestemming geeft, ontvang je meldingen over nieuwe onderwerpen of belangrijke updates. Je kunt dit altijd aanpassen via je profielinstellingen.',
            ),
            
            _buildSectionHeader('9. Wijzigingen in dit privacybeleid'),
            _buildParagraph(
              'Als we deze verklaring aanpassen, zie je de nieuwe versie in de app en op onze website. We raden aan dit regelmatig te controleren.',
            ),
            
            _buildSectionHeader('10. Contact'),
            _buildParagraph(
              'Heb je vragen of verzoeken over jouw privacy?',
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _launchEmail,
                icon: const Icon(Icons.email),
                label: const Text('Stuur een e-mail'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryStart,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryStart,
        ),
      ),
    );
  }

  Widget _buildSubtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          color: AppColors.lightText,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryStart,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          )
        ).toList(),
      ),
    );
  }
}