import '../core/api_client.dart';
import '../models/models.dart';

class VetRepository {
  final ApiClient api;
  VetRepository(this.api);

  List<Map<String, dynamic>> _list(dynamic r) => (r as List).cast<Map<String, dynamic>>();

  // Dono
  Future<List<VetConnection>> connections(String petId) async =>
      _list(await api.get('/pets/$petId/vets')).map(VetConnection.fromJson).toList();
  Future<void> invite(String petId, String email) => api.post('/pets/$petId/vets', {'email': email});
  Future<void> disconnect(String connectionId) => api.post('/connections/$connectionId/disconnect');

  // Veterinário
  Future<List<VetInvite>> invites() async => _list(await api.get('/invites')).map(VetInvite.fromJson).toList();
  Future<void> accept(String id) => api.post('/invites/$id/accept');
  Future<void> decline(String id) => api.post('/invites/$id/decline');

  // Recomendações / prescrições
  Future<List<VetNote>> notes(String petId, String myId) async =>
      _list(await api.get('/pets/$petId/notes')).map((j) => VetNote.fromJson(j, myId: myId)).toList();
  Future<void> createNote(String petId, Map<String, dynamic> body) => api.post('/pets/$petId/notes', body);
  Future<void> updateNote(String id, String title, String? content) =>
      api.put('/notes/$id', {'title': title, 'content': content});
  Future<void> deleteNote(String id) => api.delete('/notes/$id');

  Future<List<Dose>> doses(String prescriptionId) async =>
      _list(await api.get('/prescriptions/$prescriptionId/doses')).map(Dose.fromJson).toList();
  Future<void> markDose(String id, bool administered) => api.patch('/doses/$id', {'administered': administered});

  Future<List<Reminder>> reminders() async => _list(await api.get('/reminders')).map(Reminder.fromJson).toList();
}
