import Foundation
import CoreLocation

// MARK: - Extensions pour Codable
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// MARK: - Day Trip Models
struct DayTrip: Codable, Identifiable {
    let id: String
    let startLocation: Location
    let locations: [Location]
    let optimizedRoute: [Location]
    let totalDistance: Double
    let estimatedDuration: TimeInterval
    let transportMode: TransportMode
    let createdAt: Date
    let numberOfLocations: Int
    
    enum CodingKeys: String, CodingKey {
        case id, optimizedRoute, totalDistance, estimatedDuration, transportMode, numberOfLocations
        case startLocation = "start_location"
        case locations = "destination_locations"
        case createdAt = "created_at"
    }
}

struct TripPlanRequest: Codable {
    let startAddress: String
    let destinations: [String]
    let transportMode: TransportMode
}

// MARK: - Guided Tour Models
struct GuidedTour: Codable, Identifiable {
    let id: String
    let title: String
    let city: City
    let description: String
    var duration: TimeInterval
    let difficulty: TourDifficulty
    let stops: [TourStop]
    let imageURL: String?
    let rating: Double?
    let price: Double?
    
    // Nouveaux champs pour l'itinéraire adaptatif
    var startLocation: CLLocationCoordinate2D?
    var startAddress: String?
    var optimizedStops: [TourStop]?
    var totalDistance: Double?
    var estimatedTravelTime: TimeInterval?
    
    enum CodingKeys: String, CodingKey {
        case id, title, city, description, duration, difficulty, stops, rating, price
        case imageURL = "image_url"
        case startLocation = "start_location"
        case startAddress = "start_address"
        case optimizedStops = "optimized_stops"
        case totalDistance = "total_distance"
        case estimatedTravelTime = "estimated_travel_time"
    }
}

struct TourStop: Codable, Identifiable {
    let id: String
    let location: Location
    var order: Int
    let audioGuideText: String
    let audioGuideURL: String?
    let visitDuration: TimeInterval
    let tips: String?
    
    // Nouveaux champs pour l'itinéraire adaptatif
    var distanceFromPrevious: Double?
    var travelTimeFromPrevious: TimeInterval?
    var estimatedArrivalTime: Date?
    var estimatedDepartureTime: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, location, order, tips
        case audioGuideText = "audio_guide_text"
        case audioGuideURL = "audio_guide_url"
        case visitDuration = "visit_duration"
        case distanceFromPrevious = "distance_from_previous"
        case travelTimeFromPrevious = "travel_time_from_previous"
        case estimatedArrivalTime = "estimated_arrival_time"
        case estimatedDepartureTime = "estimated_departure_time"
    }
}

enum City: String, CaseIterable, Codable {
    // France
    case paris = "paris"
    case lyon = "lyon"
    case marseille = "marseille"
    case toulouse = "toulouse"
    case nice = "nice"
    case nantes = "nantes"
    case strasbourg = "strasbourg"
    case montpellier = "montpellier"
    case bordeaux = "bordeaux"

    case reims = "reims"
    case saintEtienne = "saint_etienne"
    case toulon = "toulon"
    case leHavre = "le_havre"
    case grenoble = "grenoble"
    case dijon = "dijon"
    case angers = "angers"
    case saintDenis = "saint_denis"
    case nimes = "nimes"
    case saintDenisReunion = "saint_denis_reunion"
    
    // Belgique
    case brussels = "brussels"
    case antwerp = "antwerp"
    case ghent = "ghent"
    case charleroi = "charleroi"
    case liege = "liege"
    case bruges = "bruges"
    case namur = "namur"
    case mons = "mons"

    case aalst = "aalst"
    
    // Luxembourg
    case luxembourg = "luxembourg"
    
    // Suisse
    case zurich = "zurich"
    case geneva = "geneva"

    case bern = "bern"
    case lausanne = "lausanne"
    case winterthur = "winterthur"
    case stGallen = "st_gallen"
    case lucerne = "lucerne"
    
