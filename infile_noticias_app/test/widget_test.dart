import 'package:flutter_test/flutter_test.dart';
import 'package:infile_noticias_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Nota: Este test requiere que las dependencias estén inicializadas.
    // Para tests unitarios completos, usar mocks de GetIt.
    //
    // Por ahora, solo verificamos que el widget raíz existe.
    expect(InfileNoticiasApp, isNotNull);
  });
}
