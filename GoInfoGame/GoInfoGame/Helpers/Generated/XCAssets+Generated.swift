// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal static let accentColor = ColorAsset(name: "AccentColor")
  internal enum Colors {
    internal static let accentLavender = ColorAsset(name: "Accent Lavender")
    internal static let accentPink = ColorAsset(name: "Accent Pink")
    internal static let huskyGold = ColorAsset(name: "Husky Gold")
    internal static let huskyPurple = ColorAsset(name: "Husky Purple")
    internal static let theme = ColorAsset(name: "theme")
  }
  internal enum QuestIcons {
    internal static let accessPoint = ImageAsset(name: "access_point")
    internal static let apple = ImageAsset(name: "apple")
    internal static let baby = ImageAsset(name: "baby")
    internal static let barrier = ImageAsset(name: "barrier")
    internal static let barrierLocked = ImageAsset(name: "barrier_locked")
    internal static let barrierOnPath = ImageAsset(name: "barrier_on_path")
    internal static let barrierOnRoad = ImageAsset(name: "barrier_on_road")
    internal static let beach = ImageAsset(name: "beach")
    internal static let beer = ImageAsset(name: "beer")
    internal static let benchMaterial = ImageAsset(name: "bench_material")
    internal static let benchPoi = ImageAsset(name: "bench_poi")
    internal static let benchPublicTransport = ImageAsset(name: "bench_public_transport")
    internal static let bicycle = ImageAsset(name: "bicycle")
    internal static let bicycleIncline = ImageAsset(name: "bicycle_incline")
    internal static let bicycleParking = ImageAsset(name: "bicycle_parking")
    internal static let bicycleParkingAccess = ImageAsset(name: "bicycle_parking_access")
    internal static let bicycleParkingCapacity = ImageAsset(name: "bicycle_parking_capacity")
    internal static let bicycleParkingCover = ImageAsset(name: "bicycle_parking_cover")
    internal static let bicycleParkingFee = ImageAsset(name: "bicycle_parking_fee")
    internal static let bicyclePump = ImageAsset(name: "bicycle_pump")
    internal static let bicycleRental = ImageAsset(name: "bicycle_rental")
    internal static let bicycleRentalCapacity = ImageAsset(name: "bicycle_rental_capacity")
    internal static let bicycleRepair = ImageAsset(name: "bicycle_repair")
    internal static let bicycleRepairAmenity = ImageAsset(name: "bicycle_repair_amenity")
    internal static let bicycleSecondHand = ImageAsset(name: "bicycle_second_hand")
    internal static let bicycleway = ImageAsset(name: "bicycleway")
    internal static let bicyclewaySurface = ImageAsset(name: "bicycleway_surface")
    internal static let bicyclewaySurfaceDetail = ImageAsset(name: "bicycleway_surface_detail")
    internal static let bicyclewayWidth = ImageAsset(name: "bicycleway_width")
    internal static let binPublicTransport = ImageAsset(name: "bin_public_transport")
    internal static let blind = ImageAsset(name: "blind")
    internal static let blindBus = ImageAsset(name: "blind_bus")
    internal static let blindPedestrianCrossing = ImageAsset(name: "blind_pedestrian_crossing")
    internal static let blindTrafficLights = ImageAsset(name: "blind_traffic_lights")
    internal static let blindTrafficLightsSound = ImageAsset(name: "blind_traffic_lights_sound")
    internal static let boardType = ImageAsset(name: "board_type")
    internal static let boat = ImageAsset(name: "boat")
    internal static let bridge = ImageAsset(name: "bridge")
    internal static let building = ImageAsset(name: "building")
    internal static let buildingConstruction = ImageAsset(name: "building_construction")
    internal static let buildingHeight = ImageAsset(name: "building_height")
    internal static let buildingInside = ImageAsset(name: "building_inside")
    internal static let buildingLevels = ImageAsset(name: "building_levels")
    internal static let buildingUnderground = ImageAsset(name: "building_underground")
    internal static let bus = ImageAsset(name: "bus")
    internal static let busStopLit = ImageAsset(name: "bus_stop_lit")
    internal static let busStopName = ImageAsset(name: "bus_stop_name")
    internal static let busStopShelter = ImageAsset(name: "bus_stop_shelter")
    internal static let calendar = ImageAsset(name: "calendar")
    internal static let campPower = ImageAsset(name: "camp_power")
    internal static let car = ImageAsset(name: "car")
    internal static let carAirCompressor = ImageAsset(name: "car_air_compressor")
    internal static let carBumpy = ImageAsset(name: "car_bumpy")
    internal static let carCharger = ImageAsset(name: "car_charger")
    internal static let carChargerCapacity = ImageAsset(name: "car_charger_capacity")
    internal static let carWash = ImageAsset(name: "car_wash")
    internal static let caravan = ImageAsset(name: "caravan")
    internal static let caravanSite = ImageAsset(name: "caravan_site")
    internal static let card = ImageAsset(name: "card")
    internal static let cash = ImageAsset(name: "cash")
    internal static let check = ImageAsset(name: "check")
    internal static let checkShop = ImageAsset(name: "check_shop")
    internal static let choker = ImageAsset(name: "choker")
    internal static let christian = ImageAsset(name: "christian")
    internal static let cow = ImageAsset(name: "cow")
    internal static let crown = ImageAsset(name: "crown")
    internal static let defibrillator = ImageAsset(name: "defibrillator")
    internal static let door = ImageAsset(name: "door")
    internal static let doorAddress = ImageAsset(name: "door_address")
    internal static let dot = ImageAsset(name: "dot")
    internal static let drinkingWater = ImageAsset(name: "drinking_water")
    internal static let fee = ImageAsset(name: "fee")
    internal static let ferry = ImageAsset(name: "ferry")
    internal static let ferryPedestrian = ImageAsset(name: "ferry_pedestrian")
    internal static let fire = ImageAsset(name: "fire")
    internal static let fireHydrant = ImageAsset(name: "fire_hydrant")
    internal static let fireHydrantDiameter = ImageAsset(name: "fire_hydrant_diameter")
    internal static let fireHydrantGrass = ImageAsset(name: "fire_hydrant_grass")
    internal static let fireHydrantRef = ImageAsset(name: "fire_hydrant_ref")
    internal static let footwaySurface = ImageAsset(name: "footway_surface")
    internal static let footwaySurfaceDetail = ImageAsset(name: "footway_surface_detail")
    internal static let fuel = ImageAsset(name: "fuel")
    internal static let fuelSelfService = ImageAsset(name: "fuel_self_service")
    internal static let generalRef = ImageAsset(name: "general_ref")
    internal static let glutenfree = ImageAsset(name: "glutenfree")
    internal static let guidepostEle = ImageAsset(name: "guidepost_ele")
    internal static let guidepostName = ImageAsset(name: "guidepost_name")
    internal static let guidepostSport = ImageAsset(name: "guidepost_sport")
    internal static let hairdresser = ImageAsset(name: "hairdresser")
    internal static let halal = ImageAsset(name: "halal")
    internal static let housenumber = ImageAsset(name: "housenumber")
    internal static let housenumberStreet = ImageAsset(name: "housenumber_street")
    internal static let information = ImageAsset(name: "information")
    internal static let kerbTactilePaving = ImageAsset(name: "kerb_tactile_paving")
    internal static let kerbType = ImageAsset(name: "kerb_type")
    internal static let kosher = ImageAsset(name: "kosher")
    internal static let label = ImageAsset(name: "label")
    internal static let lampMount = ImageAsset(name: "lamp_mount")
    internal static let lampType = ImageAsset(name: "lamp_type")
    internal static let lantern = ImageAsset(name: "lantern")
    internal static let laundry = ImageAsset(name: "laundry")
    internal static let leaf = ImageAsset(name: "leaf")
    internal static let level = ImageAsset(name: "level")
    internal static let mail = ImageAsset(name: "mail")
    internal static let mailRef = ImageAsset(name: "mail_ref")
    internal static let maxHeight = ImageAsset(name: "max_height")
    internal static let maxHeightMeasure = ImageAsset(name: "max_height_measure")
    internal static let maxSpeed = ImageAsset(name: "max_speed")
    internal static let maxWeight = ImageAsset(name: "max_weight")
    internal static let maxWidth = ImageAsset(name: "max_width")
    internal static let memorial = ImageAsset(name: "memorial")
    internal static let money = ImageAsset(name: "money")
    internal static let mopedAccess = ImageAsset(name: "moped_access")
    internal static let motorcycle = ImageAsset(name: "motorcycle")
    internal static let motorcycleParking = ImageAsset(name: "motorcycle_parking")
    internal static let motorcycleParkingCapacity = ImageAsset(name: "motorcycle_parking_capacity")
    internal static let motorcycleParkingCover = ImageAsset(name: "motorcycle_parking_cover")
    internal static let mtb = ImageAsset(name: "mtb")
    internal static let museum = ImageAsset(name: "museum")
    internal static let noBicycles = ImageAsset(name: "no_bicycles")
    internal static let noCars = ImageAsset(name: "no_cars")
    internal static let noCow = ImageAsset(name: "no_cow")
    internal static let noPedestrians = ImageAsset(name: "no_pedestrians")
    internal static let noteCreate = ImageAsset(name: "note_create")
    internal static let notes = ImageAsset(name: "notes")
    internal static let oneway = ImageAsset(name: "oneway")
    internal static let openingHours = ImageAsset(name: "opening_hours")
    internal static let openingHoursSigned = ImageAsset(name: "opening_hours_signed")
    internal static let parcelLockerBrand = ImageAsset(name: "parcel_locker_brand")
    internal static let parcelLockerDeposit = ImageAsset(name: "parcel_locker_deposit")
    internal static let parcelLockerPickup = ImageAsset(name: "parcel_locker_pickup")
    internal static let parking = ImageAsset(name: "parking")
    internal static let parkingAccess = ImageAsset(name: "parking_access")
    internal static let parkingFee = ImageAsset(name: "parking_fee")
    internal static let parkingLane = ImageAsset(name: "parking_lane")
    internal static let parkingMaxstay = ImageAsset(name: "parking_maxstay")
    internal static let pathSegregation = ImageAsset(name: "path_segregation")
    internal static let peak = ImageAsset(name: "peak")
    internal static let pedestrian = ImageAsset(name: "pedestrian")
    internal static let pedestrianCrossing = ImageAsset(name: "pedestrian_crossing")
    internal static let pedestrianCrossingIsland = ImageAsset(name: "pedestrian_crossing_island")
    internal static let pharmacy = ImageAsset(name: "pharmacy")
    internal static let phone = ImageAsset(name: "phone")
    internal static let picnicTableCover = ImageAsset(name: "picnic_table_cover")
    internal static let pisteDifficulty = ImageAsset(name: "piste_difficulty")
    internal static let pisteLit = ImageAsset(name: "piste_lit")
    internal static let pisteRef = ImageAsset(name: "piste_ref")
    internal static let pitchLantern = ImageAsset(name: "pitch_lantern")
    internal static let pitchSurface = ImageAsset(name: "pitch_surface")
    internal static let playground = ImageAsset(name: "playground")
    internal static let police = ImageAsset(name: "police")
    internal static let postOffice = ImageAsset(name: "post_office")
    internal static let power = ImageAsset(name: "power")
    internal static let quest = ImageAsset(name: "quest")
    internal static let railway = ImageAsset(name: "railway")
    internal static let recycling = ImageAsset(name: "recycling")
    internal static let recyclingClothes = ImageAsset(name: "recycling_clothes")
    internal static let recyclingContainer = ImageAsset(name: "recycling_container")
    internal static let recyclingGlass = ImageAsset(name: "recycling_glass")
    internal static let religion = ImageAsset(name: "religion")
    internal static let religionServiceTimes = ImageAsset(name: "religion_service_times")
    internal static let restaurant = ImageAsset(name: "restaurant")
    internal static let restaurantVegan = ImageAsset(name: "restaurant_vegan")
    internal static let restaurantVegetarian = ImageAsset(name: "restaurant_vegetarian")
    internal static let roadConstruction = ImageAsset(name: "road_construction")
    internal static let roofOrientation = ImageAsset(name: "roof_orientation")
    internal static let roofShape = ImageAsset(name: "roof_shape")
    internal static let sacScale = ImageAsset(name: "sac_scale")
    internal static let sauna = ImageAsset(name: "sauna")
    internal static let seating = ImageAsset(name: "seating")
    internal static let shelterType = ImageAsset(name: "shelter_type")
    internal static let shop = ImageAsset(name: "shop")
    internal static let shower = ImageAsset(name: "shower")
    internal static let sidewalk = ImageAsset(name: "sidewalk")
    internal static let sidewalkSurface = ImageAsset(name: "sidewalk_surface")
    internal static let smoking = ImageAsset(name: "smoking")
    internal static let snowPoi = ImageAsset(name: "snow_poi")
    internal static let sport = ImageAsset(name: "sport")
    internal static let steps = ImageAsset(name: "steps")
    internal static let stepsCount = ImageAsset(name: "steps_count")
    internal static let stepsCountBrown = ImageAsset(name: "steps_count_brown")
    internal static let stepsHandrail = ImageAsset(name: "steps_handrail")
    internal static let stepsRamp = ImageAsset(name: "steps_ramp")
    internal static let stepsTactilePaving = ImageAsset(name: "steps_tactile_paving")
    internal static let street = ImageAsset(name: "street")
    internal static let streetCabinet = ImageAsset(name: "street_cabinet")
    internal static let streetLanes = ImageAsset(name: "street_lanes")
    internal static let streetName = ImageAsset(name: "street_name")
    internal static let streetName2 = ImageAsset(name: "street_name2")
    internal static let streetShoulder = ImageAsset(name: "street_shoulder")
    internal static let streetSurface = ImageAsset(name: "street_surface")
    internal static let streetSurfaceDetail = ImageAsset(name: "street_surface_detail")
    internal static let streetTurnLanes = ImageAsset(name: "street_turn_lanes")
    internal static let streetWidth = ImageAsset(name: "street_width")
    internal static let summitCross = ImageAsset(name: "summit_cross")
    internal static let surveillance = ImageAsset(name: "surveillance")
    internal static let surveillanceCamera = ImageAsset(name: "surveillance_camera")
    internal static let swimmingPool = ImageAsset(name: "swimming_pool")
    internal static let tent = ImageAsset(name: "tent")
    internal static let toiletFee = ImageAsset(name: "toilet_fee")
    internal static let toilets = ImageAsset(name: "toilets")
    internal static let toiletsWheelchair = ImageAsset(name: "toilets_wheelchair")
    internal static let tractor = ImageAsset(name: "tractor")
    internal static let trafficLights = ImageAsset(name: "traffic_lights")
    internal static let trafficLightsButton = ImageAsset(name: "traffic_lights_button")
    internal static let trailVisibility = ImageAsset(name: "trail_visibility")
    internal static let valve = ImageAsset(name: "valve")
    internal static let viaFerrataScale = ImageAsset(name: "via_ferrata_scale")
    internal static let waySurface = ImageAsset(name: "way_surface")
    internal static let waySurfaceDetail = ImageAsset(name: "way_surface_detail")
    internal static let wayWidth = ImageAsset(name: "way_width")
    internal static let wheelchair = ImageAsset(name: "wheelchair")
    internal static let wheelchairCrossing = ImageAsset(name: "wheelchair_crossing")
    internal static let wheelchairShop = ImageAsset(name: "wheelchair_shop")
    internal static let wheelchairWidth = ImageAsset(name: "wheelchair_width")
    internal static let wifi = ImageAsset(name: "wifi")
  }
  internal enum Quests {
    internal enum AddSideWalk {
      internal static let both = ImageAsset(name: "both")
      internal static let noSidewalk = ImageAsset(name: "no-sidewalk")
      internal static let selectLeftSide = ImageAsset(name: "select-left-side")
      internal static let selectRightSide = ImageAsset(name: "select-right-side")
      internal static let sidewalkSeparate = ImageAsset(name: "sidewalk-separate")
    }
    internal enum CrossingIsland {
      internal static let icQuestPedestrianCrossingIsland = ImageAsset(name: "ic_quest_pedestrian_crossing_island")
    }
    internal enum StepsRamp {
      internal static let icQuestStepsRamp = ImageAsset(name: "ic_quest_steps_ramp")
      internal static let rampBicycle = ImageAsset(name: "ramp_bicycle")
      internal static let rampNone = ImageAsset(name: "ramp_none")
      internal static let rampStroller = ImageAsset(name: "ramp_stroller")
      internal static let rampWheelchair = ImageAsset(name: "ramp_wheelchair")
    }
    internal enum Surfaces {
      internal static let surfaceArtificialTurf = ImageAsset(name: "surface_artificial_turf")
      internal static let surfaceAsphalt = ImageAsset(name: "surface_asphalt")
      internal static let surfaceAsphaltBad = ImageAsset(name: "surface_asphalt_bad")
      internal static let surfaceAsphaltExcellent = ImageAsset(name: "surface_asphalt_excellent")
      internal static let surfaceAsphaltGood = ImageAsset(name: "surface_asphalt_good")
      internal static let surfaceAsphaltIntermediate = ImageAsset(name: "surface_asphalt_intermediate")
      internal static let surfaceAsphaltVeryBad = ImageAsset(name: "surface_asphalt_very_bad")
      internal static let surfaceCobblestone = ImageAsset(name: "surface_cobblestone")
      internal static let surfaceCompacted = ImageAsset(name: "surface_compacted")
      internal static let surfaceCompactedBad = ImageAsset(name: "surface_compacted_bad")
      internal static let surfaceCompactedGood = ImageAsset(name: "surface_compacted_good")
      internal static let surfaceCompactedIntermediate = ImageAsset(name: "surface_compacted_intermediate")
      internal static let surfaceCompactedVeryBad = ImageAsset(name: "surface_compacted_very_bad")
      internal static let surfaceConcrete = ImageAsset(name: "surface_concrete")
      internal static let surfaceConcreteBad = ImageAsset(name: "surface_concrete_bad")
      internal static let surfaceConcreteExcellent = ImageAsset(name: "surface_concrete_excellent")
      internal static let surfaceConcreteGood = ImageAsset(name: "surface_concrete_good")
      internal static let surfaceConcreteIntermediate = ImageAsset(name: "surface_concrete_intermediate")
      internal static let surfaceConcreteLanes = ImageAsset(name: "surface_concrete_lanes")
      internal static let surfaceConcretePlates = ImageAsset(name: "surface_concrete_plates")
      internal static let surfaceConcreteVeryBad = ImageAsset(name: "surface_concrete_very_bad")
      internal static let surfaceDirt = ImageAsset(name: "surface_dirt")
      internal static let surfaceFineGravel = ImageAsset(name: "surface_fine_gravel")
      internal static let surfaceGrass = ImageAsset(name: "surface_grass")
      internal static let surfaceGrassPaver = ImageAsset(name: "surface_grass_paver")
      internal static let surfaceGravel = ImageAsset(name: "surface_gravel")
      internal static let surfaceGravelBad = ImageAsset(name: "surface_gravel_bad")
      internal static let surfaceGravelIntermediate = ImageAsset(name: "surface_gravel_intermediate")
      internal static let surfaceGravelVeryBad = ImageAsset(name: "surface_gravel_very_bad")
      internal static let surfaceGroundArea = ImageAsset(name: "surface_ground_area")
      internal static let surfaceMetal = ImageAsset(name: "surface_metal")
      internal static let surfaceMud = ImageAsset(name: "surface_mud")
      internal static let surfacePaved = ImageAsset(name: "surface_paved")
      internal static let surfacePavedArea = ImageAsset(name: "surface_paved_area")
      internal static let surfacePavingStones = ImageAsset(name: "surface_paving_stones")
      internal static let surfacePavingStonesBad = ImageAsset(name: "surface_paving_stones_bad")
      internal static let surfacePavingStonesExcellent = ImageAsset(name: "surface_paving_stones_excellent")
      internal static let surfacePavingStonesGood = ImageAsset(name: "surface_paving_stones_good")
      internal static let surfacePavingStonesIntermediate = ImageAsset(name: "surface_paving_stones_intermediate")
      internal static let surfacePavingStonesVeryBad = ImageAsset(name: "surface_paving_stones_very_bad")
      internal static let surfacePebblestone = ImageAsset(name: "surface_pebblestone")
      internal static let surfaceRock = ImageAsset(name: "surface_rock")
      internal static let surfaceSand = ImageAsset(name: "surface_sand")
      internal static let surfaceSett = ImageAsset(name: "surface_sett")
      internal static let surfaceSettBad = ImageAsset(name: "surface_sett_bad")
      internal static let surfaceSettGood = ImageAsset(name: "surface_sett_good")
      internal static let surfaceSettIntermediate = ImageAsset(name: "surface_sett_intermediate")
      internal static let surfaceSettVeryBad = ImageAsset(name: "surface_sett_very_bad")
      internal static let surfaceTartan = ImageAsset(name: "surface_tartan")
      internal static let surfaceTennisClay = ImageAsset(name: "surface_tennis_clay")
      internal static let surfaceUnpaved = ImageAsset(name: "surface_unpaved")
      internal static let surfaceUnpavedArea = ImageAsset(name: "surface_unpaved_area")
      internal static let surfaceUnpavedHorrible = ImageAsset(name: "surface_unpaved_horrible")
      internal static let surfaceUnpavedImpassable = ImageAsset(name: "surface_unpaved_impassable")
      internal static let surfaceUnpavedVeryHorrible = ImageAsset(name: "surface_unpaved_very_horrible")
      internal static let surfaceWood = ImageAsset(name: "surface_wood")
      internal static let surfaceWoodchips = ImageAsset(name: "surface_woodchips")
    }
    internal static let addWayLit = ImageAsset(name: "add_way_lit")
    internal static let close = ImageAsset(name: "close")
    internal static let crossingTypeSignals = ImageAsset(name: "crossing_type_signals")
    internal static let crossingTypeUnmarked = ImageAsset(name: "crossing_type_unmarked")
    internal static let crossingTypeZebra = ImageAsset(name: "crossing_type_zebra")
    internal static let kerbHeightFlush = ImageAsset(name: "kerb_height_flush")
    internal static let kerbHeightLowered = ImageAsset(name: "kerb_height_lowered")
    internal static let kerbHeightLoweredRamp = ImageAsset(name: "kerb_height_lowered_ramp")
    internal static let kerbHeightNo = ImageAsset(name: "kerb_height_no")
    internal static let kerbHeightRaised = ImageAsset(name: "kerb_height_raised")
    internal static let sidewalkWidthImg = ImageAsset(name: "sidewalk-width-img")
    internal static let step = ImageAsset(name: "step")
    internal static let stepsInclineUpReversed = ImageAsset(name: "steps-incline-up-reversed")
    internal static let stepsInclineUp = ImageAsset(name: "steps-incline-up")
    internal static let stopLit = ImageAsset(name: "stop_lit")
    internal static let tactileCrossing = ImageAsset(name: "tactile_crossing")
    internal static let tactilePavingIllustration = ImageAsset(name: "tactile_paving_illustration")
  }
  internal static let logo = ImageAsset(name: "logo")
  internal static let longFormDismiss = ImageAsset(name: "long-form-dismiss")
  internal static let mapPoint = ImageAsset(name: "mapPoint")
  internal static let mapicon = ImageAsset(name: "mapicon")
  internal static let noImage = ImageAsset(name: "no_image")
  internal static let osmlogo = ImageAsset(name: "osmlogo")
  internal static let sync = ImageAsset(name: "sync")
  internal static let uploadSync = ImageAsset(name: "upload_sync")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  internal func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = BundleToken.bundle
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal private(set) lazy var swiftUIColor: SwiftUI.Color = {
    SwiftUI.Color(asset: self)
  }()
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Color {
  init(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }
}
#endif

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

internal extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Image {
  init(asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: ImageAsset, label: Text) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
