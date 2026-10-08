/// The day the user's week begins on. Drives every weekly view and limit.
enum WeekStart {
  monday(DateTime.monday),
  sunday(DateTime.sunday),
  saturday(DateTime.saturday);

  WeekStart(this.weekday);

  /// The matching [DateTime.weekday] value.
  final int weekday;
}
