import Foundation
import CoreLocation
import Combine

class WeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var temperature: Double? = nil
    @Published var city: String? = nil
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private let apiKey = "YOUR_OPENWEATHERMAP_API_KEY" // <-- Replace with your API key
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestWeather() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        fetchWeather(for: location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    private func fetchWeather(for coordinate: CLLocationCoordinate2D) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Weather fetch error: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                self?.temperature = response.main.temp
                self?.city = response.name
            })
            .store(in: &cancellables)
    }
}

struct WeatherResponse: Codable {
    struct Main: Codable { let temp: Double }
    let main: Main
    let name: String
} 