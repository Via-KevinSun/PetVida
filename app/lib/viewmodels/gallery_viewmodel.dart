import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../repositories/pet_repository.dart';
import 'base_viewmodel.dart';

class GalleryViewModel extends BaseViewModel {
  final PetRepository _repo;
  final String petId;
  GalleryViewModel(this._repo, this.petId);

  List<PetImage> images = [];

  Future<void> load() => run(() async => images = await _repo.gallery(petId));
  Future<bool> add(XFile f, String? caption) => run(() async {
        await _repo.addImage(petId, f, caption);
        images = await _repo.gallery(petId);
      });
  Future<bool> delete(String id) => run(() async {
        await _repo.deleteImage(petId, id);
        images = await _repo.gallery(petId);
      });
}
