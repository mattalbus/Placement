//
//  PositioningTests.swift
//  PlacementTests
//
//  Created by Sam Pettersson on 2022-09-19.
//

import Foundation
import XCTest
@testable import Placement
import ViewInspector
import SwiftUI

enum PlacementLayouterType {
    case native
    case placement
}

final class PositioningTests: XCTestCase {
    func testThatPositioningIsCorrect() {
        
        struct Content: View, Inspectable {
            var hasPlaced: ((Self) -> Void)?
            var onContainerProxy: (_ type: PlacementLayouterType, _ proxy: GeometryProxy) -> Void
            var onChildProxy: (_ type: PlacementLayouterType, _ proxy: GeometryProxy) -> Void
            
            var body: some View {
                ZStack {
                    CenterLayout(
                        nativeImplementation: true
                    ) {
                        Text("Content").fixedSize().background(GeometryReader(content: { proxy in
                            let _ = onChildProxy(.native, proxy)
                            Color.clear
                        }))
                    }.background(GeometryReader(content: { proxy in
                        let _ = onContainerProxy(.native, proxy)
                        Color.clear
                    }))
                    
                    CenterLayout(
                        nativeImplementation: false
                    ) {
                        Text("Content").fixedSize().background(GeometryReader(content: { proxy in
                            Color.clear.onAppear {
                                let _ = onChildProxy(.placement, proxy)
                                hasPlaced?(self)
                            }
                        }))
                    }.background(GeometryReader(content: { proxy in
                        let _ = onContainerProxy(.placement, proxy)
                        Color.clear
                    }))
                }
            }
        }
        
        var containerProxies: [PlacementLayouterType: GeometryProxy] = [:]
        var childProxies: [PlacementLayouterType: GeometryProxy] = [:]
        
        var sut = Content { type, proxy in
            containerProxies[type] = proxy
        } onChildProxy: { type, proxy in
            childProxies[type] = proxy
        }
        
        let didAppearExp = sut.on(\.hasPlaced) { view in
            XCTAssertEqual(
                containerProxies[.native]!.frame(in: .local),
                containerProxies[.placement]!.frame(in: .local)
            )
            XCTAssertEqual(
                childProxies[.native]!.frame(in: .global),
                childProxies[.placement]!.frame(in: .global)
            )
        }
        
        ViewHosting.host(view: sut)
        
        wait(for: [didAppearExp], timeout: 0.1)
    }
}

