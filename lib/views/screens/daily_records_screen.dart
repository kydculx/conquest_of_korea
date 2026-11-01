import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/health_service.dart';
import '../../services/supabase_service.dart';
import '../widgets/tactical_app_bar.dart';

const int _dailyTileGoal = 30;
const int _dailyStepLap = 10000;

/// 현지 날짜별 이동 타일 수를 월 달력으로 보여주는 화면.
class DailyRecordsScreen extends StatefulWidget {
  const DailyRecordsScreen({super.key});

  @override
  State<DailyRecordsScreen> createState() => _DailyRecordsScreenState();
}

class _DailyRecordsScreenState extends State<DailyRecordsScreen> {
  static const Duration _monthTransitionDuration = Duration(milliseconds: 260);

  late final DateTime _minMonth;
  late final DateTime _maxMonth;
  late final List<DateTime> _months;
  late final PageController _pageController;
  late int _currentPage;

  final Map<String, _MonthRecords> _monthCache = {};
  final Set<String> _backfilledMonths = {};
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _maxMonth = _monthStart(now);
    _minMonth = DateTime(now.year - 6, 1, 1);
    _months = _buildMonths(_minMonth, _maxMonth);
    _currentPage = _months.length - 1;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated) {
      _loadedUserId = null;
      _monthCache.clear();
      _backfilledMonths.clear();
      return;
    }

    final userId = auth.profile?.id;
    if (userId == null || userId == _loadedUserId) return;

    _loadedUserId = userId;
    _monthCache.clear();
    _backfilledMonths.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedUserId != userId) return;
      _loadMonth(_months[_currentPage]);
      _prefetchNeighbors(_currentPage);
    });
  }

  DateTime get _visibleMonth => _months[_currentPage];

  List<DateTime> _buildMonths(DateTime from, DateTime to) {
    final months = <DateTime>[];
    var cursor = DateTime(from.year, from.month, 1);
    final end = DateTime(to.year, to.month, 1);
    while (!cursor.isAfter(end)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return months;
  }

  String _monthKey(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-'
      '${month.month.toString().padLeft(2, '0')}';

  Future<void> _loadMonth(DateTime month, {bool force = false}) async {
    final userId = _loadedUserId;
    if (userId == null) return;

    final state = _monthCache.putIfAbsent(_monthKey(month), _MonthRecords.new);
    if (state.isLoading || (state.loaded && !force)) return;

    setState(() {
      state.isLoading = true;
      state.loadFailed = false;
      state.notReady = false;
    });

    try {
      final supabase = context.read<SupabaseService>();
      final results = await Future.wait([
        supabase.fetchDailyMovedTilesMonth(userId, month),
        supabase.fetchDailyStepsMonth(userId, month),
      ]);

      var stepRecords = results[1];
      final monthKey = _monthKey(month);
      if (!_backfilledMonths.contains(monthKey)) {
        _backfilledMonths.add(monthKey);
        final monthStart = DateTime(month.year, month.month, 1);
        final monthEnd = DateTime(month.year, month.month + 1, 1);
        final healthSteps = await HealthService.instance.getDailySteps(
          monthStart,
          monthEnd,
        );
        if (healthSteps.isNotEmpty) {
          final startKey = _dateKey(monthStart);
          final endKey = _dateKey(monthEnd);
          healthSteps.removeWhere(
            (key, _) =>
                key.compareTo(startKey) < 0 || key.compareTo(endKey) >= 0,
          );
          if (healthSteps.isNotEmpty) {
            await supabase.upsertDailyStepsBulk(userId, healthSteps);
            stepRecords = {...stepRecords, ...healthSteps};
          }
        }
      }

      if (!mounted || _loadedUserId != userId) return;
      setState(() {
        state.records = results[0];
        state.steps = stepRecords;
        state.isLoading = false;
        state.loaded = true;
      });
    } catch (e) {
      if (!mounted || _loadedUserId != userId) return;
      setState(() {
        state.isLoading = false;
        state.loaded = true;
        state.loadFailed = true;
        state.notReady = _isMissingHistoryTable(e);
      });
    }
  }

  void _prefetchNeighbors(int page) {
    for (final offset in const [-1, 1]) {
      final target = page + offset;
      if (target >= 0 && target < _months.length) {
        _loadMonth(_months[target]);
      }
    }
  }

  void _onPageChanged(int page) {
    if (page == _currentPage) return;
    setState(() => _currentPage = page);
    _loadMonth(_months[page]);
    _prefetchNeighbors(page);
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _months.length) return;
    _pageController.animateToPage(
      page,
      duration: _monthTransitionDuration,
      curve: Curves.easeOutCubic,
    );
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
                child: !auth.isAuthenticated
                    ? _buildLoginRequired()
                    : _buildBody(auth, locale),
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
              onTap: _currentPage > 0
                  ? () => _goToPage(_currentPage - 1)
                  : null,
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
              onTap: _currentPage < _months.length - 1
                  ? () => _goToPage(_currentPage + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AuthProvider auth, String locale) {
    if (auth.profile == null) {
      return Center(
        child: CircularProgressIndicator(color: GameColors.accentNeon),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _months.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final month = _months[index];
        final state = _monthCache[_monthKey(month)];

        if (state != null && state.loadFailed) {
          return _buildLoadFailed(month, state);
        }

        return Stack(
          children: [
            _buildCalendarContent(
              locale,
              month,
              state?.records ?? const {},
              state?.steps ?? const {},
              isLoading: state == null || state.isLoading,
            ),
            if (state == null || state.isLoading)
              Positioned(
                top: 6,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 2.5,
                    backgroundColor: Colors.transparent,
                    color: GameColors.accentNeon,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarContent(
    String locale,
    DateTime month,
    Map<String, int> records,
    Map<String, int> steps, {
    bool isLoading = false,
  }) {
    final total = _monthTotal(month, records);
    final recordedDays = _recordedDays(month, records);
    final average = recordedDays > 0 ? total / recordedDays : 0.0;
    final maxDay = _maxDay(month, records);

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
              _buildCalendarGrid(locale, month, records, steps),
              const SizedBox(height: 18),
              _buildStepGraphCard(locale, month, steps),
              if (!isLoading && total <= 0) ...[
                const SizedBox(height: 14),
                _buildEmptyNote(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepGraphCard(
    String locale,
    DateTime month,
    Map<String, int> steps,
  ) {
    final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
    final values = List<int>.generate(daysInMonth, (index) {
      final date = DateTime.utc(month.year, month.month, index + 1);
      return _stepForDate(steps, date);
    });
    final total = values.fold<int>(0, (sum, value) => sum + value);
    final recordedDays = values.where((value) => value > 0).length;
    final average = recordedDays > 0 ? total / recordedDays : 0.0;
    var maxSteps = 0;
    for (final value in values) {
      if (value > maxSteps) maxSteps = value;
    }
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                color: Palette.neonGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                GameStrings.dailyRecordStepsTitle,
                style: TextStyle(
                  color: GameColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                GameStrings.stepsCount(total),
                style: const TextStyle(
                  color: Palette.neonGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${GameStrings.dailyRecordDailyAverage} · '
            '${GameStrings.stepsCount(average.round())}',
            style: TextStyle(
              color: GameColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (maxSteps <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                GameStrings.dailyRecordStepEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: GameColors.textMuted, fontSize: 11.5),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: _StepBarChart(
                values: values,
                maxValue: maxSteps,
                todayDay: isCurrentMonth ? now.day : null,
                month: month,
                locale: locale,
              ),
            ),
        ],
      ),
    );
  }

  int _stepForDate(Map<String, int> steps, DateTime date) {
    return steps[_dateKey(date)] ?? 0;
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

  Widget _buildCalendarGrid(
    String locale,
    DateTime monthDate,
    Map<String, int> records,
    Map<String, int> steps,
  ) {
    final year = monthDate.year;
    final month = monthDate.month;
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
        childAspectRatio: 0.72,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - leadingEmptyCells + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime.utc(year, month, dayNumber);
        final count = _recordForDate(records, date);
        final stepCount = _stepForDate(steps, date);
        final isToday = _isSameDay(date, today);

        return _buildDayCell(
          date: date,
          count: count,
          steps: stepCount,
          isToday: isToday,
          locale: locale,
        );
      },
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required int? count,
    required int steps,
    required bool isToday,
    required String locale,
  }) {
    final value = count ?? 0;
    final hasRecord = value > 0;
    final countLabel = hasRecord
        ? '${_formatCount(value, locale)} ${GameStrings.dailyRecordTileUnit}'
        : GameStrings.dailyRecordNoRecord;
    final borderColor = isToday
        ? GameColors.accentNeon.withValues(alpha: 0.58)
        : GameColors.borderLight;
    void onTap() => _showDayDetail(date, value, steps, locale);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label:
          '${date.month}/${date.day} '
          '${isToday ? GameStrings.dailyRecordToday : ''} '
          '$countLabel '
          '${GameStrings.stepsCount(steps)}',
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
          decoration: BoxDecoration(
            color: isToday
                ? GameColors.accentNeon.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.025),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: borderColor, width: isToday ? 1.2 : 1),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ringSize = constraints.maxWidth
                  .clamp(26.0, 40.0)
                  .toDouble();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          fontWeight: isToday
                              ? FontWeight.w800
                              : FontWeight.w600,
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
                  Center(
                    child: _TileRing(
                      count: value,
                      goal: _dailyTileGoal,
                      steps: steps,
                      size: ringSize,
                      locale: locale,
                      achieved: value >= _dailyTileGoal,
                    ),
                  ),
                  const Spacer(),
                ],
              );
            },
          ),
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

  Widget _buildLoadFailed(DateTime month, _MonthRecords state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.notReady
                  ? Icons.cloud_off_rounded
                  : Icons.error_outline_rounded,
              color: GameColors.textMuted,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              state.notReady
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
              onPressed: () => _loadMonth(month, force: true),
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

  Future<void> _showDayDetail(
    DateTime date,
    int count,
    int steps,
    String locale,
  ) async {
    final achieved = count >= _dailyTileGoal;
    final remaining = math.max(0, _dailyTileGoal - count);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: GameColors.backgroundMedium,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: GameColors.borderNeon.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            GameStrings.dailyRecordDetailTitle,
                            style: TextStyle(
                              color: GameColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${DateFormat.yMMMMd(locale).format(date)} '
                            '(${DateFormat.EEEE(locale).format(date)})',
                            style: TextStyle(
                              color: GameColors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                      color: GameColors.textMuted,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: _TileRing(
                    count: count,
                    goal: _dailyTileGoal,
                    steps: steps,
                    size: 132,
                    locale: locale,
                    achieved: achieved,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${GameStrings.dailyRecordMovedTiles} · '
                  '${_formatCount(count, locale)} '
                  '${GameStrings.dailyRecordTileUnit}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GameColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.directions_walk_rounded,
                      color: Palette.neonGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      GameStrings.stepsCount(steps),
                      style: const TextStyle(
                        color: Palette.neonGreen,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (achieved
                                ? Palette.footprintMint
                                : GameColors.accentNeon)
                            .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color:
                          (achieved
                                  ? Palette.footprintMint
                                  : GameColors.accentNeon)
                              .withValues(alpha: 0.24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        achieved
                            ? Icons.check_circle_rounded
                            : Icons.flag_rounded,
                        color: achieved
                            ? Palette.footprintMint
                            : GameColors.accentNeon,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${GameStrings.dailyRecordGoal} · '
                              '$_dailyTileGoal '
                              '${GameStrings.dailyRecordTileUnit}',
                              style: TextStyle(
                                color: GameColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              achieved
                                  ? GameStrings.dailyRecordGoalAchieved
                                  : GameStrings.dailyRecordGoalRemaining(
                                      remaining,
                                    ),
                              style: TextStyle(
                                color: achieved
                                    ? Palette.footprintMint
                                    : GameColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (count == 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    GameStrings.dailyRecordDetailEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GameColors.textSecondary,
                    side: BorderSide(color: GameColors.dividerColor),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(GameStrings.close),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMonthPicker() async {
    final locale = _intlLocale(context);
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return _MonthPickerDialog(
          initialMonth: _visibleMonth,
          maxMonth: _maxMonth,
          locale: locale,
        );
      },
    );
    if (picked == null || !mounted) return;

    final index = _months.indexWhere(
      (month) => month.year == picked.year && month.month == picked.month,
    );
    if (index < 0) return;

    if ((index - _currentPage).abs() <= 1) {
      _goToPage(index);
    } else {
      _pageController.jumpToPage(index);
      _onPageChanged(index);
    }
  }

  int? _recordForDate(Map<String, int> records, DateTime date) {
    return records[_dateKey(date)];
  }

  int _monthTotal(DateTime month, Map<String, int> records) {
    final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
    var total = 0;
    for (var day = 1; day <= daysInMonth; day++) {
      total +=
          records[_dateKey(DateTime.utc(month.year, month.month, day))] ?? 0;
    }
    return total;
  }

  int _recordedDays(DateTime month, Map<String, int> records) {
    final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
    var days = 0;
    for (var day = 1; day <= daysInMonth; day++) {
      final count =
          records[_dateKey(DateTime.utc(month.year, month.month, day))] ?? 0;
      if (count > 0) days++;
    }
    return days;
  }

  int _maxDay(DateTime month, Map<String, int> records) {
    final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
    var max = 0;
    for (var day = 1; day <= daysInMonth; day++) {
      final count =
          records[_dateKey(DateTime.utc(month.year, month.month, day))] ?? 0;
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

class _MonthRecords {
  Map<String, int> records = const <String, int>{};
  Map<String, int> steps = const <String, int>{};
  bool isLoading = false;
  bool loaded = false;
  bool loadFailed = false;
  bool notReady = false;
}

class _TileRing extends StatelessWidget {
  final int count;
  final int goal;
  final int steps;
  final double size;
  final String locale;
  final bool achieved;

  const _TileRing({
    required this.count,
    required this.goal,
    required this.steps,
    required this.size,
    required this.locale,
    required this.achieved,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = count <= 0
        ? GameColors.textMuted.withValues(alpha: 0.6)
        : achieved
        ? Palette.footprintMint
        : GameColors.textPrimary;
    final double tileTarget = count / goal;
    final double stepTarget = steps / _dailyStepLap;
    final double maxTarget = math.max(tileTarget, stepTarget).toDouble();
    final double tileRatio = maxTarget > 0 ? tileTarget / maxTarget : 0.0;
    final double stepRatio = maxTarget > 0 ? stepTarget / maxTarget : 0.0;
    final double extraLaps = math.max(0.0, maxTarget - 1);
    final Duration animationDuration = Duration(
      milliseconds: (1200 + extraLaps * 600).round(),
    );

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: maxTarget),
        duration: animationDuration,
        curve: Curves.easeInOutCubic,
        builder: (context, animatedMax, child) {
          final progress = animatedMax * tileRatio;
          final stepProgress = animatedMax * stepRatio;
          final countRatio = maxTarget > 0 ? animatedMax / maxTarget : 0.0;
          final countLabel = NumberFormat.decimalPattern(
            locale,
          ).format((count * countRatio).round());
          return CustomPaint(
            painter: _TileRingPainter(
              progress: progress,
              stepProgress: stepProgress,
              achieved: achieved,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(size * 0.12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    countLabel,
                    maxLines: 1,
                    style: TextStyle(
                      color: textColor,
                      fontSize: size * 0.27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TileRingPainter extends CustomPainter {
  final double progress;
  final double stepProgress;
  final bool achieved;

  const _TileRingPainter({
    required this.progress,
    required this.stepProgress,
    required this.achieved,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = (size.width * 0.08).clamp(3.0, 9.0).toDouble();
    final center = Offset(size.width / 2, size.height / 2);
    final double outerRadius = size.width / 2 - strokeWidth / 2;
    final double gap = strokeWidth * 0.55;
    final double innerRadius = outerRadius - strokeWidth - gap;
    if (innerRadius <= 0) return;

    // 그래프 배경(트랙)은 타일 이동 기록 유무와 관계없이 항상 주황 계열로 유지한다.
    const Color tileTrackColor = Palette.softRed;
    final Color tileHeadColor = achieved
        ? Palette.softRed
        : Palette.footprintMint;
    const Color stepHeadColor = Palette.tealOk;

    final Paint outerTrackPaint = Paint()
      ..color = stepHeadColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final Paint innerTrackPaint = Paint()
      ..color = tileTrackColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, outerRadius, outerTrackPaint);
    canvas.drawCircle(center, innerRadius, innerTrackPaint);

    if (progress > 0) {
      final Rect rect = Rect.fromCircle(center: center, radius: innerRadius);
      final double headAngle = -math.pi / 2 + math.pi * 2 * progress;
      final Offset head = Offset(
        center.dx + innerRadius * math.cos(headAngle),
        center.dy + innerRadius * math.sin(headAngle),
      );
      final Offset tangent = Offset(-math.sin(headAngle), math.cos(headAngle));

      _drawSolidArc(
        canvas,
        rect,
        tileHeadColor,
        progress.clamp(0.0, 1.0),
        strokeWidth,
      );
      // 링을 모두 그린 뒤 머리를 마지막에 얹어, 여러 바퀴가 겹쳐도 항상 보이게 한다.
      _drawHead(canvas, head, tangent, strokeWidth, tileHeadColor);
    }

    if (stepProgress > 0) {
      final Rect rect = Rect.fromCircle(center: center, radius: outerRadius);
      final double headAngle = -math.pi / 2 + math.pi * 2 * stepProgress;
      final Offset head = Offset(
        center.dx + outerRadius * math.cos(headAngle),
        center.dy + outerRadius * math.sin(headAngle),
      );
      final Offset tangent = Offset(-math.sin(headAngle), math.cos(headAngle));

      _drawSolidArc(
        canvas,
        rect,
        stepHeadColor,
        stepProgress.clamp(0.0, 1.0),
        strokeWidth,
      );
      // 링을 모두 그린 뒤 머리를 마지막에 얹어, 여러 바퀴가 겹쳐도 항상 보이게 한다.
      _drawHead(canvas, head, tangent, strokeWidth, stepHeadColor);
    }
  }

  void _drawSolidArc(
    Canvas canvas,
    Rect rect,
    Color color,
    double progress,
    double strokeWidth,
  ) {
    if (progress <= 0) return;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, paint);
  }

  /// 머리 색은 몸통과 동일하게 유지하고, 머리 각도(진행 방향) 앞쪽에만
  /// 그림자를 드리워 머리 위치가 항상 드러나게 한다.
  void _drawHead(
    Canvas canvas,
    Offset head,
    Offset tangent,
    double strokeWidth,
    Color color,
  ) {
    // 1. 머리 각도에 맞춰 앞쪽에 드리우는 그림자
    //    넓게 퍼지는 그림자 위에 가까운 진한 그림자를 겹쳐 음영을 강조한다.
    final Paint softShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.26)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        math.max(2.0, strokeWidth * 0.3),
      );
    canvas.drawCircle(
      head + tangent * (strokeWidth * 0.62),
      strokeWidth * 0.62,
      softShadowPaint,
    );

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        math.max(1.5, strokeWidth * 0.18),
      );
    canvas.drawCircle(
      head + tangent * (strokeWidth * 0.5),
      strokeWidth * 0.5,
      shadowPaint,
    );

    // 2. 몸통과 같은 색으로 머리 끝을 둥글게 마감한다.
    //    머리와 겹치는 그림자는 덮이고, 앞쪽 그림자만 남는다.
    canvas.drawCircle(head, strokeWidth * 0.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TileRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.stepProgress != stepProgress ||
        oldDelegate.achieved != achieved;
  }
}

class _StepBarChartPainter extends CustomPainter {
  final List<int> values;
  final int maxValue;
  final int? todayDay;

  const _StepBarChartPainter({
    required this.values,
    required this.maxValue,
    required this.todayDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || maxValue <= 0) return;

    const double labelHeight = 16;
    const double topPadding = 6;
    final double chartHeight = size.height - labelHeight - topPadding;
    if (chartHeight <= 0) return;

    final double slotWidth = size.width / values.length;
    final double barWidth = (slotWidth * 0.62).clamp(2.0, 10.0).toDouble();

    final gridPaint = Paint()
      ..color = GameColors.borderLight.withValues(alpha: 0.45)
      ..strokeWidth = 0.8;
    for (final ratio in const [0.0, 0.5, 1.0]) {
      final y = topPadding + chartHeight * (1 - ratio);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final ratio = value / maxValue;
      final barHeight = chartHeight * ratio;
      if (barHeight <= 0) continue;

      final left = i * slotWidth + (slotWidth - barWidth) / 2;
      final top = topPadding + chartHeight - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      final isToday = todayDay == i + 1;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: isToday
              ? [Palette.tealOk.withValues(alpha: 0.55), Palette.tealOk]
              : [
                  Palette.neonGreen.withValues(alpha: 0.3),
                  Palette.neonGreen.withValues(alpha: 0.85),
                ],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);
    }

    final labelDays = <int>{1, 5, 10, 15, 20, 25, values.length};
    for (final day in labelDays) {
      if (day < 1 || day > values.length) continue;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$day',
          style: TextStyle(
            color: GameColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final centerX = (day - 0.5) * slotWidth;
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, size.height - labelHeight + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StepBarChartPainter oldDelegate) {
    if (oldDelegate.maxValue != maxValue || oldDelegate.todayDay != todayDay) {
      return true;
    }
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

class _StepBarChart extends StatefulWidget {
  final List<int> values;
  final int maxValue;
  final int? todayDay;
  final DateTime month;
  final String locale;

  const _StepBarChart({
    required this.values,
    required this.maxValue,
    required this.todayDay,
    required this.month,
    required this.locale,
  });

  @override
  State<_StepBarChart> createState() => _StepBarChartState();
}

class _StepBarChartState extends State<_StepBarChart> {
  int? _selectedDay;

  void _updateSelection(Offset localPosition, double width) {
    if (widget.values.isEmpty || width <= 0) return;
    final double clampedX = localPosition.dx.clamp(0.0, width - 0.001);
    final int day = (clampedX / width * widget.values.length).floor() + 1;
    final int safeDay = day.clamp(1, widget.values.length);
    if (safeDay != _selectedDay) {
      setState(() => _selectedDay = safeDay);
    }
  }

  void _clearSelection() {
    if (_selectedDay == null) return;
    setState(() => _selectedDay = null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int? selectedDay = _selectedDay;
        return Listener(
          onPointerUp: (_) => _clearSelection(),
          onPointerCancel: (_) => _clearSelection(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: (details) =>
                _updateSelection(details.localPosition, width),
            onLongPressMoveUpdate: (details) =>
                _updateSelection(details.localPosition, width),
            onLongPressEnd: (_) => _clearSelection(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StepBarChartPainter(
                      values: widget.values,
                      maxValue: widget.maxValue,
                      todayDay: widget.todayDay,
                    ),
                  ),
                ),
                if (selectedDay != null) _buildTooltip(selectedDay, width),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTooltip(int day, double width) {
    const double desiredBubbleWidth = 142;
    final double bubbleWidth = math.min(desiredBubbleWidth, width - 8);
    final double barCenterX = (day - 0.5) * (width / widget.values.length);
    final double maxLeft = math.max(4.0, width - bubbleWidth - 4.0);
    final double bubbleLeft = (barCenterX - bubbleWidth / 2).clamp(
      4.0,
      maxLeft,
    );
    final double pointerMin = math.min(14.0, bubbleWidth / 2);
    final double pointerMax = math.max(pointerMin, bubbleWidth - 14.0);
    final double pointerX = (barCenterX - bubbleLeft).clamp(
      pointerMin,
      pointerMax,
    );
    final int steps = widget.values[day - 1];
    final DateTime date = DateTime.utc(
      widget.month.year,
      widget.month.month,
      day,
    );
    final String dateLabel = DateFormat.MMMd(widget.locale).format(date);

    return Positioned(
      left: bubbleLeft,
      top: 0,
      width: bubbleWidth,
      child: _StepChartTooltip(
        dateLabel: dateLabel,
        steps: steps,
        pointerX: pointerX,
      ),
    );
  }
}

class _StepChartTooltip extends StatelessWidget {
  final String dateLabel;
  final int steps;
  final double pointerX;

  const _StepChartTooltip({
    required this.dateLabel,
    required this.steps,
    required this.pointerX,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StepTooltipPainter(pointerX: pointerX),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GameColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              GameStrings.stepsCount(steps),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Palette.neonGreen,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTooltipPainter extends CustomPainter {
  final double pointerX;

  const _StepTooltipPainter({required this.pointerX});

  @override
  void paint(Canvas canvas, Size size) {
    const double pointerHeight = 6;
    const double radius = 10;
    final double bodyHeight = size.height - pointerHeight;
    if (bodyHeight <= 0 || size.width <= 0) return;

    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, bodyHeight),
      const Radius.circular(radius),
    );
    final double px = pointerX.clamp(radius, size.width - radius);
    final Path pointer = Path()
      ..moveTo(px - 6, bodyHeight)
      ..lineTo(px, size.height)
      ..lineTo(px + 6, bodyHeight)
      ..close();

    final shadowPath = Path()
      ..addRRect(body)
      ..addPath(pointer, Offset.zero);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(shadowPath.shift(const Offset(0, 2)), shadowPaint);

    final fillPaint = Paint()
      ..color = GameColors.backgroundMedium.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(body, fillPaint);

    final borderPaint = Paint()
      ..color = Palette.neonGreen.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(body, borderPaint);

    canvas.drawPath(pointer, fillPaint);
    final pointerBorder = Path()
      ..moveTo(px - 6, bodyHeight)
      ..lineTo(px, size.height)
      ..lineTo(px + 6, bodyHeight);
    canvas.drawPath(pointerBorder, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _StepTooltipPainter oldDelegate) =>
      oldDelegate.pointerX != pointerX;
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