    // Allemagne
    case berlin = "berlin"
    case hamburg = "hamburg"
    case munich = "munich"
    case cologne = "cologne"
    case frankfurt = "frankfurt"
    case stuttgart = "stuttgart"

    case leipzig = "leipzig"
    case dortmund = "dortmund"
    case essen = "essen"
    
    // Italie
    case rome = "rome"
    case milan = "milan"
    case naples = "naples"
    case turin = "turin"
    case palermo = "palermo"
    case genoa = "genoa"
    case bologna = "bologna"
    case florence = "florence"
    case bari = "bari"
    case catania = "catania"
    
    // Espagne
    case madrid = "madrid"
    case barcelona = "barcelona"
    case valencia = "valencia"
    case seville = "seville"
    case zaragoza = "zaragoza"
    case malaga = "malaga"
    case murcia = "murcia"
    case palma = "palma"
    case lasPalmas = "las_palmas"
    case bilbao = "bilbao"
    
    // Pays-Bas
    case amsterdam = "amsterdam"
    case rotterdam = "rotterdam"
    case theHague = "the_hague"
    case utrecht = "utrecht"
    case eindhoven = "eindhoven"
    case tilburg = "tilburg"
    case groningen = "groningen"
    case breda = "breda"
    case nijmegen = "nijmegen"
    case enschede = "enschede"
    
    // Royaume-Uni
    case london = "london"
    case birmingham = "birmingham"
    case leeds = "leeds"
    case glasgow = "glasgow"
    case sheffield = "sheffield"
    case bradford = "bradford"
    case edinburgh = "edinburgh"
    case liverpool = "liverpool"
    case manchester = "manchester"
    case bristol = "bristol"

    // Tchéquie
    case prague = "prague"

    // États-Unis
    case newYork = "new_york"
    
    // Maroc
    case casablanca = "casablanca"
    case rabat = "rabat"
    case marrakech = "marrakech"
    case fez = "fez"
    case tangier = "tangier"
    case agadir = "agadir"
    case meknes = "meknes"
    case oujda = "oujda"
    case kenitra = "kenitra"
    case tetouan = "tetouan"
    
    // Turquie
    case istanbul = "istanbul"
    case ankara = "ankara"
    case izmir = "izmir"
    case bursa = "bursa"
    case antalya = "antalya"
    case adana = "adana"
    case konya = "konya"
    case gaziantep = "gaziantep"
    case kayseri = "kayseri"
    case mersin = "mersin"
    
    // Japon
    case tokyo = "tokyo"
    case osaka = "osaka"
    case kyoto = "kyoto"
    case yokohama = "yokohama"
    case nagoya = "nagoya"
    case sapporo = "sapporo"
    case kobe = "kobe"
    case fukuoka = "fukuoka"
    case kawasaki = "kawasaki"
    case saitama = "saitama"
    
    // Chine
    case beijing = "beijing"
    case shanghai = "shanghai"
    case guangzhou = "guangzhou"
    case shenzhen = "shenzhen"
    case chengdu = "chengdu"
    case tianjin = "tianjin"
    case chongqing = "chongqing"
    case nanjing = "nanjing"
    case wuhan = "wuhan"
    case xian = "xian"
    
    // Corée du Sud
    case seoul = "seoul"
    case busan = "busan"
    case incheon = "incheon"
    case daegu = "daegu"
    case daejeon = "daejeon"
    case gwangju = "gwangju"
    case suwon = "suwon"
    case ulsan = "ulsan"
    case seongnam = "seongnam"
    case bucheon = "bucheon"
    
    // Thaïlande
    case bangkok = "bangkok"
    case chiangMai = "chiang_mai"
    case phuket = "phuket"
    case pattaya = "pattaya"
    case hatYai = "hat_yai"
    case nakhonRatchasima = "nakhon_ratchasima"
    case udonThani = "udon_thani"
    case chonburi = "chonburi"
    case nakhonSiThammarat = "nakhon_si_thammarat"
    case khonKaen = "khon_kaen"
    
