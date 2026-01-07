//
//  MyListItem.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/5.
//

import SwiftUI

struct MyListItem<Content: View>: View {
    @State private var hovered: Bool = false
    @State private var backgroundScale: CGFloat = 0.92
    private let buttons: [Button]
    private let content: (Bool) -> Content
    
    init(buttons: [Button] = [], _ content: @escaping (Bool) -> Content) {
        self.buttons = buttons
        self.content = content
    }
    
    init(buttons: [Button] = [], _ content: @escaping () -> Content) {
        self.init(buttons: buttons, { _ in content() })
    }
    
    var body: some View {
        HStack {
            content(hovered)
            Spacer(minLength: 0)
            if hovered {
                HStack {
                    ForEach(buttons, id: \.id) { button in
                        Image(button.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .contentShape(.rect)
                            .onTapGesture(perform: button.action)
                    }
                }
                .padding(.trailing, 8)
                .foregroundStyle(Color.color4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(4)
        .contentShape(Rectangle())
        .background {
            RoundedRectangle(cornerRadius: 4)
                .fill(hovered ? Color.color2.opacity(0.1) : .clear)
                .scaleEffect(backgroundScale)
        }
        .onHover { hovered in
            withAnimation(.spring(response: 0.2)) {
                self.hovered = hovered
                if hovered {
                    backgroundScale = 1
                } else {
                    backgroundScale = 0.92
                }
            }
        }
    }
    
    struct Button {
        let id: UUID = .init()
        let image: String
        let action: () -> Void
        
        init(_ image: String, _ action: @escaping () -> Void) {
            self.image = image
            self.action = action
        }
    }
}

#Preview {
    MyListItem {
        HStack {
            VStack {
                MyText("aaa")
                MyText("aaa")
            }
            Spacer()
        }
    }
    .frame(width: 400, height: 50)
    .padding()
    .background(.white)
}
