# Domain boundary

Pure Dart entities, value objects, invariants, and date-only scheduling rules live
here. Domain code must not import Flutter, plugins, persistence adapters, or
presentation code. Scheduling work added by later issues must accept explicit
clock and time-zone context.
