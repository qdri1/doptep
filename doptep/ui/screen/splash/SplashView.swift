//
//  SplashView.swift
//  doptep
//

import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sceneOpacity: Double = 1
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.6
    @State private var sloganOpacity: Double = 0
    @State private var didShowLogo = false
    @State private var slogan = SplashView.slogans.randomElement() ?? ""

    private static let slogans = [
        "Oyındarıñ qızıqtı da, mändi ötsin",
        "Futbolımız dami bersin",
        "Futbol — bärimizdi biriktiretin oyın"
    ]

    private static let sceneAspectRatio: CGFloat = 1056.0 / 628.0

    var body: some View {
        ZStack {
            Color("SplashBackground")
                .ignoresSafeArea()

            if !reduceMotion {
                LottieView(name: "dop_tep_splash", loopMode: .playOnce, onCompleted: showLogo)
                    .aspectRatio(Self.sceneAspectRatio, contentMode: .fit)
                    .padding(.horizontal, 16)
                    .opacity(sceneOpacity)
            }

            VStack(spacing: 20) {
                Image("app_logo")
                    .resizable()
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text(slogan)
                    .font(.titleMedium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(sloganOpacity)
                    .offset(y: (1 - sloganOpacity) * 12)
            }
            .padding(.horizontal, 32)

            VStack {
                Spacer()
                Text("Made in KZ")
                    .font(.custom("Montserrat-Bold", size: 12))
                    .tracking(2)
                    .foregroundColor(Color.white.opacity(0.75))
                    .padding(.bottom, 24)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onFinished()
        }
        .onAppear {
            if reduceMotion {
                showLogo()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    showLogo()
                }
            }
        }
    }

    private func showLogo() {
        guard !didShowLogo else { return }
        didShowLogo = true

        withAnimation(.easeOut(duration: 0.3)) {
            sceneOpacity = 0
            logoOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
            logoScale = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.25)) {
            sloganOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            onFinished()
        }
    }
}
