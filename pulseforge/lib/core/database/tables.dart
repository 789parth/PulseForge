import 'package:drift/drift.dart';

class StepEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get steps => integer().withDefault(const Constant(0))();
  IntColumn get calories => integer().withDefault(const Constant(0))();
  IntColumn get activeMinutes => integer().withDefault(const Constant(0))();
  RealColumn get distanceKm => real().withDefault(const Constant(0.0))();

  @override
  List<Set<Column>> get uniqueKeys => [{date}];
}

class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  IntColumn get durationMinutes => integer()();
  IntColumn get calories => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
}

class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  IntColumn get target => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column>> get uniqueKeys => [{type}];
}
