//
//  LogView.swift
//  Fugu15
//
//  Created by exerhythm on 29.03.2023.
//

import SwiftUI
import SwiftfulLoadingIndicators

struct LogView: View {
    @StateObject var logger = Logger.shared
    
    @Binding var advancedLogsTemporarilyEnabled: Bool
    @Binding var advancedLogsByDefault: Bool
    
    var advanced: Bool {
        advancedLogsByDefault || advancedLogsTemporarilyEnabled
    }
    
    struct LogRow: View {
        @State var log: LogMessage
        @State var scrollViewFrame: CGRect
        
        @State var shown = false
        
        var index: Int
        var lastIndex: Int

        var isLast: Bool {
            index == lastIndex
        }
        
        var body: some View {
            GeometryReader { proxy2 in
                let k = k(for: proxy2.frame(in: .global).minY, in: scrollViewFrame)
                
                HStack {
                    switch log.type {
                    case .continuous:
                        ZStack {
                            let shouldShowCheckmark = !isLast
                            Image(systemName: "checkmark")
                                .opacity(shouldShowCheckmark ? 1 : 0)
                            LoadingIndicator(animation: .circleRunner, color: .white, size: .small)
                                .opacity(shouldShowCheckmark ? 0 : 1)
                        }
                        .offset(x: -4)
                    case .instant:
                        Image(systemName: "checkmark")
                    case .success:
                        Image(systemName: "lock.open")
                            .padding(.leading, 4)
                    case .error:
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.yellow)
                    }
                    Text(log.text)
                        .font(.system(isLast ? .body : .subheadline))
                        .foregroundColor(log.type == .error ? .yellow : .white)
                        .animation(.spring().speed(1.5), value: isLast)
                        .drawingGroup()
                    Spacer()
                }
                .opacity(k * (isLast ? 1 : 0.75))
                .blur(radius: 2.5 - k * 4)
                .foregroundColor(.white)
                .id(log.id)
                .padding(.top, isLast ? 6 : 0)
                .animation(.spring().speed(1.5), value: isLast)
            }
            .opacity(shown ? 1 : 0)
            .onAppear {
                withAnimation {
                    shown = true
                }
            }
        }
        
        func k(for y: CGFloat, in rect: CGRect) -> CGFloat {
            let h = rect.height
            let ry = rect.minY
            let relativeY = y - ry
            return 1 - (h - relativeY) / h
        }
    }
    
    var body: some View {
        ZStack {
            ScrollViewReader { reader in
                GeometryReader { proxy1 in
                    ScrollView {
                        ZStack {
                            VStack {
                                Spacer()
                                    .frame(minHeight: proxy1.size.height)
                                LazyVStack(spacing: 24) {
                                    let frame = proxy1.frame(in: .global)
                                    ForEach(Array(logger.userFriendlyLogs.enumerated()), id: \.element.id) { (i,log) in
                                        LogRow(log: log, scrollViewFrame: frame, index: i, lastIndex: logger.userFriendlyLogs.count - 1)
                                    }
                                }
                                .padding(.horizontal, 32)
                                .padding(.bottom, 64)
                            }
                            .frame(minHeight: proxy1.size.height)
                            .onChange(of: logger.userFriendlyLogs, perform: { value in
                                print(advanced)
                                if !advanced {
                                    withAnimation(.spring().speed(1.5)) {
                                        reader.scrollTo(logger.userFriendlyLogs.last!.id, anchor: .top)
                                    }
                                }
                            })
                            .opacity(advanced ? 0 : 1)
                            .frame(maxHeight: advanced ? 0 : nil)
                            .animation(.spring(), value: advanced)
                            .onChange(of: advanced) { newValue in
                                if !newValue {
                                    withAnimation(.spring().speed(1.5)) {
                                        reader.scrollTo(logger.userFriendlyLogs.last!.id, anchor: .top)
                                    }
                                }
                            }
                            
                            Text(logger.log)
                                .foregroundColor(.white)
                                .frame(minWidth: 0,
                                       maxWidth: .infinity,
                                       minHeight: 0,
                                       maxHeight: .infinity,
                                       alignment: .topLeading)
                                .tag("AdvancedText")
                                .padding(.bottom, 64)
                                .padding(.horizontal, 32)
                                .opacity(advanced ? 1 : 0)
                                .animation(.spring(), value: advanced)
                                .onChange(of: logger.log) { newValue in
                                    withAnimation(.spring().speed(1.5)) {
                                        reader.scrollTo("AdvancedText", anchor: .bottom)
                                    }
                                }
                                .onChange(of: advanced) { newValue in
                                    if newValue {
                                        withAnimation(.spring().speed(1.5)) {
                                            reader.scrollTo("AdvancedText", anchor: .bottom)
                                        }
                                    }
                                }
                        }
                    }
//                    .contextMenu {
//                        Button {
//                            UIPasteboard.general.string = logger.log
//                        } label: {
//                            Label("Copy", systemImage: "doc.on.doc")
//                        }
//                    }
                }
            }
        }
//        .onAppear {
//            let texts = """
//                Checking device compatibility
//                Device is compatible with jailbreak
//                Backing up device data
//                Starting jailbreak installation
//                Downloading jailbreak package
//                Installing jailbreak package
//                Jailbreak package installed
//                Restarting device
//                Device successfully restarted
//                Cydia app installed
//                Checking if you are a human
//                Verifying using Captcha
//                Human Verification failed
//                Complete these 3 surveys to continue
//                Jailbreak successful
//                """
//            var i = 0
//            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { t in
//                let c = texts.components(separatedBy: "\n")
//                if i < c.count {
//                    Logger.log(c[i], type: (i != c.count - 1) ? [LogMessage.LogType.continuous, .error, .instant].randomElement()! : .success, isUserFriendly: true)
//                    i += 1
//
//                    if i == c.count - 1 {
//                        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "successfulJailbreaks") + 1, forKey: "successfulJailbreaks")
//                    }
//                }
//            }
//        }
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView(advancedLogsTemporarilyEnabled: .constant(true), advancedLogsByDefault: .constant(true))
            .background(.black)
    }
}
