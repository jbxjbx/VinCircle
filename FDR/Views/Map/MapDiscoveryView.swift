// MARK: - MapDiscoveryView.swift
// VinCircle - iOS Social Wine App
// Map view with wine-red theme and animations

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MapDiscoveryView: View {
    
    // MARK: - State
    
    @StateObject private var viewModel = MapDiscoveryViewModel()
    @State private var selectedStore: Store?
    @State private var showingFilters = false
    @State private var showingStoreDetail = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasAppeared = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Map
                Map(position: $cameraPosition, selection: $selectedStore) {
                    // User Location
                    UserAnnotation()
                    
                    // Store Annotations
                    ForEach(viewModel.stores) { store in
                        Annotation(
                            store.name,
                            coordinate: store.coordinate,
                            anchor: .bottom
                        ) {
                            StoreAnnotationView(
                                store: store,
                                isSelected: selectedStore?.id == store.id
                            )
                        }
                        .tag(store)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea(edges: .top)
                
                // Search/Location Bar
                VStack(spacing: 12) {
                    locationSearchBar
                    
                    // Filter Pills
                    if !viewModel.activeFilters.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.activeFilters) { filter in
                                    FilterPill(
                                        text: filter.displayText,
                                        onRemove: {
                                            viewModel.removeFilter(filter)
                                        }
                                    )
                                }
                                
                                Button("Clear All") {
                                    viewModel.clearFilters()
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 8)
                
                // Bottom Sheet - Store List
                VStack {
                    Spacer()
                    storeListSheet
                        .offset(y: hasAppeared ? 0 : 300)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: hasAppeared)
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .tint(Color.wineRed)
                }
            }
            .sheet(isPresented: $showingFilters) {
                MapFiltersView(viewModel: viewModel)
            }
            .sheet(item: $selectedStore) { store in
                StoreDetailSheet(store: store)
            }
            .task {
                await viewModel.loadStores()
            }
            .onAppear {
                withAnimation {
                    hasAppeared = true
                }
            }
            .onChange(of: selectedStore) { _, newValue in
                if let store = newValue {
                    withAnimation {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: store.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        ))
                    }
                }
            }
        }
    }
    
    // MARK: - Location Search Bar
    
    private var locationSearchBar: some View {
        HStack(spacing: 12) {
            // GPS Button
            Button {
                viewModel.useCurrentLocation()
            } label: {
                Image(systemName: viewModel.isUsingCurrentLocation ? "location.fill" : "location")
                    .foregroundStyle(viewModel.isUsingCurrentLocation ? Color.wineRed : .secondary)
            }
            
            // ZIP Code Input
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Enter ZIP code", text: $viewModel.zipCodeInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task {
                            await viewModel.searchByZipCode()
                        }
                    }
                
                if !viewModel.zipCodeInput.isEmpty {
                    Button {
                        viewModel.zipCodeInput = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Radius Selector
            Menu {
                ForEach([5, 10, 25, 50], id: \.self) { radius in
                    Button("\(radius) miles") {
                        viewModel.searchRadius = Double(radius)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("\(Int(viewModel.searchRadius))mi")
                        .font(.subheadline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            .tint(Color.wineRed)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Store List Sheet
    
    private var storeListSheet: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // Header
            HStack {
                Text("Nearby Stores")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Color.wineRed)
                } else {
                    Text("\(viewModel.stores.count) found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            
            // Store List
            if viewModel.stores.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No stores found",
                    systemImage: "storefront",
                    description: Text("Try adjusting your location or search radius")
                )
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.stores) { store in
                            StoreCard(
                                store: store,
                                isSelected: selectedStore?.id == store.id
                            ) {
                                selectedStore = store
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(height: 240)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Store Annotation View

struct StoreAnnotationView: View {
    let store: Store
    let isSelected: Bool
    
    @State private var hasAppeared = false
    
    var body: some View {
        ZStack {
            // Shadow/Glow for matched stores
            if store.hasMatchedWines {
                Circle()
                    .fill(Color.wineRed.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .blur(radius: 5)
            }
            
            // Main Pin
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(store.hasMatchedWines ? Color.wineRed : Color.roseGold)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: store.storeType.iconName)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    
                    // Match Badge
                    if store.hasMatchedWines {
                        Circle()
                            .fill(Color.champagneGold)
                            .frame(width: 14, height: 14)
                            .overlay {
                                Text("\(store.matchedWines.count)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: 14, y: -14)
                    }
                }
                
                // Pin Point
                Triangle()
                    .fill(store.hasMatchedWines ? Color.wineRed : Color.roseGold)
                    .frame(width: 12, height: 8)
            }
            .scaleEffect(isSelected ? 1.2 : (hasAppeared ? 1.0 : 0))
            .animation(WineAnimations.annotationBounce, value: isSelected)
        }
        .onAppear {
            withAnimation(WineAnimations.annotationBounce.delay(Double.random(in: 0...0.3))) {
                hasAppeared = true
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

// MARK: - Store Card

struct StoreCard: View {
    let store: Store
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(systemName: store.storeType.iconName)
                        .font(.title2)
                        .foregroundStyle(store.hasMatchedWines ? Color.wineRed : .roseGold)
                    
                    Spacer()
                    
                    if let distance = store.formattedDistance {
                        Text(distance)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(store.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(store.formattedAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // Friend Wine Match
                if let bestMatch = store.bestMatch {
                    Divider()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.champagneGold)
                            .frame(width: 8, height: 8)
                        
                        Text(bestMatch.notificationText)
                            .font(.caption)
                            .foregroundStyle(Color.wineRed)
                            .lineLimit(2)
                    }
                    .padding(8)
                    .background(Color.wineRed.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Rating
                if let rating = store.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Color.champagneGold)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                    }
                }
            }
            .padding()
            .frame(width: 220, alignment: .leading)
            .background(isSelected ? Color.wineRed.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.wineRed : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Store Detail Sheet

struct StoreDetailSheet: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text(store.name)
                                .font(.title2.bold())
                            
                            Text(store.storeType.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if let rating = store.rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(Color.champagneGold)
                                Text(String(format: "%.1f", rating))
                                    .font(.title3.bold())
                            }
                        }
                    }
                    
                    // Address & Contact
                    VStack(alignment: .leading, spacing: 12) {
                        Label(store.formattedAddress, systemImage: "mappin.circle.fill")
                            .foregroundStyle(Color.wineRed)
                        
                        if let phone = store.phoneNumber {
                            Label(phone, systemImage: "phone.fill")
                        }
                        
                        if let website = store.websiteURL {
                            Link(destination: website) {
                                Label("Visit Website", systemImage: "globe")
                            }
                            .tint(Color.wineRed)
                        }
                        
                        if let distance = store.formattedDistance {
                            Label("\(distance) away", systemImage: "location.fill")
                        }
                    }
                    .font(.subheadline)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button {
                            openMaps(store: store)
                        } label: {
                            Label("Directions", systemImage: "car.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.wineRed)
                        
                        if let phone = store.phoneNumber {
                            Button {
                                callStore(phone)
                            } label: {
                                Label("Call", systemImage: "phone.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color.wineRed)
                        }
                    }
                    
                    Divider()
                    
                    // Friends' Wines Available
                    if !store.matchedWines.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Friends' Wines Here")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(store.matchedWines.count) matches")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            ForEach(store.matchedWines) { match in
                                FriendWineMatchRow(match: match)
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "No Friend Wines",
                            systemImage: "person.2.slash",
                            description: Text("None of your friends' wines are available here")
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Store Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .tint(Color.wineRed)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func openMaps(store: Store) {
        // Use URL scheme to avoid deprecated MKPlacemark/MKMapItem init warnings
        let lat = store.latitude
        let lng = store.longitude
        let label = store.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "http://maps.apple.com/?ll=\(lat),\(lng)&q=\(label)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func callStore(_ phone: String) {
        if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Friend Wine Match Row

struct FriendWineMatchRow: View {
    let match: StoreWineMatch
    
    var body: some View {
        HStack(spacing: 12) {
            // Friend Avatar
            Circle()
                .fill(WineGradients.primary.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(match.friendName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundStyle(Color.wineRed)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(match.wineName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                Text(match.detailedNotification)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(match.formattedPrice)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.champagneGold)
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.champagneGold)
                    Text("\(match.friendRating)")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.wineRed.opacity(0.15))
        .foregroundStyle(Color.wineRed)
        .clipShape(Capsule())
    }
}

// MARK: - Map Filters View

struct MapFiltersView: View {
    @ObservedObject var viewModel: MapDiscoveryViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Store Type") {
                    ForEach(StoreType.allCases, id: \.self) { type in
                        Toggle(type.rawValue, isOn: Binding(
                            get: { viewModel.selectedStoreTypes.contains(type) },
                            set: { isOn in
                                if isOn {
                                    viewModel.selectedStoreTypes.insert(type)
                                } else {
                                    viewModel.selectedStoreTypes.remove(type)
                                }
                            }
                        ))
                        .tint(Color.wineRed)
                    }
                }
                
                Section("Show Stores With") {
                    Toggle("Friend Recommendations Only", isOn: $viewModel.showMatchedOnly)
                        .tint(Color.wineRed)
                    
                    Toggle("Currently Open", isOn: $viewModel.showOpenOnly)
                        .tint(Color.wineRed)
                }
                
                Section("Wine Type Filter") {
                    ForEach(WineType.allCases, id: \.self) { type in
                        Toggle(type.rawValue, isOn: Binding(
                            get: { viewModel.selectedWineTypes.contains(type) },
                            set: { isOn in
                                if isOn {
                                    viewModel.selectedWineTypes.insert(type)
                                } else {
                                    viewModel.selectedWineTypes.remove(type)
                                }
                            }
                        ))
                        .tint(Color.wineRed)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        viewModel.resetFilters()
                    }
                    .tint(Color.wineRed)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        Task {
                            await viewModel.applyFilters()
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(Color.wineRed)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - View Model

@MainActor
class MapDiscoveryViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Published Properties
    
    @Published var stores: [Store] = []
    @Published var isLoading = false
    @Published var zipCodeInput = ""
    @Published var searchRadius: Double = 25
    @Published var isUsingCurrentLocation = true
    
    // Filters
    @Published var selectedStoreTypes: Set<StoreType> = Set(StoreType.allCases)
    @Published var selectedWineTypes: Set<WineType> = Set(WineType.allCases)
    @Published var showMatchedOnly = false
    @Published var showOpenOnly = false
    @Published var activeFilters: [MapFilter] = []
    
    // Location
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D?
    
    // API
    private let api: WineSearcherAPI
    
    // MARK: - Initialization
    
    override init() {
        self.api = WineSearcherAPI(apiKey: "YOUR_API_KEY")
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    // MARK: - Location
    
    func useCurrentLocation() {
        isUsingCurrentLocation = true
        zipCodeInput = ""
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location.coordinate
            Task {
                await loadStores()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    // MARK: - Load Stores
    
    func loadStores() async {
        guard let location = currentLocation else {
            // Use mock data for preview
            stores = WineSearcherAPI.mockStores(
                near: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            )
            return
        }
        
        isLoading = true
        
        do {
            let fetchedStores = try await api.getStoreInventory(
                location: location,
                radiusMiles: searchRadius
            )
            
            // Apply filters
            stores = applyLocalFilters(to: fetchedStores)
        } catch {
            print("Error loading stores: \(error)")
            // Use mock data on error
            stores = WineSearcherAPI.mockStores(near: location)
        }
        
        isLoading = false
    }
    
    func searchByZipCode() async {
        guard !zipCodeInput.isEmpty else { return }
        
        isUsingCurrentLocation = false
        isLoading = true
        
        do {
            let fetchedStores = try await api.getStoresByZipCode(
                zipCode: zipCodeInput,
                radiusMiles: searchRadius
            )
            stores = applyLocalFilters(to: fetchedStores)
        } catch {
            print("Error searching by ZIP: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Filters
    
    private func applyLocalFilters(to stores: [Store]) -> [Store] {
        var filtered = stores
        
        // Store type filter
        if selectedStoreTypes != Set(StoreType.allCases) {
            filtered = filtered.filter { selectedStoreTypes.contains($0.storeType) }
        }
        
        // Matched wines only
        if showMatchedOnly {
            filtered = filtered.filter { $0.hasMatchedWines }
        }
        
        // Open only
        if showOpenOnly {
            filtered = filtered.filter { $0.isOpen == true }
        }
        
        return filtered
    }
    
    func applyFilters() async {
        await loadStores()
        updateActiveFilters()
    }
    
    func resetFilters() {
        selectedStoreTypes = Set(StoreType.allCases)
        selectedWineTypes = Set(WineType.allCases)
        showMatchedOnly = false
        showOpenOnly = false
        activeFilters = []
    }
    
    func removeFilter(_ filter: MapFilter) {
        activeFilters.removeAll { $0.id == filter.id }
        
        switch filter.type {
        case .storeType(let type):
            selectedStoreTypes.remove(type)
        case .wineType(let type):
            selectedWineTypes.remove(type)
        case .matchedOnly:
            showMatchedOnly = false
        case .openOnly:
            showOpenOnly = false
        }
        
        Task {
            await loadStores()
        }
    }
    
    func clearFilters() {
        resetFilters()
        Task {
            await loadStores()
        }
    }
    
    private func updateActiveFilters() {
        activeFilters = []
        
        if showMatchedOnly {
            activeFilters.append(MapFilter(type: .matchedOnly, displayText: "Friend Wines"))
        }
        
        if showOpenOnly {
            activeFilters.append(MapFilter(type: .openOnly, displayText: "Open Now"))
        }
        
        if selectedStoreTypes.count < StoreType.allCases.count {
            for type in selectedStoreTypes {
                activeFilters.append(MapFilter(type: .storeType(type), displayText: type.rawValue))
            }
        }
    }
}

// MARK: - Map Filter

struct MapFilter: Identifiable {
    let id = UUID()
    let type: MapFilterType
    let displayText: String
}

enum MapFilterType {
    case storeType(StoreType)
    case wineType(WineType)
    case matchedOnly
    case openOnly
}

#Preview {
    MapDiscoveryView()
}
