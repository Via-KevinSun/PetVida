import 'package:flutter/material.dart';
import 'format.dart';

enum FieldType { text, multiline, date, number, time, datetime, choice, weekdays }

class FieldSpec {
  final String key, label;
  final FieldType type;
  final bool required;
  final Map<String, String>? options;
  const FieldSpec(this.key, this.label, this.type, {this.required = false, this.options});
}

/// Descreve cada tipo de registo de saúde; o formulário e a lista são gerados a partir disto.
class HealthKind {
  final String path, title, singular;
  final IconData icon;
  final List<FieldSpec> fields;
  final bool hasImage;
  final String Function(Map<String, dynamic>) titleOf;
  final String Function(Map<String, dynamic>) subtitleOf;
  const HealthKind(this.path, this.title, this.singular, this.icon, this.fields, this.titleOf, this.subtitleOf,
      {this.hasImage = false});
}

const severityLabels = {'low': 'Leve', 'medium': 'Moderado', 'high': 'Grave'};
const weekdayLabels = {'1': 'Seg', '2': 'Ter', '3': 'Qua', '4': 'Qui', '5': 'Sex', '6': 'Sáb', '7': 'Dom'};

String _daysLabel(String? d) =>
    d == null || d.isEmpty ? 'Todos os dias' : d.split(',').map((e) => weekdayLabels[e] ?? e).join(', ');

final healthKinds = <HealthKind>[
  HealthKind(
    'vaccines', 'Vacinas', 'vacina', Icons.vaccines_rounded,
    const [
      FieldSpec('name', 'Vacina', FieldType.text, required: true),
      FieldSpec('applied_on', 'Data de aplicação', FieldType.date, required: true),
      FieldSpec('next_due_on', 'Próxima dose', FieldType.date),
      FieldSpec('notes', 'Observações', FieldType.multiline),
    ],
    (m) => m['name'] ?? '',
    (m) => 'Aplicada em ${fmtDate(m['applied_on'])}${m['next_due_on'] != null ? ' · Próxima: ${fmtDate(m['next_due_on'])}' : ''}',
  ),
  HealthKind(
    'weights', 'Peso', 'registo de peso', Icons.monitor_weight_rounded,
    const [
      FieldSpec('weight_kg', 'Peso (kg)', FieldType.number, required: true),
      FieldSpec('recorded_on', 'Data', FieldType.date, required: true),
      FieldSpec('notes', 'Observações', FieldType.multiline),
    ],
    (m) => fmtKg(m['weight_kg'] as num?),
    (m) => fmtDate(m['recorded_on']),
  ),
  HealthKind(
    'diets', 'Dieta', 'refeição', Icons.restaurant_rounded,
    const [
      FieldSpec('food', 'Alimento / ração', FieldType.text, required: true),
      FieldSpec('amount', 'Quantidade', FieldType.text),
      FieldSpec('meal_time', 'Horário', FieldType.time),
      FieldSpec('notes', 'Observações', FieldType.multiline),
    ],
    (m) => m['food'] ?? '',
    (m) => [m['amount'], m['meal_time']].where((e) => e != null && '$e'.isNotEmpty).join(' · '),
  ),
  HealthKind(
    'routines', 'Rotina', 'rotina', Icons.schedule_rounded,
    const [
      FieldSpec('title', 'Atividade (ex.: Passeio)', FieldType.text, required: true),
      FieldSpec('time_of_day', 'Horário', FieldType.time, required: true),
      FieldSpec('days', 'Dias da semana', FieldType.weekdays),
      FieldSpec('notes', 'Observações', FieldType.multiline),
    ],
    (m) => m['title'] ?? '',
    (m) => '${m['time_of_day']} · ${_daysLabel(m['days'])}',
  ),
  HealthKind(
    'symptoms', 'Sintomas', 'sintoma', Icons.healing_rounded,
    const [
      FieldSpec('description', 'Sintoma', FieldType.text, required: true),
      FieldSpec('severity', 'Gravidade', FieldType.choice, options: severityLabels),
      FieldSpec('occurred_at', 'Quando ocorreu', FieldType.datetime, required: true),
      FieldSpec('notes', 'Observações', FieldType.multiline),
    ],
    (m) => m['description'] ?? '',
    (m) => '${fmtDateTime(m['occurred_at'])}${m['severity'] != null ? ' · ${severityLabels[m['severity']]}' : ''}',
    hasImage: true,
  ),
];
