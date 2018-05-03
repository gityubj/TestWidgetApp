//
//  TodayViewController.swift
//  TestWidget
//
//  Created by 유병재 on 2018. 4. 27..
//  Copyright © 2018년 유병재. All rights reserved.
//

import UIKit
import NotificationCenter
import Moya
import RxSwift
import RxCocoa
import CoreLocation

struct InfoList: Codable {
    var dataList : [Infomation]
    
    enum CodingKeys : String, CodingKey {
        case dataList = "list"
    }
    
    init() { self.dataList = [] }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dataList = try values.decode([Infomation].self, forKey: .dataList)
    }
}

struct Infomation: Codable {
    var dataTime: String
    var pm10Value: String //미세먼지
    var pm25Value: String //초미세먼지
    var so2Value: String //아황산가스 농도
    var coValue: String //일산화탄소 농도
    var o3Value: String //오존 농도
    var no2Value: String //이산화질소 농도

    enum CodingKeys : String, CodingKey {
        case dataTime
        case pm10Value
        case pm25Value
        case so2Value
        case coValue
        case o3Value
        case no2Value
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dataTime = (try? values.decode(String.self, forKey: .dataTime)) ?? ""
        pm10Value = (try? values.decode(String.self, forKey: .pm10Value)) ?? ""
        pm25Value = (try? values.decode(String.self, forKey: .pm25Value)) ?? ""
        so2Value = (try? values.decode(String.self, forKey: .so2Value)) ?? ""
        coValue = (try? values.decode(String.self, forKey: .coValue)) ?? ""
        o3Value = (try? values.decode(String.self, forKey: .o3Value)) ?? ""
        no2Value = (try? values.decode(String.self, forKey: .no2Value)) ?? ""
    }
}

class InfoCollectionCell : UICollectionViewCell {
    @IBOutlet var dataLabel : UILabel?
    @IBOutlet var pm10Label : UILabel? //미세먼지
    @IBOutlet var pm25Label : UILabel? //초미세먼지
    @IBOutlet var so2Label : UILabel? //아황산가스
    @IBOutlet var coLabel : UILabel? //일산화탄소
    @IBOutlet var o3Label : UILabel? //오존
    @IBOutlet var no2Label : UILabel? //이산화질소
    @IBOutlet var pm10Title : UILabel?
    @IBOutlet var pm25Title : UILabel?
    
    func configure(node: Infomation) {
        let pm10IntValue : Int = Int(node.pm10Value)!
        let pm25IntValue : Int = Int(node.pm25Value)!
        self.dataLabel?.text = "서초구 \(node.dataTime) 정보"
        self.pm10Label?.text = "미세먼지 \(node.pm10Value)㎍/㎥"
        self.pm25Label?.text = "초미세먼지 \(node.pm25Value)㎍/㎥"
//        self.so2Label?.text = "아황산가스 \(node.so2Value)㎍/㎥"
//        self.coLabel?.text = "일산화탄소 \(node.coValue)㎍/㎥"
//        self.o3Label?.text = "오존 \(node.o3Value)㎍/㎥"
//        self.no2Label?.text = "이산화질소 \(node.no2Value)㎍/㎥"
        if 0 < pm10IntValue, 15 > pm10IntValue {
             self.pm10Title?.text = "최고"
        } else if 16 < pm10IntValue, 30 > pm10IntValue {
             self.pm10Title?.text = "좋음"
        } else if 31 < pm10IntValue, 40 > pm10IntValue {
             self.pm10Title?.text = "양호"
        } else if 41 < pm10IntValue, 50 > pm10IntValue {
             self.pm10Title?.text = "보통"
        } else if 51 < pm10IntValue, 75 > pm10IntValue {
            self.pm10Title?.text = "나쁨"
        } else if 76 < pm10IntValue, 100 > pm10IntValue {
             self.pm10Title?.text = "상당히 나쁨"
        } else if 101 < pm10IntValue, 150 > pm10IntValue {
            self.pm10Title?.text = "매우 나쁨"
        } else if 151 < pm10IntValue {
            self.pm10Title?.text = "최악"
        }
        
        if 0 < pm25IntValue, 8 > pm25IntValue {
            self.pm25Title?.text = "최고"
        } else if 9 < pm25IntValue, 15 > pm25IntValue {
            self.pm25Title?.text = "좋음"
        } else if 16 < pm25IntValue, 20 > pm25IntValue {
            self.pm25Title?.text = "양호"
        } else if 21 < pm25IntValue, 25 > pm25IntValue {
            self.pm25Title?.text = "보통"
        } else if 26 < pm25IntValue, 37 > pm25IntValue {
            self.pm25Title?.text = "나쁨"
        } else if 38 < pm25IntValue, 50 > pm25IntValue {
            self.pm25Title?.text = "상당히 나쁨"
        } else if 51 < pm25IntValue, 75 > pm25IntValue {
            self.pm25Title?.text = "매우 나쁨"
        } else if 76 < pm25IntValue {
            self.pm25Title?.text = "최악"
        }
    }
}

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet var mainLabel : UILabel?
    @IBOutlet var collectionView : UICollectionView?
    
    let locationManager : CLLocationManager = CLLocationManager()
    let disposeBag      : DisposeBag        = DisposeBag()
    
    var location : BehaviorRelay<CLLocationCoordinate2D> = BehaviorRelay<CLLocationCoordinate2D>(value: CLLocationCoordinate2D())
    var infoArr  : BehaviorRelay<[Infomation]> = BehaviorRelay<[Infomation]>(value: [])

    static let provider = MoyaProvider<SearchAPI>().rx
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        if let location = self.locationManager.location { self.location.accept(location.coordinate) }

        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        guard let collectionView = self.collectionView else { return }
        
        let locationObserver = self.location.asObservable().map { return self.convertAddress(location: $0, completion: )}
        locationObserver.subscribe(onNext: { (value) in
            self.loadStationInfo(city: value)
        }).disposed(by: disposeBag)
        
        self.infoArr.bind(to: collectionView.rx.items) { (collectionView, row, item) in
            let indexPath = IndexPath(row: row, section: 0)
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "infoCell", for: indexPath) as? InfoCollectionCell {
                cell.configure(node: item)
                return cell
            }
            return UICollectionViewCell()}.disposed(by: disposeBag)
        

