import 'package:image_picker/image_picker.dart';
import '../core/health_kinds.dart';
import '../models/models.dart';
import '../repositories/pet_repository.dart';
import 'base_viewmodel.dart';

class HealthViewModel extends BaseViewModel {
  final PetRepository _repo;
  final String petId;
  final HealthKind kind;
  HealthViewModel(this._repo, this.petId, this.kind);

  List<HealthRecord> items = [];

  Future<void> load() => run(() async => items = await _repo.records(petId, kind.path));

  Future<bool> save(Map<String, dynamic> data, {String? id, XFile? photo}) => run(() async {
        if (photo != null) data['image_url'] = await _repo.uploadPhoto(photo);
        await _repo.saveRecord(petId, kind.path, data, id: id);
        items = await _repo.records(petId, kind.path);
      });

  Future<bool> delete(String id) => run(() async {
        await _repo.deleteRecord(petId, kind.path, id);
        items = await _repo.records(petId, kind.path);
      });
}
