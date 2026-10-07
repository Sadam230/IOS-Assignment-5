// =============================================================
//  Station ALMA-7, Part III: The Repair Fleet
//  iOS Mobile Development · Module 5 · Lab Assignment
//
//  How to use:
//   • Xcode: File → New → Playground → Blank, replace everything
//     with this file's contents.
//   • Terminal: swift ALMA7_Part3_Starter.swift
//
//  Rules:
//   • Do NOT modify the STARTER DATA section. LegacyBeacon in
//     particular must be reached with an extension, not edited.
//   • `!` (force unwrap) is forbidden: −0.5 points each.
//   • No map / filter / reduce / compactMap.
//   • The Health Rule must exist in exactly ONE place in this file.
// =============================================================


// MARK: - =================== STARTER DATA ===================
// MARK: - Do not modify anything in this section

/// Drone records recovered from the fleet registry.
/// One `kind` does not correspond to any drone type you will build.
let fleetData: [(kind: String, id: String, charge: Int)] = [
    (kind: "welder",  id: "W-1", charge: 80),
    (kind: "scanner", id: "S-1", charge: 45),
    (kind: "cargo",   id: "C-1", charge: 100),
    (kind: "welder",  id: "W-2", charge: 15),
    (kind: "scanner", id: "S-2", charge: 60),
    (kind: "tug",     id: "T-1", charge: 50)
]

/// Hull sensors. These are NOT drones — they never move and never work a shift.
let sensorData: [(id: String, charge: Int)] = [
    (id: "hull-cam", charge: 12),
    (id: "thermal",  charge: 77)
]

/// Hardware from the original station. You may not add anything to this
/// declaration — no methods, no protocols, no properties.
struct LegacyBeacon {
    let name: String
    let signalStrength: Int
}

let beacon = LegacyBeacon(name: "ALMA-BEACON", signalStrength: 8)

print("Fleet registry online: \(fleetData.count) drone records, \(sensorData.count) sensors, beacon \(beacon.name).")

// MARK: - ================= END OF STARTER DATA =================


// MARK: - =================== YOUR SOLUTION ===================
// Uncomment each declaration when you start working on it.


// MARK: Level 1 · The Power Cell

// Why a class and not a struct here?  ->
// A class gives reference semantics, so the same PowerCell instance can be shared and mutated.
final class PowerCell {
    private var charge: Int

    init(charge: Int) {
        if charge < 0 {
            self.charge = 0
        } else if charge > 100 {
            self.charge = 100
        } else {
            self.charge = charge
        }
    }

    func level() -> Int {
        return charge
    }

    func spend(_ amount: Int) -> Bool {
        if amount <= 0 || amount > charge {
            return false
        }

        charge -= amount
        return true
    }

    func recharge(by amount: Int) {
        if amount <= 0 {
            return
        }

        charge += amount
        if charge > 100 {
            charge = 100
        }
    }
}

// Encapsulation proof (leave this commented, with the compiler error):
// let cell = PowerCell(charge: 50)
// cell.charge = 100
// error: 'charge' is inaccessible due to 'private' protection level


// MARK: Level 2 · The Fleet

// 2.1  What does `final` on runOnce() buy you?  ->
// It prevents subclasses from overriding the shift ritual, so every drone must spend power before performing a task.
class Drone {
    let id: String
    let cell: PowerCell

    init(id: String, cell: PowerCell) {
        self.id = id
        self.cell = cell
    }

    var powerCost: Int {
        return 10
    }

    var statusLine: String {
        return "\(id): \(cell.level())% \(cell.level().powerBar)"
    }

    func performTask() -> Int {
        return 0
    }

    final func runOnce() -> Int {
        if cell.spend(powerCost) {
            return performTask()
        }
        return 0
    }
}

// 2.2
final class WelderDrone: Drone {
    override var powerCost: Int {
        return 25
    }

    override func performTask() -> Int {
        return 40
    }

    func weldSeam() -> String {
        return "Welder \(id) welded a seam"
    }
}

class ScannerDrone: Drone {
    override var powerCost: Int {
        return 10
    }

    override var statusLine: String {
        return "[scanner] " + super.statusLine
    }

    override func performTask() -> Int {
        return 15
    }
}

final class CargoDrone: Drone {
    override var powerCost: Int {
        return 20
    }

    override func performTask() -> Int {
        return 25
    }
}

