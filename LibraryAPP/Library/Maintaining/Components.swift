//
//  BookCoverView.swift
//  BookCoverView
//
//  Created by Shivam Trivedi on 18/04/26.
//

import SwiftUI

// MARK: - Async Cover Image
struct BookCoverView: View {
    let url: URL?
    let width: CGFloat
    let height: CGFloat
    var cornerRadius: CGFloat = 10

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                coverPlaceholder
                    .overlay(ProgressView().tint(.white).scaleEffect(0.7))
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                coverPlaceholder
                    .overlay(
                        Image(systemName: "book.closed.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    )
            @unknown default:
                coverPlaceholder
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
    }

    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(.white)
            if let sub = subtitle {
                Text(sub)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let error: NetworkError
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text(error.errorDescription ?? "Something went wrong")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
            Button("Retry") { retry() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Book Card (horizontal scroll)
struct BookCard: View {
    let book: BookDoc
    @EnvironmentObject var favourites: FavouritesStore

    var body: some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    BookCoverView(url: book.coverURL, width: 130, height: 190)

                    if favourites.isFavourite(book) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.orange)
                            .padding(6)
                            .background(.ultraThinMaterial, in: Circle())
                            .padding(8)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .frame(width: 130, alignment: .leading)

                    Text(book.primaryAuthor)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                        .frame(width: 130, alignment: .leading)

                    if let year = book.firstPublishYear {
                        Text("\(year)")
                            .font(.caption2)
                            .foregroundStyle(.orange.opacity(0.8))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Book Row (vertical list)
struct BookRow: View {
    let book: BookDoc
    @EnvironmentObject var favourites: FavouritesStore

    var body: some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            HStack(spacing: 14) {
                BookCoverView(url: book.coverURL, width: 65, height: 95, cornerRadius: 8)

                VStack(alignment: .leading, spacing: 5) {
                    Text(book.title)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(book.primaryAuthor)
                        .font(.caption)
                        .foregroundStyle(.gray)

                    HStack(spacing: 8) {
                        if let year = book.firstPublishYear {
                            Label("\(year)", systemImage: "calendar")
                                .font(.caption2)
                                .foregroundStyle(.orange.opacity(0.7))
                        }
                        if book.ratingsAverage != nil {
                            Label(book.rating, systemImage: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow.opacity(0.8))
                        }
                    }

                    if let subjects = book.subject?.prefix(2) {
                        HStack(spacing: 4) {
                            ForEach(Array(subjects), id: \.self) { tag in
                                TagChip(text: tag)
                            }
                        }
                    }
                }
                Spacer()

                Button {
                    favourites.toggle(book)
                } label: {
                    Image(systemName: favourites.isFavourite(book) ? "heart.fill" : "heart")
                        .foregroundStyle(favourites.isFavourite(book) ? .orange : .gray)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String

    var body: some View {
        Text(text.capitalized)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.15), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.orange.opacity(0.3), lineWidth: 0.5))
    }
}

// MARK: - Skeleton Loading
struct SkeletonCard: View {
    @State private var shimmer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(shimmer ? 0.35 : 0.2))
                .frame(width: 130, height: 190)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(shimmer ? 0.35 : 0.2))
                .frame(width: 110, height: 10)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(shimmer ? 0.25 : 0.15))
                .frame(width: 80, height: 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }
}

// MARK: - Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color.orange, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

// MARK: - Horizontal Book Shelf
struct BookShelf: View {
    let state: AsyncState<[BookDoc]>
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .loading:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<6, id: \.self) { _ in SkeletonCard() }
                }
                .padding(.horizontal)
            }
        case .success(let books):
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(books) { book in
                        BookCard(book: book)
                    }
                }
                .padding(.horizontal)
            }
        case .failure(let err):
            ErrorBanner(error: err, retry: onRetry)
        }
    }
}
