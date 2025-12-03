//
//  UtilitiesView.swift
//  Luddo-Dash
//
//  Tab 5: Utilities with map and IP location
//

import SwiftUI
import MapKit
import Charts
import Combine

// MARK: - Visited Location Model
struct VisitedLocation: Codable, Identifiable, Equatable {
    let id: UUID
    let city: String
    let region: String
    let country: String
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let ip: String
    let timestamp: Date

    init(from response: LocationResponse) {
        self.id = UUID()
        self.city = response.location?.city ?? "Unknown"
        self.region = response.location?.region ?? ""
        self.country = response.location?.country ?? ""
        self.countryCode = response.location?.countryCode ?? ""
        self.latitude = response.location?.latitude ?? 0
        self.longitude = response.location?.longitude ?? 0
        self.ip = response.ip
        self.timestamp = Date()
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var displayName: String {
        if region.isEmpty {
            return "\(city), \(countryCode)"
        }
        return "\(city), \(region)"
    }

    static func == (lhs: VisitedLocation, rhs: VisitedLocation) -> Bool {
        // Consider same location if city and IP match
        lhs.city == rhs.city && lhs.ip == rhs.ip
    }
}

// MARK: - Utilities View Model
@MainActor
class UtilitiesViewModel: ObservableObject {
    @Published var version: VersionResponse?
    @Published var serverTime: TimeResponse?
    @Published var pingResult: PingResponse?
    @Published var location: LocationResponse?
    @Published var lookupLocation: LocationResponse?
    @Published var hourlyTrends: HourlyTrendsResponse?
    @Published var lookupIP: String = ""
    @Published var isLoading = false
    @Published var isPinging = false
    @Published var isLookingUp = false
    @Published var error: String?
    @Published var latencyMs: Double?

    // Map state
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var mapZoomLevel: Double = 0.1

    // Location history
    @Published var visitedLocations: [VisitedLocation] = []
    private let locationsKey = "visitedLocations"

    private var refreshTimer: AnyCancellable?
    private let api = LuddoAPIClient.shared

    init() {
        loadVisitedLocations()
    }

