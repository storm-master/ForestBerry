import SwiftUI

struct FBStatisticsView: View {
    @State private var entries: [HarvestEntry] = []
    
    var body: some View {
        ForestBerryScreen(title: "Season Statistics") {
            Group {
                if entries.isEmpty {
                    Image("statistics_nodata")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280)
                        .padding(.top, 40)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            collectedBerriesSection
                            mostCommonlyCollectedSection
                            collectionHistorySection
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .onAppear(perform: loadEntries)
        }
    }
    
    private func loadEntries() {
        entries = HarvestJournalManager.shared.loadEntries().sorted { $0.date > $1.date }
    }
    
    private var collectedBerriesSection: some View {
        VStack(spacing: 16) {
            Text("The collected berries")
                .font(.custom("Copperplate-Bold", size: 22))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Month")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize()
                    
                    Text("\(totalMonthQuantity)")
                        .font(.custom("Copperplate-Bold", size: 48))
                        .foregroundColor(.white)
                        .fixedSize()
                    
                    Text("kilograms")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize()
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 8) {
                    Text("Season")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize()
                    
                    Text("\(totalSeasonQuantity)")
                        .font(.custom("Copperplate-Bold", size: 48))
                        .foregroundColor(.white)
                        .fixedSize()
                    
                    Text("kilograms")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .padding(20)
        .background(
            Image("txffield_background")
                .resizable(capInsets: EdgeInsets(top: 36, leading: 36, bottom: 36, trailing: 36), resizingMode: .stretch)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
    
    private var mostCommonlyCollectedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Most commonly collected")
                .font(.custom("Copperplate-Bold", size: 22))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(Array(mostCommonBerries.prefix(3)), id: \.key) { berry, count in
                    HStack(spacing: 12) {
                        if let entry = entries.first(where: { $0.berryType == berry }),
                           let imageData = entry.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .clipped()
                        }
                        
                        Text(berry)
                            .font(.custom("Copperplate-Bold", size: 20))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            Image("txffield_background")
                .resizable(capInsets: EdgeInsets(top: 36, leading: 36, bottom: 36, trailing: 36), resizingMode: .stretch)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
    
    private var collectionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Collection history")
                .font(.custom("Copperplate-Bold", size: 22))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(entries) { entry in
                    HStack(spacing: 12) {
                        VStack(spacing: 6) {
                            if let imageData = entry.imageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .clipped()
                            }
                            
                            Text(entry.berryType)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(width: 60)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Text(entry.quantityFormatted)
                                .font(.custom("Copperplate-Bold", size: 28))
                                .foregroundColor(.white)
                                .fixedSize()
                            
                            Text(entry.unit.displayName.lowercased())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .fixedSize()
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.black.opacity(0.2))
                    )
                }
            }
        }
        .padding(20)
        .background(
            Image("txffield_background")
                .resizable(capInsets: EdgeInsets(top: 36, leading: 36, bottom: 36, trailing: 36), resizingMode: .stretch)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
    
    private var totalMonthQuantity: Int {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        return entries
            .filter {
                let month = calendar.component(.month, from: $0.date)
                let year = calendar.component(.year, from: $0.date)
                return month == currentMonth && year == currentYear
            }
            .reduce(0) { $0 + Int($1.quantity) }
    }
    
    private var totalSeasonQuantity: Int {
        entries.reduce(0) { $0 + Int($1.quantity) }
    }
    
    private var mostCommonBerries: [(key: String, value: Int)] {
        let grouped = Dictionary(grouping: entries) { $0.berryType }
        let counted = grouped.mapValues { $0.count }
        return counted.sorted { $0.value > $1.value }
    }
}

