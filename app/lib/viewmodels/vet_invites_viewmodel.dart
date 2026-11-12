import '../models/models.dart';
import '../repositories/vet_repository.dart';
import 'base_viewmodel.dart';

class VetInvitesViewModel extends BaseViewModel {
  final VetRepository _repo;
  VetInvitesViewModel(this._repo);

  List<VetInvite> invites = [];

  Future<void> load() => run(() async => invites = await _repo.invites());
  Future<bool> respond(String id, bool accept) => run(() async {
        accept ? await _repo.accept(id) : await _repo.decline(id);
        invites = await _repo.invites();
      });
}