    // Vietnam
    case hoChiMinhCity = "ho_chi_minh_city"
    case hanoi = "hanoi"
    case daNang = "da_nang"
    case haiPhong = "hai_phong"
    case canTho = "can_tho"
    case hue = "hue"
    case nhaTrang = "nha_trang"
    case buonMaThuot = "buon_ma_thuot"
    case quyNhon = "quy_nhon"
    case vungTau = "vung_tau"
    
    // Inde
    case mumbai = "mumbai"
    case delhi = "delhi"
    case bangalore = "bangalore"
    case hyderabad = "hyderabad"
    case chennai = "chennai"
    case kolkata = "kolkata"
    case pune = "pune"
    case ahmedabad = "ahmedabad"
    case jaipur = "jaipur"
    case lucknow = "lucknow"
    
    // Égypte
    case cairo = "cairo"
    case alexandria = "alexandria"
    case giza = "giza"
    case sharmElSheikh = "sharm_el_sheikh"
    case luxor = "luxor"
    case aswan = "aswan"
    case hurghada = "hurghada"
    case portSaid = "port_said"
    case suez = "suez"
    case ismailia = "ismailia"
    
    var displayName: String {
        switch self {
        // France
        case .paris: return "Paris"
        case .lyon: return "Lyon"
        case .marseille: return "Marseille"
        case .toulouse: return "Toulouse"
        case .nice: return "Nice"
        case .nantes: return "Nantes"
        case .strasbourg: return "Strasbourg"
        case .montpellier: return "Montpellier"
        case .bordeaux: return "Bordeaux"

        case .reims: return "Reims"
        case .saintEtienne: return "Saint-Étienne"
        case .toulon: return "Toulon"
        case .leHavre: return "Le Havre"
        case .grenoble: return "Grenoble"
        case .dijon: return "Dijon"
        case .angers: return "Angers"
        case .saintDenis: return "Saint-Denis"
        case .nimes: return "Nîmes"
        case .saintDenisReunion: return "Saint-Denis (Réunion)"
        
        // Belgique
        case .brussels: return "Bruxelles"
        case .antwerp: return "Anvers"
        case .ghent: return "Gand"
        case .charleroi: return "Charleroi"
        case .liege: return "Liège"
        case .bruges: return "Bruges"
        case .namur: return "Namur"
        case .mons: return "Mons"

        case .aalst: return "Alost"
        
        // Luxembourg
        case .luxembourg: return "Luxembourg"
        
        // Suisse
        case .zurich: return "Zurich"
        case .geneva: return "Genève"

        case .bern: return "Berne"
        case .lausanne: return "Lausanne"
        case .winterthur: return "Winterthour"
        case .stGallen: return "Saint-Gall"
        case .lucerne: return "Lucerne"
        
        // Allemagne
        case .berlin: return "Berlin"
        case .hamburg: return "Hambourg"
        case .munich: return "Munich"
        case .cologne: return "Cologne"
        case .frankfurt: return "Francfort"
        case .stuttgart: return "Stuttgart"

        case .leipzig: return "Leipzig"
        case .dortmund: return "Dortmund"
        case .essen: return "Essen"
        
        // Italie
        case .rome: return "Rome"
        case .milan: return "Milan"
        case .naples: return "Naples"
        case .turin: return "Turin"
        case .palermo: return "Palerme"
        case .genoa: return "Gênes"
        case .bologna: return "Bologne"
        case .florence: return "Florence"
        case .bari: return "Bari"
        case .catania: return "Catane"
        
        // Espagne
        case .madrid: return "Madrid"
        case .barcelona: return "Barcelone"
        case .valencia: return "Valence"
        case .seville: return "Séville"
        case .zaragoza: return "Saragosse"
        case .malaga: return "Malaga"
        case .murcia: return "Murcie"
        case .palma: return "Palma"
        case .lasPalmas: return "Las Palmas"
        case .bilbao: return "Bilbao"
        
        // Pays-Bas
        case .amsterdam: return "Amsterdam"
        case .rotterdam: return "Rotterdam"
        case .theHague: return "La Haye"
        case .utrecht: return "Utrecht"
        case .eindhoven: return "Eindhoven"
        case .tilburg: return "Tilbourg"
        case .groningen: return "Groningue"
        case .breda: return "Breda"
        case .nijmegen: return "Nimègue"
        case .enschede: return "Enschede"
        
        // Royaume-Uni
        case .london: return "Londres"
        case .birmingham: return "Birmingham"
        case .leeds: return "Leeds"
        case .glasgow: return "Glasgow"
        case .sheffield: return "Sheffield"
        case .bradford: return "Bradford"
        case .edinburgh: return "Édimbourg"
        case .liverpool: return "Liverpool"
        case .manchester: return "Manchester"
        case .bristol: return "Bristol"

        // Tchéquie
        case .prague: return "Prague"

        // États-Unis
        case .newYork: return "New York"
        
        // Maroc
        case .casablanca: return "Casablanca"
        case .rabat: return "Rabat"
        case .marrakech: return "Marrakech"
        case .fez: return "Fès"
        case .tangier: return "Tanger"
        case .agadir: return "Agadir"
        case .meknes: return "Meknès"
        case .oujda: return "Oujda"
        case .kenitra: return "Kénitra"
        case .tetouan: return "Tétouan"
        
        // Turquie
        case .istanbul: return "Istanbul"
        case .ankara: return "Ankara"
        case .izmir: return "İzmir"
        case .bursa: return "Bursa"
        case .antalya: return "Antalya"
        case .adana: return "Adana"
        case .konya: return "Konya"
        case .gaziantep: return "Gaziantep"
        case .kayseri: return "Kayseri"
        case .mersin: return "Mersin"
        
        // Japon
        case .tokyo: return "Tokyo"
        case .osaka: return "Osaka"
        case .kyoto: return "Kyoto"
        case .yokohama: return "Yokohama"
        case .nagoya: return "Nagoya"
        case .sapporo: return "Sapporo"
        case .kobe: return "Kobe"
        case .fukuoka: return "Fukuoka"
        case .kawasaki: return "Kawasaki"
        case .saitama: return "Saitama"
        
        // Chine
        case .beijing: return "Pékin"
        case .shanghai: return "Shanghai"
        case .guangzhou: return "Guangzhou"
        case .shenzhen: return "Shenzhen"
        case .chengdu: return "Chengdu"
        case .tianjin: return "Tianjin"
        case .chongqing: return "Chongqing"
        case .nanjing: return "Nanjing"
        case .wuhan: return "Wuhan"
        case .xian: return "Xi'an"
        
        // Corée du Sud
        case .seoul: return "Séoul"
        case .busan: return "Busan"
        case .incheon: return "Incheon"
        case .daegu: return "Daegu"
        case .daejeon: return "Daejeon"
        case .gwangju: return "Gwangju"
        case .suwon: return "Suwon"
        case .ulsan: return "Ulsan"
        case .seongnam: return "Seongnam"
        case .bucheon: return "Bucheon"
        
        // Thaïlande
        case .bangkok: return "Bangkok"
        case .chiangMai: return "Chiang Mai"
        case .phuket: return "Phuket"
        case .pattaya: return "Pattaya"
        case .hatYai: return "Hat Yai"
        case .nakhonRatchasima: return "Nakhon Ratchasima"
        case .udonThani: return "Udon Thani"
        case .chonburi: return "Chonburi"
        case .nakhonSiThammarat: return "Nakhon Si Thammarat"
        case .khonKaen: return "Khon Kaen"
        
        // Vietnam
        case .hoChiMinhCity: return "Ho Chi Minh-Ville"
        case .hanoi: return "Hanoï"
        case .daNang: return "Da Nang"
        case .haiPhong: return "Haiphong"
        case .canTho: return "Can Tho"
        case .hue: return "Huế"
        case .nhaTrang: return "Nha Trang"
        case .buonMaThuot: return "Buôn Ma Thuột"
        case .quyNhon: return "Quy Nhơn"
        case .vungTau: return "Vũng Tàu"
        
        // Inde
        case .mumbai: return "Mumbai"
        case .delhi: return "Delhi"
        case .bangalore: return "Bangalore"
        case .hyderabad: return "Hyderabad"
        case .chennai: return "Chennai"
        case .kolkata: return "Kolkata"
        case .pune: return "Pune"
        case .ahmedabad: return "Ahmedabad"
        case .jaipur: return "Jaipur"
        case .lucknow: return "Lucknow"
        
        // Égypte
        case .cairo: return "Le Caire"
        case .alexandria: return "Alexandrie"
        case .giza: return "Gizeh"
        case .sharmElSheikh: return "Charm el-Cheikh"
        case .luxor: return "Louxor"
        case .aswan: return "Assouan"
        case .hurghada: return "Hurghada"
        case .portSaid: return "Port-Saïd"
        case .suez: return "Suez"
        case .ismailia: return "Ismaïlia"
        }
    }
    
