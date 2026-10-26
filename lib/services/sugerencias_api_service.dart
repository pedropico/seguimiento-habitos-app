import '../models/plantilla_habito.dart';
import 'api_client.dart';

class SugerenciasApiService {
  SugerenciasApiService(this._client);

  final ApiClient _client;

  static const int limite = 20;

  Future<List<PlantillaHabito>> listar(
      {int skip = 0, int limit = limite}) async {
    final r = await _client
        .get('/sugerencias/', query: {'skip': skip, 'limit': limit});
    final json = r.data;
    if (json is! List) {
      throw ApiException(
          'Respuesta inesperada del servidor al leer las sugerencias.');
    }
    return json
        .whereType<Map>()
        .map((m) => PlantillaHabito.fromJson(Map<String, dynamic>.from(m)))
        .where((p) => p.id.isNotEmpty)
        .take(limit)
        .toList();
  }
}
