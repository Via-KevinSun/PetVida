import '../models/models.dart';
import '../repositories/vet_repository.dart';
import 'base_viewmodel.dart';

/// Lado do dono: convidar e desligar veterinários de um pet.
class ConnectionsViewModel extends BaseViewModel {
  final VetRepository _repo;
  final String petId;
  ConnectionsViewModel(this._repo, this.petId);

  List<VetConnection> items = [];

  Future<void> load() => run(() async => items = await _repo.connections(petId));
  Future<bool> invite(String email) => run(() async {
        await _repo.invite(petId, email.trim());
        items = await _repo.connections(petId);
      });
  Future<bool> disconnect(String id) => run(() async {
        await _repo.disconnect(id);
        items = await _repo.connections(petId);
      });
}
