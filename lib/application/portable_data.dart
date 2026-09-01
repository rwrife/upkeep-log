import 'package:upkeep_log/domain/domain.dart';

/// Complete structured state at the application boundary.
///
/// [completionRevisions] contains every revision, ordered by completion ID and
/// revision. It deliberately does not collapse history to the latest value.
final class PortableData {
  const PortableData({
    required this.homes,
    required this.rooms,
    required this.assets,
    required this.tasks,
    required this.occurrences,
    required this.completionRevisions,
    required this.attachments,
  });

  final List<HomeProfile> homes;
  final List<Room> rooms;
  final List<Asset> assets;
  final List<TaskTemplate> tasks;
  final List<TaskOccurrence> occurrences;
  final List<Completion> completionRevisions;
  final List<AttachmentMetadata> attachments;
}
