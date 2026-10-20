import Foundation
import Combine

@MainActor
public final class TelemetryEngine: ObservableObject {
    @Published public var cpuHistory: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    @Published public var networkHistory: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    @Published public var currentNetworkMbps: Double = 0.0

    private var timer: AnyCancellable?

    public init() {
        start()
    }

    public func start() {
        timer = Timer.publish(every: 2.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pulse(runningCount: 0, currentCpuSum: 0.0)
            }
    }

    public func update(runningServices: [ServiceInstance]) {
        let count = runningServices.count
        guard count > 0 else {
            self.currentNetworkMbps = 0.0
            return
        }

        var totalCpu = 0.0
        for s in runningServices {
            totalCpu += s.currentCpuPercent
        }
        pulse(runningCount: count, currentCpuSum: totalCpu)
    }

    private func pulse(runningCount: Int, currentCpuSum: Double) {
        guard runningCount > 0 else {
            self.currentNetworkMbps = 0.0
            return
        }

        let avgCpu = (currentCpuSum / Double(runningCount) * 10).rounded() / 10
        var newCpu = cpuHistory
        if newCpu.count >= 10 { newCpu.removeFirst() }
        newCpu.append(avgCpu)
        self.cpuHistory = newCpu

        let netDelta = Double.random(in: -5.0...8.0)
        let baseNet = Double(runningCount) * 120.0
        let newNet = max(50.0, min(950.0, baseNet + netDelta))
        self.currentNetworkMbps = (newNet * 10).rounded() / 10

        var newNetHist = networkHistory
        if newNetHist.count >= 10 { newNetHist.removeFirst() }
        newNetHist.append(self.currentNetworkMbps)
        self.networkHistory = newNetHist
    }

    public func stop() {
        timer?.cancel()
        timer = nil
    }
}
