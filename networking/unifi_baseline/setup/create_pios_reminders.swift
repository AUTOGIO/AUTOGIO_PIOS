import EventKit
import Foundation

let listName = "PIOS Network"
let shortcutURL = "shortcuts://run-shortcut?name=PIOS%20UniFi%20Daily%20Health"
let actionScript = "\(NSHomeDirectory())/AUTOGIO_PIOS/networking/unifi_baseline/scripts/pios_reminder_action.zsh"
let body = """
Tap the link below to run the health check and open today's log.

\(shortcutURL)

Manual:
zsh \(actionScript)
"""

let reminderTitles = [
    ("PIOS Daily Health (10am)", 10, 0),
    ("PIOS Daily Health (10pm)", 22, 0),
]

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

// Remove existing PIOS daily reminders
var existing: [EKReminder] = []
let fetchSem = DispatchSemaphore(value: 0)
store.fetchReminders(matching: store.predicateForReminders(in: [calendar])) { items in
    existing = items ?? []
    fetchSem.signal()
}
fetchSem.wait()

for item in existing {
    let t = item.title ?? ""
    if t.hasPrefix("PIOS Daily Health") {
        try? store.remove(item, commit: true)
    }
}

let cal = Calendar.current
let now = Date()

for (title, hour, minute) in reminderTitles {
    var components = cal.dateComponents([.year, .month, .day], from: now)
    components.hour = hour
    components.minute = minute
    components.second = 0
    guard var due = cal.date(from: components) else { continue }
    if due <= now {
        due = cal.date(byAdding: .day, value: 1, to: due) ?? due
    }

    let reminder = EKReminder(eventStore: store)
    reminder.calendar = calendar
    reminder.title = title
    reminder.notes = body
    reminder.dueDateComponents = cal.dateComponents([.year, .month, .day, .hour, .minute], from: due)
    reminder.isCompleted = false
    reminder.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil)]

    let alarm = EKAlarm(absoluteDate: due)
    reminder.addAlarm(alarm)

    try! store.save(reminder, commit: true)
    print("Created: \(title) — daily at \(hour):\(String(format: "%02d", minute))")
}

print("Reminders list: \(listName)")
print("Shortcut link: \(shortcutURL)")