    func startAutoRefresh() {
        Task { await refresh() }

        // Refresh time every 5 seconds
        refreshTimer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refreshTime() }
            }
    }

    // MARK: - Location History Management

    private func loadVisitedLocations() {
        if let data = UserDefaults.standard.data(forKey: locationsKey),
           let locations = try? JSONDecoder().decode([VisitedLocation].self, from: data) {
            self.visitedLocations = locations
        }
    }

    private func saveVisitedLocations() {
        if let data = try? JSONEncoder().encode(visitedLocations) {
            UserDefaults.standard.set(data, forKey: locationsKey)
        }
    }

    private func addVisitedLocation(_ response: LocationResponse) {
        guard response.location != nil else { return }
        let newLocation = VisitedLocation(from: response)

        // Only add if not already in the list (same city and IP)
        if !visitedLocations.contains(where: { $0 == newLocation }) {
            visitedLocations.insert(newLocation, at: 0)
            // Keep only last 50 locations
            if visitedLocations.count > 50 {
                visitedLocations = Array(visitedLocations.prefix(50))
            }
            saveVisitedLocations()
        }
    }

    func clearLocationHistory() {
        visitedLocations.removeAll()
        saveVisitedLocations()
        FeedbackManager.shared.lightHaptic()
    }

    func stopAutoRefresh() {
        refreshTimer?.cancel()
    }

    func refresh() async {
        if version == nil {
            isLoading = true
        }
        error = nil

        do {
            async let versionTask = api.version()
            async let timeTask = api.serverTime()
            async let locationTask = api.location()
            async let trendsTask = api.hourlyTrends(hours: 24)

            let (versionResult, timeResult, locationResult, trendsResult) = try await (
                versionTask,
                timeTask,
                locationTask,
                trendsTask
            )

            withAnimation(.easeInOut(duration: 0.3)) {
                self.version = versionResult
                self.serverTime = timeResult
                self.location = locationResult
                self.hourlyTrends = trendsResult

                // Add to visited locations history
                addVisitedLocation(locationResult)

                // Initialize map camera position
                if let loc = locationResult.location {
                    self.cameraPosition = .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude),
                        span: MKCoordinateSpan(latitudeDelta: mapZoomLevel, longitudeDelta: mapZoomLevel)
                    ))
                }
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func refreshTime() async {
        do {
            let time = try await api.serverTime()
            withAnimation(.easeInOut(duration: 0.3)) {
                self.serverTime = time
            }
        } catch {
            // Silent fail
        }
    }

    func performPing() async {
        isPinging = true
        let startTime = Date()

        do {
            let result = try await api.ping()
            let latency = Date().timeIntervalSince(startTime) * 1000

            withAnimation(.easeInOut(duration: 0.3)) {
                self.pingResult = result
                self.latencyMs = latency
            }
            FeedbackManager.shared.successHaptic()
        } catch {
            self.error = error.localizedDescription
            FeedbackManager.shared.errorHaptic()
        }

        isPinging = false
    }

    func lookupIPAddress() async {
        guard !lookupIP.isEmpty else { return }

        isLookingUp = true

        do {
            let result = try await api.location(ip: lookupIP)
            withAnimation(.easeInOut(duration: 0.3)) {
                self.lookupLocation = result
            }
            FeedbackManager.shared.successHaptic()
        } catch {
            self.error = "Failed to lookup IP: \(lookupIP)"
            FeedbackManager.shared.errorHaptic()
        }

        isLookingUp = false
    }

    func zoomIn() {
        guard mapZoomLevel > 0.01 else { return }
        mapZoomLevel /= 2
        updateCameraPosition()
        FeedbackManager.shared.lightHaptic()
    }

    func zoomOut() {
        guard mapZoomLevel < 50 else { return }
        mapZoomLevel *= 2
        updateCameraPosition()
        FeedbackManager.shared.lightHaptic()
    }

    private func updateCameraPosition() {
        // Get current center from camera position or fall back to server location
        guard let loc = location?.location else { return }

        // Default to server location center
        let center = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)

        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: mapZoomLevel, longitudeDelta: mapZoomLevel)
            ))
        }
    }

    func centerOnUserLocation(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: mapZoomLevel, longitudeDelta: mapZoomLevel)
            ))
        }
        FeedbackManager.shared.lightHaptic()
    }

    func centerOnServerLocation() {
        guard let loc = location?.location else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude),
                span: MKCoordinateSpan(latitudeDelta: mapZoomLevel, longitudeDelta: mapZoomLevel)
            ))
        }
        FeedbackManager.shared.lightHaptic()
    }

    func centerOnLocation(_ location: VisitedLocation) {
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: mapZoomLevel, longitudeDelta: mapZoomLevel)
            ))
        }
        FeedbackManager.shared.lightHaptic()
    }
}

// MARK: - Utilities View
struct UtilitiesView: View {
    @StateObject private var viewModel = UtilitiesViewModel()
    @ObservedObject private var locationManager = LocationManager.shared

