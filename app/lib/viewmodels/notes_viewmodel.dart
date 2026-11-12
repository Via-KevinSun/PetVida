import '../models/models.dart';
import '../repositories/vet_repository.dart';
import 'base_viewmodel.dart';

class NotesViewModel extends BaseViewModel {
  final VetRepository _repo;
  final String petId, myId;
  NotesViewModel(this._repo, this.petId, this.myId);

  List<VetNote> notes = [];

  Future<void> load() => run(() async => notes = await _repo.notes(petId, myId));

  Future<bool> create(Map<String, dynamic> body) => run(() async {
        await _repo.createNote(petId, body);
        notes = await _repo.notes(petId, myId);
      });
  Future<bool> update(String id, String title, String? content) => run(() async {
        await _repo.updateNote(id, title, content);
        notes = await _repo.notes(petId, myId);
      });
  Future<bool> delete(String id) => run(() async {
        await _repo.deleteNote(id);
        notes = await _repo.notes(petId, myId);
      });

  Future<List<Dose>> doses(String prescriptionId) => _repo.doses(prescriptionId);
  Future<void> markDose(Dose d, bool v) async {
    await _repo.markDose(d.id, v);
    d.administered = v;
    notes = await _repo.notes(petId, myId); // atualiza taxa de adesão
    notifyListeners();
  }
}
