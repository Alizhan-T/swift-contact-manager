import Foundation

final class Contact {
    let id: Int
    var name: String
    var email: String?
    var phones: [(String, String)]     // (phone, label)
    var tags: Set<String>

    init(id: Int, name: String, email: String?, phones: [(String, String)], tags: Set<String>) {
        self.id = id
        self.name = name
        self.email = email
        self.phones = phones
        self.tags = tags
    }

    func line() -> String {
        let emailText = (email?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "—"
        let phonesText = phones.map { "\($0.1):\($0.0)" }.joined(separator: ", ")
        let tagsText = tags.sorted().joined(separator: ", ")
        return "ID \(id) | \(name) | email: \(emailText) | phones: [\(phonesText)] | tags: {\(tagsText)}"
    }
}

// Storage
var list: [Contact] = []                 // List
var byId: [Int: Contact] = [:]           // Map
var usedPhones: Set<String> = []         // Set
var nextId = 1

// ---------- IO helpers ----------
func ask(_ text: String) -> String {
    print(text, terminator: "")
    return readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

func askNonEmpty(_ text: String) -> String {
    while true {
        let s = ask(text)
        if !s.isEmpty { return s }
        print(" Cannot be empty.\n")
    }
}

func askOpt(_ text: String) -> String? {
    let s = ask(text)
    return s.isEmpty ? nil : s
}

func askInt(_ text: String) -> Int? {
    Int(ask(text))
}

// ---------- Core ops ----------
func insert(_ c: Contact) {
    byId[c.id] = c
    if !list.contains(where: { $0.id == c.id }) { list.append(c) }
}

func update(_ c: Contact) {
    byId[c.id] = c
    if let idx = list.firstIndex(where: { $0.id == c.id }) {
        list[idx] = c
    }
}

func addContact() {
    let name = askNonEmpty("Name: ")
    let email = askOpt("Email (enter=skip): ")?.lowercased()

    var phones: [(String, String)] = []
    while true {
        let raw = askNonEmpty("Phone: ")
        let phone = raw.filter { !$0.isWhitespace }

        if phone.isEmpty {
            print(" Phone cannot be empty.\n")
            continue
        }
        if usedPhones.contains(phone) {
            print(" Already exists!\n")
            continue
        }

        let label = (askOpt("Label (enter=mobile): ") ?? "mobile").lowercased()
        phones.append((phone, label))
        usedPhones.insert(phone)

        if ask("More phone? (y/n): ").lowercased() != "y" { break }
    }

    let tagsStr = askOpt("Tags comma (enter=none): ")
    let tags: Set<String> = Set(
        (tagsStr ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    )

    let c = Contact(id: nextId, name: name, email: email, phones: phones, tags: tags)
    nextId += 1
    insert(c)
    print(" Added.\n")
}

func listContacts() {
    if list.isEmpty { print(" No contacts.\n"); return }
    list.forEach { print($0.line()) }
    print()
}

func findContacts() {
    if list.isEmpty { print(" No contacts.\n"); return }
    let q = askNonEmpty("Search (name/email/phone): ").lowercased()

    let results = list.filter { c in
        let nameHit = c.name.lowercased().contains(q)
        let emailHit = (c.email?.lowercased().contains(q) ?? false)
        let phoneHit = c.phones.contains { $0.0.contains(q) || $0.1.lowercased().contains(q) }
        return nameHit || emailHit || phoneHit
    }

    if results.isEmpty { print(" No matches.\n"); return }
    results.forEach { print($0.line()) }
    print()
}

func editContact() {
    guard let id = askInt("ID: "), let c = byId[id] else { print("Not found.\n"); return }

    if let newName = askOpt("New name (enter=keep): ") {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { c.name = trimmed }
    }

    if let newEmail = askOpt("New email (enter=keep): ") {
        let trimmed = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        c.email = trimmed.isEmpty ? nil : trimmed.lowercased()
    }

    if ask("Replace phones? (y/n): ").lowercased() == "y" {
        // remove old phones from usedPhones
        c.phones.forEach { usedPhones.remove($0.0) }

        var newPhones: [(String, String)] = []
        while true {
            let raw = askNonEmpty("Phone: ")
            let phone = raw.filter { !$0.isWhitespace }
            if phone.isEmpty { print(" Phone cannot be empty.\n"); continue }
            if usedPhones.contains(phone) { print("Already exists!\n"); continue }

            let label = (askOpt("Label (enter=mobile): ") ?? "mobile").lowercased()
            newPhones.append((phone, label))
            usedPhones.insert(phone)

            if ask("More phone? (y/n): ").lowercased() != "y" { break }
        }
        c.phones = newPhones
    }

    if let tagsStr = askOpt("New tags comma (enter=keep): ") {
        c.tags = Set(
            tagsStr.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
    }

    update(c)
    print(" Updated.\n")
}

func deleteContact() {
    guard let id = askInt("ID: "), let c = byId[id] else { print("Not found.\n"); return }
    c.phones.forEach { usedPhones.remove($0.0) }
    byId.removeValue(forKey: id)
    list.removeAll { $0.id == id }
    print(" Deleted.\n")
}

// ---------- Menu ----------
while true {
    print("""
    ===== Contact Manager =====
    1 Add   2 List   3 Find   4 Update   5 Delete   0 Exit
    """)
    switch ask("Choose: ") {
    case "1": addContact()
    case "2": listContacts()
    case "3": findContacts()
    case "4": editContact()
    case "5": deleteContact()
    case "0": exit(0)
    default: print("Wrong option.\n")
    }
}