    var flag: String {
        switch self {
        // France
        case .paris, .lyon, .marseille, .toulouse, .nice, .nantes, .strasbourg, .montpellier, .bordeaux, .reims, .saintEtienne, .toulon, .leHavre, .grenoble, .dijon, .angers, .saintDenis, .nimes, .saintDenisReunion:
            return "🇫🇷"
        
        // Belgique
        case .brussels, .antwerp, .ghent, .charleroi, .liege, .bruges, .namur, .mons, .aalst:
            return "🇧🇪"
        
        // Luxembourg
        case .luxembourg:
            return "🇱🇺"
        
        // Suisse
        case .zurich, .geneva, .bern, .lausanne, .winterthur, .stGallen, .lucerne:
            return "🇨🇭"
        
        // Allemagne
        case .berlin, .hamburg, .munich, .cologne, .frankfurt, .stuttgart, .leipzig, .dortmund, .essen:
            return "🇩🇪"
        
        // Italie
        case .rome, .milan, .naples, .turin, .palermo, .genoa, .bologna, .florence, .bari, .catania:
            return "🇮🇹"
        
        // Espagne
        case .madrid, .barcelona, .valencia, .seville, .zaragoza, .malaga, .murcia, .palma, .lasPalmas, .bilbao:
            return "🇪🇸"
        
        // Pays-Bas
        case .amsterdam, .rotterdam, .theHague, .utrecht, .eindhoven, .tilburg, .groningen, .breda, .nijmegen, .enschede:
            return "🇳🇱"
        
        // Royaume-Uni
        case .london, .birmingham, .leeds, .glasgow, .sheffield, .bradford, .edinburgh, .liverpool, .manchester, .bristol:
            return "🇬🇧"
        
        // États-Unis
        case .newYork:
            return "🇺🇸"
        
        // Maroc
        case .casablanca, .rabat, .marrakech, .fez, .tangier, .agadir, .meknes, .oujda, .kenitra, .tetouan:
            return "🇲🇦"

        // Tchéquie
        case .prague:
            return "🇨🇿"
        
        // Turquie
        case .istanbul, .ankara, .izmir, .bursa, .antalya, .adana, .konya, .gaziantep, .kayseri, .mersin:
            return "🇹🇷"
        
        // Japon
        case .tokyo, .osaka, .kyoto, .yokohama, .nagoya, .sapporo, .kobe, .fukuoka, .kawasaki, .saitama:
            return "🇯🇵"
        
        // Chine
        case .beijing, .shanghai, .guangzhou, .shenzhen, .chengdu, .tianjin, .chongqing, .nanjing, .wuhan, .xian:
            return "🇨🇳"
        
        // Corée du Sud
        case .seoul, .busan, .incheon, .daegu, .daejeon, .gwangju, .suwon, .ulsan, .seongnam, .bucheon:
            return "🇰🇷"
        
        // Thaïlande
        case .bangkok, .chiangMai, .phuket, .pattaya, .hatYai, .nakhonRatchasima, .udonThani, .chonburi, .nakhonSiThammarat, .khonKaen:
            return "🇹🇭"
        
        // Vietnam
        case .hoChiMinhCity, .hanoi, .daNang, .haiPhong, .canTho, .hue, .nhaTrang, .buonMaThuot, .quyNhon, .vungTau:
            return "🇻🇳"
        
        // Inde
        case .mumbai, .delhi, .bangalore, .hyderabad, .chennai, .kolkata, .pune, .ahmedabad, .jaipur, .lucknow:
            return "🇮🇳"
        
        // Égypte
        case .cairo, .alexandria, .giza, .sharmElSheikh, .luxor, .aswan, .hurghada, .portSaid, .suez, .ismailia:
            return "🇪🇬"
        }
    }
    
