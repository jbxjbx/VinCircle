// MARK: - MyListView.swift
// FRIDAYRED - Wine Ranking App
// My List tab with grape-segmented personal rankings

import SwiftUI

struct MyListView: View {
    @EnvironmentObject private var dataService: RankingDataService
    @State private var selectedGrapeId: UUID?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Grape Variety Switcher
                grapeSwitcher
                
                // Ranked List
                if let grapeId = selectedGrapeId,
                   let ranking = dataService.ranking(for: grapeId) {
                    rankedList(ranking: ranking, grapeId: grapeId)
                } else {
                    emptyState
                }
            }
            .navigationTitle("My List")
            .background(Color(.systemGroupedBackground))
            .onAppear {
                // Select first grape with rankings
                if selectedGrapeId == nil {
                    selectedGrapeId = dataService.rankedGrapes().first?.id
                }
            }
        }
    }
    
    // MARK: - Grape Switcher
    private var grapeSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(dataService.rankedGrapes()) { grape in
                    let ranking = dataService.ranking(for: grape.id)
                    let count = ranking?.entries.count ?? 0
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedGrapeId = grape.id
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(grape.name)
                                .font(.subheadline.bold())
                            Text("(\(count))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedGrapeId == grape.id ? Color.wineRed : Color(.systemGray5))
                        .foregroundStyle(selectedGrapeId == grape.id ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Ranked List
    @ViewBuilder
    private func rankedList(ranking: Ranking, grapeId: UUID) -> some View {
        let grape = GrapeVariety.standardVarieties.first { $0.id == grapeId }
        
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("MY \(grape?.name.uppercased() ?? "WINES")S")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                ForEach(ranking.sortedEntries) { entry in
                    if let wine = dataService.wine(byId: entry.wineId) {
                        RankEntryRow(entry: entry, wine: wine, ranking: ranking)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wineglass")
                .font(.system(size: 60))
                .foregroundStyle(Color.wineRed.opacity(0.5))
            
            Text("No Rankings Yet")
                .font(.title2.bold())
            
            Text("Start building your wine list!\nTap Rate to add your first wine.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink {
                RateView()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Rate Your First Wine")
                }
                .font(.headline)
                .padding()
                .background(Color.wineRed)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Rank Entry Row
struct RankEntryRow: View {
    let entry: RankEntry
    let wine: Wine
    let ranking: Ranking
    
    // Check if this entry is tied with another
    private var isTied: Bool {
        ranking.entries.filter { $0.position == entry.position }.count > 1
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Number
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 44, height: 44)
                
                Text("#\(entry.position)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            
            // Wine Info
            VStack(alignment: .leading, spacing: 4) {
                Text(wine.name)
                    .font(.headline)
                
                HStack {
                    Text(wine.producer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let region = wine.region() {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(region.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 8) {
                    Text("Best: \(entry.bestVintageDisplay)")
                        .font(.caption)
                        .foregroundStyle(Color.wineRed)
                    
                    if entry.vintagesTried > 1 {
                        Text("• \(entry.vintagesTried) vintages tried")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    if isTied {
                        Text("(tied)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
    }
    
    private var rankColor: Color {
        switch entry.position {
        case 1: return .champagneGold
        case 2: return Color(.systemGray)
        case 3: return Color(hex: "#CD7F32")  // Bronze
        default: return Color.wineRed.opacity(0.7)
        }
    }
}

#Preview {
    MyListView()
        .environmentObject(RankingDataService.shared)
}
