import '../config/environment.dart';

class Validators {
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci il tuo username';
    }

    if (value.length < Environment.minUsernameLength) {
      return 'Username deve essere almeno ${Environment.minUsernameLength} caratteri';
    }

    if (value.length > Environment.maxUsernameLength) {
      return 'Username non può superare ${Environment.maxUsernameLength} caratteri';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username può contenere solo lettere, numeri e underscore';
    }

    return null;
  }

  static String? validatePassword(String? value, {bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Inserisci una password' : null;
    }

    if (value.length < Environment.minPasswordLength) {
      return 'Password deve essere almeno ${Environment.minPasswordLength} caratteri';
    }

    if (value.length > Environment.maxPasswordLength) {
      return 'Password non può superare ${Environment.maxPasswordLength} caratteri';
    }

    return null;
  }

  static String? validatePasswordConfirmation(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Conferma la password';
    }

    if (password != confirmPassword) {
      return 'Le password non coincidono';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci la tua email';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Inserisci una email valida';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci il tuo nome';
    }

    if (value.length > Environment.maxNameLength) {
      return 'Nome non può superare ${Environment.maxNameLength} caratteri';
    }

    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s\').hasMatch(value)) {
    return 'Nome contiene caratteri non validi';
    }

  return null;
}

static String? validateRequired(String? value, String fieldName) {
if (value == null || value.isEmpty) {
return 'Il campo $fieldName è obbligatorio';
}
return null;
}

static String? validateMinLength(String? value, int minLength, String fieldName) {
if (value == null || value.length < minLength) {
return '$fieldName deve essere almeno $minLength caratteri';
}
return null;
}

static String? validateMaxLength(String? value, int maxLength, String fieldName) {
if (value != null && value.length > maxLength) {
return '$fieldName non può superare $maxLength caratteri';
}
return null;
}
}