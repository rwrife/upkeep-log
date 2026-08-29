import 'package:upkeep_log/domain/domain.dart';

enum HistoryStatus { all, completed, corrected }

final class HistoryFilter {
  const HistoryFilter({
    this.assetId,
    this.roomId,
    this.taskText = '',
    this.completedFrom,
    this.completedTo,
    this.status = HistoryStatus.all,
  });
  final String? assetId;
  final String? roomId;
  final String taskText;
  final LocalDate? completedFrom;
  final LocalDate? completedTo;
  final HistoryStatus status;
}

final class HistoryEntry {
  const HistoryEntry({
    required this.home,
    required this.task,
    required this.occurrence,
    required this.completion,
    required this.asset,
    required this.room,
  });
  final HomeProfile home;
  final TaskTemplate task;
  final TaskOccurrence occurrence;
  final Completion completion;
  final Asset? asset;
  final Room? room;
}

List<HistoryEntry> filterHistory(
  Iterable<HistoryEntry> values,
  HistoryFilter filter,
) {
  final String text = filter.taskText.trim().toLowerCase();
  final List<HistoryEntry> result = values.where((HistoryEntry entry) {
    if (filter.assetId != null && entry.asset?.id != filter.assetId) {
      return false;
    }
    if (filter.roomId != null && entry.room?.id != filter.roomId) return false;
    if (text.isNotEmpty && !entry.task.name.toLowerCase().contains(text)) {
      return false;
    }
    if (filter.completedFrom != null &&
        entry.completion.actualDate < filter.completedFrom!) {
      return false;
    }
    if (filter.completedTo != null &&
        entry.completion.actualDate > filter.completedTo!) {
      return false;
    }
    if (filter.status == HistoryStatus.completed &&
        entry.completion.revision > 1) {
      return false;
    }
    if (filter.status == HistoryStatus.corrected &&
        entry.completion.revision == 1) {
      return false;
    }
    return true;
  }).toList();
  result.sort((HistoryEntry a, HistoryEntry b) {
    var compared = b.completion.actualDate.compareTo(a.completion.actualDate);
    if (compared != 0) return compared;
    compared = b.completion.scheduledDate.compareTo(a.completion.scheduledDate);
    if (compared != 0) return compared;
    compared = a.task.name.toLowerCase().compareTo(b.task.name.toLowerCase());
    if (compared != 0) return compared;
    return a.completion.id.compareTo(b.completion.id);
  });
  return result;
}
