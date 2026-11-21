import SwiftUI

struct CareGuideView: View {
    @State private var query = ""

    private var articles: [CareGuideArticle] {
        CareGuideCatalog.search(query)
    }

    var body: some View {
        List {
            if articles.isEmpty {
                ContentUnavailableView {
                    Label("A thoughtful guide is taking root", systemImage: "book.closed")
                } description: {
                    Text("Feed Good's care guide is being prepared and reviewed before publication. Your own care routines remain available, and they are prompts to observe rather than fixed horticultural advice.")
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(articles) { article in
                        NavigationLink {
                            CareGuideArticleView(article: article)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(article.title)
                                    .font(.headline)
                                    .foregroundStyle(FeedGoodTheme.soil)
                                Text(article.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(FeedGoodTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                } header: {
                    Text("Learn at your own pace")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(FeedGoodTheme.background)
        .navigationTitle("Care Guide")
        .searchable(text: $query, prompt: "Search care topics")
        .accessibilityIdentifier("careGuide.list")
    }
}

private struct CareGuideArticleView: View {
    let article: CareGuideArticle

    var body: some View {
        List {
            Section {
                Text(article.summary)
                    .font(.body)
                    .foregroundStyle(FeedGoodTheme.muted)
            }
            ForEach(article.sections) { section in
                Section(section.title) {
                    Text(section.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Section("Sources") {
                ForEach(article.sources) { source in
                    if let url = URL(string: source.url) {
                        Link(destination: url) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.title)
                                    .font(.body.weight(.medium))
                                Text(source.publisher)
                                    .font(.caption)
                                    .foregroundStyle(FeedGoodTheme.muted)
                            }
                        }
                    }
                }
            }
            Section {
                Text("General learning only. Plant needs vary by species and growing conditions. Check plant-specific requirements and observe your own plant before changing its care.")
                    .font(.footnote)
                    .foregroundStyle(FeedGoodTheme.muted)
            }
        }
        .scrollContentBackground(.hidden)
        .background(FeedGoodTheme.background)
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