    var body: some View {
        PageWithHeader(
            title: "Utilities",
            subtitle: "Tools & info",
            color: .utilsGreen
        ) {
            if viewModel.isLoading && viewModel.version == nil {
                LoadingView("Loading utilities...")
                    .frame(height: 400)
            } else if let error = viewModel.error, viewModel.version == nil {
                ErrorView(error) {
                    Task { await viewModel.refresh() }
                }
                .frame(height: 400)
            } else {
                utilitiesContent
            }
        }
        .onAppear {
            viewModel.startAutoRefresh()
            // Request location permission or get location on first appear
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()
            } else if locationManager.isAuthorized && locationManager.userLocation == nil {
                locationManager.requestLocation()
            }
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            // When authorization is granted, request location
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                locationManager.requestLocation()
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private var utilitiesContent: some View {
        VStack(spacing: 20) {
            // Location Map with Controls
            if let location = viewModel.location, let loc = location.location {
                SectionHeader("Your Location", icon: "location.fill")
                enhancedMapCard(location: location, loc: loc)
            }

            // Visitors Trend Chart
            if let trends = viewModel.hourlyTrends, !trends.trends.isEmpty {
                SectionHeader("Visitor Trends (24h)", icon: "chart.line.uptrend.xyaxis")
                visitorsTrendChart(trends: trends.trends)
            }

            // Ping Tool
            SectionHeader("Latency Test", icon: "bolt.horizontal.fill")
            pingCard

            // Server Time
            if let time = viewModel.serverTime {
                SectionHeader("Server Time", icon: "clock.fill")
                serverTimeCard(time: time)
            }

            // IP Lookup Tool
            SectionHeader("IP Lookup", icon: "magnifyingglass")
            ipLookupCard

            // API Info
            if let version = viewModel.version {
                SectionHeader("API Info", icon: "info.circle.fill")
                apiInfoCard(version: version)
            }
        }
    }

    // MARK: - Enhanced Map Card
    @ViewBuilder
    private func enhancedMapCard(location: LocationResponse, loc: LocationResponse.Location) -> some View {
        VStack(spacing: 0) {
            // Map with controls overlay
            ZStack(alignment: .topTrailing) {
                // Map with binding for interactive controls
                Map(position: $viewModel.cameraPosition) {
                    // Show all visited locations
                    ForEach(viewModel.visitedLocations) { visitedLoc in
                        // Current location (first in list) gets different styling
                        if visitedLoc.id == viewModel.visitedLocations.first?.id {
                            Marker(visitedLoc.city, coordinate: visitedLoc.coordinate)
                                .tint(Color.utilsGreen)
                        } else {
                            // Historical locations with different color
                            Marker(visitedLoc.displayName, coordinate: visitedLoc.coordinate)
                                .tint(Color.utilsGreen.opacity(0.6))
                        }
                    }

                    // User's actual device location marker
                    if let userLoc = locationManager.userLocation {
                        Marker("You", coordinate: userLoc)
                            .tint(Color.dashboardBlue)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 220)

                // Map Controls
                VStack(spacing: 8) {
                    // Zoom controls
                    VStack(spacing: 0) {
                        Button {
                            viewModel.zoomIn()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 36, height: 36)
                        }

                        Divider()
                            .frame(width: 36)

                        Button {
                            viewModel.zoomOut()
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 36, height: 36)
                        }
                    }
                    .background(.ultraThinMaterial)
                    .foregroundStyle(.primary)
                    .cornerRadius(8)

                    // My Location button
                    Button {
                        if let userLoc = locationManager.userLocation {
                            viewModel.centerOnUserLocation(userLoc)
                        } else {
                            // Request permission if not determined, or request location if authorized
                            if locationManager.authorizationStatus == .notDetermined {
                                locationManager.requestPermission()
                            } else {
                                locationManager.requestLocation()
                            }
                            FeedbackManager.shared.lightHaptic()
                        }
                    } label: {
                        Image(systemName: locationManager.userLocation != nil ? "location.fill" : "location")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .foregroundStyle(locationManager.userLocation != nil ? Color.dashboardBlue : .primary)
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)

                    // Server Location button
                    Button {
                        viewModel.centerOnServerLocation()
                    } label: {
                        Image(systemName: "server.rack")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .foregroundStyle(Color.utilsGreen)
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }
                .padding(8)
            }
            .cornerRadius(12, corners: [.topLeft, .topRight])

            // Location Details
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.utilsGreen)
                                .frame(width: 8, height: 8)
                            Text("\(loc.city), \(loc.region)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        Text("\(loc.country) (\(loc.countryCode))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(loc.timezone)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // Show user location if different
                if let userLoc = locationManager.userLocation {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.dashboardBlue)
                            .frame(width: 8, height: 8)
                        Text("Your device location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.4f, %.4f", userLoc.latitude, userLoc.longitude))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider()

                if let network = location.network {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ISP")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text(network.isp)
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("IP")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text(location.ip)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                        }
                    }
                }

