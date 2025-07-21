////
////  ArrowHeadingStore.swift
////  SimpleMiles
////
////  Created by Invictus Maneo on 7/21/25.
////
//
//import Combine
//import CoreLocation
//
//final class ArrowHeadingStore: ObservableObject {
//    @Published private(set) var trueHeading: CLLocationDirection = 0
//
//    private var cancellable: AnyCancellable?
//
//    init(headingPublisher: AnyPublisher<CLLocationDirection, Never>) {
//        cancellable = headingPublisher
//            .receive(on: DispatchQueue.main)
//            .assign(to: \.trueHeading, on: self)
//    }
//}
