//
//  StartupView.swift
//  Authorization
//
//  Created by SaeedBashir on 10/23/23.
//

import Foundation
import SwiftUI
import Core
import Theme

public struct StartupView: View {
    
//    @State private var searchQuery: String = ""
    
    @Environment(\.isHorizontal) private var isHorizontal

    @Bindable private var viewModel: StartupViewModel

    public init(viewModel: StartupViewModel) {
        self.viewModel = viewModel
    }
    
    // Saberes (pedido 150 — protótipo aprovado em 15/10/2026, igual ao Android SaberesBoasVindas.kt): colagem com capas
    // dos cursos sobre o azul-escuro, “Grátis”, título, selos e os três caminhos (criar conta, entrar, ver os cursos).
    // Patch saberes-ios/patches/boas-vindas.patch; as imagens saberesCapa1–3/saberesLogoBranco vêm do aplicar.sh.
    public var body: some View {
        GeometryReader { tela in
            ScrollView {
                VStack(spacing: 0) {
                    saberesColagem(largura: tela.size.width)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Comida é direito. Aprenda a defendê-lo.")
                            .font(.custom("Saberes-Bold", size: 30))
                            .foregroundColor(SaberesCor.tinta)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("heading_text")
                        Text("Cursos gratuitos da UNESP sobre Segurança Alimentar e Nutricional, no seu ritmo e com certificado.")
                            .font(.custom("Saberes-Regular", size: 15))
                            .foregroundColor(SaberesCor.textoSuave)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            saberesSelo("Certificado", icone: "rosette")
                            saberesSelo("3 a 6 horas", icone: "clock")
                            saberesSelo("No celular", icone: "iphone")
                        }
                        .padding(.bottom, 8)
                        Button {
                            viewModel.router.showRegisterScreen(sourceScreen: .startup)
                        } label: {
                            Text("Criar conta grátis")
                                .font(.custom("Saberes-Bold", size: 17))
                                .foregroundColor(SaberesCor.tinta)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(SaberesCor.ambar)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .accessibilityIdentifier("logistration_register_button")
                        Button {
                            viewModel.router.showLoginScreen(sourceScreen: .startup)
                        } label: {
                            Text("Já tenho conta")
                                .font(.custom("Saberes-SemiBold", size: 16))
                                .foregroundColor(SaberesCor.azul)
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .background(Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(SaberesCor.azul, lineWidth: 1.5))
                        }
                        .accessibilityIdentifier("logistration_signin_button")
                        Button {
                            viewModel.router.showDiscoveryScreen(searchQuery: "", sourceScreen: .startup)
                            viewModel.logAnalytics()
                        } label: {
                            HStack(spacing: 6) {
                                Text("Ver os cursos antes de entrar")
                                    .font(.custom("Saberes-Medium", size: 14))
                                Image(systemName: "arrow.right").font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(SaberesCor.azul)
                            .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .accessibilityIdentifier("explore_courses_button")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, minHeight: max(420, tela.size.height - 360), alignment: .top)
                    .background(
                        // só os cantos de cima arredondados (os de baixo ficam fora da tela)
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.white)
                            .padding(.bottom, -40)
                    )
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(AuthLocalization.Startup.title)
        .navigationBarHidden(true)
        .background(
            VStack(spacing: 0) {
                SaberesCor.tinta
                Color.white
            }
            .ignoresSafeArea()
        )
        .environment(\.colorScheme, .light)
        .onFirstAppear {
            viewModel.trackScreenEvent()
        }
    }

    // posições do protótipo (390 pt de largura), em escala
    private func saberesColagem(largura: CGFloat) -> some View {
        let k = min(largura, 600) / 390
        return ZStack(alignment: .topLeading) {
            SaberesCor.tinta
            Image("saberesLogoBranco")
                .resizable().scaledToFit()
                .frame(width: 128)
                .offset(x: 24, y: 12)
                .accessibilityLabel("Saberes INTERSSAN.org")
            saberesCapa("saberesCapa1", x: 24 * k, y: 70, largura: 200 * k, altura: 136, giro: -4)
            saberesCapa("saberesCapa2", x: 196 * k, y: 56, largura: 178 * k, altura: 122, giro: 5)
            saberesCapa("saberesCapa3", x: 112 * k, y: 188, largura: 204 * k, altura: 140, giro: -1)
                .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
            HStack(spacing: 6) {
                Image(systemName: "checkmark").font(.system(size: 13, weight: .bold))
                Text("Grátis").font(.custom("Saberes-Bold", size: 13))
            }
            .foregroundColor(SaberesCor.tinta)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Capsule().fill(SaberesCor.ambar))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
            .offset(x: 262 * k, y: 172)
        }
        .frame(height: 360)
        .clipped()
    }

    private func saberesCapa(_ nome: String, x: CGFloat, y: CGFloat, largura: CGFloat, altura: CGFloat,
                             giro: Double) -> some View {
        Image(nome)
            .resizable().scaledToFill()
            .frame(width: largura, height: altura)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .rotationEffect(.degrees(giro))
            .offset(x: x, y: y)
            .accessibilityHidden(true)
    }

    private func saberesSelo(_ texto: String, icone: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icone).font(.system(size: 12, weight: .semibold)).foregroundColor(SaberesCor.azul)
            Text(texto).font(.custom("Saberes-Medium", size: 12.5)).foregroundColor(Color(red: 1/255, green: 75/255, blue: 103/255))
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(Capsule().fill(SaberesCor.azulClaro))
        .accessibilityElement(children: .combine)
    }
}

// cores do Saberes (as mesmas do Android, SaberesUi.kt)
enum SaberesCor {
    static let tinta = Color(red: 10/255, green: 42/255, blue: 56/255)        // #0A2A38
    static let azul = Color(red: 1/255, green: 99/255, blue: 135/255)         // #016387
    static let azulClaro = Color(red: 227/255, green: 241/255, blue: 245/255) // #E3F1F5
    static let ambar = Color(red: 246/255, green: 174/255, blue: 47/255)      // #F6AE2F
    static let textoSuave = Color(red: 61/255, green: 79/255, blue: 87/255)   // #3D4F57
}

#if DEBUG
struct StartupView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = StartupViewModel(
            router: AuthorizationRouterMock(),
            analytics: CoreAnalyticsMock(),
            config: ConfigMock()
        )
        
        StartupView(viewModel: vm)
            .preferredColorScheme(.light)
            .previewDisplayName("StartupView Light")
            .loadFonts()
        
        StartupView(viewModel: vm)
            .preferredColorScheme(.dark)
            .previewDisplayName("StartupView Dark")
            .loadFonts()
    }
}
#endif
