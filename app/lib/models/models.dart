class AppUser {
  final String id, name, email, role;
  AppUser({required this.id, required this.name, required this.email, required this.role});
  factory AppUser.fromJson(Map<String, dynamic> j) =>
      AppUser(id: j['id'], name: j['name'], email: j['email'], role: j['role']);
  bool get isVet => role == 'vet';
}

class Pet {
  final String id, name;
  final String? photoUrl, breed, birthDate, sex, color, microchip, notes, ownerName;
  final double? weightKg;
  Pet({required this.id, required this.name, this.photoUrl, this.breed, this.birthDate, this.sex, this.weightKg,
      this.color, this.microchip, this.notes, this.ownerName});
  factory Pet.fromJson(Map<String, dynamic> j) => Pet(
        id: j['id'], name: j['name'], photoUrl: j['photo_url'], breed: j['breed'], birthDate: j['birth_date'],
        sex: j['sex'], weightKg: (j['weight_kg'] as num?)?.toDouble(), color: j['color'], microchip: j['microchip'],
        notes: j['notes'], ownerName: j['owner_name'],
      );
  String get sexLabel => sex == 'male' ? 'Macho' : sex == 'female' ? 'Fêmea' : '';
}

class HealthRecord {
  final String id;
  final Map<String, dynamic> data;
  HealthRecord(this.id, this.data);
  factory HealthRecord.fromJson(Map<String, dynamic> j) => HealthRecord(j['id'], j);
}

class TimelineEvent {
  final String id, kind, title;
  final DateTime at;
  final String? description, imageUrl, vetName;
  final bool? vetActive;
  TimelineEvent({required this.id, required this.kind, required this.title, required this.at, this.description,
      this.imageUrl, this.vetName, this.vetActive});
  factory TimelineEvent.fromJson(Map<String, dynamic> j) => TimelineEvent(
        id: j['id'], kind: j['kind'], title: j['title'] ?? '', at: DateTime.parse(j['at']).toLocal(),
        description: j['description'], imageUrl: j['image_url'], vetName: j['vet_name'], vetActive: j['vet_active'],
      );
}

class PetImage {
  final String id, url;
  final String? caption;
  PetImage(this.id, this.url, this.caption);
  factory PetImage.fromJson(Map<String, dynamic> j) => PetImage(j['id'], j['url'], j['caption']);
}

class VetConnection {
  final String id, email, status;
  final String? vetName;
  VetConnection(this.id, this.email, this.status, this.vetName);
  factory VetConnection.fromJson(Map<String, dynamic> j) =>
      VetConnection(j['id'], j['vet_email'], j['status'], j['vet_name']);
  String get statusLabel => const {
        'pending': 'Convite pendente', 'accepted': 'Ligado', 'declined': 'Recusado', 'disconnected': 'Desligado',
      }[status] ?? status;
}

class VetInvite {
  final String id, petId, petName, ownerName;
  final String? breed, photoUrl;
  VetInvite(this.id, this.petId, this.petName, this.ownerName, this.breed, this.photoUrl);
  factory VetInvite.fromJson(Map<String, dynamic> j) =>
      VetInvite(j['id'], j['pet_id'], j['pet_name'], j['owner_name'], j['breed'], j['photo_url']);
}

class Dose {
  final String id;
  final DateTime at;
  bool administered;
  Dose(this.id, this.at, this.administered);
  factory Dose.fromJson(Map<String, dynamic> j) =>
      Dose(j['id'], DateTime.parse(j['scheduled_at']).toLocal(), j['administered'] == true);
}

class VetNote {
  final String id, type, title, vetName;
  final String? content, prescriptionId, medication, dosage;
  final DateTime createdAt;
  final bool vetActive;
  final int? frequencyHours, durationDays, adherenceRate;
  final int totalDoses, dueDoses, takenDueDoses;
  final bool mine;
  VetNote({required this.id, required this.type, required this.title, required this.vetName, required this.createdAt,
      required this.vetActive, this.content, this.prescriptionId, this.medication, this.dosage, this.frequencyHours,
      this.durationDays, this.adherenceRate, this.totalDoses = 0, this.dueDoses = 0, this.takenDueDoses = 0,
      this.mine = false});
  factory VetNote.fromJson(Map<String, dynamic> j, {String? myId}) => VetNote(
        id: j['id'], type: j['type'], title: j['title'], content: j['content'], vetName: j['vet_name'],
        createdAt: DateTime.parse(j['created_at']).toLocal(), vetActive: j['vet_active'] == true,
        prescriptionId: j['prescription_id'], medication: j['medication'], dosage: j['dosage'],
        frequencyHours: j['frequency_hours'], durationDays: j['duration_days'], adherenceRate: j['adherence_rate'],
        totalDoses: j['total_doses'] ?? 0, dueDoses: j['due_doses'] ?? 0, takenDueDoses: j['taken_due_doses'] ?? 0,
        mine: myId != null && j['vet_id'] == myId,
      );
  bool get isPrescription => type == 'prescription';
  String get typeLabel => const {'recommendation': 'Recomendação', 'suggestion': 'Sugestão', 'prescription': 'Prescrição'}[type]!;
}

class Reminder {
  final String id, type, petId, petName, title;
  final String? subtitle, date, timeOfDay, days;
  final DateTime? at;
  Reminder({required this.id, required this.type, required this.petId, required this.petName, required this.title,
      this.subtitle, this.date, this.timeOfDay, this.days, this.at});
  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'], type: j['type'], petId: j['pet_id'], petName: j['pet_name'], title: j['title'],
        subtitle: j['subtitle'], date: j['date'], timeOfDay: j['time_of_day'], days: j['days'],
        at: j['at'] == null ? null : DateTime.parse(j['at']).toLocal(),
      );

  /// Próximas ocorrências concretas (instantes locais) usadas na lista e nas notificações.
  List<DateTime> occurrences({int daysAhead = 7}) {
    final now = DateTime.now();
    if (type == 'dose') return at != null && at!.isAfter(now) ? [at!] : [];
    if (type == 'vaccine') {
      final d = DateTime.tryParse(date ?? '');
      if (d == null) return [];
      final t = DateTime(d.year, d.month, d.day, 9);
      return t.isAfter(now) ? [t] : [];
    }
    final parts = (timeOfDay ?? '08:00').split(':');
    final h = int.tryParse(parts[0]) ?? 8, m = int.tryParse(parts[1]) ?? 0;
    final allowed = (days == null || days!.isEmpty) ? null : days!.split(',').map(int.parse).toSet();
    final out = <DateTime>[];
    for (var i = 0; i <= daysAhead; i++) {
      final day = now.add(Duration(days: i));
      final t = DateTime(day.year, day.month, day.day, h, m);
      if (t.isAfter(now) && (allowed == null || allowed.contains(t.weekday))) out.add(t);
    }
    return out;
  }
}
