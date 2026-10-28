import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../widgets/tactical_app_bar.dart';

/// UTC 일자별 이동 타일 수를 월 달력으로 보여주는 화면.
class DailyRecordsScreen extends StatefulWidget {
  const DailyRecordsScreen({super.key});

  @override
  State<DailyRecordsScreen> createState() => _DailyRecordsScreenState();
}

class _DailyRecordsScreenState extends State<DailyRecordsScreen> {
  late DateTime _visibleMonth;
  Map<String, int> _records = {};
  bool _isLoading = true;
  bool _loginRequired = false;
  bool _loadFailed = false;
  bool _notReady = false;
  String? _loadedUserId;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _visibleMonth = _monthStart(DateTime.now());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated) {
      _loadedUserId = null;
      _loginRequired = true;
      _isLoading = false;
      _records = {};
      return;
    }

    final userId = auth.profile?.id;
    if (userId == null) {
      _loginRequired = false;
      _isLoading = true;
      return;
    }

    if (userId != _loadedUserId) {
      _loadedUserId = userId;
      _loginRequired = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _loadedUserId == userId) {
          _loadMonth(_visibleMonth);
        }
      });
    }
  }

  Future<void> _loadMonth(DateTime month) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.profile?.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _loginRequired = !auth.isAuthenticated;
        _isLoading = false;
      });
      return;
    }

    final requestId = ++_requestId;
    setState(() {
      _visibleMonth = _monthStart(month);
      _isLoading = true;
      _loginRequired = false;
      _loadFailed = false;
      _notReady = false;
    });

    try {
      final records = await context
          .read<SupabaseService>()
          .fetchDailyMovedTilesMonth(userId, _visibleMonth);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
        _notReady = _isMissingHistoryTable(e);
      });
    }
  }

  bool _isMissingHistoryTable(Object error) {
    final message = error.toString();
    return message.contains('daily_moved_tiles_history') &&
        (message.contains('does not exist') ||
            message.contains('Could not find the table') ||
            message.contains('42P01'));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = _intlLocale(context);

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      appBar: TacticalAppBar(
        titleText: GameStrings.dailyRecordTitle,
        showBackButton: true,
        backgroundColor: GameColors.tacticalBlack,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: GameColors.cozyDarkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildMonthHeader(locale),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: _handleMonthSwipe,
                  child: !auth.isAuthenticated
                      ? _buildLoginRequired()
                      : _buildBody(locale),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader(String locale) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MonthArrowButton(
              icon: Icons.chevron_left_rounded,
              tooltip: GameStrings.dailyRecordPreviousMonth,
              onTap: () => _changeMonth(-1),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _showMonthPicker,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    DateFormat.yMMMM(locale).format(_visibleMonth),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
            _MonthArrowButton(
              icon: Icons.chevron_right_rounded,
              tooltip: GameStrings.dailyRecordNextMonth,
              onTap: _canGoNextMonth ? () => _changeMonth(1) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String locale) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: GameColors.accentNeon),
      );
    }
    if (_loginRequired) {
      return _buildLoginRequired();
    }
    if (_loadFailed) {
      return _buildLoadFailed();
    }
    return _buildCalendarContent(locale);
  }

  Widget _buildCalendarContent(String locale) {
    final total = _monthTotal();
    final recordedDays = _recordedDays();
    final average = recordedDays > 0 ? total / recordedDays : 0.0;
    final maxDay = _maxDay();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMonthTotalCard(locale, total),
              const SizedBox(height: 10),
              _buildSummaryRow(
                locale: locale,
                recordedDays: recordedDays,
                average: average,
                maxDay: maxDay,
              ),
              const SizedBox(height: 18),
              _buildWeekdayHeader(locale),
              const SizedBox(height: 6),
              _buildCalendarGrid(locale),
              if (total <= 0) ...[
                const SizedBox(height: 14),
                _buildEmptyNote(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthTotalCard(String locale, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameColors.accentNeon.withValues(alpha: 0.16),
            GameColors.backgroundMedium.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GameColors.accentNeon.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GameColors.accentNeon.withValues(alpha: 0.12),
              border: Border.all(
                color: GameColors.accentNeon.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.grid_view_rounded,
              color: GameColors.accentNeon,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GameStrings.dailyRecordMonthTotal,
                  style: TextStyle(
                    color: GameColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatCount(total, locale)} ${GameStrings.dailyRecordTileUnit}',
                  style: TextStyle(
                    color: GameColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String locale,
    required int recordedDays,
    required double average,
    required int maxDay,
  }) {
    return Row(
      children: [
        Expanded(
          child: _SummaryItem(
            label: GameStrings.dailyRecordRecordedDays,
            value: '$recordedDays',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SummaryItem(
            label: GameStrings.dailyRecordDailyAverage,
            value: average.toStringAsFixed(average >= 10 ? 0 : 1),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SummaryItem(
            label: GameStrings.dailyRecordBestDay,
            value: _formatCount(maxDay, locale),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(String locale) {
    final labels = List.generate(
      7,
      (index) => DateFormat.E(locale).format(DateTime.utc(2024, 1, 7 + index)),
    );

    return Row(
      children: List.generate(7, (index) {
        final color = index == 0
            ? Palette.softRed
            : index == 6
            ? Palette.blueSoft
            : GameColors.textMuted;
        return Expanded(
          child: Center(
            child: Text(
              labels[index],
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCalendarGrid(String locale) {
    final year = _visibleMonth.year;
    final month = _visibleMonth.month;
    final firstDay = DateTime.utc(year, month, 1);
    final daysInMonth = DateTime.utc(year, month + 1, 0).day;
    final leadingEmptyCells = firstDay.weekday % 7;
    final itemCount = ((leadingEmptyCells + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.78,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - leadingEmptyCells + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime.utc(year, month, dayNumber);
        final count = _recordForDate(date);
        final isToday = _isSameDay(date, today);

        return _buildDayCell(
          date: date,
          count: count,
          isToday: isToday,
          locale: locale,
        );
      },
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required int? count,
    required bool isToday,
    required String locale,
  }) {
    final hasRecord = count != null && count > 0;
    final countLabel = hasRecord
        ? '${_formatCount(count, locale)} ${GameStrings.dailyRecordTileUnit}'
        : GameStrings.dailyRecordNoRecord;
    final borderColor = isToday
        ? GameColors.accentNeon.withValues(alpha: 0.58)
        : GameColors.borderLight;

    return Semantics(
      excludeSemantics: true,
      label:
          '${date.month}/${date.day} '
          '${isToday ? GameStrings.dailyRecordToday : ''} '
          '$countLabel',
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
        decoration: BoxDecoration(
          color: isToday
              ? GameColors.accentNeon.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: borderColor, width: isToday ? 1.2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isToday
                        ? GameColors.accentNeon
                        : GameColors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isToday)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: GameColors.accentNeon,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                hasRecord ? _formatCount(count, locale) : '-',
                maxLines: 1,
                style: TextStyle(
                  color: hasRecord
                      ? Palette.footprintMint
                      : GameColors.textMuted.withValues(alpha: 0.55),
                  fontSize: 10.5,
                  fontWeight: hasRecord ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GameColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: GameColors.textMuted.withValues(alpha: 0.75),
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              GameStrings.dailyRecordEmpty,
              style: TextStyle(
                color: GameColors.textSecondary,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadFailed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _notReady ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
              color: GameColors.textMuted,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              _notReady
                  ? GameStrings.dailyRecordNotReady
                  : GameStrings.dailyRecordLoadFailed,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GameColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => _loadMonth(_visibleMonth),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(GameStrings.dailyRecordRetry),
              style: TextButton.styleFrom(
                foregroundColor: GameColors.accentNeon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: GameColors.textMuted,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              GameStrings.dailyRecordLoginRequired,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GameColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.login);
              },
              icon: const Icon(Icons.login_rounded, size: 17),
              label: Text(GameStrings.dailyRecordLoginAction),
              style: TextButton.styleFrom(
                foregroundColor: GameColors.accentNeon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canGoNextMonth {
    final currentMonth = _monthStart(DateTime.now());
    return _visibleMonth.isBefore(currentMonth);
  }

  void _changeMonth(int delta) {
    if (_isLoading) return;
    if (delta > 0 && !_canGoNextMonth) return;
    _loadMonth(
      DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1),
    );
  }

  void _handleMonthSwipe(DragEndDetails details) {
    if (_isLoading || _loginRequired || _loadFailed) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return;
    if (velocity < 0) {
      _changeMonth(1);
    } else {
      _changeMonth(-1);
    }
  }

  Future<void> _showMonthPicker() async {
    final locale = _intlLocale(context);
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return _MonthPickerDialog(
          initialMonth: _visibleMonth,
          maxMonth: _monthStart(DateTime.now()),
          locale: locale,
        );
      },
    );
    if (picked != null && mounted) {
      await _loadMonth(picked);
    }
  }

  int? _recordForDate(DateTime date) {
    return _records[_dateKey(date)];
  }

  int _monthTotal() {
    final year = _visibleMonth.year;
    final month = _visibleMonth.month;
    final daysInMonth = DateTime.utc(year, month + 1, 0).day;
    var total = 0;
    for (var day = 1; day <= daysInMonth; day++) {
      total += _records[_dateKey(DateTime.utc(year, month, day))] ?? 0;
    }
    return total;
  }

  int _recordedDays() {
    final year = _visibleMonth.year;
    final month = _visibleMonth.month;
    final daysInMonth = DateTime.utc(year, month + 1, 0).day;
    var days = 0;
    for (var day = 1; day <= daysInMonth; day++) {
      final count = _records[_dateKey(DateTime.utc(year, month, day))] ?? 0;
      if (count > 0) days++;
    }
    return days;
  }

  int _maxDay() {
    final year = _visibleMonth.year;
    final month = _visibleMonth.month;
    final daysInMonth = DateTime.utc(year, month + 1, 0).day;
    var max = 0;
    for (var day = 1; day <= daysInMonth; day++) {
      final count = _records[_dateKey(DateTime.utc(year, month, day))] ?? 0;
      if (count > max) max = count;
    }
    return max;
  }

  String _formatCount(int count, String locale) {
    return NumberFormat.decimalPattern(locale).format(count);
  }

  String _intlLocale(BuildContext context) {
    final tag = Localizations.localeOf(
      context,
    ).toLanguageTag().replaceAll('-', '_');
    try {
      DateFormat.yMMMM(tag).format(DateTime.utc(2026, 10, 1));
      return tag;
    } catch (_) {
      return 'en';
    }
  }

  DateTime _monthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _MonthArrowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _MonthArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.28 : 1.0,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.035),
              border: Border.all(color: GameColors.borderLight),
            ),
            child: Icon(icon, color: GameColors.textSecondary, size: 20),
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: GameColors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: GameColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialMonth;
  final DateTime maxMonth;
  final String locale;

  const _MonthPickerDialog({
    required this.initialMonth,
    required this.maxMonth,
    required this.locale,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    final minYear = widget.maxMonth.year - 6;
    final canGoPrevious = _year > minYear;
    final canGoNext = _year < widget.maxMonth.year;

    return Dialog(
      backgroundColor: GameColors.backgroundMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              GameStrings.dailyRecordPickerTitle,
              style: TextStyle(
                color: GameColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: canGoPrevious
                      ? () => setState(() => _year--)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: GameColors.textSecondary,
                ),
                Expanded(
                  child: Text(
                    '$_year',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canGoNext ? () => setState(() => _year++) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: GameColors.textSecondary,
                ),
              ],
            ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: List.generate(12, (index) {
                final month = index + 1;
                final monthDate = DateTime.utc(_year, month, 1);
                final disabled = monthDate.isAfter(widget.maxMonth);
                final selected =
                    _year == widget.initialMonth.year &&
                    month == widget.initialMonth.month;
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: disabled
                      ? null
                      : () => Navigator.pop(context, monthDate),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? GameColors.accentNeon.withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.025),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? GameColors.accentNeon.withValues(alpha: 0.45)
                            : GameColors.borderLight,
                      ),
                    ),
                    child: Opacity(
                      opacity: disabled ? 0.28 : 1.0,
                      child: Text(
                        DateFormat.MMM(widget.locale).format(monthDate),
                        style: TextStyle(
                          color: selected
                              ? GameColors.accentNeon
                              : GameColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    DateTime.utc(
                      widget.maxMonth.year,
                      widget.maxMonth.month,
                      1,
                    ),
                  ),
                  child: Text(GameStrings.dailyRecordThisMonth),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(GameStrings.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