    var country: String {
        switch self {
        case .paris, .lyon, .marseille, .toulouse, .nice, .nantes, .strasbourg, .montpellier, .bordeaux, .reims, .saintEtienne, .toulon, .leHavre, .grenoble, .dijon, .angers, .saintDenis, .nimes, .saintDenisReunion:
            return "France"
        case .brussels, .antwerp, .ghent, .charleroi, .liege, .bruges, .namur, .mons, .aalst:
            return "Belgique"
        case .luxembourg:
            return "Luxembourg"
        case .zurich, .geneva, .bern, .lausanne, .winterthur, .stGallen, .lucerne:
            return "Suisse"
        case .berlin, .hamburg, .munich, .cologne, .frankfurt, .stuttgart, .leipzig, .dortmund, .essen:
            return "Allemagne"
        case .rome, .milan, .naples, .turin, .palermo, .genoa, .bologna, .florence, .bari, .catania:
            return "Italie"
        case .madrid, .barcelona, .valencia, .seville, .zaragoza, .malaga, .murcia, .palma, .lasPalmas, .bilbao:
            return "Espagne"
        case .amsterdam, .rotterdam, .theHague, .utrecht, .eindhoven, .tilburg, .groningen, .breda, .nijmegen, .enschede:
            return "Pays-Bas"
        case .london, .birmingham, .leeds, .glasgow, .sheffield, .bradford, .edinburgh, .liverpool, .manchester, .bristol:
            return "Royaume-Uni"
        case .prague:
            return "Tchéquie"
        case .newYork:
            return "États-Unis"
        case .casablanca, .rabat, .marrakech, .fez, .tangier, .agadir, .meknes, .oujda, .kenitra, .tetouan:
            return "Maroc"
        case .istanbul, .ankara, .izmir, .bursa, .antalya, .adana, .konya, .gaziantep, .kayseri, .mersin:
            return "Turquie"
        case .tokyo, .osaka, .kyoto, .yokohama, .nagoya, .sapporo, .kobe, .fukuoka, .kawasaki, .saitama:
            return "Japon"
        case .beijing, .shanghai, .guangzhou, .shenzhen, .chengdu, .tianjin, .chongqing, .nanjing, .wuhan, .xian:
            return "Chine"
        case .seoul, .busan, .incheon, .daegu, .daejeon, .gwangju, .suwon, .ulsan, .seongnam, .bucheon:
            return "Corée du Sud"
        case .bangkok, .chiangMai, .phuket, .pattaya, .hatYai, .nakhonRatchasima, .udonThani, .chonburi, .nakhonSiThammarat, .khonKaen:
            return "Thaïlande"
        case .hoChiMinhCity, .hanoi, .daNang, .haiPhong, .canTho, .hue, .nhaTrang, .buonMaThuot, .quyNhon, .vungTau:
            return "Vietnam"
        case .mumbai, .delhi, .bangalore, .hyderabad, .chennai, .kolkata, .pune, .ahmedabad, .jaipur, .lucknow:
            return "Inde"
        case .cairo, .alexandria, .giza, .sharmElSheikh, .luxor, .aswan, .hurghada, .portSaid, .suez, .ismailia:
            return "Égypte"
        }
    }
}

