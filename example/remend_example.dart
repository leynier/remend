import 'package:remend/remend.dart';

void main() {
  // Basic usage
  final partial = 'This is **bold text';
  final completed = remend(partial);
  print(completed); // This is **bold text**

  // With options
  final result = remend(r'Formula: $x^2', RemendOptions(inlineKatex: true));
  print(result); // Formula: $x^2$
}
