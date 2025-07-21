//import Foundation
//import MapKit.MKAddressFilter
//import MapKit.MKAnnotation
//import MapKit.MKAnnotationView
//import MapKit.MKCircle
//import MapKit.MKCircleRenderer
//import MapKit.MKCircleView
//import MapKit.MKClusterAnnotation
//import MapKit.MKCompassButton
//import MapKit.MKDirections
//import MapKit.MKDirectionsRequest
//import MapKit.MKDirectionsResponse
//import MapKit.MKDirectionsTypes
//import MapKit.MKDistanceFormatter
//import MapKit.MKFoundation
//import MapKit.MKGeoJSONSerialization
//import MapKit.MKGeodesicPolyline
//import MapKit.MKGeometry
//import MapKit.MKGradientPolylineRenderer
//import MapKit.MKHybridMapConfiguration
//import MapKit.MKIconStyle
//import MapKit.MKImageryMapConfiguration
//import MapKit.MKLocalPointsOfInterestRequest
//import MapKit.MKLocalSearch
//import MapKit.MKLocalSearchCompleter
//import MapKit.MKLocalSearchRequest
//import MapKit.MKLocalSearchResponse
//import MapKit.MKLookAroundScene
//import MapKit.MKLookAroundSceneRequest
//import MapKit.MKLookAroundSnapshot
//import MapKit.MKLookAroundSnapshotOptions
//import MapKit.MKLookAroundSnapshotter
//import MapKit.MKLookAroundViewController
//import MapKit.MKMapCamera
//import MapKit.MKMapCameraBoundary
//import MapKit.MKMapCameraZoomRange
//import MapKit.MKMapConfiguration
//import MapKit.MKMapFeatureAnnotation
//import MapKit.MKMapItem
//import MapKit.MKMapItemAnnotation
//import MapKit.MKMapItemDetailViewController
//import MapKit.MKMapItemIdentifier
//import MapKit.MKMapItemRequest
//import MapKit.MKMapSnapshot
//import MapKit.MKMapSnapshotOptions
//import MapKit.MKMapSnapshotter
//import MapKit.MKMapView
//import MapKit.MKMarkerAnnotationView
//import MapKit.MKMultiPoint
//import MapKit.MKMultiPolygon
//import MapKit.MKMultiPolygonRenderer
//import MapKit.MKMultiPolyline
//import MapKit.MKMultiPolylineRenderer
//import MapKit.MKOverlay
//import MapKit.MKOverlayPathRenderer
//import MapKit.MKOverlayPathView
//import MapKit.MKOverlayRenderer
//import MapKit.MKOverlayView
//import MapKit.MKPinAnnotationView
//import MapKit.MKPitchControl
//import MapKit.MKPlacemark
//import MapKit.MKPointAnnotation
//import MapKit.MKPointOfInterestCategory
//import MapKit.MKPointOfInterestFilter
//import MapKit.MKPolygon
//import MapKit.MKPolygonRenderer
//import MapKit.MKPolygonView
//import MapKit.MKPolyline
//import MapKit.MKPolylineRenderer
//import MapKit.MKPolylineView
//import MapKit.MKReverseGeocoder
//import MapKit.MKScaleView
//import MapKit.MKSelectionAccessory
//import MapKit.MKShape
//import MapKit.MKStandardMapConfiguration
//import MapKit.MKTileOverlay
//import MapKit.MKTileOverlayRenderer
//import MapKit.MKTypes
//import MapKit.MKUserLocation
//import MapKit.MKUserLocationView
//import MapKit.MKUserTrackingBarButtonItem
//import MapKit.MKUserTrackingButton
//import MapKit.MKZoomControl
//import MapKit.NSUserActivity_MKMapItem
//import _Concurrency
//import _StringProcessing
//import _SwiftConcurrencyShims
//
//@available(iOS 18.0, visionOS 2.0, tvOS 18.0, macOS 15.0, *)
//@available(watchOS, unavailable)
//extension MKMapItem.Identifier : RawRepresentable, Codable {
//
//    /// The raw type that can be used to represent all values of the conforming
//    /// type.
//    ///
//    /// Every distinct value of the conforming type has a corresponding unique
//    /// value of the `RawValue` type, but there may be values of the `RawValue`
//    /// type that don't have a corresponding value of the conforming type.
//    public typealias RawValue = String
//}
//
//@available(iOS 14.0, tvOS 14.0, macOS 11.0, *)
//extension MKGradientPolylineRenderer {
//
//    public var locations: [CGFloat] { get }
//
//    public func setColors(_ colors: [UIColor], locations: [CGFloat])
//}
//
//@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
//@available(watchOS, unavailable)
//@available(tvOS, unavailable)
//extension MKSelectionAccessory.MapItemDetailPresentationStyle {
//
//    public static func automatic(presentationViewController: UIViewController? = nil) -> MKSelectionAccessory.MapItemDetailPresentationStyle
//
//    public static func callout(_ style: MKSelectionAccessory.MapItemDetailPresentationStyle.CalloutStyle = .automatic) -> MKSelectionAccessory.MapItemDetailPresentationStyle
//}
//
//@available(iOS 14.0, tvOS 14.0, macOS 11.0, *)
//extension MKMultiPoint {
//
//    public func locations(at indexes: IndexSet) -> [CGFloat]
//}
//
//@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
//extension MKLocalSearch.Request {
//
//    public typealias ResultType = MKLocalSearch.ResultType
//}
//
//
//// MARK: - SwiftUI Additions
//
//import CoreLocation
//import SwiftUI
//import UniformTypeIdentifiers
//import os
//
//// Available when SwiftUI is imported with MapKit
///// A customizable annotation that marks a map location.
/////
///// Create instances of ``Annotation`` in the closure you provide to the
///// `content` parameter in ``MapView`` initializers.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//@MainActor @preconcurrency public struct Annotation<Label, Content> : MapContent where Label : View, Content : View {
//
//    /// Creates an annotation that displays a view at a coordinate on the map.
//    ///
//    /// - Parameters:
//    ///   - coordinate: The coordinate to display the annotation at.
//    ///   - anchor: How to place the content around the provided coordinate.
//    ///   - accessoryAnchor: How to place accessories around the provided content.
//    ///   - content: The view to place on the map.
//    ///   - label: The label for the annotation, including a title, and optional
//    ///     subtitle.
//    @available(iOS 18.0, macOS 15.0, visionOS 2.0, watchOS 11.0, tvOS 18.0, *)
//    @MainActor @preconcurrency public init(coordinate: CLLocationCoordinate2D, anchor: UnitPoint = .center, accessoryAnchor: UnitPoint, @ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label)
//
//    /// Creates an annotation that displays a view at a coordinate on the map.
//    ///
//    /// Uses `.center` for `accessoryAnchor`. For greater control of selection accessory
//    /// positioning, please use an initializer with an `accessoryAnchor` parameter.
//    ///
//    /// - Parameters:
//    ///   - coordinate: The coordinate to display the annotation at.
//    ///   - anchor: How to place the content around the provided coordinate.
//    ///   - content: The view to place on the map.
//    ///   - label: The label for the annotation, including a title, and optional
//    ///     subtitle.
//    @MainActor @preconcurrency public init(coordinate: CLLocationCoordinate2D, anchor: UnitPoint = .center, @ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label)
//
//    /// Creates an annotation that displays a view at a coordinate on the map.
//    ///
//    /// - Parameters:
//    ///   - titleKey: The localized string key to lookup the title under.
//    ///   - coordinate: The coordinate to display the annotation at.
//    ///   - anchor: How to place the content around the provided coordinate.
//    ///   - accessoryAnchor: How to place accessories around the provided content.
//    ///   - content: The view to place on the map.
//    @available(iOS 18.0, macOS 15.0, visionOS 2.0, watchOS 11.0, tvOS 18.0, *)
//    @MainActor @preconcurrency public init(_ titleKey: LocalizedStringKey, coordinate: CLLocationCoordinate2D, anchor: UnitPoint = .center, accessoryAnchor: UnitPoint, @ViewBuilder content: () -> Content) where Label == Text
//
//    /// Creates an annotation that displays a view at a coordinate on the map.
//    ///
//    /// Uses `.center` for `accessoryAnchor`. For greater control of selection accessory
//    /// positioning, please use an initializer with an `accessoryAnchor` parameter.
//    ///
//    /// - Parameters:
//    ///   - titleKey: The localized string key to lookup the title under.
//    ///   - coordinate: The coordinate to display the annotation at.
//    ///   - anchor: How to place the content around the provided coordinate.
//    ///   - content: The view to place on the map.
//    @MainActor @preconcurrency public init(_ titleKey: LocalizedStringKey, coordinate: CLLocationCoordinate2D, anchor: UnitPoint = .center, @ViewBuilder content: () -> Content) where Label == Text
//
//    /// Creates an annotation that displays a view at a coordinate on the map.
//    ///
//    /// - Parameters:
//    ///   - title: The title of the annotation.
//    ///   - coordinate: The coordinate to display the annotation at.
//    ///   - anchor: How to place the content around the provided coordinate.
//    ///   - accessoryAnchor: How to place accessories around the provided content.
//    ///   - content: The view to place on the map.
//    @available(iOS 18.0, macOS 15.0, visionOS 2.0, watchOS 11.0, tvOS 18.0, *)
//    @MainActor @preconcurrency public init<S>(_ title: S, coordinate: CLLocationCoordinate2D, anchor: UnitPoint = .center, accessoryAnchor: UnitPoint, @ViewBuilder content: () -> Content) where Label == Text, S : StringProtocol
//
//    /// Creates an annotation that displays a view at a coordinate on the map.
//    ///
//    /// Uses `.center` for `accessoryAnchor`. For greater control of selection accessory
//    /// positioning, please use an initializer with an `accessoryAnchor` parameter.
//    ///
//    /// - Parameters:
//    ///   - title: The title of the annotation.
//    ///   - coordinate: The coordinate to display the annotation at.
//    ///   - anchor: How to place the content around the provided coordinate.
//    ///   - content: The view to place on the map.
//    @MainActor @preconcurrency public init<S>(_ title: S, coordinate: CLLocationCoordinate2D, anchor: UnitPoint = .center, @ViewBuilder content: () -> Content) where Label == Text, S : StringProtocol
//
//    /// Creates an annotation that displays a view at a coordinate on the map.
//    ///
//    /// The accessoryAnchor parameter is unused on tvOS and watchOS.
//    ///
//    /// - Parameters:
//    ///   - item: A map item that provides a label and coordinate for the annotation.
//    ///   - anchor: How to place the content around the provided coordinate.
//    ///   - accessoryAnchor: How to place accessories around the provided content.
//    ///   - content: The view to place on the map.
//    @available(iOS 18.0, macOS 15.0, visionOS 2.0, watchOS 11.0, tvOS 18.0, *)
//    @MainActor @preconcurrency public init(item: MKMapItem, anchor: UnitPoint = .center, accessoryAnchor: UnitPoint = .center, @ViewBuilder content: () -> Content) where Label == Text
//
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = Never
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension Annotation : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
///// A type-erased map content.
/////
///// An `AnyMapContent` allows changing the type of content used in a given map view.
//@available(iOS 17.5, macOS 14.5, watchOS 10.5, tvOS 17.5, visionOS 1.2, *)
//@MainActor @preconcurrency public struct AnyMapContent : MapContent {
//
//    /// Create an instance that type-erases `base`.
//    @MainActor @preconcurrency public init<Content>(_ base: Content) where Content : MapContent
//
//    @available(iOS 17.5, tvOS 17.5, watchOS 10.5, visionOS 1.2, macOS 14.5, *)
//    public typealias Body = Never
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.5, macOS 14.5, watchOS 10.5, tvOS 17.5, visionOS 1.2, *)
//extension AnyMapContent : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
///// You don't use this type directly. Instead MapKit creates this type on
///// your behalf.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//@MainActor @preconcurrency public struct DefaultUserAnnotationContent : View {
//
//    /// The content and behavior of the view.
//    ///
//    /// When you implement a custom view, you must implement a computed
//    /// `body` property to provide the content for your view. Return a view
//    /// that's composed of built-in views that SwiftUI provides, plus other
//    /// composite views that you've already defined:
//    ///
//    ///     struct MyView: View {
//    ///         var body: some View {
//    ///             Text("Hello, World!")
//    ///         }
//    ///     }
//    ///
//    /// For more information about composing views and a view hierarchy,
//    /// see <doc:Declaring-a-Custom-View>.
//    @MainActor @preconcurrency public var body: some View { get }
//
//    /// The type of view representing the body of this view.
//    ///
//    /// When you create a custom view, Swift infers this type from your
//    /// implementation of the required ``View/body-swift.property`` property.
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = some View
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension DefaultUserAnnotationContent : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public protocol DynamicMapContent : MapContent {
//
//    /// The type of the underlying collection of data.
//    associatedtype Data : Collection
//
//    /// The collection of underlying data.
//    var data: Self.Data { get }
//}
//
//// Available when SwiftUI is imported with MapKit
///// A piece of map content that doesn't contain any content.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//@MainActor @preconcurrency public struct EmptyMapContent : MapContent {
//
//    /// Creates an empty map content.
//    @MainActor @preconcurrency public init()
//
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = Never
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension EmptyMapContent : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, *)
//@available(tvOS, unavailable)
//@available(watchOS, unavailable)
//@MainActor @preconcurrency public struct LookAroundPreview : View {
//
//    @MainActor @preconcurrency public init(initialScene: MKLookAroundScene?, allowsNavigation: Bool = true, showsRoadLabels: Bool = true, pointsOfInterest: PointOfInterestCategories = .all, badgePosition: MKLookAroundBadgePosition = .topLeading)
//
//    @MainActor @preconcurrency public init(scene: Binding<MKLookAroundScene?>, allowsNavigation: Bool = true, showsRoadLabels: Bool = true, pointsOfInterest: PointOfInterestCategories = .all, badgePosition: MKLookAroundBadgePosition = .topLeading)
//
//    /// The content and behavior of the view.
//    ///
//    /// When you implement a custom view, you must implement a computed
//    /// `body` property to provide the content for your view. Return a view
//    /// that's composed of built-in views that SwiftUI provides, plus other
//    /// composite views that you've already defined:
//    ///
//    ///     struct MyView: View {
//    ///         var body: some View {
//    ///             Text("Hello, World!")
//    ///         }
//    ///     }
//    ///
//    /// For more information about composing views and a view hierarchy,
//    /// see <doc:Declaring-a-Custom-View>.
//    @MainActor @preconcurrency public var body: some View { get }
//
//    /// The type of view representing the body of this view.
//    ///
//    /// When you create a custom view, Swift infers this type from your
//    /// implementation of the required ``View/body-swift.property`` property.
//    @available(iOS 17.0, macOS 14.0, *)
//    @available(tvOS, unavailable)
//    @available(watchOS, unavailable)
//    public typealias Body = some View
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, *)
//@available(tvOS, unavailable)
//@available(watchOS, unavailable)
//extension LookAroundPreview : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
//@MainActor @preconcurrency public struct Map<Content> : View where Content : View {
//
//    /// Creates an instance showing a specific region and optionally configuring
//    /// available interactions, user location and tracking behavior as well as
//    /// annotations.
//    ///
//    /// - Parameters:
//    /// - mapRect: The map rect to display.
//    /// - interactions: The types of user interactions that should be enabled.
//    /// - showsUserLocation: Whether to display the user's location in this Map
//    ///   or not. Only takes effect if the user has authorized the app to access
//    ///   their location.
//    /// - userTrackingMode: How the map should respond to user location updates
//    /// - annotationItems: The collection of data backing the annotation views
//    /// - annotationContent: A closure producing the annotation content
//    @available(iOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @available(macOS, introduced: 11.0, deprecated: 14.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @available(tvOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @available(watchOS, introduced: 7.0, deprecated: 10.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @MainActor @preconcurrency public init<Items, Annotation>(mapRect: Binding<MKMapRect>, interactionModes: MapInteractionModes = .all, showsUserLocation: Bool = false, userTrackingMode: Binding<MapUserTrackingMode>? = nil, annotationItems: Items, annotationContent: @escaping (Items.Element) -> Annotation) where Content == _DefaultAnnotatedMapContent<Items>, Items : RandomAccessCollection, Annotation : MapAnnotationProtocol, Items.Element : Identifiable
//
//    /// Creates an instance showing a specific region and optionally configuring
//    /// available interactions, user location and tracking behavior as well as
//    /// annotations.
//    ///
//    /// - Parameters:
//    /// - coordinateRegion: The coordinate region to display.
//    /// - interactions: The types of user interactions that should be enabled.
//    /// - showsUserLocation: Whether to display the user's location in this Map
//    ///   or not. Only takes effect if the user has authorized the app to access
//    ///   their location.
//    /// - userTrackingMode: How the map should respond to user location updates
//    /// - annotationItems: The collection of data backing the annotation views.
//    /// - annotationContent: A closure producing the annotation content.
//    @available(iOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @available(macOS, introduced: 11.0, deprecated: 14.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @available(tvOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @available(watchOS, introduced: 7.0, deprecated: 10.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @MainActor @preconcurrency public init<Items, Annotation>(coordinateRegion: Binding<MKCoordinateRegion>, interactionModes: MapInteractionModes = .all, showsUserLocation: Bool = false, userTrackingMode: Binding<MapUserTrackingMode>? = nil, annotationItems: Items, annotationContent: @escaping (Items.Element) -> Annotation) where Content == _DefaultAnnotatedMapContent<Items>, Items : RandomAccessCollection, Annotation : MapAnnotationProtocol, Items.Element : Identifiable
//
//    /// Creates an instance showing a specific region and optionally configuring
//    /// available interactions, user location and tracking behavior.
//    ///
//    /// - Parameters:
//    /// - mapRect: The map rect to display.
//    /// - interactions: The types of user interactions that should be enabled.
//    /// - showsUserLocation: Whether to display the user's location in this Map
//    ///   or not. Only takes effect if the user has authorized the app to access
//    ///   their location.
//    /// - userTrackingMode: How the map should respond to user location updates
//    @available(iOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @available(macOS, introduced: 11.0, deprecated: 14.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @available(tvOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @available(watchOS, introduced: 7.0, deprecated: 10.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @MainActor @preconcurrency public init(mapRect: Binding<MKMapRect>, interactionModes: MapInteractionModes = .all, showsUserLocation: Bool = false, userTrackingMode: Binding<MapUserTrackingMode>? = nil) where Content == _DefaultMapContent
//
//    /// Creates an instance showing a specific region and optionally configuring
//    /// available interactions, user location and tracking behavior.
//    ///
//    /// - Parameters:
//    /// - coordinateRegion: The coordinate region to display.
//    /// - interactions: The types of user interactions that should be enabled.
//    /// - showsUserLocation: Whether to display the user's location in this Map
//    ///   or not. Only takes effect if the user has authorized the app to access
//    ///   their location.
//    /// - userTrackingMode: How the map should respond to user location updates
//    @available(iOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @available(macOS, introduced: 11.0, deprecated: 14.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @available(tvOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @available(watchOS, introduced: 7.0, deprecated: 10.0, message: "Use Map initializers that take a MapContentBuilder instead.")
//    @MainActor @preconcurrency public init(coordinateRegion: Binding<MKCoordinateRegion>, interactionModes: MapInteractionModes = .all, showsUserLocation: Bool = false, userTrackingMode: Binding<MapUserTrackingMode>? = nil) where Content == _DefaultMapContent
//
//    /// The content and behavior of the view.
//    ///
//    /// When you implement a custom view, you must implement a computed
//    /// `body` property to provide the content for your view. Return a view
//    /// that's composed of built-in views that SwiftUI provides, plus other
//    /// composite views that you've already defined:
//    ///
//    ///     struct MyView: View {
//    ///         var body: some View {
//    ///             Text("Hello, World!")
//    ///         }
//    ///     }
//    ///
//    /// For more information about composing views and a view hierarchy,
//    /// see <doc:Declaring-a-Custom-View>.
//    @MainActor @preconcurrency public var body: some View { get }
//
//    /// The type of view representing the body of this view.
//    ///
//    /// When you create a custom view, Swift infers this type from your
//    /// implementation of the required ``View/body-swift.property`` property.
//    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
//    public typealias Body = some View
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension Map {
//
//    /// Creates a map with no map content.
//    ///
//    /// - Parameters:
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - scope: The scope to associated with the map.
//    @MainActor @preconcurrency public init(bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, scope: Namespace.ID? = nil) where Content == MapContentView<Never, EmptyMapContent>
//
//    /// Creates a map from the contents specified in the map content builder.
//    ///
//    /// - Parameters:
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - scope: The scope to associate with the map.
//    ///   - content: The content of the map.
//    @MainActor @preconcurrency public init<C>(bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> C) where Content == MapContentView<Never, C>, C : MapContent
//
//    /// Creates a map with no map content.
//    ///
//    /// - Parameters:
//    ///   - initialPosition: The initial position of the map's camera.
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - scope: The scope to associate with the map.
//    @MainActor @preconcurrency public init(initialPosition: MapCameraPosition, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, scope: Namespace.ID? = nil) where Content == MapContentView<Never, EmptyMapContent>
//
//    /// Creates a map from the contents specified in the map content builder.
//    ///
//    /// - Parameters:
//    ///   - initialPosition: The initial position of the map's camera.
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - scope: The scope to associate with the map.
//    ///   - content: The content of the map.
//    @MainActor @preconcurrency public init<C>(initialPosition: MapCameraPosition, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> C) where Content == MapContentView<Never, C>, C : MapContent
//
//    /// Creates a map with no map content.
//    ///
//    /// - Parameters:
//    ///   - position: A binding specifying how to position the map camera.
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - scope: The scope to associate with the map.
//    @MainActor @preconcurrency public init(position: Binding<MapCameraPosition>, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, scope: Namespace.ID? = nil) where Content == MapContentView<Never, EmptyMapContent>
//
//    /// Creates a map from the contents specified in the map content builder.
//    ///
//    /// - Parameters:
//    ///   - position: A binding specifying how to position the map camera.
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - scope: The scope to associate with the map.
//    ///   - content: The content of the map.
//    @MainActor @preconcurrency public init<C>(position: Binding<MapCameraPosition>, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> C) where Content == MapContentView<Never, C>, C : MapContent
//
//    /// Creates a map with no map content.
//    ///
//    /// - Parameters:
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to the tag value of the selected map content.
//    ///   - scope: The scope to associate with the map.
//    @MainActor @preconcurrency public init<SelectedValue>(bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<SelectedValue?>, scope: Namespace.ID? = nil) where Content == MapContentView<SelectedValue, EmptyMapContent>, SelectedValue : Hashable
//
//    /// Creates a map from the contents specified in the map content builder.
//    ///
//    /// - Parameters:
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to the tag value of the selected map content.
//    ///   - scope: The scope to associate with the map.
//    ///   - content: The content of the map.
//    @MainActor @preconcurrency public init<SelectedValue, C>(bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<SelectedValue?>, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> C) where Content == MapContentView<SelectedValue, C>, SelectedValue : Hashable, C : MapContent
//
//    /// Creates a map from the contents specified in the map content builder.
//    ///
//    /// - Parameters:
//    ///   - initialPosition: The initial position of the map's camera.
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to the tag value of the selected map content.
//    ///   - scope: The scope to associate with the map.
//    ///   - content: The content of the map.
//    @MainActor @preconcurrency public init<SelectedValue, C>(initialPosition: MapCameraPosition, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<SelectedValue?>, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> C) where Content == MapContentView<SelectedValue, C>, SelectedValue : Hashable, C : MapContent
//
//    /// Creates a map from the contents specified in the map content builder.
//    ///
//    /// - Parameters:
//    ///   - position: A binding specifying how to position the map camera.
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to the tag value of the selected map content.
//    ///   - scope: The scope to associate with the map.
//    ///   - content: The content of the map.
//    @MainActor @preconcurrency public init<SelectedValue, C>(position: Binding<MapCameraPosition>, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<SelectedValue?>, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> C) where Content == MapContentView<SelectedValue, C>, SelectedValue : Hashable, C : MapContent
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, *)
//@available(macOS, unavailable)
//@available(tvOS, unavailable)
//@available(watchOS, unavailable)
//extension Map {
//
//    /// Creates a map with no map content.
//    ///
//    /// - Parameters:
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to the selected map feature.
//    ///   - scope: The scope to associate with the map.
//    @MainActor @preconcurrency public init(bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<MapFeature?>, scope: Namespace.ID? = nil) where Content == MapContentView<MapFeature, EmptyMapContent>
//
//    /// Creates a map from the contents specified in the map content builder.
//    ///
//    /// - Parameters:
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to the selected map feature.
//    ///   - scope: The scope to associate with the map.
//    ///   - content: The content of the map.
//    @MainActor @preconcurrency public init<C>(bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<MapFeature?>, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> C) where Content == MapContentView<MapFeature, C>, C : MapContent
//
//    /// Creates a map with no map content.
//    ///
//    /// - Parameters:
//    ///   - initialPosition: The initial position of the map's camera.
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to the selected map feature.
//    ///   - scope: The scope to associate with the map.
//    @MainActor @preconcurrency public init(initialPosition: MapCameraPosition, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<MapFeature?>, scope: Namespace.ID? = nil) where Content == MapContentView<MapFeature, EmptyMapContent>
//
//    /// Creates a map from the contents specified in the map content builder.
//    ///
//    /// - Parameters:
//    ///   - initialPosition: The initial position of the map's camera.
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to the selected map feature.
//    ///   - scope: The scope to associate with the map.
//    ///   - content: The content of the map.
//    @MainActor @preconcurrency public init<C>(initialPosition: MapCameraPosition, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<MapFeature?>, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> C) where Content == MapContentView<MapFeature, C>, C : MapContent
//
//    /// Creates a map with no map content.
//    ///
//    /// - Parameters:
//    ///   - position: A binding specifying how to position the map camera.
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to the tag value of the selected map content.
//    ///   - scope: The scope to associate with the map.
//    @MainActor @preconcurrency public init(position: Binding<MapCameraPosition>, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<MapFeature?>, scope: Namespace.ID? = nil) where Content == MapContentView<MapFeature, EmptyMapContent>
//
//    /// Creates a map from the contents specified in the map content builder.
//    ///
//    /// - Parameters:
//    ///   - position: A binding specifying how to position the map camera.
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to the selected map feature.
//    ///   - scope: The scope to associate with the map.
//    ///   - content: The content of the map.
//    @MainActor @preconcurrency public init<C>(position: Binding<MapCameraPosition>, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<MapFeature?>, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> C) where Content == MapContentView<MapFeature, C>, C : MapContent
//
//    /// Creates a map from the contents specified in the map content builder.
//    ///
//    /// - Parameters:
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to either the tag value of the selected map content, or the selected
//    ///     map feature.
//    ///   - scope: The scope to associate with the map.
//    ///   - content: The content of the map.
//    @MainActor @preconcurrency public init<SelectedValue, C>(bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<SelectedValue?>, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> C) where Content == MapSelectableContentView<SelectedValue, C>, SelectedValue : MapSelectable, C : MapContent
//
//    /// Creates a map from the contents specified in the map content builder.
//    ///
//    /// - Parameters:
//    ///   - initialPosition: The initial position of the map's camera.
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to either the tag value of the selected map content, or the selected
//    ///     map feature.
//    ///   - scope: The scope to associate with the map.
//    ///   - content: The content of the map.
//    @MainActor @preconcurrency public init<SelectedValue, C>(initialPosition: MapCameraPosition, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<SelectedValue?>, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> C) where Content == MapSelectableContentView<SelectedValue, C>, SelectedValue : MapSelectable, C : MapContent
//
//    /// Creates a map with no map content.
//    ///
//    /// - Parameters:
//    ///   - position: A binding specifying how to position the map camera.
//    ///   - bounds: The bounds to restrict the map's camera movement to.
//    ///   - interactionModes: The ways users are allowed to interact with the
//    ///     map.
//    ///   - selection: A binding to either the tag value of the selected map content, or the selected
//    ///     map feature.
//    ///   - scope: The scope to associate with the map.
//    @MainActor @preconcurrency public init<SelectedValue, C>(position: Binding<MapCameraPosition>, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<SelectedValue?>, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> C) where Content == MapSelectableContentView<SelectedValue, C>, SelectedValue : MapSelectable, C : MapContent
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
//extension Map : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS, introduced: 14.0, deprecated: 17.0, message: "Use Annotation along with Map initializers that take a MapContentBuilder instead.")
//@available(macOS, introduced: 11.0, deprecated: 14.0, message: "Use Annotation along with Map initializers that take a MapContentBuilder instead.")
//@available(tvOS, introduced: 14.0, deprecated: 17.0, message: "Use Annotation along with Map initializers that take a MapContentBuilder instead.")
//@available(watchOS, introduced: 7.0, deprecated: 10.0, message: "Use Annotation along with Map initializers that take a MapContentBuilder instead.")
//public struct MapAnnotation<Content> : MapAnnotationProtocol where Content : View {
//
//    public init(coordinate: CLLocationCoordinate2D, anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5), @ViewBuilder content: () -> Content)
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
//public protocol MapAnnotationProtocol {
//}
//
//// Available when SwiftUI is imported with MapKit
///// Defines a virtual viewpoint above the map surface.
/////
///// `MapCamera` allows you to specify the viewpoint of a `Map`, as well as
///// affect how MapKit presents the map to the user. You use a `MapCamera` to
///// specify the location of the camera on the map, the compass heading
///// indicating the camera’s viewing direction, the pitch of the camera relative
///// to the map perpendicular, and the camera’s distance from the target point.
///// These factors create a map view with a three-dimensional perspective.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct MapCamera : Equatable {
//
//    /// The map coordinate at the center of the map view.
//    public var centerCoordinate: CLLocationCoordinate2D
//
//    /// The distance from the center point of the map to the camera, in meters.
//    public var distance: Double
//
//    /// The heading of the camera (in degrees) relative to true north.
//    public var heading: Double
//
//    /// The viewing angle of the camera, in degrees.
//    public var pitch: Double
//
//    /// Returns a Boolean value indicating whether two values are equal.
//    ///
//    /// Equality is the inverse of inequality. For any values `a` and `b`,
//    /// `a == b` implies that `a != b` is `false`.
//    ///
//    /// - Parameters:
//    ///   - lhs: A value to compare.
//    ///   - rhs: Another value to compare.
//    public static func == (lhs: MapCamera, rhs: MapCamera) -> Bool
//
//    /// Creates a camera using the specified distance, pitch, and heading information.
//    ///
//    /// - Parameters:
//    ///   - centerCoordinate: The map coordinate at the center of the map view.
//    ///   - distance: The distance from the center point of the map to the
//    ///     camera, in meters.
//    ///   - heading: The heading of the camera (in degrees) relative to true
//    ///     north.
//    ///   - pitch: The viewing angle of the camera, in degrees.
//    public init(centerCoordinate: CLLocationCoordinate2D, distance: Double, heading: Double = 0, pitch: Double = 0)
//
//    /// Creates a `MapCamera` from the given MKMapCamera.
//    @available(watchOS, unavailable)
//    public init(_ camera: MKMapCamera)
//}
//
//// Available when SwiftUI is imported with MapKit
///// Defines an optional boundary of an area within which the map’s center needs to
///// remain, and an optional camera zoom range that limits the distances to which the
///// user can zoom.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct MapCameraBounds {
//
//    /// MapCameraBounds with the specified region boundary and zoom range.
//    ///
//    /// - Parameters:
//    ///   - centerCoordinateBounds: A boundary of an area within which the map’s
//    ///     center needs to remain.
//    ///   - minDistance: The minimum distance the user can zoom in on a map based
//    ///     on its center point, measured in meters.
//    ///   - maxDistance: The maximum distance the user can zoom out on a map based
//    ///     on its center point, measured in meters.
//    public init(centerCoordinateBounds: MKCoordinateRegion, minimumDistance: Double? = nil, maximumDistance: Double? = nil)
//
//    /// MapCameraBounds with the specified region boundary and zoom range.
//    ///
//    /// - Parameters:
//    ///   - centerCoordinateBounds: A boundary of an area within which the map’s
//    ///     center needs to remain.
//    ///   - minimumDistance: The minimum distance the user can zoom in on a map based
//    ///     on its center point, measured in meters.
//    ///   - maximumDistance: The maximum distance the user can zoom out on a map based
//    ///     on its center point, measured in meters.
//    public init(centerCoordinateBounds: MKMapRect, minimumDistance: Double? = nil, maximumDistance: Double? = nil)
//
//    /// MapCameraBounds with the specified zoom range.
//    ///
//    /// - Parameters:
//    ///   - minimumDistance: The minimum distance the user can zoom in on a map based
//    ///     on its center point, measured in meters.
//    ///   - maximumDistance: The maximum distance the user can zoom out on a map based
//    ///     on its center point, measured in meters.
//    public init(minimumDistance: Double? = nil, maximumDistance: Double? = nil)
//}
//
//// Available when SwiftUI is imported with MapKit
///// How to position the map's camera within the map.
/////
///// `MapCameraPosition` contains a number of semantic framings, such as
///// `.automatic` (which frames the content of the map), as well as the `camera`
///// case, which allows you to specify an explicit camera position.
/////
///// When passed as a binding to a map, the map will adjust its camera to frame
///// the requested content, or to exactly match the camera specified. If the `Map`
///// is interacted with by a user in a way that moves the map, the map will reset
///// the position to a value that specifies `positionedByUser`.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct MapCameraPosition : Equatable {
//
//    /// Create a position that frames the map's content.
//    public static var automatic: MapCameraPosition { get }
//
//    /// Creates a position using an explicit MapCamera.
//    public static func camera(_ camera: MapCamera) -> MapCameraPosition
//
//    /// Creates a position that frames the given coordinate region.
//    ///
//    /// - Parameter region: The coordinate region to frame.
//    public static func region(_ region: MKCoordinateRegion) -> MapCameraPosition
//
//    /// Creates a position that frames the given map rect.
//    ///
//    /// - Parameter rect: The map rect to frame.
//    public static func rect(_ rect: MKMapRect) -> MapCameraPosition
//
//    /// Creates a position that frames the given map item.
//    /// - Parameters:
//    ///   - item: The item to frame.
//    ///   - allowsAutomaticPitch: If the map's camera may use pitch in framing the
//    ///     item.
//    public static func item(_ item: MKMapItem, allowsAutomaticPitch: Bool = true) -> MapCameraPosition
//
//    /// Creates a position that frames the user's location.
//    ///
//    /// - Parameters:
//    ///   - followsHeading: If the camera should rotate to match the heading.
//    ///     of the user.
//    ///   - fallback: The position to use if the user's location hasn't yet been
//    ///     resolved.
//    public static func userLocation(followsHeading: Bool = false, fallback: MapCameraPosition) -> MapCameraPosition
//
//    /// The camera if the position represents an explicit camera, otherwise nil.
//    public var camera: MapCamera? { get }
//
//    /// The region the map is framing if the map is framing a region, otherwise
//    /// nil.
//    public var region: MKCoordinateRegion? { get }
//
//    /// The rect the map is framing if the map is framing a rect, otherwise nil.
//    public var rect: MKMapRect? { get }
//
//    /// The item the map is framing if the map is framing an item, otherwise
//    /// nil.
//    public var item: MKMapItem? { get }
//
//    /// Returns `true` if the user has positioned the camera.
//    public var positionedByUser: Bool { get }
//
//    /// Returns `true` if the map is following the user's location.
//    public var followsUserLocation: Bool { get }
//
//    /// Returns `true` if the map is following the user's heading.
//    public var followsUserHeading: Bool { get }
//
//    /// Returns a non-nil position if this camera position has a fallback position.
//    public var fallbackPosition: MapCameraPosition? { get }
//
//    /// Returns `true` if this camera position allows automatic pitch.
//    public var allowsAutomaticPitch: Bool { get }
//
//    /// Returns a Boolean value indicating whether two values are equal.
//    ///
//    /// Equality is the inverse of inequality. For any values `a` and `b`,
//    /// `a == b` implies that `a != b` is `false`.
//    ///
//    /// - Parameters:
//    ///   - lhs: A value to compare.
//    ///   - rhs: Another value to compare.
//    public static func == (a: MapCameraPosition, b: MapCameraPosition) -> Bool
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct MapCameraUpdateContext {
//
//    /// The current map camera.
//    public let camera: MapCamera
//
//    /// A map region approximating the view of the map's camera.
//    public let region: MKCoordinateRegion
//
//    /// A map rect approximating the view of the map's camera.
//    public let rect: MKMapRect
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct MapCameraUpdateFrequency {
//
//    /// When map interactions are complete.
//    public static var onEnd: MapCameraUpdateFrequency { get }
//
//    /// All camera updates, including while interaction is taking place.
//    public static var continuous: MapCameraUpdateFrequency { get }
//}
//
//// Available when SwiftUI is imported with MapKit
///// A circular overlay with a configurable radius that you center on a geographic coordinate.
/////
///// Create instances of ``Circle`` in the closure you provide to the
///// `content` parameter in ``MapView`` initializers.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct MapCircle {
//
//    /// Creates a circle.
//    ///
//    /// - Parameters:
//    ///   - center: The location of the center of the circle.
//    ///   - radius: The radius of the circle in meters.
//    public init(center coordinate: CLLocationCoordinate2D, radius: CLLocationDistance)
//
//    /// Creates the largest possible circle centered within the given map rect.
//    ///
//    /// - Parameter mapRect: The rect to center the circle within.
//    public init(mapRect: MKMapRect)
//
//    /// Creates a map circle from the given `MKCircle`.
//    ///
//    /// - Parameter circle: The `MKCircle` to convert.
//    @available(watchOS, unavailable)
//    public init(_ circle: MKCircle)
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapCircle : MapContent {
//
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = Never
//}
//
//// Available when SwiftUI is imported with MapKit
///// A view that reflects the current orientation of the associated `Map`.
///// Tapping the compass reorients so that due north is at the top of the
///// `Map` view.
/////
///// May be used in conjunction with `Map` as a stand alone view
/////
/////     struct CompassButtonTestView: View {
/////         @Namespace var mapScope
/////
/////         var body: some View {
/////         VStack {
/////                 Map(scope: mapScope)
/////                 MapCompass(scope: mapScope)
/////             }
/////             .mapScope(mapScope)
/////         }
/////     }
/////
///// MapCompass may also be used in conjunction with the `.mapControls()`
///// modifier
/////
/////     Map()
/////         .mapControls {
/////             MapCompass()
/////         }
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//@MainActor @preconcurrency public struct MapCompass : View {
//
//    /// Creates a map compass.
//    ///
//    /// - Parameters:
//    ///   - scope: The namespace passed to the associated Map and .mapScope(). For
//    ///            use outside of .mapControls()
//    @MainActor @preconcurrency public init(scope: Namespace.ID? = nil)
//
//    /// The content and behavior of the view.
//    ///
//    /// When you implement a custom view, you must implement a computed
//    /// `body` property to provide the content for your view. Return a view
//    /// that's composed of built-in views that SwiftUI provides, plus other
//    /// composite views that you've already defined:
//    ///
//    ///     struct MyView: View {
//    ///         var body: some View {
//    ///             Text("Hello, World!")
//    ///         }
//    ///     }
//    ///
//    /// For more information about composing views and a view hierarchy,
//    /// see <doc:Declaring-a-Custom-View>.
//    @MainActor @preconcurrency public var body: some View { get }
//
//    /// The type of view representing the body of this view.
//    ///
//    /// When you create a custom view, Swift infers this type from your
//    /// implementation of the required ``View/body-swift.property`` property.
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = some View
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapCompass : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//@MainActor @preconcurrency public protocol MapContent {
//
//    associatedtype Body : MapContent
//
//    @MapContentBuilder @MainActor @preconcurrency var body: Self.Body { get }
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapContent {
//
//    /// The tint shape style to apply to map content.
//    ///
//    /// The tint is always respected and should be used
//    /// as a way to provide additional meaning to map content.
//    ///
//    /// - Parameter tint: The tint to apply.
//    @MainActor @preconcurrency public func tint<S>(_ tint: S) -> some MapContent where S : ShapeStyle
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapContent {
//
//    /// Sets the visibility of titles for markers and annotations.
//    ///
//    /// With the default .automatic visibility, title is always visible.
//    @MainActor @preconcurrency public func annotationTitles(_ visibility: Visibility) -> some MapContent
//
//
//    /// Sets the visibility of subtitles for markers and annotations.
//    ///
//    /// With the default .automatic visibility, subtitle is visible only when
//    /// the annotation is selected.
//    @MainActor @preconcurrency public func annotationSubtitles(_ visibility: Visibility) -> some MapContent
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
//@available(watchOS, unavailable)
//@available(tvOS, unavailable)
//extension MapContent {
//
//    /// Specifies the selection accessory to display for the selected map item content
//    ///
//    /// Supported for `Marker(item:)` and `Annotation(item:`)
//    ///
//    /// - Parameters:
//    ///   - style: The map item detail selection accessory style. If `nil`, no
//    ///     selection accessory will be displayed.
//    @MainActor @preconcurrency public func mapItemDetailSelectionAccessory(_ style: MapItemDetailSelectionAccessoryStyle? = .automatic) -> some MapContent
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapContent {
//
//    /// Sets the unique tag value of this piece of map content.
//    ///
//    /// Use this modifier to differentiate between selectable content in the map. When the map's
//    /// selection binding has the same value as the tag applied to a piece of map content, that content is
//    /// considered selected.
//    ///
//    /// A ``ForEach`` automatically applies a default tag to each enumerated
//    /// view using the `id` parameter of the corresponding element. If
//    /// the element's `id` parameter and the the map's selection input have the same type, you can omit
//    /// the explicit tag modifier.
//    ///
//    /// - Parameter tag: A <doc://com.apple.documentation/documentation/Swift/Hashable>
//    ///   value to use as the map content's tag.
//    ///
//    /// - Returns: Map content with the specified tag set.
//    @MainActor @preconcurrency public func tag<V>(_ tag: V) -> some MapContent where V : Hashable
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapContent {
//
//    /// Applies the given shape style to drawn map overlays.
//    ///
//    /// - Parameters:
//    ///   - content: The shape style to apply.
//    ///   - lineWidth: The line width to draw the stroke with.
//    @MainActor @preconcurrency public func stroke(_ content: some ShapeStyle, lineWidth: CGFloat = 1) -> some MapContent
//
//
//    /// Sets the line width used for drawing map overlays.
//    ///
//    /// - Parameters:
//    ///   - lineWidth: The line width to draw the stroke with.
//    @MainActor @preconcurrency public func stroke(lineWidth: CGFloat = 1) -> some MapContent
//
//
//    /// Applies the given shape style to drawn map overlays.
//    ///
//    /// - Parameters:
//    ///   - content: The shape style to apply.
//    ///   - lineWidth: The line width to draw the stroke with.
//    @MainActor @preconcurrency public func stroke(_ content: some ShapeStyle, style: StrokeStyle) -> some MapContent
//
//
//    /// Applies the given stroke style to drawn map overlays.
//    ///
//    /// - Parameters:
//    ///   - style: The stroke style to apply.
//    @MainActor @preconcurrency public func strokeStyle(style: StrokeStyle) -> some MapContent
//
//
//    /// Specifies the shape style used to fill content in drawing map overlays.
//    ///
//    /// - Parameters:
//    ///   - content: The shape style to apply.
//    @MainActor @preconcurrency public func foregroundStyle(_ content: some ShapeStyle) -> some MapContent
//
//
//    /// Specifies the position of overlays relative to other map content.
//    @MainActor @preconcurrency public func mapOverlayLevel(level: MKOverlayLevel) -> some MapContent
//
//}
//
//// Available when SwiftUI is imported with MapKit
///// A result builder that creates map content content from closures.
/////
///// The `buildBlock` methods in this type create ``MapContent``
///// instances based on the number and types of sources provided as parameters.
/////
///// Don't use this type directly; instead, SwiftUI annotates the `content`
///// parameter of the various ``MapView`` initializers with the
///// `@MapContentBuilder` annotation, implicitly calling this builder for you.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//@resultBuilder public struct MapContentBuilder {
//
//    /// Builds an expression within the builder.
//    public static func buildExpression<Content>(_ content: Content) -> Content where Content : MapContent
//
//    /// Creates an empty map content containing no statements.
//    public static func buildBlock() -> EmptyMapContent
//
//    /// Creates a single content result.
//    public static func buildBlock<C>(_ content: C) -> C where C : MapContent
//
//    /// Provides support for “if” statements in multi-statement closures,
//    /// producing an optional view that is visible only when the condition
//    /// evaluates to `true`.
//    public static func buildIf<Content>(_ content: Content?) -> Content? where Content : MapContent
//
//    /// Provides support for "if" statements in multi-statement closures,
//    /// producing conditional content for the "then" branch.
//    public static func buildEither<TrueContent, FalseContent>(first: TrueContent) -> _ConditionalMapContent<TrueContent, FalseContent> where TrueContent : MapContent, FalseContent : MapContent
//
//    /// Provides support for "if-else" statements in multi-statement closures,
//    /// producing conditional content for the "else" branch.
//    public static func buildEither<TrueContent, FalseContent>(second: FalseContent) -> _ConditionalMapContent<TrueContent, FalseContent> where TrueContent : MapContent, FalseContent : MapContent
//
//    /// Provides support for "if" statements with `#available()` clauses in
//    /// multi-statement closures, producing conditional content for the "then"
//    /// branch, i.e. the conditionally-available branch.
//    @available(iOS 17.5, macOS 14.5, watchOS 10.5, tvOS 17.5, visionOS 1.2, *)
//    public static func buildLimitedAvailability(_ content: any MapContent) -> some MapContent
//
//
//    public static func buildBlock<each Content>(_ content: repeat each Content) -> TupleMapContent<(repeat each Content)> where repeat each Content : MapContent
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//@MainActor @preconcurrency public struct MapContentView<SelectionValue, Content> : View where SelectionValue : Hashable, Content : MapContent {
//
//    /// The content and behavior of the view.
//    ///
//    /// When you implement a custom view, you must implement a computed
//    /// `body` property to provide the content for your view. Return a view
//    /// that's composed of built-in views that SwiftUI provides, plus other
//    /// composite views that you've already defined:
//    ///
//    ///     struct MyView: View {
//    ///         var body: some View {
//    ///             Text("Hello, World!")
//    ///         }
//    ///     }
//    ///
//    /// For more information about composing views and a view hierarchy,
//    /// see <doc:Declaring-a-Custom-View>.
//    @MainActor @preconcurrency public var body: some View { get }
//
//    /// The type of view representing the body of this view.
//    ///
//    /// When you create a custom view, Swift infers this type from your
//    /// implementation of the required ``View/body-swift.property`` property.
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = some View
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapContentView : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
///// Represents a tappable map feature.
/////
///// Tappable map features can include single points of interest, such as hotels, restaurants, etc., a territory,
///// or a physcal map feature.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct MapFeature {
//
//    /// The kind of feature represented by a map feature.
//    public struct FeatureKind {
//
//        /// A point of interest.
//        public static var pointOfInterest: MapFeature.FeatureKind { get }
//
//        /// A territory.
//        public static var territory: MapFeature.FeatureKind { get }
//
//        /// A physical map feature.
//        public static var physicalFeature: MapFeature.FeatureKind { get }
//    }
//
//    /// The coordinate of the map feature.
//    public var coordinate: CLLocationCoordinate2D { get }
//
//    /// The title of the map feature if it has one, otherwise nil.
//    public var title: String? { get }
//
//    /// The kind of feature represented by the map feature.
//    public var kind: MapFeature.FeatureKind { get }
//
//    /// The background color associated with the map feature if it has one, otherwise nil.
//    public var backgroundColor: Color? { get }
//
//    /// The image associated with the map feature if it has one, otherwise nil.
//    public var image: Image? { get }
//
//    /// The point of interest category of the map feature if it has one, otherwise nil.
//    public var pointOfInterestCategory: MKPointOfInterestCategory? { get }
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, *)
//@available(macOS, unavailable)
//@available(tvOS, unavailable)
//@available(watchOS, unavailable)
//extension MapFeature : Equatable {
//
//    /// Returns a Boolean value indicating whether two values are equal.
//    ///
//    /// Equality is the inverse of inequality. For any values `a` and `b`,
//    /// `a == b` implies that `a != b` is `false`.
//    ///
//    /// - Parameters:
//    ///   - lhs: A value to compare.
//    ///   - rhs: Another value to compare.
//    public static func == (lhs: MapFeature, rhs: MapFeature) -> Bool
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, *)
//@available(macOS, unavailable)
//@available(tvOS, unavailable)
//@available(watchOS, unavailable)
//extension MapFeature : Hashable {
//
//    /// Hashes the essential components of this value by feeding them into the
//    /// given hasher.
//    ///
//    /// Implement this method to conform to the `Hashable` protocol. The
//    /// components used for hashing must be the same as the components compared
//    /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
//    /// with each of these components.
//    ///
//    /// - Important: In your implementation of `hash(into:)`,
//    ///   don't call `finalize()` on the `hasher` instance provided,
//    ///   or replace it with a different instance.
//    ///   Doing so may become a compile-time error in the future.
//    ///
//    /// - Parameter hasher: The hasher to use when combining the components
//    ///   of this instance.
//    public func hash(into hasher: inout Hasher)
//
//    /// The hash value.
//    ///
//    /// Hash values are not guaranteed to be equal across different executions of
//    /// your program. Do not save hash values to use during a future execution.
//    ///
//    /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
//    ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
//    ///   The compiler provides an implementation for `hashValue` for you.
//    public var hashValue: Int { get }
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapFeature.FeatureKind : Equatable {
//
//    /// Returns a Boolean value indicating whether two values are equal.
//    ///
//    /// Equality is the inverse of inequality. For any values `a` and `b`,
//    /// `a == b` implies that `a != b` is `false`.
//    ///
//    /// - Parameters:
//    ///   - lhs: A value to compare.
//    ///   - rhs: Another value to compare.
//    public static func == (lhs: MapFeature.FeatureKind, rhs: MapFeature.FeatureKind) -> Bool
//}
//
//// Available when SwiftUI is imported with MapKit
///// The ways a user can interact with a map.
//@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
//public struct MapInteractionModes : OptionSet {
//
//    /// The corresponding value of the raw type.
//    ///
//    /// A new instance initialized with `rawValue` will be equivalent to this
//    /// instance. For example:
//    ///
//    ///     enum PaperSize: String {
//    ///         case A4, A5, Letter, Legal
//    ///     }
//    ///
//    ///     let selectedSize = PaperSize.Letter
//    ///     print(selectedSize.rawValue)
//    ///     // Prints "Letter"
//    ///
//    ///     print(selectedSize == PaperSize(rawValue: selectedSize.rawValue)!)
//    ///     // Prints "true"
//    public let rawValue: Int
//
//    /// Creates a new option set from the given raw value.
//    ///
//    /// This initializer always succeeds, even if the value passed as `rawValue`
//    /// exceeds the static properties declared as part of the option set. This
//    /// example creates an instance of `ShippingOptions` with a raw value beyond
//    /// the highest element, with a bit mask that effectively contains all the
//    /// declared static members.
//    ///
//    ///     let extraOptions = ShippingOptions(rawValue: 255)
//    ///     print(extraOptions.isStrictSuperset(of: .all))
//    ///     // Prints "true"
//    ///
//    /// - Parameter rawValue: The raw value of the option set to create. Each bit
//    ///   of `rawValue` potentially represents an element of the option set,
//    ///   though raw values may include bits that are not defined as distinct
//    ///   values of the `OptionSet` type.
//    public init(rawValue: Int)
//
//    public static let pan: MapInteractionModes
//
//    public static let zoom: MapInteractionModes
//
//    public static let all: MapInteractionModes
//
//    /// The type of the elements of an array literal.
//    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
//    public typealias ArrayLiteralElement = MapInteractionModes
//
//    /// The element type of the option set.
//    ///
//    /// To inherit all the default implementations from the `OptionSet` protocol,
//    /// the `Element` type must be `Self`, the default.
//    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
//    public typealias Element = MapInteractionModes
//
//    /// The raw type that can be used to represent all values of the conforming
//    /// type.
//    ///
//    /// Every distinct value of the conforming type has a corresponding unique
//    /// value of the `RawValue` type, but there may be values of the `RawValue`
//    /// type that don't have a corresponding value of the conforming type.
//    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
//    public typealias RawValue = Int
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapInteractionModes {
//
//    public static let rotate: MapInteractionModes
//
//    public static let pitch: MapInteractionModes
//}
//
//// Available when SwiftUI is imported with MapKit
///// The map item detail selection accessory style
//@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
//@available(watchOS, unavailable)
//@available(tvOS, unavailable)
//public struct MapItemDetailSelectionAccessoryStyle {
//
//    /// An appropriate style will be chosen automatically
//    public static var automatic: MapItemDetailSelectionAccessoryStyle { get }
//
//    /// The style to use for callout content
//    public struct CalloutStyle {
//
//        /// An appropriate style will be chosen based on available space
//        public static var automatic: MapItemDetailSelectionAccessoryStyle.CalloutStyle { get }
//
//        /// A rich, detailed view
//        public static var full: MapItemDetailSelectionAccessoryStyle.CalloutStyle { get }
//
//        /// A compact, space-saving presentation
//        public static var compact: MapItemDetailSelectionAccessoryStyle.CalloutStyle { get }
//    }
//
//    /// Show the accessory as an annotation callout on the map
//    ///
//    /// Uses `automatic` callout style
//    public static var callout: MapItemDetailSelectionAccessoryStyle { get }
//
//    /// Show the accessory as an annotation callout on the map
//    ///
//    /// - Parameters:
//    ///   - style: the `CalloutStyle` to use
//    public static func callout(_ style: MapItemDetailSelectionAccessoryStyle.CalloutStyle = .automatic) -> MapItemDetailSelectionAccessoryStyle
//
//    /// Show map item detail by presenting a sheet
//    public static var sheet: MapItemDetailSelectionAccessoryStyle { get }
//
//    /// An "Open in Apple Maps" link below the content's label
//    public static var caption: MapItemDetailSelectionAccessoryStyle { get }
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS, introduced: 14.0, deprecated: 17.0, message: "Use Marker along with Map initializers that take a MapContentBuilder instead.")
//@available(macOS, introduced: 11.0, deprecated: 14.0, message: "Use Marker along with Map initializers that take a MapContentBuilder instead.")
//@available(tvOS, introduced: 14.0, deprecated: 17.0, message: "Use Marker along with Map initializers that take a MapContentBuilder instead.")
//@available(watchOS, introduced: 7.0, deprecated: 10.0, message: "Use Marker along with Map initializers that take a MapContentBuilder instead.")
//public struct MapMarker : MapAnnotationProtocol {
//
//    public init(coordinate: CLLocationCoordinate2D, tint: Color? = nil)
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS, introduced: 14.0, deprecated: 16.0, message: "Use Marker")
//@available(tvOS, introduced: 14.0, deprecated: 16.0, message: "Use Marker")
//@available(macOS, introduced: 11.0, deprecated: 13.0, message: "Use Marker")
//@available(watchOS, introduced: 7.0, deprecated: 9.0, message: "Use Marker")
//public struct MapPin : MapAnnotationProtocol {
//
//    public init(coordinate: CLLocationCoordinate2D, tint: Color? = nil)
//}
//
//// Available when SwiftUI is imported with MapKit
///// A button that will set the asosciated pitch of the associated `Map` to a
///// pleasing angle if flat, or return to flat if pitched.
/////
///// May be used in conjunction with `Map` as a stand alone view
/////
/////     struct PitchButtonTestView: View {
/////         @Namespace var mapScope
/////
/////         var body: some View {
/////             VStack {
/////                 Map(scope: mapScope)
/////                 MapPitchToggle(scope: mapScope)
/////             }
/////             .mapScope(mapScope)
/////         }
/////     }
/////
///// MapPitchToggle may also be used in conjunction with the `.mapControls()` modifier
/////
/////     Map()
/////         .mapControls {
/////             MapPitchToggle()
/////         }
//@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
//@available(watchOS, unavailable)
//@MainActor @preconcurrency public struct MapPitchToggle : View {
//
//    /// Creates a map pitch button.
//    ///
//    /// - Parameters:
//    ///   - scope: The namespace passed to the associated Map and .mapScope(). For
//    ///            use outside of .mapControls()
//    @MainActor @preconcurrency public init(scope: Namespace.ID? = nil)
//
//    /// The content and behavior of the view.
//    ///
//    /// When you implement a custom view, you must implement a computed
//    /// `body` property to provide the content for your view. Return a view
//    /// that's composed of built-in views that SwiftUI provides, plus other
//    /// composite views that you've already defined:
//    ///
//    ///     struct MyView: View {
//    ///         var body: some View {
//    ///             Text("Hello, World!")
//    ///         }
//    ///     }
//    ///
//    /// For more information about composing views and a view hierarchy,
//    /// see <doc:Declaring-a-Custom-View>.
//    @MainActor @preconcurrency public var body: some View { get }
//
//    /// The type of view representing the body of this view.
//    ///
//    /// When you create a custom view, Swift infers this type from your
//    /// implementation of the required ``View/body-swift.property`` property.
//    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
//    @available(watchOS, unavailable)
//    public typealias Body = some View
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
//@available(watchOS, unavailable)
//extension MapPitchToggle : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
///// A closed polygon overlay.
/////
///// Create instances of ``Polygon`` in the closure you provide to the
///// `content` parameter in ``MapView`` initializers.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct MapPolygon {
//
//    /// Creates a polygon from a list of coordinates.
//    ///
//    /// - Parameter coordinates: The coordinates of the vertices of the polygon.
//    public init(coordinates: [CLLocationCoordinate2D])
//
//    /// Creates a polygon from a list of map points.
//    ///
//    /// - Parameter points: The points that make up the vertices of the polygon.
//    public init(points: [MKMapPoint])
//
//    /// Creates a map polygon from the given `MKPolygon`.
//    ///
//    /// - Parameter polygon: The `MKPolygon` to convert.
//    @available(watchOS, unavailable)
//    public init(_ polygon: MKPolygon)
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapPolygon : MapContent {
//
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = Never
//}
//
//// Available when SwiftUI is imported with MapKit
///// An open polygon overlay consisting of one or more connected line segments.
/////
///// Create instances of ``Polyline`` in the closure you provide to the
///// `content` parameter in ``MapView`` initializers.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct MapPolyline {
//
//    /// How lines are styled to represent the contour of the Earth.
//    public struct ContourStyle {
//
//        /// Straight line between points.
//        public static var straight: MapPolyline.ContourStyle { get }
//
//        /// Render line segments that follow the contours of the Earth to represent the
//        /// shortest path between the specified points.
//        public static var geodesic: MapPolyline.ContourStyle { get }
//    }
//
//    /// Creates a polyline that traces a path between the given coordinates.
//    ///
//    /// - Parameters:
//    ///   - coordinates: The coordinates to trace the path between.
//    ///   - contourStyle: The contour style to be used.
//    public init(coordinates: [CLLocationCoordinate2D], contourStyle: MapPolyline.ContourStyle = .straight)
//
//    /// Creates a polyline that traces a path between the given points.
//    ///
//    /// - Parameters:
//    ///   - points: The points to trace the path between.
//    ///   - contourStyle: The contour style to be used.
//    public init(points: [MKMapPoint], contourStyle: MapPolyline.ContourStyle = .straight)
//
//    /// Creates a map polyline from the given `MKPolyline`.
//    ///
//    /// - Parameter polyline: The `MKPolyline` to convert.
//    @available(watchOS, unavailable)
//    public init(_ polyline: MKPolyline)
//
//    /// Creates a polyline that traces the given route.
//    ///
//    /// - Parameter route: The route to trace.
//    @available(watchOS, unavailable)
//    public init(_ route: MKRoute)
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapPolyline : MapContent {
//
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = Never
//}
//
//// Available when SwiftUI is imported with MapKit
///// A proxy for accessing sizing information about a given map view.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct MapProxy {
//
//    /// Creates a camera in the context of the map  being read that frames the given coordinate region.
//    ///
//    /// - Parameter region: The coordinate region to frame.
//    public func camera(framing region: MKCoordinateRegion) -> MapCamera
//
//    /// Creates a camera in the context of the map being read that frames the given map rect.
//    ///
//    /// - Parameter rect: The map rect to frame.
//    public func camera(framing rect: MKMapRect) -> MapCamera
//
//    /// Creates a camera in the context of the map being read that frames the given map item.
//    ///
//    /// - Parameters:
//    ///   - item: The map item to frame.
//    ///   - allowPitch: If the camera can be pitched to frame the content.
//    public func camera(framing item: MKMapItem, allowPitch: Bool = true) -> MapCamera
//
//    /// Converts a point in the specified coordinate space to a map coordinate.
//    ///
//    /// If `point` is outside of the MapReader's associated Map, returns nil.
//    ///
//    ///     struct ContentView: View {
//    ///         @State private var markerCoordinate: CLLocationCoordinate2D = .office
//    ///
//    ///         var body: some View {
//    ///             MapReader { proxy in
//    ///                 Map {
//    ///                     Marker("Marker", coordinate: markerCoordinate)
//    ///                 }
//    ///                 .onTapGesture { location in
//    ///                     if let coordinate = proxy.convert(location, from: .local) {
//    ///                         markerCoordinate = coordinate
//    ///                     }
//    ///                 }
//    ///             }
//    ///         }
//    ///     }
//    ///
//    /// - Parameters:
//    ///   - point: The point you want to convert.
//    ///   - space: The reference coordinate space for the point parameter.
//    public func convert(_ point: CGPoint, from space: some CoordinateSpaceProtocol) -> CLLocationCoordinate2D?
//
//    /// Converts a map coordinate to a point in the specified coordinate space.
//    ///
//    /// If `coordinate` is not represented by a point in the MapReader's
//    /// associated Map, returns nil.
//    ///
//    /// - Parameters:
//    ///   - coordinate: The map coordinate that you want to find the
//    ///     corresponding point for.
//    ///   - space: The reference coordinate space for the returned point.
//    public func convert(_ coordinate: CLLocationCoordinate2D, to space: some CoordinateSpaceProtocol) -> CGPoint?
//}
//
//// Available when SwiftUI is imported with MapKit
///// A container view that defines its contents as a function of information about the first contained map.
/////
///// The map reader's content builder receives a ``MapProxy`` instance. This instance can used to get
///// the information needed to convert between a ``MapCamera``, and an ``MKMapRect`` or
///// ``MKMapRegion``.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//@MainActor @preconcurrency public struct MapReader<Content> : View where Content : View {
//
//    /// Creates an instance that allows view content to reference information about a contained map.
//    ///
//    /// - Parameter content: Generates the content of the map reader from information about the
//    /// first map contained within content.
//    @MainActor @preconcurrency public init(@ViewBuilder content: @escaping (MapProxy) -> Content)
//
//    /// The content and behavior of the view.
//    ///
//    /// When you implement a custom view, you must implement a computed
//    /// `body` property to provide the content for your view. Return a view
//    /// that's composed of built-in views that SwiftUI provides, plus other
//    /// composite views that you've already defined:
//    ///
//    ///     struct MyView: View {
//    ///         var body: some View {
//    ///             Text("Hello, World!")
//    ///         }
//    ///     }
//    ///
//    /// For more information about composing views and a view hierarchy,
//    /// see <doc:Declaring-a-Custom-View>.
//    @MainActor @preconcurrency public var body: some View { get }
//
//    /// The type of view representing the body of this view.
//    ///
//    /// When you create a custom view, Swift infers this type from your
//    /// implementation of the required ``View/body-swift.property`` property.
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = some View
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapReader : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
///// Displays a legend with distance information for the associated `Map`
/////
///// May be used in conjunction with `Map` as a stand alone view
/////
/////     struct ScaleTestView: View {
/////         @Namespace var mapScope
/////
/////         var body: some View {
/////             VStack {
/////                 Map(scope: mapScope)
/////                 MapCompass(scope: mapScope)
/////             }
/////             .mapScope(mapScope)
/////         }
/////     }
/////
///// The scale indicator grows and shrinks (visually, its frame is static) based
///// on the zoom level of the map. By default the leading edge remains anchored
///// and the trailing edge moves as the scale changes. If the scale is trailing
///// aligned, then it may be more visually appealing for the ScaleView to be
///// anchored to the trailing edge
/////
/////     ZStack(alignment: .trailing) {
/////         Map(mapScope)
/////         MapScaleView(anchorEdge: .trailing, scope: mapScope)
/////     }
/////     .mapScope(mapScope)
/////
///// MapScaleView may also be used in conjunction with the `.mapControls()` modifier
/////
/////     Map()
/////         .mapControls {
/////             MapScaleView()
/////         }
//@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
//@available(watchOS, unavailable)
//@MainActor @preconcurrency public struct MapScaleView : View {
//
//    /// Creates a map scale view.
//    ///
//    /// - Parameters:
//    ///   - anchorEdge: The fixed edge the scale grows and shrinks from. For use
//    ///                 outside of `.mapControls()`
//    ///   - scope: The namespace passed to the associated Map and `.mapScope()`. For
//    ///            use outside of `.mapControls()`
//    @MainActor @preconcurrency public init(anchorEdge: HorizontalEdge = .leading, scope: Namespace.ID? = nil)
//
//    /// The content and behavior of the view.
//    ///
//    /// When you implement a custom view, you must implement a computed
//    /// `body` property to provide the content for your view. Return a view
//    /// that's composed of built-in views that SwiftUI provides, plus other
//    /// composite views that you've already defined:
//    ///
//    ///     struct MyView: View {
//    ///         var body: some View {
//    ///             Text("Hello, World!")
//    ///         }
//    ///     }
//    ///
//    /// For more information about composing views and a view hierarchy,
//    /// see <doc:Declaring-a-Custom-View>.
//    @MainActor @preconcurrency public var body: some View { get }
//
//    /// The type of view representing the body of this view.
//    ///
//    /// When you create a custom view, Swift infers this type from your
//    /// implementation of the required ``View/body-swift.property`` property.
//    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
//    @available(watchOS, unavailable)
//    public typealias Body = some View
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
//@available(watchOS, unavailable)
//extension MapScaleView : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
///// Represents a selection of either a map feature, or map content with a given tag value.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public protocol MapSelectable : Hashable {
//
//    /// Selecting the given map feature.
//    var feature: MapFeature? { get }
//
//    init(_ feature: MapFeature?)
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, *)
//@available(macOS, unavailable)
//@available(tvOS, unavailable)
//@available(watchOS, unavailable)
//@MainActor @preconcurrency public struct MapSelectableContentView<SelectionValue, Content> : View where SelectionValue : MapSelectable, Content : MapContent {
//
//    /// The content and behavior of the view.
//    ///
//    /// When you implement a custom view, you must implement a computed
//    /// `body` property to provide the content for your view. Return a view
//    /// that's composed of built-in views that SwiftUI provides, plus other
//    /// composite views that you've already defined:
//    ///
//    ///     struct MyView: View {
//    ///         var body: some View {
//    ///             Text("Hello, World!")
//    ///         }
//    ///     }
//    ///
//    /// For more information about composing views and a view hierarchy,
//    /// see <doc:Declaring-a-Custom-View>.
//    @MainActor @preconcurrency public var body: some View { get }
//
//    /// The type of view representing the body of this view.
//    ///
//    /// When you create a custom view, Swift infers this type from your
//    /// implementation of the required ``View/body-swift.property`` property.
//    @available(iOS 17.0, *)
//    @available(tvOS, unavailable)
//    @available(watchOS, unavailable)
//    @available(macOS, unavailable)
//    public typealias Body = some View
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, *)
//@available(macOS, unavailable)
//@available(tvOS, unavailable)
//@available(watchOS, unavailable)
//extension MapSelectableContentView : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
///// Can represent a tag value or a `MapFeature`.
//@available(iOS 18.0, macOS 15.0, visionOS 2.0, watchOS 11.0, tvOS 18.0, *)
//public struct MapSelection<SelectionValue> : MapSelectable where SelectionValue : Hashable {
//
//    public var value: SelectionValue? { get }
//
//    /// Selecting the given map feature.
//    public var feature: MapFeature? { get }
//
//    public init(_ value: SelectionValue)
//
//    public init(_ feature: MapFeature?)
//
//    /// Returns a Boolean value indicating whether two values are equal.
//    ///
//    /// Equality is the inverse of inequality. For any values `a` and `b`,
//    /// `a == b` implies that `a != b` is `false`.
//    ///
//    /// - Parameters:
//    ///   - lhs: A value to compare.
//    ///   - rhs: Another value to compare.
//    public static func == (a: MapSelection<SelectionValue>, b: MapSelection<SelectionValue>) -> Bool
//
//    /// Hashes the essential components of this value by feeding them into the
//    /// given hasher.
//    ///
//    /// Implement this method to conform to the `Hashable` protocol. The
//    /// components used for hashing must be the same as the components compared
//    /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
//    /// with each of these components.
//    ///
//    /// - Important: In your implementation of `hash(into:)`,
//    ///   don't call `finalize()` on the `hasher` instance provided,
//    ///   or replace it with a different instance.
//    ///   Doing so may become a compile-time error in the future.
//    ///
//    /// - Parameter hasher: The hasher to use when combining the components
//    ///   of this instance.
//    public func hash(into hasher: inout Hasher)
//
//    /// The hash value.
//    ///
//    /// Hash values are not guaranteed to be equal across different executions of
//    /// your program. Do not save hash values to use during a future execution.
//    ///
//    /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
//    ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
//    ///   The compiler provides an implementation for `hashValue` for you.
//    public var hashValue: Int { get }
//}
//
//// Available when SwiftUI is imported with MapKit
///// A Style that can be applied to a Map.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct MapStyle {
//
//    /// How elevation should be rendered.
//    public struct Elevation {
//
//        /// The default elevation style.
//        public static var automatic: MapStyle.Elevation { get }
//
//        /// A flat, 2D elevation style.
//        public static var flat: MapStyle.Elevation { get }
//
//        /// A realistic 3D elevation style.
//        public static var realistic: MapStyle.Elevation { get }
//    }
//
//    /// Controls how map features are emphasized in the Standard style.
//    public struct StandardEmphasis {
//
//        /// The default emphasis style.
//        public static var automatic: MapStyle.StandardEmphasis { get }
//
//        /// A muted emphasis style.
//        public static var muted: MapStyle.StandardEmphasis { get }
//    }
//
//    /// Standard style.
//    public static var standard: MapStyle { get }
//
//    /// Imagery-based style, such as one using satellite imagery.
//    public static var imagery: MapStyle { get }
//
//    /// Hybrid style, such as one using satellite imagery of an area with road and road name information
//    /// layers on top.
//    public static var hybrid: MapStyle { get }
//
//    /// Standard style.
//    ///
//    /// - Parameters:
//    ///   - elevation: How elevation should be rendered.
//    ///   - emphasis: Controls how the framework emphasizes map features
//    ///   - pointsOfInterest: Point of interest categories shown on the map
//    ///   - showsTraffic: Controls whether the map displays traffic conditions
//    public static func standard(elevation: MapStyle.Elevation = .automatic, emphasis: MapStyle.StandardEmphasis = .automatic, pointsOfInterest: PointOfInterestCategories = .all, showsTraffic: Bool = false) -> MapStyle
//
//    /// Imagery-based style, such as one using satellite imagery.
//    ///
//    /// - Parameters:
//    ///   - elevation: How elevation should be rendered.
//    public static func imagery(elevation: MapStyle.Elevation = .automatic) -> MapStyle
//
//    /// Hybrid style, such as one using satellite imagery of an area with road
//    /// and road name information layers on top.
//    ///
//    /// - Parameters:
//    ///   - elevation: How elevation should be rendered.
//    ///   - pointsOfInterest: Point of interest categories shown on the map
//    ///   - showsTraffic: Controls whether the map displays traffic conditions
//    public static func hybrid(elevation: MapStyle.Elevation = .automatic, pointsOfInterest: PointOfInterestCategories = .all, showsTraffic: Bool = false) -> MapStyle
//}
//
//// Available when SwiftUI is imported with MapKit
///// A button that will set the framing of the associated `Map` to the User Location
/////
///// May be used in conjunction with `Map` as a stand alone view
/////
/////     struct LocationButtonTestView: View {
/////         @Namespace var mapScope
/////
/////         var body: some View {
/////             VStack {
/////                 Map(scope: mapScope)
/////                 MapUserLocationButton(scope: mapScope)
/////             }
/////             .mapScope(mapScope)
/////         }
/////     }
/////
///// MapUserLocationButton may also be used in conjunction with the
///// `.mapControls()` modifier
/////
/////     Map()
/////         .mapControls {
/////             MapUserLocationButton()
/////         }
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//@MainActor @preconcurrency public struct MapUserLocationButton : View {
//
//    /// Creates a map user location button.
//    ///
//    /// - Parameters:
//    ///   - scope: The namespace passed to the associated Map and .mapScope(). For
//    ///            use outside of .mapControls()
//    @MainActor @preconcurrency public init(scope: Namespace.ID? = nil)
//
//    /// The content and behavior of the view.
//    ///
//    /// When you implement a custom view, you must implement a computed
//    /// `body` property to provide the content for your view. Return a view
//    /// that's composed of built-in views that SwiftUI provides, plus other
//    /// composite views that you've already defined:
//    ///
//    ///     struct MyView: View {
//    ///         var body: some View {
//    ///             Text("Hello, World!")
//    ///         }
//    ///     }
//    ///
//    /// For more information about composing views and a view hierarchy,
//    /// see <doc:Declaring-a-Custom-View>.
//    @MainActor @preconcurrency public var body: some View { get }
//
//    /// The type of view representing the body of this view.
//    ///
//    /// When you create a custom view, Swift infers this type from your
//    /// implementation of the required ``View/body-swift.property`` property.
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = some View
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension MapUserLocationButton : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a `position` parameter along with\nMapCameraPosition.userLocation to configure the user location\ntracking behavior.")
//@available(macOS, introduced: 11.0, deprecated: 14.0, message: "Use Map initializers that take a `position` parameter along with\nMapCameraPosition.userLocation to configure the user location\ntracking behavior.")
//@available(tvOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a `position` parameter along with\nMapCameraPosition.userLocation to configure the user location\ntracking behavior.")
//@available(watchOS, introduced: 7.0, deprecated: 10.0, message: "Use Map initializers that take a `position` parameter along with\nMapCameraPosition.userLocation to configure the user location\ntracking behavior.")
//public enum MapUserTrackingMode {
//
//    case none
//
//    case follow
//
//    @available(iOS 17.0, watchOS 10.0, tvOS 17.0, *)
//    @available(macOS, unavailable)
//    case followWithHeading
//
//    /// Returns a Boolean value indicating whether two values are equal.
//    ///
//    /// Equality is the inverse of inequality. For any values `a` and `b`,
//    /// `a == b` implies that `a != b` is `false`.
//    ///
//    /// - Parameters:
//    ///   - lhs: A value to compare.
//    ///   - rhs: Another value to compare.
//    public static func == (a: MapUserTrackingMode, b: MapUserTrackingMode) -> Bool
//
//    /// Hashes the essential components of this value by feeding them into the
//    /// given hasher.
//    ///
//    /// Implement this method to conform to the `Hashable` protocol. The
//    /// components used for hashing must be the same as the components compared
//    /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
//    /// with each of these components.
//    ///
//    /// - Important: In your implementation of `hash(into:)`,
//    ///   don't call `finalize()` on the `hasher` instance provided,
//    ///   or replace it with a different instance.
//    ///   Doing so may become a compile-time error in the future.
//    ///
//    /// - Parameter hasher: The hasher to use when combining the components
//    ///   of this instance.
//    public func hash(into hasher: inout Hasher)
//
//    /// The hash value.
//    ///
//    /// Hash values are not guaranteed to be equal across different executions of
//    /// your program. Do not save hash values to use during a future execution.
//    ///
//    /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
//    ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
//    ///   The compiler provides an implementation for `hashValue` for you.
//    public var hashValue: Int { get }
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a `position` parameter along with\nMapCameraPosition.userLocation to configure the user location\ntracking behavior.")
//@available(macOS, introduced: 11.0, deprecated: 14.0, message: "Use Map initializers that take a `position` parameter along with\nMapCameraPosition.userLocation to configure the user location\ntracking behavior.")
//@available(tvOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a `position` parameter along with\nMapCameraPosition.userLocation to configure the user location\ntracking behavior.")
//@available(watchOS, introduced: 7.0, deprecated: 10.0, message: "Use Map initializers that take a `position` parameter along with\nMapCameraPosition.userLocation to configure the user location\ntracking behavior.")
//extension MapUserTrackingMode : Equatable {
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a `position` parameter along with\nMapCameraPosition.userLocation to configure the user location\ntracking behavior.")
//@available(macOS, introduced: 11.0, deprecated: 14.0, message: "Use Map initializers that take a `position` parameter along with\nMapCameraPosition.userLocation to configure the user location\ntracking behavior.")
//@available(tvOS, introduced: 14.0, deprecated: 17.0, message: "Use Map initializers that take a `position` parameter along with\nMapCameraPosition.userLocation to configure the user location\ntracking behavior.")
//@available(watchOS, introduced: 7.0, deprecated: 10.0, message: "Use Map initializers that take a `position` parameter along with\nMapCameraPosition.userLocation to configure the user location\ntracking behavior.")
//extension MapUserTrackingMode : Hashable {
//}
//
//// Available when SwiftUI is imported with MapKit
///// A balloon-shaped annotation that marks a map location.
/////
///// Create instances of ``Marker`` in the closure you provide to the
///// `content` parameter in ``MapView`` initializers.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//@MainActor @preconcurrency public struct Marker<Label> : MapContent where Label : View {
//
//    /// Creates a marker at the given location.
//    ///
//    /// - Parameters:
//    ///   - coordinate: The coordinate to display the marker at.
//    ///   - label: The label for the marker.
//    @MainActor @preconcurrency public init(coordinate: CLLocationCoordinate2D, @ViewBuilder label: () -> Label)
//
//    /// Creates a marker at the given location.
//    ///
//    /// - Parameters:
//    ///   - titleKey: The localized string key to lookup the title under.
//    ///   - coordinate: The coordinate to display the marker at.
//    @MainActor @preconcurrency public init(_ titleKey: LocalizedStringKey, coordinate: CLLocationCoordinate2D) where Label == Text
//
//    /// Creates a marker at the given location.
//    ///
//    /// - Parameters:
//    ///   - title: The title of the marker.
//    ///   - coordinate: The coordinate to display the marker at.
//    @MainActor @preconcurrency public init<S>(_ title: S, coordinate: CLLocationCoordinate2D) where Label == Text, S : StringProtocol
//
//    /// Creates a marker at the given location with a monogram displayed as the
//    /// balloon's icon.
//    ///
//    /// - Parameters:
//    ///   - titleKey: The localized string key to lookup the title under.
//    ///   - monogram: Up to three characters to display on the marker's balloon.
//    ///   - coordinate: The coordinate to display the marker at.
//    @MainActor @preconcurrency public init(_ titleKey: LocalizedStringKey, monogram: Text, coordinate: CLLocationCoordinate2D) where Label == Label<Text, Text>
//
//    /// Creates a marker at the given location with a monogram displayed as the
//    /// balloon's icon.
//    ///
//    /// - Parameters:
//    ///   - title: The title of the marker.
//    ///   - monogram: Up to three characters to display on the marker's balloon.
//    ///   - coordinate: The coordinate to display the marker at.
//    @MainActor @preconcurrency public init<S>(_ title: S, monogram: Text, coordinate: CLLocationCoordinate2D) where Label == Label<Text, Text>, S : StringProtocol
//
//    /// Creates a marker at the given location with a system image displayed as
//    /// the balloon's icon.
//    ///
//    /// - Parameters:
//    ///   - titleKey: The localized string key to lookup the title under.
//    ///   - systemImage: The system image to use as the marker balloon's glyph.
//    ///   - coordinate: The coordinate to display the marker at.
//    @MainActor @preconcurrency public init(_ titleKey: LocalizedStringKey, systemImage: String, coordinate: CLLocationCoordinate2D) where Label == Label<Text, Image>
//
//    /// Creates a marker at the given location with a system image displayed as
//    /// the balloon's icon.
//    ///
//    /// - Parameters:
//    ///   - title: The title of the marker.
//    ///   - systemImage: The system image to use as the marker balloon's glyph.
//    ///   - coordinate: The coordinate to display the marker at.
//    @MainActor @preconcurrency public init<S>(_ title: S, systemImage: String, coordinate: CLLocationCoordinate2D) where Label == Label<Text, Image>, S : StringProtocol
//
//    /// Creates a marker at the given location with an image displayed as
//    /// the balloon's icon.
//    ///
//    /// - Parameters:
//    ///   - titleKey: The localized string key to lookup the title under.
//    ///   - image: The name of the image resource to look up and use as
//    ///     the marker balloon's glyph.
//    ///   - coordinate: The coordinate to display the marker at.
//    @MainActor @preconcurrency public init(_ titleKey: LocalizedStringKey, image: String, coordinate: CLLocationCoordinate2D) where Label == Label<Text, Image>
//
//    /// Creates a marker at the given location with an image displayed as
//    /// the balloon's icon.
//    ///
//    /// - Parameters:
//    ///   - title: The title of the marker.
//    ///   - image: The name of the image resource to look up and use as
//    ///     the marker balloon's glyph.
//    ///   - coordinate: The coordinate to display the marker at.
//    @MainActor @preconcurrency public init<S>(_ title: S, image: String, coordinate: CLLocationCoordinate2D) where Label == Label<Text, Image>, S : StringProtocol
//
//    /// Creates a marker for a given map item using a MapKi-provided label.
//    ///
//    /// MapKit will compose a label using available information, such as the `name` property.
//    ///
//    /// - Parameters:
//    ///   - item: The map item to display.
//    @MainActor @preconcurrency public init(item: MKMapItem) where Label == Text
//
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = Never
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension Marker : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
///// Point of Interest categories to be shown.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct PointOfInterestCategories {
//
//    /// Show all points of interest.
//    public static var all: PointOfInterestCategories { get }
//
//    /// Show only points of interest belonging to certain categories.
//    public static func including(_ categories: [MKPointOfInterestCategory]) -> PointOfInterestCategories
//
//    /// Show only points of interest belonging to certain categories.
//    public static func including(_ categories: MKPointOfInterestCategory...) -> PointOfInterestCategories
//
//    /// Show all points of interest except those belonging to certain categories.
//    public static func excluding(_ categories: [MKPointOfInterestCategory]) -> PointOfInterestCategories
//
//    /// Show all points of interest except those belonging to certain categories.
//    public static func excluding(_ categories: MKPointOfInterestCategory...) -> PointOfInterestCategories
//
//    /// Do not show points of interest.
//    public static var excludingAll: PointOfInterestCategories { get }
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension PointOfInterestCategories : ExpressibleByArrayLiteral {
//
//    /// Creates an instance initialized with the given elements.
//    public init(arrayLiteral: MKPointOfInterestCategory...)
//
//    /// The type of the elements of an array literal.
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias ArrayLiteralElement = MKPointOfInterestCategory
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//@MainActor @frozen @preconcurrency public struct TupleMapContent<T> : MapContent {
//
//    @MainActor @preconcurrency public var value: T
//
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = Never
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension TupleMapContent : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
///// Displays the current location of the user on the map.
///// Successful usage of `UserAnnotation` requires obtaining a suitable level of
///// location access authorization first. Refer to Core Location documentation for
///// more information on how to accomplish this.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//@MainActor @preconcurrency public struct UserAnnotation<Content> : MapContent where Content : View {
//
//    /// Displays the current location of the user using the system styled user location puck.
//    ///
//    /// - Parameter anchor: How to anchor the user location puck around the user's location.
//    @MainActor @preconcurrency public init(anchor: UnitPoint = .center) where Content == EmptyView
//
//    /// Displays the current location of the user using the MapKit default style and behavior.
//    /// The visual display varies with the level of authorization the user grants your app.
//    @MainActor @preconcurrency public init() where Content == DefaultUserAnnotationContent
//
//    /// Displays the current location of the user using a custom view.
//    /// - Parameters:
//    ///   - anchor: How to anchor the custom view around the user's location.
//    ///   - content: The custom view to show at the user's location.
//    @MainActor @preconcurrency public init(anchor: UnitPoint = .center, @ViewBuilder content: @escaping () -> Content)
//
//    /// Displays the current location of the user using a custom view.
//    /// - Parameters:
//    ///   - anchor: How to anchor the custom view around the user's location.
//    ///   - content: The custom view to show at the user's location.
//    @MainActor @preconcurrency public init(anchor: UnitPoint = .center, @ViewBuilder content: @escaping (UserLocation) -> Content)
//
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = Never
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension UserAnnotation : Sendable {
//}
//
//// Available when SwiftUI is imported with MapKit
///// Information about the current location of the user.
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//public struct UserLocation {
//
//    /// The user's current location.
//    public var location: CLLocation? { get }
//
//    public var heading: CLHeading? { get }
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, *)
//@available(macOS, unavailable)
//@available(tvOS, unavailable)
//@available(watchOS, unavailable)
//extension View {
//
//    /// Specifies a custom presentation for the currently selected feature.
//    ///
//    /// The supported presentation options are `Annotation`, and `Marker`. Other types of map
//    /// content will be ignored and handled as though no content was returned.
//    ///
//    /// If empty map content is returned, the system presentation will be used.
//    ///
//    /// - Parameters:
//    ///   - content: Generates the custom presentation for a given map feature.
//    @MainActor @preconcurrency public func mapFeatureSelectionContent(@MapContentBuilder content: @escaping (MapFeature) -> some MapContent) -> some View
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension Group : MapContent where Content : MapContent {
//
//    /// Creates a group of map content.
//    ///
//    /// - Parameter content: A map content builder that produces the map content to group.
//    public init(@MapContentBuilder content: () -> Content)
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension Optional : MapContent where Wrapped : MapContent {
//
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = Never
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension View {
//
//    /// Performs an action when Map camera framing changes
//    ///
//    /// - Parameters:
//    ///   - frequency: How frequently the action should be performed during a camera interaction.
//    ///   - action: A closure to run when the camera framing changes.
//    @MainActor @preconcurrency public func onMapCameraChange(frequency: MapCameraUpdateFrequency = .onEnd, _ action: @escaping () -> Void) -> some View
//
//
//    /// Performs an action when Map camera framing changes
//    ///
//    /// - Parameters:
//    ///   - frequency: How frequently the action should be performed during a camera interaction.
//    ///   - action: A closure to run when the camera framing changes.
//    ///     The closure takes a `MapCameraUpdateContext` parameter that indicates
//    ///     the camera and the framed area.
//    @MainActor @preconcurrency public func onMapCameraChange(frequency: MapCameraUpdateFrequency = .onEnd, _ action: @escaping (MapCameraUpdateContext) -> Void) -> some View
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, *)
//@available(macOS, unavailable)
//@available(tvOS, unavailable)
//@available(watchOS, unavailable)
//extension MKMapItemRequest {
//
//    public convenience init(feature: MapFeature)
//
//    @available(iOS, introduced: 17.0, deprecated: 18.0, message: "Use mapFeature")
//    public var feature: MapFeature { get }
//
//    @available(iOS 18.0, visionOS 2.0, *)
//    @available(macOS, unavailable)
//    @available(tvOS, unavailable)
//    @available(watchOS, unavailable)
//    public var mapFeature: MapFeature? { get }
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension View {
//
//    /// Uses the given keyframes to animate the camera of a ``Map`` when the
//    /// given trigger value changes.
//    ///
//    /// When the trigger value changes, the map calls the `keyframes` closure
//    /// to generate the keyframes that will animate the camera. The animation
//    /// will continue for the duration of the keyframes that you specify.
//    ///
//    /// If the user performs a gesture while the animation is in progress, the
//    /// animation will be immediately removed, allowing the interaction to take
//    /// control of the camera.
//    ///
//    /// - Parameters:
//    ///   - trigger: A value to observe for changes.
//    ///   - keyframes: A keyframes builder closure that is called when starting
//    ///     a new keyframe animation. The current map camera is provided as the
//    ///     only parameter.
//    @MainActor @preconcurrency public func mapCameraKeyframeAnimator(trigger: some Equatable, @KeyframesBuilder<MapCamera> keyframes: @escaping (MapCamera) -> some Keyframes<MapCamera>) -> some View
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension ModifiedContent : MapContent where Content : MapContent, Modifier : _MapContentModifier {
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension ModifiedContent : DynamicMapContent where Content : DynamicMapContent, Modifier : _MapContentModifier {
//
//    /// The collection of underlying data.
//    public var data: Content.Data { get }
//
//    /// The type of the underlying collection of data.
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Data = Content.Data
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 18.0, visionOS 2.0, *)
//@available(macOS, unavailable)
//@available(watchOS, unavailable)
//@available(tvOS, unavailable)
//extension View {
//
//    /// Specifies the selection accessory to display for a `MapFeature`
//    ///
//    /// - Parameters:
//    ///   - style: The map item detail selection accessory style. If `nil`, no
//    ///     selection accessory will be displayed.
//    @MainActor @preconcurrency public func mapFeatureSelectionAccessory(_ style: MapItemDetailSelectionAccessoryStyle? = .automatic) -> some View
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension ForEach : DynamicMapContent where Content : MapContent {
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension ForEach where Content : MapContent {
//
//    /// Creates an instance that uniquely identifies and creates map content
//    /// across updates based on the identity of the underlying data.
//    ///
//    /// It's important that the `id` of a data element doesn't change unless you
//    /// replace the data element with a new data element that has a new
//    /// identity. If the `id` of a data element changes, the content view
//    /// generated from that data element loses any current state and animations.
//    ///
//    /// - Parameters:
//    ///   - data: The identified data that the ``ForEach`` instance uses to
//    ///     create map content dynamically.
//    ///   - content: The map content builder that creates map content
//    ///     dynamically.
//    @MainActor public init(_ data: Data, @MapContentBuilder content: @escaping (Data.Element) -> Content) where ID == Data.Element.ID, Data.Element : Identifiable
//
//    /// Creates an instance that uniquely identifies and creates map content
//    /// across updates based on the provided key path to the underlying data's
//    /// identifier.
//    ///
//    /// It's important that the `id` of a data element doesn't change, unless
//    /// the data element has been replaced with a new data element that has a
//    /// new identity. If the `id` of a data element changes, then the map
//    /// content generated from that data element will lose any current state
//    /// and animations.
//    ///
//    /// - Parameters:
//    ///   - data: The data that the ``ForEach`` instance uses to create map
//    ///     content dynamically.
//    ///   - id: The key path to the provided data's identifier.
//    ///   - content: The map content builder that creates map content
//    ///     dynamically.
//    @MainActor public init(_ data: Data, id: KeyPath<Data.Element, ID>, @MapContentBuilder content: @escaping (Data.Element) -> Content)
//
//    /// Creates an instance that computes map content on demand over a given
//    /// constant range.
//    ///
//    /// The instance only reads the initial value of the provided `data` and
//    /// doesn't need to identify map content across updates. To compute map
//    /// map content on demand over a dynamic range, use
//    /// ``ForEach/init(_:id:content:)``.
//    ///
//    /// - Parameters:
//    ///   - data: A constant range.
//    ///   - content: The map content builder that creates map content
//    ///   dynamically.
//    @MainActor public init(_ data: Range<Int>, @MapContentBuilder content: @escaping (Int) -> Content) where Data == Range<Int>, ID == Int
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension View {
//
//    /// Specifies the map style to be used.
//    @MainActor @preconcurrency public func mapStyle(_ value: MapStyle) -> some View
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension ForEach : MapContent where Content : MapContent {
//
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias Body = Never
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension Never : MapSelectable {
//
//    /// Selecting the given map feature.
//    public var feature: MapFeature?
//
//    public init(_ feature: MapFeature?)
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension Never : MapContent {
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, *)
//@available(macOS, unavailable)
//@available(tvOS, unavailable)
//@available(watchOS, unavailable)
//extension View {
//
//    /// Specifies which map features should have selection disabled.
//    ///
//    /// The `selectionDisabled` parameter takes a closure which maps map features, to booleans. If
//    /// that closure returns true for a given map feature, that map feature will be considered unselectable.
//    ///
//    /// - Parameter selectionDisabled: Determines if selection should be disabled for a given
//    ///   map feature.
//    @MainActor @preconcurrency public func mapFeatureSelectionDisabled(_ selectionDisabled: @escaping (MapFeature) -> Bool) -> some View
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension Never {
//
//    public typealias MapContentValue = Never
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
//@available(watchOS, unavailable)
//@available(tvOS, unavailable)
//extension View {
//
//    /// Presents a map item detail sheet.
//    ///
//    /// - Parameters:
//    ///     - isPresented: The binding to whether the detail sheet should be shown.
//    ///     - item: The map item to display. If nil, a "loading" view is displayed.
//    ///     - displaysMap: If an inline map should be displayed with the place data.
//    ///       A value of `true` must be specified if the application UI is not
//    ///       already showing the place in a map view.
//    @MainActor @preconcurrency public func mapItemDetailSheet(isPresented: Binding<Bool>, item: MKMapItem?, displaysMap: Bool = true) -> some View
//
//
//    /// Presents a map item detail sheet.
//    ///
//    /// - Parameters:
//    ///     - item: When `item` is non-`nil`, a detail sheet is displayed for the
//    ///       map item.
//    ///     - displaysMap: If an inline map should be displayed with the place data.
//    ///       A value of `true` must be specified if the application UI is not
//    ///       already showing the place in a map view.
//    @MainActor @preconcurrency public func mapItemDetailSheet(item: Binding<MKMapItem?>, displaysMap: Bool = true) -> some View
//
//
//    /// Presents a map item detail popover.
//    ///
//    /// Use this modifier if you want the system to choose the best orientation
//    /// of the popover's arrow. If you want to specify a particular edge for the
//    /// arrow, use
//    /// ``View/mapItemDetailPopover(isPresented:item:displaysMap:attachmentAnchor:arrowEdge:)``.
//    ///
//    /// - Parameters:
//    ///     - isPresented: The binding to whether the detail sheet should be shown.
//    ///     - item: The map item to display. If nil, a "loading" view is displayed.
//    ///     - displaysMap: If an inline map should be displayed with the place data.
//    ///       A value of `true` must be specified if the application UI is not
//    ///       already showing the place in a map view.
//    ///     - attachmentAnchor: The positioning anchor that defines the attachment
//    ///       point of the popover. The default is `bounds`.
//    @MainActor @preconcurrency public func mapItemDetailPopover(isPresented: Binding<Bool>, item: MKMapItem?, displaysMap: Bool = true, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds)) -> some View
//
//
//    /// Presents a map item detail popover.
//    ///
//    /// - Parameters:
//    ///     - isPresented: The binding to whether the detail sheet should be shown.
//    ///     - item: The map item to display. If nil, a "loading" view is displayed.
//    ///     - displaysMap: If an inline map should be displayed with the place data.
//    ///       A value of `true` must be specified if the application UI is not
//    ///       already showing the place in a map view.
//    ///     - attachmentAnchor: The positioning anchor that defines the attachment
//    ///       point of the popover. The default is `bounds`.
//    ///     - arrowEdge: The edge of the `attachmentAnchor` that defines the
//    ///       location of the popover’s arrow.
//    @MainActor @preconcurrency public func mapItemDetailPopover(isPresented: Binding<Bool>, item: MKMapItem?, displaysMap: Bool = true, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdge: Edge) -> some View
//
//
//    /// Presents a map item detail popover.
//    ///
//    /// Use this modifier if you want the system to choose the best orientation
//    /// of the popover's arrow. If you want to specify a particular edge for the
//    /// arrow, use
//    /// ``View/mapItemDetailPopover(item:displaysMap:attachmentAnchor:arrowEdge:)``.
//    ///
//    /// - Parameters:
//    ///     - item: When `item` is non-`nil`, a detail popover is displayed for the
//    ///       map item.
//    ///     - displaysMap: If an inline map should be displayed with the place data.
//    ///       A value of `true` must be specified if the application UI is not
//    ///       already showing the place in a map view.
//    ///     - attachmentAnchor: The positioning anchor that defines the attachment
//    ///       point of the popover. The default is `bounds`.
//    @MainActor @preconcurrency public func mapItemDetailPopover(item: Binding<MKMapItem?>, displaysMap: Bool = true, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds)) -> some View
//
//
//    /// Presents a map item detail popover.
//    ///
//    /// - Parameters:
//    ///     - item: When `item` is non-`nil`, a detail popover is displayed for the
//    ///       map item.
//    ///     - displaysMap: If an inline map should be displayed with the place data.
//    ///       A value of `true` must be specified if the application UI is not
//    ///       already showing the place in a map view.
//    ///     - attachmentAnchor: The positioning anchor that defines the attachment
//    ///       point of the popover. The default is `bounds`.
//    ///     - arrowEdge: The edge of the `attachmentAnchor` that defines the
//    ///       location of the popover’s arrow.
//    @MainActor @preconcurrency public func mapItemDetailPopover(item: Binding<MKMapItem?>, displaysMap: Bool = true, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdge: Edge) -> some View
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension View {
//
//    /// Configures all `Map` views in the associated environment to have
//    /// standard size and position controls
//    ///
//    /// You provide the controls you want to appear atop your map. When using a
//    /// control in conjunction with `.mapControls` you don't need to specify a
//    /// scope. Views that are not MapKit controls will be ignored.
//    ///
//    ///     Map()
//    ///     .mapControls {
//    ///         MapScaleView()
//    ///         MapUserLocationButton()
//    ///     }
//    ///
//    /// Controls can be modified individually or all at once. Custom frames and
//    /// alignments set on controls are ignored.
//    ///
//    ///     Map()
//    ///     .mapControls {
//    ///         MapCompass()
//    ///             .mapControls(.visible)
//    ///         MapPitchToggle()
//    ///             .buttonBorderShape(.circular)
//    ///             .tint(.purple)
//    ///     }
//    ///     .controlSize(.large)
//    ///
//    /// On watchOS, space is at a premium. When using the mapControls modifier,
//    /// MapUserLocationButton and MapCompass are automatically combined if present.
//    ///
//    ///     Map()
//    ///     .mapControls {
//    ///         MapUserLocationButton()
//    ///         MapCompass()
//    ///     }
//    ///
//    /// - Parameters:
//    ///   - content: A view builder returning the controls you wish your `Map`
//    @MainActor @preconcurrency public func mapControls(@ViewBuilder _ content: () -> some View) -> some View
//
//
//    /// Configures all Map controls in the environment to have the specified
//    /// visibility
//    ///
//    /// MapCompass, MapScaleView, and MapPitchToggle may automatically show and
//    /// hide based on the current state of the Map. That may not be appropriate
//    /// for all use cases, where always showing a control may be desirable.
//    ///
//    ///     HStack {
//    ///         MapCompass()
//    ///         MapScaleView()
//    ///         MapPitchToggle()
//    ///     }
//    ///     .mapControls(.visible)
//    ///
//    /// Other controls don't have an automatic visibility behavior, so they will
//    /// always be visible when automatic is specified. Controls may also be
//    /// hidden via this modifier when conditionalizing the view is not
//    /// appropriate
//    ///
//    ///     MapUserLocationButton()
//    ///         .mapControls(.automatic)
//    ///     MapZoomStepper()
//    ///         .mapControls(.hidden)
//    ///
//    /// - Parameters:
//    ///     - visibility: how modified map controls should show or hide
//    @MainActor @preconcurrency public func mapControlVisibility(_ visibility: Visibility) -> some View
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension CLLocationCoordinate2D : Animatable {
//
//    /// The data to animate.
//    public var animatableData: AnimatablePair<CLLocationDegrees, CLLocationDegrees>
//
//    /// The type defining the data to animate.
//    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
//    public typealias AnimatableData = AnimatablePair<CLLocationDegrees, CLLocationDegrees>
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
//extension View {
//
//    /// Creates a mapScope that SwiftUI uses to connect map controls to an associated map.
//    @MainActor @preconcurrency public func mapScope(_ scope: Namespace.ID) -> some View
//
//}
//
//// Available when SwiftUI is imported with MapKit
//@available(iOS 17.0, *)
//@available(macOS, unavailable)
//@available(tvOS, unavailable)
//@available(watchOS, unavailable)
//extension View {
//
//    @MainActor @preconcurrency public func lookAroundViewer(isPresented: Binding<Bool>, initialScene: MKLookAroundScene?, allowsNavigation: Bool = true, showsRoadLabels: Bool = true, pointsOfInterest: PointOfInterestCategories = .all, onDismiss: (() -> Void)? = nil) -> some View
//
//
//    @MainActor @preconcurrency public func lookAroundViewer(isPresented: Binding<Bool>, scene: Binding<MKLookAroundScene?>, allowsNavigation: Bool = true, showsRoadLabels: Bool = true, pointsOfInterest: PointOfInterestCategories = .all, onDismiss: (() -> Void)? = nil) -> some View
//
//}
//