//        self.location.asObservable().map { return self.convertAddress(location: $0)}.flatMap { self.loadStationInfo(city: $0)}
//            .bind(to: collectionView.rx.items) { (collectionView, row, item) in
//                let indexPath = IndexPath(row: row, section: 0)
//                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "infoCell", for: indexPath) as? InfoCollectionCell {
//                    cell.configure(node: item)
//                    return cell
//                }
//                return UICollectionViewCell()}.disposed(by: disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        let expanded = activeDisplayMode == .expanded
        preferredContentSize = expanded ? CGSize(width: maxSize.width, height: 200) : maxSize
    }
    
//    func loadStationInfo(city:String) -> Observable<[Infomation]> {
//        return TodayViewController.provider.request(.station(name: city))
//            .filter(statusCode: 200)
//            .map(InfoList.self)
//            .map{ return $0.dataList }.asObservable()
//    }
    func loadStationInfo(city:String) {
        let request = TodayViewController.provider.request(.station(name: city))
            .filter(statusCode: 200)
            .map(InfoList.self)
            .map{ return $0.dataList }.asObservable()
        request.subscribe(onNext: { (infoArr) in
            self.infoArr.accept(infoArr)
        }).disposed(by: disposeBag)
        
    }

    typealias ConvertAddressCompletion = (String) -> Void

    func convertAddress(location: CLLocationCoordinate2D, completion: @escaping ConvertAddressCompletion) {
        let findLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let geocoder = CLGeocoder()
        let locale = Locale(identifier: "ko_KR")
        if #available(iOSApplicationExtension 11.0, *) {
            geocoder.reverseGeocodeLocation(findLocation, preferredLocale: locale) { (place, _) in
                if let locality = place?.first?.locality {
                    completion(locality)
                }
            }
        } else {
            geocoder.reverseGeocodeLocation(findLocation) { (place, error) in
                if let locality = place?.first?.locality {
                    completion(locality)
                }
            }
        }
    }
    
    @IBAction func goToApp() {
        let appUrl = URL(string: "testWidgetApp://")
        self.extensionContext?.open(appUrl!, completionHandler: nil)
    }
}

extension TodayViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.locationManager.stopUpdatingLocation()
            self.location.accept(location.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { print("location fail \(error)") }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var shouldAllow = false
        switch status {
        case .denied:
            print("denied")
        case .restricted:
            print("restricted")
        case .notDetermined:
            print("notDetermined")
        default:
            shouldAllow = true
        }
        if shouldAllow {
            self.locationManager.requestLocation()
        }
    }
}