import 'package:image_picker/image_picker.dart';
import '../core/api_client.dart';
import '../models/models.dart';

class PetRepository {
  final ApiClient api;
  PetRepository(this.api);

  List<Map<String, dynamic>> _list(dynamic r) => (r as List).cast<Map<String, dynamic>>();

  Future<List<Pet>> pets() async => _list(await api.get('/pets')).map(Pet.fromJson).toList();
  Future<Pet> pet(String id) async => Pet.fromJson(await api.get('/pets/$id'));
  Future<Pet> create(Map<String, dynamic> b) async => Pet.fromJson(await api.post('/pets', b));
  Future<Pet> update(String id, Map<String, dynamic> b) async => Pet.fromJson(await api.put('/pets/$id', b));
  Future<void> delete(String id) => api.delete('/pets/$id');

  Future<String> uploadPhoto(XFile f) async =>
      (await api.upload('/uploads', await f.readAsBytes(), f.name))['url'];

  // Registos de saúde
  Future<List<HealthRecord>> records(String petId, String kind) async =>
      _list(await api.get('/pets/$petId/$kind')).map(HealthRecord.fromJson).toList();
  Future<void> saveRecord(String petId, String kind, Map<String, dynamic> b, {String? id}) =>
      id == null ? api.post('/pets/$petId/$kind', b) : api.put('/pets/$petId/$kind/$id', b);
  Future<void> deleteRecord(String petId, String kind, String id) => api.delete('/pets/$petId/$kind/$id');

  // Timeline e galeria
  Future<List<TimelineEvent>> timeline(String petId, {List<String>? kinds}) async => _list(await api.get(
          '/pets/$petId/timeline', query: {if (kinds != null && kinds.isNotEmpty) 'kinds': kinds.join(',')}))
      .map(TimelineEvent.fromJson)
      .toList();
  Future<List<PetImage>> gallery(String petId) async =>
      _list(await api.get('/pets/$petId/images')).map(PetImage.fromJson).toList();
  Future<void> addImage(String petId, XFile f, String? caption) async =>
      api.upload('/pets/$petId/images', await f.readAsBytes(), f.name, fields: {if (caption != null) 'caption': caption});
  Future<void> deleteImage(String petId, String id) => api.delete('/pets/$petId/images/$id');
}