enum TourDifficulty: String, CaseIterable, Codable, Equatable {
    case easy = "easy"
    case moderate = "moderate"
    case challenging = "challenging"
    
    var displayName: String {
        switch self {
        case .easy: return "Facile"
        case .moderate: return "Modéré"
        case .challenging: return "Difficile"
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "1.circle"
        case .moderate: return "2.circle"
        case .challenging: return "3.circle"
        }
    }
}

// MARK: - GuidedTour Extensions
extension GuidedTour {
    /// Retourne une copie du tour avec les arrêts optimisés (ordre le plus court, nearest neighbor)
    func optimizedTour(from start: CLLocationCoordinate2D?) -> GuidedTour {
        guard stops.count > 1 else { return self }
        let startCoord = start ?? stops.first!.location.coordinate
        var remaining = stops
        var route: [TourStop] = []
        var currentCoord = startCoord
        while !remaining.isEmpty {
            let nearestIdx = remaining.enumerated().min(by: { a, b in
                let distA = CLLocation(latitude: currentCoord.latitude, longitude: currentCoord.longitude).distance(from: CLLocation(latitude: a.element.location.latitude, longitude: a.element.location.longitude))
                let distB = CLLocation(latitude: currentCoord.latitude, longitude: currentCoord.longitude).distance(from: CLLocation(latitude: b.element.location.latitude, longitude: b.element.location.longitude))
                return distA < distB
            })?.offset ?? 0
            let next = remaining.remove(at: nearestIdx)
            route.append(next)
            currentCoord = next.location.coordinate
        }
        return GuidedTour(
            id: id,
            title: title,
            city: city,
            description: description,
            duration: duration,
            difficulty: difficulty,
            stops: route,
            imageURL: imageURL,
            rating: rating,
            price: price,
            startLocation: start,
            optimizedStops: route,
            totalDistance: totalDistance,
            estimatedTravelTime: estimatedTravelTime
        )
    }
}

