import EventKit
import Foundation

let listName = "PIOS Network"
let titlePrefix = "PIOS Post-Health Follow-up"
let unifiURL = "https://unifi.ui.com"
let gateChecklist = "\(NSHomeDirectory())/AUTOGIO_PIOS/networking/unifi_baseline/checklists/wan_stability_gate.md"

let delayMinutes: Int = {
    if CommandLine.arguments.count > 1, let n = Int(CommandLine.arguments[1]), n >= 0 {
        return n
    }
    return 15
}()

var verdictLine = "Verdict: (see latest daily_health report)"
if CommandLine.arguments.count > 2 {
    verdictLine = CommandLine.arguments[2]
}

let body = """
After the daily health check — manual WAN gate review.

\(verdictLine)

Checklist:
☐ UniFi → Topology → Starlink (WAN1) — no new disconnect/high-latency since last check
☐ Starlink app — timestamps match (or no new issues)
☐ wan_watch log — confirm hourly samples still PASS (if watch is running)

If disconnects found:
→ Log timestamps in wan_stability_gate.md and investigate cable/port 5

Optional (not blocking baseline):
☐ Local admin + .unifi.local.env (Phase 2 API stats)
☐ giovannini.uk DNS on Cloudflare (Phase 6)

Open UniFi:
\(unifiURL)

Gate checklist:
\(gateChecklist)
"""

let store = EKEventStore()
let semaphore = DispatchSemaphore(value: 0)
var accessGranted = false

if #available(macOS 14.0, *) {
    store.requestFullAccessToReminders { granted, _ in
        accessGranted = granted
        semaphore.signal()
    }
} else {
    store.requestAccess(to: .reminder) { granted, _ in
        accessGranted = granted
        semaphore.signal()
    }
}
semaphore.wait()

guard accessGranted else {
    fputs("ERROR: Reminders access denied. Grant access in System Settings → Privacy → Reminders.\n", stderr)
    exit(1)
}

func calendar(for name: String) -> EKCalendar? {
    store.calendars(for: .reminder).first { $0.title == name }
}

let calendar: EKCalendar
if let existing = calendar(for: listName) {
    calendar = existing
} else {
    let newCal = EKCalendar(for: .reminder, eventStore: store)
    newCal.title = listName
    newCal.source = store.defaultCalendarForNewReminders()?.source
        ?? store.sources.first { $0.sourceType == .local }
        ?? store.sources.first!
    try! store.saveCalendar(newCal, commit: true)
    calendar = newCal
}

var existing: [EKReminder] = []
let fetchSem = DispatchSemaphore(value: 0)
store.fetchReminders(matching: store.predicateForReminders(in: [calendar])) { items in
    existing = items ?? []
    fetchSem.signal()
}
fetchSem.wait()

for item in existing {
    if item.title?.hasPrefix(titlePrefix) == true, !item.isCompleted {
        try? store.remove(item, commit: true)
    }
}

let cal = Calendar.current
let due = cal.date(byAdding: .minute, value: delayMinutes, to: Date()) ?? Date()

let reminder = EKReminder(eventStore: store)
reminder.calendar = calendar
reminder.title = titlePrefix
reminder.notes = body
reminder.dueDateComponents = cal.dateComponents(
    [.year, .month, .day, .hour, .minute],
    from: due
)
reminder.isCompleted = false
reminder.addAlarm(EKAlarm(absoluteDate: due))

try! store.save(reminder, commit: true)

let formatter = DateFormatter()
formatter.dateStyle = .medium
formatter.timeStyle = .short
print("Created: \(titlePrefix) — due \(formatter.string(from: due)) (\(delayMinutes) min after health check)")
