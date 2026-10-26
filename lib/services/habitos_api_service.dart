import '../models/habito.dart';
import '../models/registro.dart';
import 'api_client.dart';

class HabitosApiService {
  HabitosApiService(this._client);

  final ApiClient _client;

  Future<List<Habito>> listar({int skip = 0, int limit = 100}) async {
    final r =
        await _client.get('/habitos/', query: {'skip': skip, 'limit': limit});
    final json = r.data;
    if (json is! List) {
      throw ApiException(
          'Respuesta inesperada del servidor al listar tus hábitos.');
    }
    return json
        .whereType<Map>()
        .map((m) => Habito.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<List<Registro>> registrosDe(int habitoId, {int limit = 60}) async {
    final r = await _client.get('/habitos/$habitoId/registros',
        query: {'skip': 0, 'limit': limit});
    final json = r.data;
    if (json is! List) {
      throw ApiException(
          'Respuesta inesperada del servidor al leer los registros.');
    }
    return json
        .whereType<Map>()
        .map((m) => Registro.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<Habito> crear(String nombre, int frecuenciaObjetivo) async {
    final r = await _client.post('/habitos/',
        data: {'nombre': nombre, 'frecuencia_objetivo': frecuenciaObjetivo});
    return Habito.fromJson(_objeto(r.data, 'al crear el hábito'));
  }

  Future<Habito> actualizar(int id, Map<String, dynamic> cambios) async {
    final r = await _client.patch('/habitos/$id', data: cambios);
    return Habito.fromJson(_objeto(r.data, 'al actualizar el hábito'));
  }

  Future<void> eliminar(int id) async {
    await _client.delete('/habitos/$id');
  }

  Future<Registro> marcar(int id, {String? fecha}) async {
    final r = await _client.post('/habitos/$id/marcar',
        data: fecha == null ? const <String, dynamic>{} : {'fecha': fecha});
    return Registro.fromJson(_objeto(r.data, 'al marcar el hábito'));
  }

  Map<String, dynamic> _objeto(Object? datos, String contexto) {
    if (datos is! Map) {
      throw ApiException('Respuesta inesperada del servidor $contexto.');
    }
    return Map<String, dynamic>.from(datos);
  }
}