// MARK: - Beat Boredom Models
struct ActivityFilter: Codable {
    var category: LocationCategory?
    var maxDistance: Double // in kilometers
    var transportMode: TransportMode
    var availableTime: TimeInterval // in seconds
    var timeSlot: TimeSlot?
}

struct TimeSlot: Codable {
    let startTime: Date
    let endTime: Date
}

struct ActivitySuggestion: Codable, Identifiable {
    let id: String
    let location: Location
    let estimatedDuration: TimeInterval
    let distanceFromUser: Double
    let matchScore: Double
    let reasonsToVisit: [String]
    let currentlyOpen: Bool
}

// MARK: - Adventurer Mode Models
struct AdventureRequest: Codable {
    let userLocation: String
    let excludedCategories: [LocationCategory]
    let maxDistance: Double
    let preferredDuration: TimeInterval?
}

struct Adventure: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let startLocation: Location?
    let locations: [Location]
    let surpriseElement: String
    let estimatedDuration: TimeInterval
    let totalDistance: Double
    let difficulty: TourDifficulty
    let createdAt: Date
    let missingCategories: [LocationCategory] // Catégories non trouvées
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, locations, difficulty, totalDistance, estimatedDuration
        case surpriseElement = "surprise_element"
        case createdAt = "created_at"
        case startLocation = "start_location"
        case missingCategories = "missing_categories"
    }
} 