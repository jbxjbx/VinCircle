// MARK: - StructuredPostingView.swift
// VinCircle - iOS Social Wine App
// Structured wine posting flow with wine-red theme and animations

import SwiftUI
import PhotosUI
import Combine

struct StructuredPostingView: View {
    
    // MARK: - Environment & State
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = StructuredPostingViewModel()
    @State private var hasAppeared = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Indicator
                progressBar
                
                // Step Content
                TabView(selection: $viewModel.currentStep) {
                    wineSearchStep
                        .tag(PostingStep.search)
                    
                    vintageSelectionStep
                        .tag(PostingStep.vintage)
                    
                    attributesStep
                        .tag(PostingStep.attributes)
                    
                    scoreStep
                        .tag(PostingStep.score)
                    
                    comparisonStep
                        .tag(PostingStep.comparison)
                    
                    reviewStep
                        .tag(PostingStep.review)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(WineAnimations.stepTransition, value: viewModel.currentStep)
            }
            .navigationTitle("Add Tasting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(Color.wineRed)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.currentStep == .review {
                        Button("Post") {
                            Task {
                                await viewModel.submitPost()
                                dismiss()
                            }
                        }
                        .fontWeight(.semibold)
                        .tint(Color.wineRed)
                        .disabled(!viewModel.isReadyToSubmit)
                    }
                }
            }
            .onAppear {
                withAnimation(WineAnimations.cardAppear) {
                    hasAppeared = true
                }
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(PostingStep.allCases, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step.rawValue <= viewModel.currentStep.rawValue
                          ? AnyShapeStyle(WineGradients.progress)
                          : AnyShapeStyle(Color.gray.opacity(0.3)))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Step 1: Wine Search
    
    private var wineSearchStep: some View {
        VStack(spacing: 20) {
            Text("Search for a wine")
                .font(.title2.bold())
                .padding(.top)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
            
            Text("Find the exact wine you tasted")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.wineRed)
                TextField("Wine name, producer, or region", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            
            // Wine Type Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WineType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.rawValue,
                            isSelected: viewModel.selectedType == type
                        ) {
                            viewModel.selectedType = viewModel.selectedType == type ? nil : type
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Search Results
            if viewModel.isSearching {
                ProgressView()
                    .tint(Color.wineRed)
                    .padding()
            } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                ContentUnavailableView(
                    "No wines found",
                    systemImage: "wineglass",
                    description: Text("Try a different search term")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, wine in
                            WineSearchResultRow(wine: wine, isSelected: viewModel.selectedWine?.id == wine.id) {
                                viewModel.selectWine(wine)
                            }
                            .staggeredAppear(index: index, isVisible: hasAppeared)
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
            
            // Next Button
            nextButton(enabled: viewModel.selectedWine != nil)
        }
    }
    
    // MARK: - Step 2: Vintage Selection
    
    private var vintageSelectionStep: some View {
        VStack(spacing: 20) {
            if let wine = viewModel.selectedWine {
                Text("Select Vintage")
                    .font(.title2.bold())
                    .padding(.top)
                
                Text(wine.name)
                    .font(.headline)
                    .foregroundStyle(Color.wineRed)
                
                // Vintage Grid
                let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(wine.vintages, id: \.self) { vintage in
                        VintageChip(
                            year: vintage,
                            isSelected: viewModel.selectedVintage == vintage
                        ) {
                            viewModel.selectedVintage = vintage
                        }
                    }
                    
                    // "Other" option for unlisted vintages
                    VintageChip(
                        year: nil,
                        isSelected: viewModel.showCustomVintage
                    ) {
                        viewModel.showCustomVintage.toggle()
                    }
                }
                .padding()
                
                if viewModel.showCustomVintage {
                    HStack {
                        TextField("Enter year", text: $viewModel.customVintageText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                        
                        Button("Set") {
                            if let year = Int(viewModel.customVintageText) {
                                viewModel.selectedVintage = year
                                viewModel.showCustomVintage = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.wineRed)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                backButton
                nextButton(enabled: viewModel.selectedVintage != nil)
            }
        }
    }
    
    // MARK: - Step 3: Attributes
    
    private var attributesStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Wine Characteristics")
                    .font(.title2.bold())
                    .padding(.top)
                
                Text("Describe what you tasted")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Attribute Sliders
                VStack(spacing: 20) {
                    AttributeSlider(
                        title: "Acidity",
                        leftLabel: "Low",
                        rightLabel: "High",
                        value: $viewModel.attributes.acidity
                    )
                    
                    AttributeSlider(
                        title: "Sweetness",
                        leftLabel: "Dry",
                        rightLabel: "Sweet",
                        value: $viewModel.attributes.sweetness
                    )
                    
                    AttributeSlider(
                        title: "Tannin",
                        leftLabel: "Soft",
                        rightLabel: "Firm",
                        value: $viewModel.attributes.tannin
                    )
                    
                    AttributeSlider(
                        title: "Body",
                        leftLabel: "Light",
                        rightLabel: "Full",
                        value: $viewModel.attributes.body
                    )
                    
                    AttributeSlider(
                        title: "Alcohol",
                        leftLabel: "Light",
                        rightLabel: "Warming",
                        value: $viewModel.attributes.alcohol
                    )
                }
                .padding(.horizontal)
                
                Divider().padding(.vertical, 8)
                
                // Flavor Notes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Flavor Notes")
                        .font(.headline)
                    
                    ForEach(FlavorCategory.allCases, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(FlavorNote.allCases.filter { $0.category == category }, id: \.self) { note in
                                    FlavorChip(
                                        note: note,
                                        isSelected: viewModel.attributes.flavorNotes.contains(note)
                                    ) {
                                        viewModel.toggleFlavorNote(note)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Finish Length
                VStack(alignment: .leading, spacing: 8) {
                    Text("Finish")
                        .font(.headline)
                    
                    HStack(spacing: 10) {
                        ForEach(FinishLength.allCases, id: \.self) { finish in
                            FilterChip(
                                title: finish.rawValue,
                                isSelected: viewModel.attributes.finish == finish
                            ) {
                                viewModel.attributes.finish = finish
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Oak Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Oak Influence")
                        .font(.headline)
                    
                    HStack(spacing: 10) {
                        ForEach(OakLevel.allCases, id: \.self) { oak in
                            FilterChip(
                                title: oak.rawValue,
                                isSelected: viewModel.attributes.oakInfluence == oak
                            ) {
                                viewModel.attributes.oakInfluence = oak
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                HStack(spacing: 16) {
                    backButton
                    nextButton(enabled: true)
                }
                .padding(.top, 24)
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Step 4: Score
    
    private var scoreStep: some View {
        VStack(spacing: 32) {
            Text("Your Rating")
                .font(.title2.bold())
                .padding(.top)
            
            Text("How would you rate this wine?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Large Score Display with wine-themed gradient
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Color.wineRed, .champagneGold, .roseGold, Color.wineRed],
                            center: .center
                        ),
                        lineWidth: 12
                    )
                    .frame(width: 200, height: 200)
                    .shadow(color: Color.wineRed.opacity(0.3), radius: 10)
                
                VStack {
                    Text("\(viewModel.subjectiveScore)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.wineRed)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: viewModel.subjectiveScore)
                    
                    Text(scoreLabel(for: viewModel.subjectiveScore))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Score Slider
            VStack {
                Slider(value: $viewModel.scoreSliderValue, in: 1...100, step: 1)
                    .tint(Color.wineRed)
                    .padding(.horizontal, 40)
                    .onChange(of: viewModel.scoreSliderValue) { _, newValue in
                        viewModel.subjectiveScore = Int(newValue)
                    }
                
                HStack {
                    Text("1")
                    Spacer()
                    Text("50")
                    Spacer()
                    Text("100")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            }
            
            // Photo Upload
            VStack(spacing: 12) {
                Text("Add Photos (Optional)")
                    .font(.headline)
                
                PhotosPicker(
                    selection: $viewModel.selectedPhotos,
                    maxSelectionCount: 4,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Select Photos")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .tint(Color.wineRed)
                .padding(.horizontal)
                
                // Photo Preview
                if !viewModel.photoImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.photoImages.indices, id: \.self) { index in
                                viewModel.photoImages[index]
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                backButton
                nextButton(enabled: true)
            }
        }
    }
    
    // MARK: - Step 5: Comparison
    
    private var comparisonStep: some View {
        VStack(spacing: 24) {
            Text("Compare Wines")
                .font(.title2.bold())
                .padding(.top)
            
            if let comparison = viewModel.comparisonWine {
                Text("Do you prefer this over...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Comparison Card
                VStack(spacing: 16) {
                    HStack(alignment: .top, spacing: 20) {
                        // New Wine
                        VStack {
                            Circle()
                                .fill(WineGradients.primary.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: "wineglass.fill")
                                        .font(.title)
                                        .foregroundStyle(Color.wineRed)
                                }
                            
                            Text(viewModel.selectedWine?.name ?? "")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            Text("New Wine")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Text("vs")
                            .font(.title2.bold())
                            .foregroundStyle(.secondary)
                        
                        // Comparison Wine
                        VStack {
                            Circle()
                                .fill(WineGradients.champagne.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: "wineglass")
                                        .font(.title)
                                        .foregroundStyle(Color.champagneGold)
                                }
                            
                            Text(comparison.wineName)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            Text("\(comparison.vintage)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    
                    // Preference Buttons
                    HStack(spacing: 16) {
                        Button {
                            viewModel.preferNewWine = true
                        } label: {
                            VStack {
                                Image(systemName: viewModel.preferNewWine == true ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(Color.wineRed)
                                Text("Prefer New")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.preferNewWine == true ? Color.wineRed.opacity(0.2) : Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            viewModel.preferNewWine = false
                        } label: {
                            VStack {
                                Image(systemName: viewModel.preferNewWine == false ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(Color.champagneGold)
                                Text("Prefer Previous")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.preferNewWine == false ? Color.champagneGold.opacity(0.2) : Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
            } else {
                // No comparison available (first wine)
                ContentUnavailableView(
                    "First Wine!",
                    systemImage: "star.fill",
                    description: Text("This is your first wine - nothing to compare yet!")
                )
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                backButton
                nextButton(enabled: viewModel.comparisonWine == nil || viewModel.preferNewWine != nil)
            }
        }
    }
    
    // MARK: - Step 6: Review
    
    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Review Your Tasting")
                    .font(.title2.bold())
                    .padding(.top)
                
                if let wine = viewModel.selectedWine {
                    // Wine Summary Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(wine.name)
                                    .font(.headline)
                                Text(wine.producer)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(viewModel.selectedVintage ?? 0)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.wineRed)
                            }
                            
                            Spacer()
                            
                            // Score Badge
                            ZStack {
                                Circle()
                                    .fill(scoreColor(for: viewModel.subjectiveScore).opacity(0.2))
                                    .frame(width: 60, height: 60)
                                
                                Text("\(viewModel.subjectiveScore)")
                                    .font(.title2.bold())
                                    .foregroundStyle(scoreColor(for: viewModel.subjectiveScore))
                            }
                        }
                        
                        Divider()
                        
                        // Attributes Summary
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Characteristics")
                                .font(.subheadline.bold())
                            
                            HStack {
                                AttributeSummary(label: "Acidity", value: viewModel.attributes.acidity)
                                AttributeSummary(label: "Sweetness", value: viewModel.attributes.sweetness)
                                AttributeSummary(label: "Tannin", value: viewModel.attributes.tannin)
                            }
                            
                            HStack {
                                AttributeSummary(label: "Body", value: viewModel.attributes.body)
                                AttributeSummary(label: "Alcohol", value: viewModel.attributes.alcohol)
                            }
                        }
                        
                        // Flavor Notes
                        if !viewModel.attributes.flavorNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Flavor Notes")
                                    .font(.subheadline.bold())
                                
                                FlowLayout(spacing: 6) {
                                    ForEach(viewModel.attributes.flavorNotes, id: \.self) { note in
                                        Text(note.rawValue.capitalized)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.wineRed.opacity(0.1))
                                            .foregroundStyle(Color.wineRed)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                
                HStack(spacing: 16) {
                    backButton
                }
                .padding(.top, 24)
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Views
    
    private func nextButton(enabled: Bool) -> some View {
        Button {
            withAnimation(WineAnimations.stepTransition) {
                viewModel.goToNextStep()
            }
        } label: {
            Text("Next")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    if enabled {
                        WineGradients.primary
                    } else {
                        LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
                    }
                }
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!enabled)
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
    
    private var backButton: some View {
        Button {
            withAnimation(WineAnimations.stepTransition) {
                viewModel.goToPreviousStep()
            }
        } label: {
            Text("Back")
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
    
    private func scoreLabel(for score: Int) -> String {
        switch score {
        case 90...100: return "Outstanding"
        case 80..<90: return "Excellent"
        case 70..<80: return "Very Good"
        case 60..<70: return "Good"
        case 50..<60: return "Average"
        default: return "Below Average"
        }
    }
    
    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 90...100: return Color.wineRed
        case 80..<90: return Color.champagneGold
        case 70..<80: return Color.roseGold
        case 60..<70: return Color.orange
        default: return Color.gray
        }
    }
}

// MARK: - View Model

@MainActor
class StructuredPostingViewModel: ObservableObject {
    
    @Published var currentStep: PostingStep = .search
    
    // Search
    @Published var searchQuery = ""
    @Published var selectedType: WineType?
    @Published var isSearching = false
    @Published var searchResults: [WineSearchResult] = []
    @Published var selectedWine: WineSearchResult?
    
    // Vintage
    @Published var selectedVintage: Int?
    @Published var showCustomVintage = false
    @Published var customVintageText = ""
    
    // Attributes
    @Published var attributes = WineAttributes()
    
    // Score
    @Published var subjectiveScore = 75
    @Published var scoreSliderValue: Double = 75
    
    // Photos
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var photoImages: [Image] = []
    
    // Comparison
    @Published var comparisonWine: WinePost?
    @Published var preferNewWine: Bool?
    
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Watch for search query changes with proper debounce
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task { @MainActor in
                    await self?.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) async {
        // Cancel previous search
        searchTask?.cancel()
        
        guard query.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            guard !Task.isCancelled else { return }
            
            // Use mock data for search
            var results = MockDataService.searchWines(query: query)
            
            // Apply type filter if selected
            if let type = selectedType {
                results = results.filter { $0.type == type }
            }
            
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
    
    var isReadyToSubmit: Bool {
        selectedWine != nil && selectedVintage != nil
    }
    
    func selectWine(_ wine: WineSearchResult) {
        selectedWine = wine
        selectedVintage = nil
    }
    
    func toggleFlavorNote(_ note: FlavorNote) {
        if attributes.flavorNotes.contains(note) {
            attributes.flavorNotes.removeAll { $0 == note }
        } else {
            attributes.flavorNotes.append(note)
        }
    }
    
    func goToNextStep() {
        if let nextStep = PostingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
        }
    }
    
    func goToPreviousStep() {
        if let prevStep = PostingStep(rawValue: currentStep.rawValue - 1) {
            currentStep = prevStep
        }
    }
    
    func submitPost() async {
        // Submit logic would go here
        // Create WinePost, update Elo ratings, etc.
    }
}


// MARK: - Posting Steps

enum PostingStep: Int, CaseIterable {
    case search = 0
    case vintage = 1
    case attributes = 2
    case score = 3
    case comparison = 4
    case review = 5
}

// MARK: - Supporting Views

struct WineSearchResultRow: View {
    let wine: WineSearchResult
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Wine Type Icon
                Circle()
                    .fill(WineGradients.primary.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: wine.type.iconName)
                            .foregroundStyle(Color.wineRed)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(wine.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("\(wine.producer) • \(wine.region)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    if let price = wine.averagePrice {
                        Text("$\(Double(truncating: price as NSNumber), specifier: "%.0f") avg")
                            .font(.caption)
                            .foregroundStyle(Color.champagneGold)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.wineRed)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.wineRed.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.wineRed : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct VintageChip: View {
    let year: Int?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(year.map { String($0) } ?? "Other")
                .font(.headline)
                .frame(minWidth: 70)
                .padding(.vertical, 12)
                .background(isSelected ? Color.wineRed : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct AttributeSlider: View {
    let title: String
    let leftLabel: String
    let rightLabel: String
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                Text(leftLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .leading)
                
                Slider(value: $value, in: 0...1)
                    .tint(Color.wineRed)
                
                Text(rightLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }
}

struct FlavorChip: View {
    let note: FlavorNote
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(note.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.wineRed : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct AttributeSummary: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            ProgressView(value: value)
                .tint(.wineRed)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .init(frame.size))
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (frames: [CGRect], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var frames: [CGRect] = []
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        
        let totalHeight = currentY + lineHeight
        return (frames, CGSize(width: maxWidth, height: totalHeight))
    }
}

#Preview {
    StructuredPostingView()
}
