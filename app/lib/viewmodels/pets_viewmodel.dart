import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../repositories/pet_repository.dart';
import 'base_viewmodel.dart';

/// Lista de pets (dono: os seus; veterinário: os ligados) + criar/editar/apagar.
class PetsViewModel extends BaseViewModel {
  final PetRepository _repo;
  PetsViewModel(this._repo);

  List<Pet> pets = [];

  Future<void> load() => run(() async => pets = await _repo.pets());

  Future<bool> save({String? id, required Map<String, dynamic> data, XFile? photo}) => run(() async {
        if (photo != null) data['photo_url'] = await _repo.uploadPhoto(photo);
        id == null ? await _repo.create(data) : await _repo.update(id, data);
        pets = await _repo.pets();
      });

  Future<bool> delete(String id) => run(() async {
        await _repo.delete(id);
        pets = await _repo.pets();
      });
}
