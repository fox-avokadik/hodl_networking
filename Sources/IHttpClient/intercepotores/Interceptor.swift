//
//  Interceptor.swift
//  Shopper-BE
//
//  Created by Stepan Bezhuk on 14.03.2025.
//

import Foundation

// MARK: - Interceptor Protocol
public protocol Interceptor: Sendable {
  func willSend(request: inout URLRequest)
  func didReceive(response: URLResponse, data: Data)
  func onError<T: Decodable>(
    response: HTTPURLResponse,
    data: Data,
    originalRequest: (path: String, method: HTTPMethod, parameters: [String: Sendable]?, headers: [String: String]?),
    client: IHttpClient
  ) async throws -> HTTPResponse<T>?
}

// Base implementation to reduce required code in implementations
extension Interceptor {
  func didReceive(response: URLResponse, data: Data) {}
  
  func onError<T: Decodable>(
    response: HTTPURLResponse,
    data: Data,
    originalRequest: (path: String, method: HTTPMethod, parameters: [String: Sendable]?, headers: [String: String]?),
    client: IHttpClient
  ) async throws -> HTTPResponse<T>? {
    return nil
  }
}
