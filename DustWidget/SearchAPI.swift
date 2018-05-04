//
//  SearchStationAPI.swift
//  TestWidget
//
//  Created by 유병재 on 2018. 4. 30..
//  Copyright © 2018년 유병재. All rights reserved.
//

import Foundation
import Moya

private extension String {
    var URLEscapedString: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}

enum SearchAPI {
    case station(name: String)
}

extension SearchAPI: TargetType {

    var serviceKey: String { return "WrJAts8SBMI9hXY7hbz94ipn6EiCz/9s/N+9inWYeJUwfDLZMcAKO4JblCFCG0w6Pp0khCYhecxV5+ZP9eT22Q==" }
    var baseURL: URL { return URL(string: "http://openapi.airkorea.or.kr/openapi/services/rest/ArpltnInforInqireSvc")! }
    var path: String {
        switch self {
        case .station:
            return "/getMsrstnAcctoRltmMesureDnsty"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .station:
            return .get
        }
    }
    
    var parameters: [String: Any]? {
        return nil
    }
    
    var task: Task {
        switch self {
        case .station(let name):
            return .requestParameters(parameters: ["serviceKey": self.serviceKey,
                                                   "numOfRows": 10,
                                                   "pageSize": 10,
                                                   "pageNo": 1,
                                                   "startPage": 1,
                                                   "stationName": name,
                                                   "dataTerm": "DAILY",
                                                   "ver": 1.3,
                                                   "_returnType": "json"], encoding: URLEncoding.queryString)
        }
    }
    
    var sampleData: Data {
        switch self {
        case .station:
            return "}".data(using: .utf8)!
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var parameterEncoding: ParameterEncoding {
        return JSONEncoding.default
    }
}
