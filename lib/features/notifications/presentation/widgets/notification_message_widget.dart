// lib/features/notifications/presentation/widgets/notification_message_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';

/// 📝 Widget per visualizzare i messaggi delle notifiche con gestione corretta dei \n
class NotificationMessageWidget extends StatelessWidget {
  final String message;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;
  final bool isDark;

  const NotificationMessageWidget({
    super.key,
    required this.message,
    this.maxLines,
    this.overflow,
    this.style,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Sostituisce \n con caratteri di nuova riga reali
    final processedMessage = message.replaceAll('\\n', '\n');
    
    // Se il messaggio contiene \n, usa un widget che li gestisce correttamente
    if (processedMessage.contains('\n')) {
      return RichText(
        text: TextSpan(
          style: style ?? TextStyle(
            fontSize: 14.sp,
            color: isDark ? Colors.grey[300] : AppColors.textSecondary,
            height: 1.4,
          ),
          children: _buildTextSpans(processedMessage),
        ),
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.ellipsis,
      );
    } else {
      // Messaggio normale senza \n
      return Text(
        processedMessage,
        style: style ?? TextStyle(
          fontSize: 14.sp,
          color: isDark ? Colors.grey[300] : AppColors.textSecondary,
          height: 1.4,
        ),
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.ellipsis,
      );
    }
  }

  List<TextSpan> _buildTextSpans(String text) {
    final lines = text.split('\n');
    final spans = <TextSpan>[];
    
    for (int i = 0; i < lines.length; i++) {
      spans.add(TextSpan(text: lines[i]));
      
      // Aggiungi una nuova riga se non è l'ultima riga
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    
    return spans;
  }
}
