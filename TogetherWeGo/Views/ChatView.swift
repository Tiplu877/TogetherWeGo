//
//  ChatView.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/10/26.
//


import SwiftUI

struct ChatView: View {
    @Environment(AuthViewModel.self) private var auth
    let tripID: String
    @State private var model = ChatViewModel()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    if model.messages.isEmpty {
                        ContentUnavailableView(
                            "No messages yet",
                            systemImage: "bubble.left.and.bubble.right",
                            description: Text("Say hi to your group!")
                        )
                        .padding(.top, 40)
                    }

                    ForEach(Array(model.messages.enumerated()), id: \.element.id) { index, message in
                        // Only show the name when the sender changes
                        let showName = index == 0 || model.messages[index - 1].senderID != message.senderID

                        MessageRow(message: message,
                                   isMine: message.senderID == auth.userID,
                                   showName: showName)
                            .id(message.id)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = message.text
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                if message.senderID == auth.userID {
                                    Button(role: .destructive) {
                                        model.delete(message)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.messages.count) {
                if let last = model.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let announcement = model.latestAnnouncement {
                AnnouncementBanner(message: announcement)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(.bar)
            }
        }
        .safeAreaInset(edge: .bottom) {
            inputBar
        }
        .task {
            guard auth.userID != nil else { return }
            model.start(tripID: tripID)
        }
        .onDisappear {
            model.stop()
        }
    }

    private var inputBar: some View {
        VStack(spacing: 4) {
            if let error = model.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            if model.trimmedDraft.count > 400 {
                Text("\(model.trimmedDraft.count)/\(ChatViewModel.maxLength)")
                    .font(.caption)
                    .foregroundStyle(model.trimmedDraft.count > ChatViewModel.maxLength ? Color.red : Color.secondary)
            }
            HStack(alignment: .bottom, spacing: 8) {
                Button {
                    model.sendAsAnnouncement.toggle()
                } label: {
                    Image(systemName: model.sendAsAnnouncement ? "megaphone.fill" : "megaphone")
                        .font(.title3)
                }
                .accessibilityLabel(model.sendAsAnnouncement ? "Announcement mode on" : "Send as announcement")

                TextField(model.sendAsAnnouncement ? "Announcement for everyone" : "Message",
                          text: $model.draft,
                          axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))

                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
                .disabled(!model.canSend)
                .accessibilityLabel("Send")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func send() {
        guard let userID = auth.userID else { return }
        model.send(userID: userID, userName: auth.displayName)
    }
}

// One chat bubble
struct MessageRow: View {
    let message: ChatMessage
    let isMine: Bool
    let showName: Bool

    var body: some View {
        if message.isAnnouncement {
            AnnouncementBanner(message: message)
        } else {
            VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
                if showName && !isMine {
                    Text(message.senderName)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundStyle(isMine ? Color.white : Color.primary)
                    .background(isMine ? Color.accentColor : Color(.secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 18))
                Text(message.sentAt.chatTimestamp)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
            .padding(isMine ? .leading : .trailing, 48)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(isMine ? "You" : message.senderName) said: \(message.text), \(message.sentAt.chatTimestamp)")
        }
    }
}

// The orange pinned-style card for announcements
struct AnnouncementBanner: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "megaphone.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(message.text)
                    .font(.subheadline.weight(.semibold))
                Text("\(message.senderName) · \(message.sentAt.chatTimestamp)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Announcement from \(message.senderName): \(message.text)")
    }
}