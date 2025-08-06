import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  String _selectedCategory = 'Tutte';

  final List<String> _categories = [
    'Tutte',
    'Timer & Audio',
    'Allenamenti',
    'Progressi',
    'Account & Dati',
    'Tecnici',
  ];

  final Map<String, List<FAQItem>> _faqData = {
    'Timer & Audio': [
      FAQItem(
        question: '🏋️ Come funziona il timer di recupero?',
        answer: 'Il timer si avvia automaticamente dopo ogni serie. Continua a funzionare anche quando l\'app è in background e ti notifica quando è completato. Puoi metterlo in pausa o saltarlo se necessario.',
        category: 'Timer & Audio',
      ),
      FAQItem(
        question: '🎵 Perché la musica si interrompe durante i timer?',
        answer: 'Abbiamo risolto questo problema! Ora i timer utilizzano l\'audio ducking che riduce temporaneamente il volume della musica invece di interromperla. Puoi disattivare i suoni timer nelle impostazioni audio.',
        category: 'Timer & Audio',
      ),
      FAQItem(
        question: '⏱️ Come funzionano i timer isometrici?',
        answer: 'I timer isometrici si attivano automaticamente per esercizi come plank o wall sit. Contano i secondi invece delle ripetizioni e completano automaticamente la serie quando finisce il tempo.',
        category: 'Timer & Audio',
      ),
      FAQItem(
        question: '🔧 Come posso personalizzare l\'esperienza audio?',
        answer: 'Vai su Impostazioni > Audio per controllare: suoni timer, vibrazione feedback, riduzione volume musica. Le impostazioni vengono salvate e applicate a tutti i timer.',
        category: 'Timer & Audio',
      ),
    ],
    'Allenamenti': [
      FAQItem(
        question: '🔄 Come funzionano i superset e circuit?',
        answer: 'Gli esercizi vengono raggruppati automaticamente se hanno lo stesso tipo di set. I superset alternano esercizi, i circuit fanno round completi. Il timer di recupero si attiva solo alla fine del gruppo.',
        category: 'Allenamenti',
      ),
      FAQItem(
        question: '📊 Cosa sono i plateau e come funzionano?',
        answer: 'Il sistema rileva automaticamente quando stai usando gli stessi pesi/ripetizioni per diverse sessioni consecutive. Ti suggerisce come progredire: aumentare peso, ripetizioni o cambiare tecnica.',
        category: 'Allenamenti',
      ),
      FAQItem(
        question: '🔢 Come funziona il calcolatore 1RM?',
        answer: 'Usa la formula di Brzycki per calcolare il tuo massimo teorico. Inserisci peso e ripetizioni di una serie recente e otterrai una stima del tuo 1RM. Utile per programmare gli allenamenti.',
        category: 'Allenamenti',
      ),
      FAQItem(
        question: '📱 L\'app funziona offline?',
        answer: 'Sì! Puoi creare allenamenti e registrare serie anche senza connessione. I dati si sincronizzano automaticamente quando torni online. Solo alcune funzionalità premium richiedono internet.',
        category: 'Allenamenti',
      ),
    ],
    'Progressi': [
      FAQItem(
        question: '📈 Come tracciare i progressi nel tempo?',
        answer: 'L\'app salva automaticamente ogni serie. Puoi vedere le statistiche nella sezione Progressi: peso massimo, volume totale, frequenza allenamenti e trend nel tempo.',
        category: 'Progressi',
      ),
      FAQItem(
        question: '📊 Come interpretare le statistiche?',
        answer: 'Le statistiche mostrano: peso massimo per esercizio, volume totale (peso × ripetizioni), frequenza allenamenti, e trend di miglioramento nel tempo. I grafici ti aiutano a visualizzare i progressi.',
        category: 'Progressi',
      ),
      FAQItem(
        question: '🎯 Come impostare obiettivi realistici?',
        answer: 'Basati sui tuoi dati storici, l\'app può suggerire obiettivi realistici. Inizia con incrementi del 5-10% per peso o 1-2 ripetizioni in più. Il sistema di plateau ti aiuta a capire quando progredire.',
        category: 'Progressi',
      ),
    ],
    'Account & Dati': [
      FAQItem(
        question: '💾 I miei dati si perdono se cambio telefono?',
        answer: 'No! I tuoi dati sono sincronizzati nel cloud. Basta fare login con lo stesso account su un nuovo dispositivo e tutti i tuoi allenamenti, progressi e impostazioni saranno disponibili.',
        category: 'Account & Dati',
      ),
      FAQItem(
        question: '🔐 Come proteggere i miei dati?',
        answer: 'I tuoi dati sono crittografati e sicuri. Usa una password forte e non condividere il tuo account. Puoi abilitare l\'autenticazione a due fattori per maggiore sicurezza.',
        category: 'Account & Dati',
      ),
      FAQItem(
        question: '📤 Come esportare i miei dati?',
        answer: 'Vai su Profilo > Impostazioni > Esporta Dati per scaricare la cronologia dei tuoi allenamenti in formato CSV. Utile per backup o analisi esterne.',
        category: 'Account & Dati',
      ),
      FAQItem(
        question: '🗑️ Come eliminare il mio account?',
        answer: 'Vai su Profilo > Impostazioni > Elimina Account. I tuoi dati verranno eliminati definitivamente entro 30 giorni. Questa azione non può essere annullata.',
        category: 'Account & Dati',
      ),
    ],
    'Tecnici': [
      FAQItem(
        question: '🎯 Come funziona il sistema di versioning?',
        answer: 'Gli utenti tester ricevono aggiornamenti più frequenti per testare nuove funzionalità. Gli utenti normali ricevono versioni stabili. Il sistema è automatico e trasparente.',
        category: 'Tecnici',
      ),
      FAQItem(
        question: '📱 Quali dispositivi sono supportati?',
        answer: 'L\'app funziona su Android 6.0+ e iOS 12.0+. Richiede almeno 100MB di spazio libero e una connessione internet per la sincronizzazione.',
        category: 'Tecnici',
      ),
      FAQItem(
        question: '🔋 L\'app consuma molta batteria?',
        answer: 'L\'app è ottimizzata per il consumo energetico. I timer in background usano notifiche locali invece di processi continui. Chiudi l\'app quando non la usi per risparmiare batteria.',
        category: 'Tecnici',
      ),
      FAQItem(
        question: '🌐 Problemi di connessione?',
        answer: 'Verifica la tua connessione internet. L\'app funziona offline ma richiede internet per sincronizzare i dati. Prova a riavviare l\'app o il dispositivo se i problemi persistono.',
        category: 'Tecnici',
      ),
    ],
  };

  List<FAQItem> get _filteredFAQs {
    if (_selectedCategory == 'Tutte') {
      return _faqData.values.expand((faqs) => faqs).toList();
    }
    return _faqData[_selectedCategory] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Domande Frequenti'),
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor: isDarkMode ? Colors.white : AppColors.textPrimary,
        elevation: 0,
      ),
      body: Container(
        color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        child: Column(
          children: [
            // Categorie
            _buildCategorySelector(isDarkMode),
            
            // Lista FAQ
            Expanded(
              child: _filteredFAQs.isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : _buildFAQList(isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDarkMode) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Container(
            margin: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              selectedColor: AppColors.indigo600,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : (isDarkMode ? Colors.white70 : Colors.black87),
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAQList(bool isDarkMode) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredFAQs.length,
      itemBuilder: (context, index) {
        final faq = _filteredFAQs[index];
        return _buildFAQCard(faq, isDarkMode);
      },
    );
  }

  Widget _buildFAQCard(FAQItem faq, bool isDarkMode) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            child: Text(
              faq.answer,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.4,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64.sp,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Nessuna FAQ trovata',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Prova a selezionare una categoria diversa',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () => context.push('/feedback'),
            icon: const Icon(Icons.feedback_outlined),
            label: const Text('Contattaci'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;
  final String category;

  FAQItem({
    required this.question,
    required this.answer,
    required this.category,
  });
} 