import '../models/models.dart';
import '../repositories/pet_repository.dart';
import 'base_viewmodel.dart';

class TimelineViewModel extends BaseViewModel {
  final PetRepository _repo;
  final String petId;
  TimelineViewModel(this._repo, this.petId);

  static const filters = {
    'vaccine': 'Vacinas', 'weight': 'Peso', 'symptom': 'Sintomas', 'diet': 'Dieta',
    'prescription': 'Prescrições', 'recommendation': 'Recomendações', 'suggestion': 'Sugestões', 'image': 'Imagens',
  };

  final Set<String> selected = {};
  List<TimelineEvent> events = [];

  Future<void> load() => run(() async => events = await _repo.timeline(petId, kinds: selected.toList()));

  void toggle(String kind) {
    selected.contains(kind) ? selected.remove(kind) : selected.add(kind);
    load();
  }

  void clear() {
    selected.clear();
    load();
  }
}
