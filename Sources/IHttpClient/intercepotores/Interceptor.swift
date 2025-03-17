//
//  Interceptor.swift
//  Shopper-BE
//
//  Created by Stepan Bezhuk on 14.03.2025.
//

import Foundation

// MARK: - Interceptor Protocol
public protocol Interceptor {
  func willSend(request: inout URLRequest)
  func didReceive(response: URLResponse, data: Data)
  func onError(
    response: HTTPURLResponse,
    data: Data,
    originalRequest: (path: String, method: HTTPMethod, parameters: [String: Any]?, headers: [String: String]?),
    client: IHttpClient
  ) async throws -> Any?
}

// Base implementation to reduce required code in implementations
extension Interceptor {
  func didReceive(response: URLResponse, data: Data) {}

  func onError(
    response: HTTPURLResponse,
    data: Data,
    originalRequest: (path: String, method: HTTPMethod, parameters: [String: Any]?, headers: [String: String]?),
    client: IHttpClient
  ) async throws -> Any? {
    return nil
  }
}
