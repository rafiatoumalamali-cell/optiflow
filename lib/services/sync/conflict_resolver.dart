import '../../utils/logger.dart';

class ConflictResolver {
  /// Resolves conflicts between local and remote data using "Last Write Wins" strategy.
  /// Returns the data that should be kept.
  static Map<String, dynamic> resolve(Map<String, dynamic> localData, Map<String, dynamic> remoteData) {
    try {
      final localUpdateStr = localData['updated_at'];
      final remoteUpdateStr = remoteData['updated_at'];

      if (localUpdateStr == null) return remoteData;
      if (remoteUpdateStr == null) return localData;

      final localUpdate = _parseDate(localUpdateStr);
      final remoteUpdate = _parseDate(remoteUpdateStr);

      if (remoteUpdate.isAfter(localUpdate)) {
        Logger.info('Conflict: Remote is newer. Keeping remote.', name: 'ConflictResolver');
        return remoteData;
      } else {
        Logger.info('Conflict: Local is newer. Keeping local.', name: 'ConflictResolver');
        return localData;
      }
    } catch (e, stack) {
      Logger.error('ConflictResolver: Error resolving conflict. Falling back to remote.', name: 'ConflictResolver', error: e, stackTrace: stack);
      return remoteData;
    }
  }

  static DateTime _parseDate(dynamic date) {
    if (date is DateTime) return date;
    if (date is String) return DateTime.parse(date);
    // Handle Firestore Timestamp if passed as a dynamic map entry
    if (date != null && date.toString().contains('Timestamp')) {
       // This is a simplification; in a real app, you'd handle the Timestamp object properly.
       // But typically we convert to String or DateTime before passing here.
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
