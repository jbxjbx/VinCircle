// MARK: - RateView.swift
// FRIDAYRED - Wine Ranking App
// Rate tab with wine search and comparison flow

import SwiftUI

struct RateView: View {
    @EnvironmentObject private var dataService: RankingDataService
    @State private var searchText = ""
    @State private var selectedWine: Wine?
    @State private var showingAddWine = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search for a wine to rate", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                
                // Results / Empty State
                if searchText.isEmpty {
                    searchPrompt
                } else {
                    searchResults
                }
            }
            .navigationTitle("Rate")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingAddWine) {
                AddWineView { newWine in
                    dataService.addWine(newWine)
                    selectedWine = newWine
                }
            }
            .navigationDestination(item: $selectedWine) { wine in
                RateWineView(wine: wine)
            }
        }
    }
    
    // MARK: - Search Prompt
    private var searchPrompt: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "wineglass")
                .font(.system(size: 60))
                .foregroundStyle(Color.wineRed.opacity(0.5))
            
            Text("Search for a Wine")
                .font(.title2.bold())
            
            Text("Type the wine name or producer\nto find and rate it")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Search Results
    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                let results = dataService.searchWines(query: searchText)
                
                ForEach(results) { wine in
                    wineRow(wine)
                }
                
                // Add New Wine Option
                Button {
                    showingAddWine = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.wineRed)
                        
                        VStack(alignment: .leading) {
                            Text("Add a new wine")
                                .font(.headline)
                            Text("Can't find it? Add it to the database")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Wine Row
    private func wineRow(_ wine: Wine) -> some View {
        Button {
            selectedWine = wine
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(wine.producer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(wine.name)
                        .font(.headline)
                    
                    if let grape = wine.grape(), let region = wine.region() {
                        Text("\(grape.name) • \(region.name)")
                            .font(.caption)
                            .foregroundStyle(Color.wineRed)
                    }
                }
                
                Spacer()
                
                // Show if already ranked
                if isWineRanked(wine) {
                    Text("Ranked")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.wineRed.opacity(0.1))
                        .foregroundStyle(Color.wineRed)
                        .clipShape(Capsule())
                }
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .buttonStyle(.plain)
    }
    
    private func isWineRanked(_ wine: Wine) -> Bool {
        dataService.rankings.contains { ranking in
            ranking.userId == dataService.currentUser.id &&
            ranking.entry(for: wine.id) != nil
        }
    }
}

// MARK: - Add Wine View
struct AddWineView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onAdd: (Wine) -> Void
    
    @State private var producer = ""
    @State private var name = ""
    @State private var selectedGrapeId: UUID?
    @State private var selectedRegionId: UUID?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Wine Details") {
                    TextField("Producer (e.g., Catena Zapata)", text: $producer)
                    TextField("Wine Name (e.g., Adrianna Vineyard)", text: $name)
                }
                
                Section("Grape Variety") {
                    Picker("Primary Grape", selection: $selectedGrapeId) {
                        Text("Select...").tag(nil as UUID?)
                        ForEach(GrapeVariety.standardVarieties) { grape in
                            Text(grape.name).tag(grape.id as UUID?)
                        }
                    }
                }
                
                Section("Region") {
                    Picker("Wine Region", selection: $selectedRegionId) {
                        Text("Select...").tag(nil as UUID?)
                        ForEach(WineRegion.commonRegions) { region in
                            Text("\(region.name), \(region.country)").tag(region.id as UUID?)
                        }
                    }
                }
            }
            .navigationTitle("Add New Wine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addWine()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !producer.isEmpty && !name.isEmpty && selectedGrapeId != nil && selectedRegionId != nil
    }
    
    private func addWine() {
        guard let grapeId = selectedGrapeId, let regionId = selectedRegionId else { return }
        
        let wine = Wine(
            name: name,
            producer: producer,
            primaryGrapeId: grapeId,
            regionId: regionId,
            createdByUserId: RankingDataService.shared.currentUser.id
        )
        
        onAdd(wine)
        dismiss()
    }
}

// MARK: - Rate Wine View
struct RateWineView: View {
    let wine: Wine
    
