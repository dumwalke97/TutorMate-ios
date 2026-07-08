import SwiftUI
import StoreKit
import FirebaseAuth

struct PaywallView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @ObservedObject private var store = StoreManager.shared
    @ObservedObject private var firebaseManager = FirebaseManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID = StoreManager.annualProductID
    @State private var isPurchasing = false
    @State private var showAccountSheet = false
    @State private var pendingPurchase = false
    @State private var errorMessage: String? = nil

    /// Subscriptions are tied to an account so access can sync across devices.
    private var needsAccount: Bool {
        firebaseManager.currentUser == nil || firebaseManager.currentUser?.isAnonymous == true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    featureList
                    planCards
                    subscribeButton
                    cancelAnytimeNote
                    restoreButton
                    finePrint
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Color.tmCanvas.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 26, weight: .regular))
                            .foregroundColor(.tmInk.opacity(0.55))
                    }
                }
            }
            .toolbarBackground(Color.tmCanvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .interactiveDismissDisabled(isPurchasing)
        .sheet(isPresented: $showAccountSheet) {
            LoginView(viewModel: viewModel)
        }
        .onChange(of: firebaseManager.currentUser?.uid) { _ in
            // Continue the purchase automatically once the user finishes
            // creating an account.
            if pendingPurchase && !needsAccount {
                pendingPurchase = false
                showAccountSheet = false
                startPurchase()
            }
        }
        .alert(
            "Subscription",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
            }
        }
    }

    // MARK: - Sections

    private var headerMessage: String {
        if UsageTracker.shared.hasFreeUsesRemaining {
            return "Unlimited quizzes and assignment checks, synced across your devices."
        }
        return "You've used your \(UsageTracker.freeUseLimit) free quizzes and checks. Go unlimited to keep learning."
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 72, height: 72)
                .background(Color.tmNavy)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text("TutorMate Premium")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.tmInk)

            Text(headerMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: "sparkles", text: "Unlimited quiz generation")
            featureRow(icon: "checkmark.circle", text: "Unlimited assignment checks")
            featureRow(icon: "folder", text: "Save worksheets to folders on all your devices")
            featureRow(icon: "bolt", text: "All future premium features included")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tmCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.tmNavy.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.tmGreen)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.tmInk)
        }
    }

    @ViewBuilder
    private var planCards: some View {
        if store.products.isEmpty {
            VStack(spacing: 10) {
                ProgressView()
                Text("Loading plans…")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
        } else {
            VStack(spacing: 12) {
                if let annual = store.annualProduct {
                    planCard(
                        product: annual,
                        title: "Annual",
                        badge: store.annualSavingsPercent.map { "SAVE \($0)%" },
                        subtitle: "per year"
                    )
                }
                if let monthly = store.monthlyProduct {
                    planCard(
                        product: monthly,
                        title: "Monthly",
                        badge: nil,
                        subtitle: "per month"
                    )
                }
            }
        }
    }

    private func planCard(product: Product, title: String, badge: String?, subtitle: String) -> some View {
        let isSelected = selectedProductID == product.id
        return Button {
            selectedProductID = product.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.tmInk)
                        if let badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.tmGreen)
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(product.displayPrice) \(subtitle)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .tmNavy : .tmInk.opacity(0.25))
            }
            .padding(18)
            .background(Color.tmCard)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.tmNavy : Color.tmInk.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var subscribeButton: some View {
        Button(action: subscribeTapped) {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(needsAccount ? "Sign Up & Subscribe" : "Subscribe")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(.white)
            .background(Color.tmNavy)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isPurchasing || store.products.isEmpty)
    }

    private var cancelAnytimeNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.tmGreen)
            Text("No commitment — cancel anytime.")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.top, -12)
    }

    private var restoreButton: some View {
        Button(action: restoreTapped) {
            Text("Restore Purchases")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.tmNavy)
        }
        .disabled(isPurchasing)
    }

    private var finePrint: some View {
        VStack(spacing: 10) {
            Text("Payment will be charged to your Apple Account at confirmation of purchase. The subscription renews automatically unless it is canceled at least 24 hours before the end of the current period. Manage or cancel anytime in your App Store settings.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link("Privacy Policy", destination: URL(string: "https://tutormate.ai/privacy")!)
            }
            .font(.caption)
            .foregroundColor(.tmNavy)
        }
    }

    // MARK: - Actions

    private func subscribeTapped() {
        if needsAccount {
            pendingPurchase = true
            viewModel.authStartAsSignUp = true
            showAccountSheet = true
            return
        }
        startPurchase()
    }

    private func startPurchase() {
        guard let product = store.products.first(where: { $0.id == selectedProductID }) else { return }
        isPurchasing = true
        Task {
            do {
                let success = try await store.purchase(product)
                isPurchasing = false
                if success {
                    dismiss()
                }
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func restoreTapped() {
        isPurchasing = true
        Task {
            do {
                try await store.restorePurchases()
                isPurchasing = false
                if store.isSubscribed {
                    dismiss()
                } else {
                    errorMessage = "No active subscription was found for this Apple Account."
                }
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
