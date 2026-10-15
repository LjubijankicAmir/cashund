/// How often the buddy reacts right after something is logged.
enum ReactionFrequency {
  /// After every new transaction.
  always,

  /// After every n-th new transaction; see `UserPreferences.reactionInterval`.
  sometimes,

  never,
}
