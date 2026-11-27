import SwiftUI

/// The game (the web's GamePlay): HUD, question card, "Pasar", report and sound. Compact width:
/// HUD bar on top, card, actions within thumb reach. Wide (iPad, landscape): card on the left and
/// the watch panel on the right.
struct GameScreen: View {
    let session: GameSession
    let onExit: () -> Void

    @Environment(AppEnvironment.self) private var env
    @Environment(\.horizontalSizeClass) private var horizontalSize
    @Environment(\.verticalSizeClass) private var verticalSize
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var fx = GameFx()
    @State private var reporting: ReportTarget?
    @State private var confirmExit = false
    @AccessibilityFocusState private var questionFocused: Bool

    private var wide: Bool { horizontalSize == .regular || verticalSize == .compact }
    /// Large text or a short screen (iPhone in landscape) scrolls; otherwise the card fills the
    /// height with the answers at the bottom. Chosen up front: iOS 26 measures `ViewThatFits`
    /// candidates on a background thread, which traps on main-actor view code.
    private var scrolls: Bool { dynamicTypeSize >= .xxLarge || verticalSize == .compact }

    var body: some View {
        ZStack {
            Color.ground.ignoresSafeArea()
            if wide { wideLayout } else { compactLayout }
            FxLayer(fx: fx)
        }
        .background(GameKeyboardShortcuts(onKey: handleKey))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("game.screen")
        .onChange(of: session.feedback) { _, feedback in react(to: feedback) }
        .onChange(of: session.snapshot.score) { old, new in if new < old { fx.showHit(old - new) } }
        .onChange(of: session.snapshot.streak) { old, new in if new < old && old >= 2 { fx.breakStreak() } }
        .onChange(of: session.announcementCount) { _, _ in
            AccessibilityNotification.Announcement(session.announcement).post()
        }
        .onChange(of: session.question?.id) { _, _ in questionFocused = true }
        .alert("¿Abandonar la partida?", isPresented: $confirmExit) {
            Button("Abandonar", role: .destructive, action: onExit)
            Button("Seguir jugando", role: .cancel) { session.resume() }
        } message: {
            Text("La partida no se guardará ni contará para el ranking.")
        }
        .sheet(item: $reporting, onDismiss: { session.resume() }) { target in
            ReportQuestionSheet(
                target: target,
                onSend: {
                    reporting = nil
                    env.analytics.track(.questionReport(target.category, target.difficulty))
                    Task { _ = await env.mail.compose(questionReportDraft(id: target.id, text: target.text)) }
                },
                onCancel: { reporting = nil }
            )
        }
        .onAppear { questionFocused = true }
    }

    // MARK: Layouts

    private var compactLayout: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                exitButton
                HUD(session: session, fx: fx, wide: false)
            }
            playArea
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var wideLayout: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                exitButton
                playArea
            }
            .frame(maxWidth: 680)
            ScrollView {
                HUD(session: session, fx: fx, wide: true)
            }
            .frame(width: 300)
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    @ViewBuilder private var playArea: some View {
        if scrolls {
            ScrollView { cardAndActions(fill: false) }
                .scrollBounceBehavior(.basedOnSize)
        } else {
            cardAndActions(fill: true)
        }
    }

    @ViewBuilder private func cardAndActions(fill: Bool) -> some View {
        VStack(spacing: 12) {
            if let question = session.question {
                QuestionCardView(question: question, feedback: session.feedback, onAnswer: { session.answer($0) },
                                 fillHeight: fill, questionFocused: $questionFocused)
                    .frame(maxHeight: fill ? .infinity : nil)
            }
            HStack(spacing: 12) {
                SkipButton(freeLeft: session.snapshot.freeSkipsLeft, cost: session.snapshot.skipCost,
                           locked: session.feedback != nil) { session.skip() }
                Spacer(minLength: 0)
                reportButton
                soundButton
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: Controls

    private var exitButton: some View {
        Button {
            session.pause()
            confirmExit = true
        } label: {
            Image(systemName: "xmark")
                .font(.headline.weight(.bold))
                .frame(width: 44, height: 44)
                .background(Color.groundRaised, in: Circle())
                .overlay(Circle().strokeBorder(Color.groundBorder, lineWidth: 1))
        }
        .foregroundStyle(Color.onGround)
        .accessibilityLabel(Text("Abandonar la partida"))
        .accessibilityIdentifier("exitGame")
    }

    private var reportButton: some View {
        Button {
            guard let q = session.question, session.feedback == nil, reporting == nil else { return }
            session.pause()
            reporting = ReportTarget(id: q.id, text: q.text, category: q.category, difficulty: q.difficulty)
        } label: {
            Image(systemName: "flag").font(.body.weight(.semibold)).frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(Color.groundBorder, lineWidth: 1))
        }
        .foregroundStyle(Color.onGroundSoft)
        .disabled(session.question == nil || session.feedback != nil)
        .accessibilityLabel(Text("Reportar esta pregunta"))
        .accessibilityIdentifier("reportQuestion")
    }

    private var soundButton: some View {
        @Bindable var sound = env.sound
        return Button {
            sound.isMuted.toggle()
        } label: {
            Image(systemName: sound.isMuted ? "speaker.slash" : "speaker.wave.2")
                .font(.body.weight(.semibold)).frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(Color.groundBorder, lineWidth: 1))
        }
        .foregroundStyle(Color.onGroundSoft)
        .accessibilityLabel(Text(sound.isMuted ? "Activar el sonido" : "Silenciar el sonido"))
        .accessibilityIdentifier("soundToggle")
    }

    // MARK: Reactions

    private func react(to feedback: AnswerFeedback?) {
        guard let feedback else { return }
        if !feedback.correct {
            fx.flashWrong()
            return
        }
        let streak = session.snapshot.streak
        guard streak >= GameFx.cheerFrom else { return }
        fx.cheer(streak: streak, bonus: feedback.bonus)
        let big = feedback.bonus > 0
        Haptics.streak(big: big)
        if big {
            let player = env.player
            Task {
                try? await Task.sleep(for: .milliseconds(180))
                player.play(.streak)
            }
        }
    }

    private func handleKey(_ key: String) {
        guard session.question != nil, session.feedback == nil, reporting == nil, !confirmExit else { return }
        switch actionForKey(key, optionCount: session.question?.options.count ?? 0) {
        case .answer(let index): session.answer(index)
        case .skip: session.skip()
        case nil: break
        }
    }
}

/// Hardware keyboard (iPad): 1-4 or A-D answer, P skips, like the web.
private struct GameKeyboardShortcuts: View {
    let onKey: (String) -> Void
    private static let keys = ["1", "2", "3", "4", "a", "b", "c", "d", "p"]

    var body: some View {
        ZStack {
            ForEach(Self.keys, id: \.self) { key in
                Button { onKey(key) } label: { EmptyView() }
                    .keyboardShortcut(KeyEquivalent(Character(key)), modifiers: [])
            }
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }
}
