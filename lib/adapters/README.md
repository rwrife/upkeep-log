# Adapter boundary

Concrete Drift/SQLite, app-private file, local-notification, and document-picker
implementations live here. Adapters implement ports owned by `application` and
may use domain types, but they must not import presentation code.
