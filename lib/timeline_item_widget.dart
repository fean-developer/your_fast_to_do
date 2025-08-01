import 'timer_screen.dart';

import 'timeline_item.dart';
import 'package:flutter/material.dart';
import 'timeline_item.dart';

class TimelineItemWidget extends StatelessWidget {
  final dynamic item;
  final int itemNumber;
  final bool isLast;
  final VoidCallback onToggle;
  final Function(int) onSubItemToggle;

  const TimelineItemWidget({
    super.key,
    required this.item,
    required this.itemNumber,
    required this.isLast,
    required this.onToggle,
    required this.onSubItemToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and circle
          Column(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: item.isCompleted ? item.color : Colors.white,
                    border: Border.all(
                      color: item.color,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: item.isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 30)
                      : Icon(item.icon, color: item.color, size: 30),
                ),
              ),
              if (!isLast)
                Container(
                  width: 3,
                  height: 100,
                  color: item.color.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '0$itemNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: item.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                // Sub-items with checkboxes
                ...List.generate(item.subItems.length, (subIndex) => SubItemWidget(
                  subItem: item.subItems[subIndex],
                  parentCompleted: item.isCompleted,
                  color: item.color,
                  isCompleted: item.subItems[subIndex].completed,
                  onToggle: () {
                    onSubItemToggle(subIndex);
                  },
                  onTimer: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TimerScreen(
                          subItem: item.subItems[subIndex],
                          onSave: () {},
                        ),
                      ),
                    );
                  },
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SubItemWidget extends StatelessWidget {
  final SubItem subItem;
  final bool parentCompleted;
  final Color color;
  final bool isCompleted;
  final VoidCallback onToggle;
  final VoidCallback onTimer;

  SubItemWidget({
    Key? key,
    required this.subItem,
    required this.parentCompleted,
    required this.color,
    required this.isCompleted,
    required this.onToggle,
    required this.onTimer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subItem.subitem,
              style: TextStyle(
                fontSize: 12,
                color: isCompleted ? Colors.grey : Colors.black87,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
            IconButton(
            icon: Icon(Icons.play_arrow, size: 18, color: isCompleted ? Colors.grey : Colors.green),
            tooltip: 'Iniciar/Ver Timer',
            onPressed: isCompleted ? null : onTimer,
            disabledColor: Colors.grey,
            ),
        ],
      ),
    );
  }
}
