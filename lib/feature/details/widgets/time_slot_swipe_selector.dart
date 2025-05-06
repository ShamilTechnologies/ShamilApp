// lib/feature/details/widgets/time_slot_swipe_selector.dart

import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// A widget that displays available time slots as chips and allows
/// selecting a range via a swipe gesture.
class TimeSlotSwipeSelector extends StatefulWidget {
  final List<TimeOfDay> availableSlots;
  final TimeOfDay? confirmedStartTime; // From Bloc state
  final TimeOfDay? confirmedEndTime;   // From Bloc state
  final Function(TimeOfDay start, TimeOfDay end) onRangeSelected; // Callback
  final int serviceDurationMinutes; // Needed to calculate end time

  const TimeSlotSwipeSelector({
    super.key,
    required this.availableSlots,
    this.confirmedStartTime,
    this.confirmedEndTime,
    required this.onRangeSelected,
    required this.serviceDurationMinutes,
  });

  @override
  State<TimeSlotSwipeSelector> createState() => _TimeSlotSwipeSelectorState();
}

class _TimeSlotSwipeSelectorState extends State<TimeSlotSwipeSelector> {
  // --- State for Swipe Selection ---
  int? _swipeStartIndex;
  int? _swipeCurrentIndex;
  final Map<int, GlobalKey> _chipKeys = {};
  GlobalKey _wrapGestureDetectorKey = GlobalKey();
  RenderBox? _wrapRenderBox;

  @override
  void initState() {
    super.initState();
    _generateKeys();
    // Get RenderBox after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRenderBox());
  }

