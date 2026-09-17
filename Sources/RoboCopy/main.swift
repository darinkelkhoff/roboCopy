import AppKit

@main
enum RoboCopyMain {
    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        application.run()
    }
}
