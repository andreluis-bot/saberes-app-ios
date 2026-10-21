//
//  PrimaryCourseDashboardView.swift
//  Dashboard
//
//  Created by  Stepanok Ivan on 16.04.2024.
//

import SwiftUI
import Core
import OEXFoundation
import Theme
import Swinject
import Kingfisher

public struct PrimaryCourseDashboardView<ProgramView: View>: View {
    
    private var viewModel: PrimaryCourseDashboardViewModel
    @ViewBuilder let programView: ProgramView
    private var openDiscoveryPage: () -> Void
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    @State private var selectedMenu: MenuOption = .courses
    
    public init(
        viewModel: PrimaryCourseDashboardViewModel,
        programView: ProgramView,
        openDiscoveryPage: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.programView = programView
        self.openDiscoveryPage = openDiscoveryPage
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                if viewModel.enrollments?.primaryCourse == nil
                    && !viewModel.fetchInProgress
                    && selectedMenu == .courses {
                    NoCoursesView(openDiscovery: {
                        openDiscoveryPage()
                    }).zIndex(1)
                }
                learnTitleAndSearch(proxy: proxy)
                    .zIndex(1)
                // MARK: - Page body
                VStack(alignment: .leading) {
                    Spacer(minLength: 50)
                    switch selectedMenu {
                    case .courses:
                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            if viewModel.fetchInProgress {
                                VStack(alignment: .center) {
                                    ProgressBar(size: 40, lineWidth: 8)
                                        .padding(.top, 200)
                                }.frame(maxWidth: .infinity,
                                        maxHeight: .infinity)
                            } else {
                                LazyVStack(spacing: 0) {
                                        if let enrollments = viewModel.enrollments {
                                            if idiom != .pad {
                                                saberesCabecalho(enrollments)
                                            }
                                            if let primary = enrollments.primaryCourse, idiom != .pad {
                                                saberesContinuar(primary)
                                            } else if let primary = enrollments.primaryCourse {
                                                PrimaryCardView(
                                                    courseName: primary.name,
                                                    org: primary.org,
                                                    courseImage: primary.courseBanner,
                                                    courseStartDate: primary.courseStart,
                                                    courseEndDate: primary.courseEnd,
                                                    futureAssignments: primary.futureAssignments,
                                                    pastAssignments: primary.pastAssignments,
                                                    progressEarned: primary.progressEarned,
                                                    progressPossible: primary.progressPossible,
                                                    canResume: primary.lastVisitedBlockID != nil,
                                                    resumeTitle: primary.resumeTitle,
                                                    useRelativeDates: viewModel.storage.useRelativeDates,
                                                    assignmentAction: { lastVisitedBlockID in
                                                        viewModel.router.showCourseScreens(
                                                            courseID: primary.courseID,
                                                            hasAccess: primary.hasAccess,
                                                            courseStart: primary.courseStart,
                                                            courseEnd: primary.courseEnd,
                                                            enrollmentStart: nil,
                                                            enrollmentEnd: nil,
                                                            title: primary.name,
                                                            courseRawImage: primary.courseBanner,
                                                            showDates: lastVisitedBlockID == nil,
                                                            lastVisitedBlockID: lastVisitedBlockID
                                                        )
                                                    },
                                                    openCourseAction: {
                                                        viewModel.router.showCourseScreens(
                                                            courseID: primary.courseID,
                                                            hasAccess: primary.hasAccess,
                                                            courseStart: primary.courseStart,
                                                            courseEnd: primary.courseEnd,
                                                            enrollmentStart: nil,
                                                            enrollmentEnd: nil,
                                                            title: primary.name,
                                                            courseRawImage: primary.courseBanner,
                                                            showDates: false,
                                                            lastVisitedBlockID: nil
                                                        )
                                                    },
                                                    resumeAction: {
                                                        viewModel.router.showCourseScreens(
                                                            courseID: primary.courseID,
                                                            hasAccess: primary.hasAccess,
                                                            courseStart: primary.courseStart,
                                                            courseEnd: primary.courseEnd,
                                                            enrollmentStart: nil,
                                                            enrollmentEnd: nil,
                                                            title: primary.name,
                                                            courseRawImage: primary.courseBanner,
                                                            showDates: false,
                                                            lastVisitedBlockID: primary.lastVisitedBlockID
                                                        )
                                                    }
                                                )
                                            }
                                            if !enrollments.courses.isEmpty {
                                                viewAll(enrollments)
                                            }
                                            if idiom == .pad {
                                                LazyVGrid(
                                                    columns: [
                                                        GridItem(.flexible(), spacing: 16),
                                                        GridItem(.flexible(), spacing: 16),
                                                        GridItem(.flexible(), spacing: 16),
                                                        GridItem(.flexible(), spacing: 16)
                                                    ],
                                                    alignment: .leading,
                                                    spacing: 15
                                                ) {
                                                    courses(enrollments)
                                                }
                                                .padding(20)
                                            } else {
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack(spacing: 16) {
                                                        courses(enrollments)
                                                    }
                                                    .padding(20)
                                                }
                                            }
                                            Spacer(minLength: 100)
                                        }
                                }
                            }
                        }
                        .frameLimit(width: proxy.size.width)
                    }
                    .refreshable {
                        Task {
                            await viewModel.getEnrollments(showProgress: false)
                        }
                    }
                    .accessibilityAction {}
                    case .programs:
                        programView
                    }
                }.padding(.top, 8)
                // MARK: - Offline mode SnackBar
                OfflineSnackBarView(
                    connectivity: viewModel.connectivity,
                    reloadAction: {
                        await viewModel.getEnrollments(showProgress: false)
                    }
                ).zIndex(2)
                
                // MARK: - Error Alert
                if viewModel.showError {
                    VStack {
                        Spacer()
                        SnackBarView(message: viewModel.errorMessage)
                    }
                    .padding(
                        .bottom,
                        viewModel.connectivity.isInternetAvaliable ? 0 : OfflineSnackBarView.height
                    )
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                            viewModel.errorMessage = nil
                        }
                    }
                    .zIndex(2)
                }
            }
            .onFirstAppear {
                Task {
                    await viewModel.getEnrollments()
                }
                viewModel.setupNotifications()
            }
            .onAppear {
                viewModel.updateNeeded = true
            }
            .background(
                Theme.Colors.background
                    .ignoresSafeArea()
            )
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .navigationTitle(DashboardLocalization.title)
        }
    }
    
    @ViewBuilder
    private func courses(_ enrollments: PrimaryEnrollment) -> some View {
        let useRelativeDates = viewModel.storage.useRelativeDates
        ForEach(
            Array(enrollments.courses.enumerated()),
            id: \.offset
        ) { _, course in
            Button(action: {
                viewModel.router.showCourseScreens(
                    courseID: course.courseID,
                    hasAccess: course.hasAccess,
                    courseStart: course.courseStart,
                    courseEnd: course.courseEnd,
                    enrollmentStart: course.enrollmentStart,
                    enrollmentEnd: course.enrollmentEnd,
                    title: course.name,
                    courseRawImage: course.imageURL,
                    showDates: false,
                    lastVisitedBlockID: nil
                )
            }, label: {
                CourseCardView(
                    courseName: course.name,
                    courseImage: course.imageURL,
                    progressEarned: 0,
                    progressPossible: 0,
                    courseStartDate: nil,
                    courseEndDate: nil,
                    hasAccess: course.hasAccess,
                    showProgress: false,
                    useRelativeDates: useRelativeDates
                ).frame(width: idiom == .pad ? nil : 120)
            }
            )
            .accessibilityIdentifier("course_item")
        }
        if enrollments.courses.count < enrollments.count {
            viewAllButton(enrollments)
        }
    }
    
    private func viewAllButton(_ enrollments: PrimaryEnrollment) -> some View {
        Button(action: {
            viewModel.router.showAllCourses(courses: enrollments.courses)
        }, label: {
            ZStack(alignment: .topTrailing) {
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        CoreAssets.viewAll.swiftUIImage
                        Text(DashboardLocalization.Learn.viewAll)
                            .font(Theme.Fonts.labelMedium)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                    }
                    Spacer()
                }
                .frame(width: idiom == .pad ? nil : 120)
            }
            .background(Theme.Colors.cardViewBackground)
            .cornerRadius(8)
            .shadow(color: Theme.Colors.courseCardShadow, radius: 6, x: 2, y: 2)
        })
    }
    
    private func viewAll(_ enrollments: PrimaryEnrollment) -> some View {
        Button(action: {
            viewModel.router.showAllCourses(courses: enrollments.courses)
        }, label: {
            HStack {
                Text(DashboardLocalization.Learn.viewAllCourses(enrollments.count + 1))
                    .font(Theme.Fonts.titleSmall)
                    .accessibilityIdentifier("courses_welcomeback_text")
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal, 16)
            .foregroundColor(Theme.Colors.textPrimary)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        })
    }
    
    // MARK: - Saberes (pedido 150, parte 2 — igual ao Android SaberesInicio.kt / SaberesContinuar.kt)
    // Vem do patch saberes-ios/patches/inicio.patch.

    // (calculadas: tipo genérico não aceita propriedade estática guardada)
    private static var tinta: Color { Color(red: 10/255, green: 42/255, blue: 56/255) }    // #0A2A38
    private static var ambar: Color { Color(red: 246/255, green: 174/255, blue: 47/255) }  // #F6AE2F

    private func saberesAbrir(_ primary: PrimaryCourse, ultimaAula: String?) {
        viewModel.router.showCourseScreens(
            courseID: primary.courseID,
            hasAccess: primary.hasAccess,
            courseStart: primary.courseStart,
            courseEnd: primary.courseEnd,
            enrollmentStart: nil,
            enrollmentEnd: nil,
            title: primary.name,
            courseRawImage: primary.courseBanner,
            showDates: false,
            lastVisitedBlockID: ultimaAula
        )
    }

    /// Saudação pelo horário com o primeiro nome e três contadores. O app iOS não recebe os certificados na lista de
    /// cursos (o Android recebe), então o terceiro contador é “em andamento”.
    private func saberesCabecalho(_ enrollments: PrimaryEnrollment) -> some View {
        let nome = (viewModel.storage.user?.name ?? "").split(separator: " ").first.map(String.init) ?? ""
        let hora = Calendar.current.component(.hour, from: Date())
        let saudacao = hora < 5 ? "Boa noite" : hora < 12 ? "Bom dia" : hora < 18 ? "Boa tarde" : "Boa noite"
        var progresso = enrollments.courses.map { ($0.progressEarned, $0.progressPossible) }
        if let p = enrollments.primaryCourse { progresso.append((p.progressEarned, p.progressPossible)) }
        let total = enrollments.count + (enrollments.primaryCourse == nil ? 0 : 1)
        let concluidos = progresso.filter { $0.1 > 0 && $0.0 >= $0.1 }.count
        let andamento = progresso.filter { $0.0 > 0 && $0.0 < $0.1 }.count
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(nome.isEmpty ? "\(saudacao)!" : "\(saudacao),")
                    .font(.custom("Saberes-Regular", size: 14))
                    .foregroundColor(Theme.Colors.textSecondary)
                if !nome.isEmpty {
                    Text(nome)
                        .font(.custom("Saberes-Bold", size: 26))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .accessibilityElement(children: .combine)
            HStack(spacing: 10) {
                saberesContador(total, total == 1 ? "curso" : "cursos",
                                Color(red: 62/255, green: 155/255, blue: 91/255))
                saberesContador(concluidos, concluidos == 1 ? "concluído" : "concluídos", Self.ambar)
                saberesContador(andamento, "em andamento", Color(red: 1/255, green: 99/255, blue: 135/255))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private func saberesContador(_ n: Int, _ rotulo: String, _ cor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 4).fill(cor).frame(width: 24, height: 4).padding(.top, 4)
            Text("\(n)")
                .font(.custom("Saberes-Bold", size: 20))
                .foregroundColor(Theme.Colors.textPrimary)
            Text(rotulo)
                .font(.custom("Saberes-Medium", size: 12))
                .foregroundColor(Theme.Colors.textSecondary)
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.Colors.cardViewBackground))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(n) \(rotulo)")
    }

    /// Cartão escuro “Continue de onde parou”: capa, nome, barra de progresso e botão âmbar.
    private func saberesContinuar(_ primary: PrimaryCourse) -> some View {
        let pct = primary.progressPossible > 0
            ? min(100, max(0, 100 * primary.progressEarned / primary.progressPossible)) : 0
        let comecou = primary.lastVisitedBlockID != nil
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                KFImage(URL(string: primary.courseBanner))
                    .placeholder { Self.tinta }
                    .resizable()
                    .scaledToFill()
                    .frame(height: 148)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .accessibilityHidden(true)
                Text(comecou ? "Continue de onde parou" : "Comece por aqui")
                    .font(.custom("Saberes-Medium", size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(Self.tinta.opacity(0.82)))
                    .padding(14)
                // curso de demonstração (o servidor marca o org: app_movel_api.py, pedido 182)
                if primary.org.hasPrefix("Demonstração") {
                    Text("DEMONSTRAÇÃO")
                        .font(.custom("Saberes-Bold", size: 11))
                        .foregroundColor(Self.tinta)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(Self.ambar))
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                Text(primary.name)
                    .font(.custom("Saberes-SemiBold", size: 18))
                    .foregroundColor(.white)
                    .lineLimit(3)
                HStack(spacing: 12) {
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(red: 28/255, green: 69/255, blue: 86/255))
                            Capsule().fill(Self.ambar).frame(width: g.size.width * CGFloat(pct) / 100)
                        }
                    }
                    .frame(height: 8)
                    Text("\(pct)%")
                        .font(.custom("Saberes-Medium", size: 13))
                        .foregroundColor(.white)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(pct)% concluído")
                Button {
                    saberesAbrir(primary, ultimaAula: primary.lastVisitedBlockID)
                } label: {
                    Text(comecou ? "Continuar aula  ▶" : "Começar o curso  ▶")
                        .font(.custom("Saberes-Bold", size: 16))
                        .foregroundColor(Self.tinta)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Self.ambar))
                }
                .accessibilityIdentifier("saberes_continuar_button")
            }
            .padding(16)
        }
        .background(Self.tinta)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .onTapGesture { saberesAbrir(primary, ultimaAula: nil) }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func learnTitleAndSearch(proxy: GeometryProxy) -> some View {
        let showDropdown = viewModel.config.program.enabled && viewModel.config.program.isWebViewConfigured
       return ZStack(alignment: .top) {
            Theme.Colors.background
                .frame(height: showDropdown ? 70 : 50)
            ZStack(alignment: .topTrailing) {
                VStack {
                    HStack(alignment: .center) {
                        Text(DashboardLocalization.Learn.title)
                            .font(Theme.Fonts.displaySmall)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .accessibilityIdentifier("courses_header_text")
                        Spacer()
                    }
                    if showDropdown {
                        HStack(alignment: .center) {
                            DropDownMenu(selectedOption: $selectedMenu, analytics: viewModel.analytics)
                            Spacer()
                        }
                    }
                }
                    .frameLimit(width: proxy.size.width)
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.router.showSettings()
                    }, label: {
                        CoreAssets.settings.swiftUIImage.renderingMode(.template)
                            .foregroundColor(Theme.Colors.accentColor)
                    })
                }
                .padding(.top, 8)
                .offset(x: idiom == .pad ? 1 : 5, y: idiom == .pad ? 4 : -5)
            }
            
            .listRowBackground(Color.clear)
            .padding(.horizontal, 20)
            .accessibilityElement(children: .contain)
        }
    }
}

#if DEBUG
struct PrimaryCourseDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = PrimaryCourseDashboardViewModel(
            interactor: DashboardInteractor.mock,
            connectivity: Connectivity(config: ConfigMock()),
            analytics: DashboardAnalyticsPreviewMock(),
            config: ConfigMock(),
            storage: CoreStorageMock(),
            router: DashboardRouterMock()
        )
        
        PrimaryCourseDashboardView(
            viewModel: vm,
            programView: EmptyView(),
            openDiscoveryPage: {
            }
        )
        .preferredColorScheme(.light)
        .previewDisplayName("DashboardView Light")
        
        PrimaryCourseDashboardView(
            viewModel: vm,
            programView: EmptyView(),
            openDiscoveryPage: {
            }
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("DashboardView Dark")
    }
}
#endif
