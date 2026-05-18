import 'dart:math';

class RandomPasswordGenerator {
  static String generate() {
    const length = 8;
    const String upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowerCase = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String specialChars = '#@\$!.';

    final Random _random = Random.secure();
    
    // Ensure at least one of each required type
    String password = '';
    password += upperCase[_random.nextInt(upperCase.length)];
    password += lowerCase[_random.nextInt(lowerCase.length)];
    password += numbers[_random.nextInt(numbers.length)];
    password += specialChars[_random.nextInt(specialChars.length)];

    // Fill the rest randomly
    const String allChars = upperCase + lowerCase + numbers + specialChars;
    for (int i = 4; i < length; i++) {
      password += allChars[_random.nextInt(allChars.length)];
    }

    // Shuffle the characters to ensure the required ones aren't always at the beginning
    List<String> chars = password.split('');
    chars.shuffle(_random);
    
    return chars.join('');
  }
}