                // Visited Locations History
                if viewModel.visitedLocations.count > 1 {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Visited Locations (\(viewModel.visitedLocations.count))")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button {
                                viewModel.clearLocationHistory()
                            } label: {
                                Text("Clear")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.visitedLocations) { visitedLoc in
                                    Button {
                                        viewModel.centerOnLocation(visitedLoc)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(visitedLoc.city)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundStyle(visitedLoc.id == viewModel.visitedLocations.first?.id ? Color.utilsGreen : .primary)
                                            Text(visitedLoc.countryCode)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(visitedLoc.id == viewModel.visitedLocations.first?.id ? Color.utilsGreen.opacity(0.1) : Color.cardBackground)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(visitedLoc.id == viewModel.visitedLocations.first?.id ? Color.utilsGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
    }

    // MARK: - Visitors Trend Chart
    @ViewBuilder
    private func visitorsTrendChart(trends: [HourlyTrend]) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                // Summary stats
                HStack(spacing: 20) {
                    let totalVisitors = trends.reduce(0) { $0 + $1.visitors.total }
                    let uniqueVisitors = trends.reduce(0) { $0 + $1.visitors.unique }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(totalVisitors)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.utilsGreen)
                        Text("Total Visits")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .frame(height: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(uniqueVisitors)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.dashboardBlue)
                        Text("Unique")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                // Chart
                Chart {
                    ForEach(Array(trends.suffix(12).enumerated()), id: \.offset) { index, trend in
                        LineMark(
                            x: .value("Hour", index),
                            y: .value("Visitors", trend.visitors.total)
                        )
                        .foregroundStyle(Color.utilsGreen.gradient)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        AreaMark(
                            x: .value("Hour", index),
                            y: .value("Visitors", trend.visitors.total)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.utilsGreen.opacity(0.3), Color.utilsGreen.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        // Unique visitors line
                        LineMark(
                            x: .value("Hour", index),
                            y: .value("Unique", trend.visitors.unique)
                        )
                        .foregroundStyle(Color.dashboardBlue.gradient)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 120)

                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.utilsGreen)
                            .frame(width: 16, height: 3)
                        Text("Total")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.dashboardBlue, style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                            .frame(width: 16, height: 3)
                        Text("Unique")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("Last 12 hours")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Ping Card
    @ViewBuilder
    private var pingCard: some View {
        CardContainer {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server Latency")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let latency = viewModel.latencyMs {
                            HStack(spacing: 4) {
                                Text(String(format: "%.0f", latency))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(latencyColor(latency))

                                Text("ms")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("--")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()

                    Button {
                        Task { await viewModel.performPing() }
                    } label: {
                        if viewModel.isPinging {
                            ProgressView()
                                .frame(width: 80, height: 40)
                        } else {
                            Text("Ping")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 80, height: 40)
                                .background(Color.utilsGreen)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(viewModel.isPinging)
                }

                if let ping = viewModel.pingResult {
                    Divider()

                    HStack {
                        Text("Client IP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(ping.clientIP)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    // MARK: - Server Time Card
    @ViewBuilder
    private func serverTimeCard(time: TimeResponse) -> some View {
        CardContainer {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(time.formatted.date)
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(time.formatted.time)
                            .font(.title)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(time.serverTimezone)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Day \(time.utc.dayOfYear)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider()

                HStack {
                    infoItem("Unix", value: "\(time.unix)")
                    Spacer()
                    infoItem("Day of Week", value: dayOfWeekName(time.utc.dayOfWeek))
                }
            }
        }
    }

    // MARK: - IP Lookup Card
    @ViewBuilder
    private var ipLookupCard: some View {
        CardContainer {
            VStack(spacing: 12) {
                HStack {
                    TextField("Enter IP address", text: $viewModel.lookupIP)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button {
                        Task { await viewModel.lookupIPAddress() }
                    } label: {
                        if viewModel.isLookingUp {
                            ProgressView()
                                .frame(width: 60, height: 36)
                        } else {
                            Text("Lookup")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 36)
                                .background(Color.utilsGreen)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(viewModel.lookupIP.isEmpty || viewModel.isLookingUp)
                }

                if let lookup = viewModel.lookupLocation, let loc = lookup.location {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(loc.city), \(loc.country)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text(loc.countryCode)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.utilsGreen.opacity(0.1))
                                .cornerRadius(4)
                        }

                        if let network = lookup.network {
                            Text(network.isp)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - API Info Card
    @ViewBuilder
    private func apiInfoCard(version: VersionResponse) -> some View {
        CardContainer {
            VStack(spacing: 12) {
                HStack {
                    Text(version.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("v\(version.version)")
                        .font(.subheadline)
                        .foregroundStyle(Color.utilsGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.utilsGreen.opacity(0.1))
                        .cornerRadius(6)
                }

                Divider()

                Text("Capabilities")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                FlowLayout(spacing: 8) {
                    ForEach(version.capabilities, id: \.self) { capability in
                        Text(capability)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cardBackground)
                            .cornerRadius(4)
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func infoItem(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    // MARK: - Helper Functions

    private func latencyColor(_ latency: Double) -> Color {
        if latency < 100 { return .success }
        if latency < 300 { return .warning }
        return .error
    }

    private func dayOfWeekName(_ day: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[day % 7]
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview {
    UtilitiesView()
}