// 2.3
func makeDrone(kind: String, id: String, charge: Int) -> Drone? {
    let cell = PowerCell(charge: charge)

    if kind == "welder" {
        return WelderDrone(id: id, cell: cell)
    } else if kind == "scanner" {
        return ScannerDrone(id: id, cell: cell)
    } else if kind == "cargo" {
        return CargoDrone(id: id, cell: cell)
    } else {
        return nil
    }
}

var fleet: [Drone] = []

for record in fleetData {
    if let drone = makeDrone(
        kind: record.kind,
        id: record.id,
        charge: record.charge
    ) {
        fleet.append(drone)
    } else {
        print("Warning: skipped unknown drone kind \(record.kind)")
    }
}


// MARK: Level 3 · The Shift

func runShift(_ fleet: [Drone], rounds: Int) -> Int {
    var totalWork = 0

    if rounds <= 0 {
        return 0
    }

    for _ in 1...rounds {
        for drone in fleet {
            totalWork += drone.runOnce()
        }
    }

    return totalWork
}

let A = runShift(fleet, rounds: 3)

for drone in fleet {
    print(drone.statusLine)
}

var healthyCount = 0

for drone in fleet {
    if drone.cell.level() >= drone.powerCost {
        healthyCount += 1
    }
}

print("Drones ready for one more task: \(healthyCount)")

var B = 0

for drone in fleet {
    B += drone.cell.level()
}

let C = healthyCount

// MARK: Level 4 · Diagnostics

// 4.1
protocol Diagnosable {
    var componentID: String { get }
    var statusCode: Int { get }
    func diagnose() -> String
}

// 4.2
protocol Rechargeable {
    mutating func recharge(by amount: Int)
}

// Why does Drone implement recharge(by:) without `mutating`?  ->
// Drone is a class, so it has reference semantics and does not need `mutating`.
extension Drone: Diagnosable, Rechargeable {
    var componentID: String {
        return id
    }

    var statusCode: Int {
        return healthStatus(for: cell.level())
    }

    func recharge(by amount: Int) {
        cell.recharge(by: amount)
    }
}

struct SensorModule: Diagnosable, Rechargeable {
    let componentID: String
    var chargeLevel: Int

    var statusCode: Int {
        return healthStatus(for: chargeLevel)
    }

    mutating func recharge(by amount: Int) {
        if amount <= 0 {
            return
        }

        chargeLevel += amount

        if chargeLevel > 100 {
            chargeLevel = 100
        }
    }
}

var sensors: [SensorModule] = []

for record in sensorData {
    sensors.append(
        SensorModule(
            componentID: record.id,
            chargeLevel: record.charge
        )
    )
}

// 4.3
// Why could [Drone] never have held the sensors?  ->
// SensorModule is a struct, not a subclass of Drone, while [Diagnosable] can hold both types.

func diagnosticsReport(_ components: [Diagnosable]) -> String {
    var report = ""

    for component in components {
        if report.isEmpty {
            report = component.diagnose()
        } else {
            report += "\n" + component.diagnose()
        }
    }

    return report
}
var components: [Diagnosable] = []

for drone in fleet {
    components.append(drone)
}

for sensor in sensors {
    components.append(sensor)
}

print(diagnosticsReport(components))

// MARK: Level 5 · Shared Behaviour

// 5.1 · default diagnose() + the single home of the Health Rule
extension Diagnosable {
    func healthStatus(for value: Int) -> Int {
        if value < 20 {
            return 2
        } else if value < 50 {
            return 1
        } else {
            return 0
        }
    }

    func diagnose() -> String {
        return "\(componentID): code \(statusCode)"
    }
}

// 5.2 · the beacon you cannot edit
extension LegacyBeacon: Diagnosable {
    var componentID: String {
        return name
    }

    var statusCode: Int {
        return healthStatus(for: signalStrength)
    }

    func diagnose() -> String {
        return "\(componentID): legacy signal code \(statusCode)"
    }
}

var diagnosticPool = components
diagnosticPool.append(beacon)

print(diagnosticsReport(diagnosticPool))

var D = 0

for component in diagnosticPool {
    D += component.statusCode
}

// 5.3
extension Int {
    var powerBar: String {
        var value = self

        if value < 0 {
            value = 0
        } else if value > 100 {
            value = 100
        }

        let filled = value / 10
        var bar = ""

        for position in 0..<10 {
            if position < filled {
                bar += "#"
            } else {
                bar += "."
            }
        }

        return bar
    }
}


