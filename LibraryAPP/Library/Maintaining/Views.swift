//
//  View.swift
//  Views
//
//  Created by Shivam Trivedi on 18/04/26.
//

import SwiftUI

// ─────────────────────────────────────────────────
// MARK: - Home View
// ─────────────────────────────────────────────────
struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {

                        // Hero header
                        HeroHeader()
                            .padding(.top, 8)

                        // Trending section
                        SectionHeader("Trending Now", subtitle: "Classic literature")
                        BookShelf(state: vm.trending) {
                            Task { await vm.loadTrending() }
                        }

                        // Fantasy section
                        SectionHeader("Fantasy Worlds", subtitle: "Escape into magic")
                        BookShelf(state: vm.fantasy) {
                            Task { await vm.loadSubject("fantasy") }
                        }

                        // Science section
                        SectionHeader("Science & Discovery", subtitle: "Expand your mind")
                        BookShelf(state: vm.science) {
                            Task { await vm.loadSubject("science") }
                        }

                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task { await vm.loadAll() }
    }
}

// MARK: - Hero Header
struct HeroHeader: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("BookShelf")
                    .font(.system(size: 36, weight: .heavy, design: .serif))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                Text("Your personal reading universe")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange)
        }
        .padding(.horizontal)
    }
}

// ─────────────────────────────────────────────────
// MARK: - Search View
// ─────────────────────────────────────────────────
struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.orange)

                        TextField("Search books, authors...", text: $vm.query)
                            .foregroundStyle(.white)
                            .tint(.orange)
                            .focused($isFocused)
                            .submitLabel(.search)
                            .onSubmit { Task { await vm.search() } }
                            .onChange(of: vm.query) { _ in
                                Task { await vm.search() }
                            }

                        if !vm.query.isEmpty {
                            Button { vm.clear(); isFocused = false } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                    .padding()

                    // Results
                    Group {
                        switch vm.state {
                        case .idle:
                            SearchPlaceholder()
                        case .loading:
                            ProgressView()
                                .tint(.orange)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .success(let books):
                            if books.isEmpty {
                                ContentUnavailableView("No Results", systemImage: "book.closed", description: Text("Try a different search"))
                                    .foregroundStyle(.gray)
                            } else {
                                List(books) { book in
                                    BookRow(book: book)
                                        .listRowBackground(Color.black)
                                        .listRowSeparatorTint(Color.white.opacity(0.08))
                                }
                                .listStyle(.plain)
                                .scrollDismissesKeyboard(.immediately)
                            }
                        case .failure(let err):
                            ErrorBanner(error: err) { Task { await vm.search() } }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct SearchPlaceholder: View {
    let suggestions = ["Harry Potter", "Dune", "Isaac Asimov", "Lord of the Rings", "Tolkien"]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 52))
                .foregroundStyle(.orange.opacity(0.4))
            Text("Search millions of books")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
            Text("Try searching for:")
                .font(.caption)
                .foregroundStyle(.gray)
            FlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { s in
                    Text(s)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal)
            Spacer()
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0, +) + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        let maxWidth = proposal.width ?? 300
        var rows: [[LayoutSubview]] = [[]]
        var rowWidth: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([view]); rowWidth = size.width + spacing
            } else {
                rows[rows.count - 1].append(view); rowWidth += size.width + spacing
            }
        }
        return rows
    }
}

// ─────────────────────────────────────────────────
// MARK: - Favourites View
// ─────────────────────────────────────────────────
struct FavouritesView: View {
    @EnvironmentObject var favourites: FavouritesStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if favourites.books.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 52))
                            .foregroundStyle(.orange.opacity(0.4))
                        Text("Your library is empty")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("Heart a book to save it here")
                            .font(.callout)
                            .foregroundStyle(.gray)
                    }
                } else {
                    List(favourites.books) { book in
                        BookRow(book: book)
                            .listRowBackground(Color.black)
                            .listRowSeparatorTint(Color.white.opacity(0.08))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    favourites.toggle(book)
                                } label: {
                                    Label("Remove", systemImage: "heart.slash")
                                }
                                .tint(.orange)
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// ─────────────────────────────────────────────────
// MARK: - Book Detail View
// ─────────────────────────────────────────────────
struct BookDetailView: View {
    let book: BookDoc
    @StateObject private var vm = BookDetailViewModel()
    @EnvironmentObject var favourites: FavouritesStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // MARK: Hero Section
                    ZStack(alignment: .bottom) {
                        // Blurred background cover
                        AsyncImage(url: book.largeCoverURL) { img in
                            img.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: { Color.gray.opacity(0.2) }
                        .frame(height: 320)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.6), .black],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .blur(radius: 0)

                        // Cover + meta
                        HStack(alignment: .bottom, spacing: 20) {
                            BookCoverView(url: book.largeCoverURL, width: 110, height: 165)
                                .shadow(color: .orange.opacity(0.3), radius: 12, y: 6)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(book.title)
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                    .foregroundStyle(.white)
                                    .lineLimit(3)

                                Text(book.primaryAuthor)
                                    .font(.subheadline)
                                    .foregroundStyle(.orange)

                                if let year = book.firstPublishYear {
                                    Text("First published \(year)")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }

                                if book.ratingsAverage != nil {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(.yellow)
                                            .font(.caption)
                                        Text(book.rating)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.white)
                                        if let count = book.ratingsCount {
                                            Text("(\(count))")
                                                .font(.caption2)
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }

                    // MARK: Action buttons
                    HStack(spacing: 14) {
                        Button {
                            favourites.toggle(book)
                        } label: {
                            Label(
                                favourites.isFavourite(book) ? "Saved" : "Save",
                                systemImage: favourites.isFavourite(book) ? "heart.fill" : "heart"
                            )
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(favourites.isFavourite(book) ? .black : .orange)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                favourites.isFavourite(book) ? Color.orange : Color.orange.opacity(0.12),
                                in: Capsule()
                            )
                        }

                        if let url = URL(string: "https://openlibrary.org\(book.key)") {
                            Link(destination: url) {
                                Label("Open Library", systemImage: "arrow.up.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal)

                    // MARK: Detail Content
                    VStack(alignment: .leading, spacing: 20) {
                        switch vm.detailState {
                        case .idle:
                            EmptyView()
                        case .loading:
                            HStack { Spacer(); ProgressView().tint(.orange); Spacer() }
                                .padding(.top, 30)
                        case .success(let detail):
                            DetailContent(detail: detail, book: book)
                        case .failure(let err):
                            ErrorBanner(error: err) { Task { await vm.load(book: book) } }
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load(book: book) }
    }
}

struct DetailContent: View {
    let detail: BookDetailResponse
    let book: BookDoc

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("About this book")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.horizontal)

                Text(detail.descriptionText)
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .lineSpacing(5)
                    .padding(.horizontal)
            }

            Divider().background(Color.white.opacity(0.1)).padding(.horizontal)

            // Subjects
            if let subjects = detail.subjects?.prefix(10), !subjects.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Subjects")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .padding(.horizontal)

                    FlowLayout(spacing: 8) {
                        ForEach(Array(subjects), id: \.self) { s in
                            TagChip(text: s)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Pages info
            if let pages = book.numberOfPagesMedian {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.orange)
                    Text("~\(pages) pages")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal)
            }
        }
    }
}