  @override
  void didUpdateWidget(covariant TimeSlotSwipeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regenerate keys if the number of slots changes
    if (oldWidget.availableSlots.length != widget.availableSlots.length) {
      _generateKeys();
       // Update RenderBox reference after keys are potentially regenerated
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateRenderBox());
    }
  }

  /// Generates GlobalKeys for each chip based on availableSlots.
  void _generateKeys() {
    _chipKeys.clear();
    widget.availableSlots.asMap().forEach((index, _) {
      _chipKeys[index] = GlobalKey();
    });
  }

  /// Updates the reference to the RenderBox for hit testing.
  void _updateRenderBox() {
     if (mounted && _wrapGestureDetectorKey.currentContext != null) {
       setState(() {
         _wrapRenderBox = _wrapGestureDetectorKey.currentContext!.findRenderObject() as RenderBox?;
       });
     }
  }

  /// Helper to convert TimeOfDay to total minutes since midnight.
  int _timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  /// Finds the index of the chip within the Wrap widget based on global position.
  int? _findChipIndex(Offset globalPosition) {
    int? nearestIndex;
    final RenderBox? containerRenderBox = _wrapRenderBox;
    if (containerRenderBox == null || !containerRenderBox.hasSize) return null;
    final Offset localPosition = containerRenderBox.globalToLocal(globalPosition);
    double minDistanceSq = double.infinity;

    _chipKeys.forEach((index, key) {
      final RenderBox? chipRenderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (chipRenderBox != null && chipRenderBox.hasSize) {
        try {
          final Offset chipOriginInContainer = chipRenderBox.localToGlobal(Offset.zero, ancestor: containerRenderBox);
          final Rect chipRect = chipOriginInContainer & chipRenderBox.size;
          if (chipRect.contains(localPosition)) {
            final Offset chipCenterInContainer = chipRect.center;
            final double distSq = (localPosition - chipCenterInContainer).distanceSquared;
            if (distSq < minDistanceSq) {
              minDistanceSq = distSq;
              nearestIndex = index;
            }
          }
        } catch (e) { /* Handle transform errors */ }
      }
    });
    return nearestIndex;
  }

  // --- Gesture Handlers ---
  void _onPanStart(DragStartDetails details) {
    final index = _findChipIndex(details.globalPosition);
    if (index != null) {
      setState(() { _swipeStartIndex = index; _swipeCurrentIndex = index; });
    } else {
      setState(() { _swipeStartIndex = null; _swipeCurrentIndex = null; });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_swipeStartIndex == null) return;
    final index = _findChipIndex(details.globalPosition);
    if (index != null && index != _swipeCurrentIndex) {
      setState(() { _swipeCurrentIndex = index; });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_swipeStartIndex != null && _swipeCurrentIndex != null) {
      final int startIndex = min(_swipeStartIndex!, _swipeCurrentIndex!);
      final int endIndex = max(_swipeStartIndex!, _swipeCurrentIndex!);

      if (startIndex >= 0 && endIndex < widget.availableSlots.length) {
        final TimeOfDay startTime = widget.availableSlots[startIndex];
        final duration = widget.serviceDurationMinutes;

        if (duration > 0) {
          final TimeOfDay lastSelectedSlotStartTime = widget.availableSlots[endIndex];
          final int lastSlotStartMinutes = _timeOfDayToMinutes(lastSelectedSlotStartTime);
          final int calculatedEndMinutes = lastSlotStartMinutes + duration;
          final int endHour = (calculatedEndMinutes ~/ 60) % 24;
          final int endMinute = calculatedEndMinutes % 60;
          final TimeOfDay endTime = TimeOfDay(hour: endHour, minute: endMinute);

          // Call the callback to notify the parent/Bloc
          widget.onRangeSelected(startTime, endTime);
        } else {
          print("Swipe End Error: Invalid service duration ($duration).");
          // Optionally show a snackbar via ScaffoldMessenger if context is available
        }
      }
    }
    // Reset swipe tracking state
    setState(() { _swipeStartIndex = null; _swipeCurrentIndex = null; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      key: _wrapGestureDetectorKey, // Assign key here
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
            color: Colors.grey.shade100.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8)),
        child: LayoutBuilder(builder: (context, constraints) {
          // Ensure RenderBox is updated after layout
          WidgetsBinding.instance.addPostFrameCallback((_) => _updateRenderBox());
          return Wrap(
            spacing: 8.0,
            runSpacing: 10.0,
            alignment: WrapAlignment.start,
            children: widget.availableSlots.asMap().entries.map((entry) {
              final index = entry.key;
              final time = entry.value;
              final key = _chipKeys[index]!; // Assume key exists due to _generateKeys

              bool isSelected = false;
              bool isSwipeSelecting = _swipeStartIndex != null;
              int? tempStartIndex = isSwipeSelecting ? min(_swipeStartIndex!, _swipeCurrentIndex!) : null;
              int? tempEndIndex = isSwipeSelecting ? max(_swipeStartIndex!, _swipeCurrentIndex!) : null;

              if (isSwipeSelecting) {
                isSelected = index >= tempStartIndex! && index <= tempEndIndex!;
              } else if (widget.confirmedStartTime != null && widget.confirmedEndTime != null) {
                final slotMins = _timeOfDayToMinutes(time);
                isSelected = slotMins >= _timeOfDayToMinutes(widget.confirmedStartTime!) &&
                             slotMins < _timeOfDayToMinutes(widget.confirmedEndTime!);
              }

              final chipColor = isSelected ? AppColors.primaryColor : AppColors.primaryColor.withOpacity(0.08);
              final chipTextColor = isSelected ? Colors.white : AppColors.primaryColor.withOpacity(0.9);
              final chipBorderColor = isSelected ? AppColors.primaryColor : Colors.grey.shade300;

              return FilterChip(
                key: key,
                label: Text(time.format(context)),
                selected: isSelected,
                showCheckmark: false,
                labelStyle: TextStyle( color: chipTextColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
                selectedColor: chipColor,
                backgroundColor: chipColor,
                shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8), side: BorderSide(color: chipBorderColor, width: 1)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (bool _) {}, // Handled by GestureDetector
              );
            }).toList(),
          );
        }),
      ),
    );
  }
}