    @EnvironmentObject private var dataService: RankingDataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var vintageYear: Int? = nil
    @State private var vintageText = ""
    @State private var notes = ""
    @State private var currentStep = 0
    @State private var sentiment: SentimentBucket?
    @State private var showingComparison = false
    @State private var isComplete = false
    @State private var finalPosition = 1
    
    var body: some View {
        VStack {
            if isComplete {
                completionView
            } else if currentStep == 0 {
                vintageSelectionStep
            } else if currentStep == 1 {
                notesStep
            } else {
                comparisonStep
            }
        }
        .navigationTitle("Rate Wine")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Step 1: Vintage Selection
    private var vintageSelectionStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 8) {
                Text(wine.producer)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(wine.name)
                    .font(.title.bold())
            }
            
            Text("What vintage did you try?")
                .font(.headline)
            
            TextField("e.g., 2019", text: $vintageText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 150)
                .multilineTextAlignment(.center)
            
            Button("I don't know / NV") {
                vintageYear = nil
                currentStep = 1
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                vintageYear = Int(vintageText)
                currentStep = 1
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.wineRed)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
    
    // MARK: - Step 2: Notes (Optional)
    private var notesStep: some View {
        VStack(spacing: 24) {
            Text("Any tasting notes? (optional)")
                .font(.headline)
            
            TextEditor(text: $notes)
                .frame(height: 150)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Button("Skip") {
                    startRating()
                }
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    startRating()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.wineRed)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
    
    // MARK: - Step 3: Comparison / Sentiment
    private var comparisonStep: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("How was it?")
                .font(.title.bold())
            
            VStack(spacing: 16) {
                ForEach(SentimentBucket.allCases, id: \.self) { bucket in
                    Button {
                        sentiment = bucket
                        placeWine(with: bucket)
                    } label: {
                        HStack {
                            Text(bucket.emoji)
                                .font(.title)
                            Text(bucket.displayText.dropFirst(bucket.emoji.count))
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("Wine Ranked!")
                .font(.title.bold())
            
            Text("\(wine.fullName) is now")
                .font(.headline)
            
            Text("#\(finalPosition)")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(Color.wineRed)
            
            if let grape = wine.grape() {
                Text("in your \(grape.name)s")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("View My List")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.wineRed)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button("Rate Another") {
                    dismiss()
                }
                .foregroundStyle(Color.wineRed)
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    private func startRating() {
        currentStep = 2
    }
    
    private func placeWine(with sentiment: SentimentBucket) {
        let grapeId = wine.primaryGrapeId
        var ranking = dataService.getOrCreateRanking(for: grapeId)
        
        // If this is the first wine, simple placement
        if ranking.entries.isEmpty {
            AdaptiveRankingEngine.shared.placeFirstWine(
                in: &ranking,
                wineId: wine.id,
                vintageYear: vintageYear,
                sentiment: sentiment,
                notes: notes.isEmpty ? nil : notes
            )
            finalPosition = 1
        } else {
            // For now, simple placement based on sentiment
            // TODO: Implement full comparison flow
            let position: Int
            switch sentiment {
            case .loved:
                position = 1
            case .okay:
                position = max(1, (ranking.entries.count + 1) / 2)
            case .didntLove:
                position = ranking.entries.count + 1
            }
            
            AdaptiveRankingEngine.shared.insertWine(
                in: &ranking,
                wineId: wine.id,
                atPosition: position,
                vintageYear: vintageYear,
                sentiment: sentiment,
                notes: notes.isEmpty ? nil : notes
            )
            finalPosition = position
        }
        
        dataService.updateRanking(ranking)
        
        // Add feed event
        let event = FeedEvent(
            actorUserId: dataService.currentUser.id,
            eventType: .wineRated,
            wineId: wine.id,
            grapeId: grapeId,
            vintageYear: vintageYear,
            rankPosition: finalPosition,
            totalInList: ranking.entries.count
        )
        dataService.addFeedEvent(event)
        
        withAnimation {
            isComplete = true
        }
    }
}

#Preview {
    RateView()
        .environmentObject(RankingDataService.shared)
}
