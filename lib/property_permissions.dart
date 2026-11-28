/// UI-level ownership guard. Supabase RLS remains the authoritative security boundary.
bool canEditProperty({
  required bool manager,
  required String? currentUserId,
  required String? ownerId,
}) {
  if (manager) return true;
  return currentUserId != null &&
      currentUserId.isNotEmpty &&
      ownerId != null &&
      ownerId.isNotEmpty &&
      currentUserId == ownerId;
}
