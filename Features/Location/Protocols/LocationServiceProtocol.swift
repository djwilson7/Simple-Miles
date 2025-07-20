//
//  LocationServiceProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/19/25.
//
import Foundation
import Combine
import CoreLocation

protocol LocationServiceProtocol: AnyObject {
    var locationPublisher: AnyPublisher<CLLocation, Never> { get }
    var headingPublisher: AnyPublisher<CLLocationDirection, Never> { get }
    func initialize()
    func stopTracking()
}
