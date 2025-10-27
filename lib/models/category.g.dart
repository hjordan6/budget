// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetCategoryAdapter extends TypeAdapter<BudgetCategory> {
  @override
  final int typeId = 0;

  @override
  BudgetCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetCategory(
      name: fields[0] as String,
      budget: fields[1] as double,
      balance: fields[2] as double,
      interval: fields[3] as BudgetInterval,
      nextUpdate: fields[5] as DateTime,
      notes: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetCategory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.budget)
      ..writeByte(2)
      ..write(obj.balance)
      ..writeByte(3)
      ..write(obj.interval)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.nextUpdate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetIntervalAdapter extends TypeAdapter<BudgetInterval> {
  @override
  final int typeId = 1;

  @override
  BudgetInterval read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetInterval.week;
      case 1:
        return BudgetInterval.month;
      case 2:
        return BudgetInterval.quarter;
      case 3:
        return BudgetInterval.year;
      default:
        return BudgetInterval.week;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetInterval obj) {
    switch (obj) {
      case BudgetInterval.week:
        writer.writeByte(0);
        break;
      case BudgetInterval.month:
        writer.writeByte(1);
        break;
      case BudgetInterval.quarter:
        writer.writeByte(2);
        break;
      case BudgetInterval.year:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetIntervalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