// MARK: Level 6 · Incident Reports
// Two of these do not compile. Two compile and lie.
// For each: expectation, actual behaviour, the language rule, the fix.

/*
// Report 1
class PatchDrone: Drone {
    func performTask() -> Int {
        return 30
    }
}

// Expectation:
// PatchDrone should replace Drone's performTask() and return 30.
//
// Actual behaviour:
// This does not compile because performTask() overrides an inherited method
// but is missing the override keyword.
//
// Language rule:
// Swift requires override when a subclass replaces a superclass method.
//
// Fix:
// Write:
// override func performTask() -> Int {
//     return 30
// }


// Report 2
final class HeavyWelder: WelderDrone {
    override func runOnce() -> Int {
        return 999
    }
}

// Expectation:
// HeavyWelder should inherit from WelderDrone and replace runOnce().
//
// Actual behaviour:
// This does not compile.
//
// Language rule:
// WelderDrone is final, so it cannot be subclassed.
// Also, Drone.runOnce() is final, so it cannot be overridden.
//
// Fix:
// Do not subclass final WelderDrone and do not override final runOnce().
// Use another design, such as a separate Drone subclass.


// Report 3
let reportFleet: [Drone] = [WelderDrone(id: "W-9", cell: PowerCell(charge: 100))]
let first = reportFleet[0]
print(first.weldSeam())

// Expectation:
// first contains a WelderDrone, so weldSeam() should be callable.
//
// Actual behaviour:
// This does not compile because first has the static type Drone.
//
// Language rule:
// A reference typed as Drone exposes only members available on Drone,
// even when the runtime object is a WelderDrone.
//
// Fix:
// Downcast safely:
// if let welder = first as? WelderDrone {
//     print(welder.weldSeam())
// }
// `as?` returns an optional because the object may not actually be a WelderDrone.


// Report 4
protocol Labelled {
    var componentID: String { get }
}

extension Labelled {
    func label() -> String { "generic component" }
}

struct Thruster: Labelled {
    let componentID: String
    func label() -> String { "thruster \(componentID)" }
}

let parts: [Labelled] = [Thruster(componentID: "T-1")]
print(parts[0].label())

// Expectation:
// It may look like this should print "thruster T-1".
//
// Actual behaviour:
// It compiles but prints "generic component".
//
// Language rule:
// label() is not a requirement of the Labelled protocol.
// It exists only in the protocol extension, so a value viewed as Labelled
// uses the extension implementation.
//
// Fix:
// Make label() a protocol requirement:
// protocol Labelled {
//     var componentID: String { get }
//     func label() -> String
// }
*/

// MARK: Finale · Mission Code

let missionCode = "\(A)-\(B)-\(C)-\(D)"
print("MISSION CODE: \(missionCode)")

// MARK: Bonus

// Way 1 — runtime failure:
// A base Drone initializer could use preconditionFailure() when type(of: self) == Drone.self.
// This prevents a plain Drone from being created successfully at runtime.

// Way 2 — compile-time failure:
// Replace the Drone base class with a protocol, so there is no base Drone
// implementation that can be instantiated directly.

protocol DroneProtocol {
    var id: String { get }
    var cell: PowerCell { get }
    var powerCost: Int { get }

    func performTask() -> Int
}

extension DroneProtocol {
    func runOnce() -> Int {
        if cell.spend(powerCost) {
            return performTask()
        }
        return 0
    }
}

struct ProtocolWelderDrone: DroneProtocol {
    let id: String
    let cell: PowerCell

    var powerCost: Int {
        return 25
    }

    func performTask() -> Int {
        return 40
    }
}

// I would choose the protocol-based design because it prevents creating a
// meaningless base Drone at compile time and allows conforming types to be structs.
// If drones needed to share mutable state, I would prefer reference semantics,
// such as classes or a shared reference-type PowerCell.


// MARK: - ================= DEFENSE QUESTIONS =================
/*
 1. Why does a class satisfy a `mutating` protocol requirement without the
    keyword, while a struct must write it?

 2. One thing inheritance does that protocols cannot, and one thing
    protocols do that inheritance cannot:

 3. What does `final` prevent, and what did it protect in runOnce()?

 4. In Report 4, why did the protocol extension's method win?

*/
