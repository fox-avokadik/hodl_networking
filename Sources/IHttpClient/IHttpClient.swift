//
//  IHttpClient.swift
//  Shopper-BE
//
//  Created by Stepan Bezhuk on 14.03.2025.
//

import Foundation

public class IHttpClient {
  private let session: URLSession
  private let baseURL: URL
  private var interceptors: [Interceptor] = []
  
  public init(baseURL: String, session: URLSession = .shared) {
    self.baseURL = URL(string: baseURL)!
    self.session = session
  }
  
  public func addInterceptor(_ interceptor: Interceptor) {
    interceptors.append(interceptor)
  }
  
  public func request<T: Decodable>(
    _ path: String,
    method: HTTPMethod = .get,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil
  ) async throws -> HTTPResponse<T> {
    
    var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
    urlRequest.httpMethod = method.rawValue
    headers?.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
    
    if let parameters = parameters {
      urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    // Apply interceptors before sending the request
    for interceptor in interceptors {
      interceptor.willSend(request: &urlRequest)
    }
    
    do {
      let (data, response) = try await session.data(for: urlRequest)
      
      // Apply interceptors after receiving the response
      for interceptor in interceptors {
        interceptor.didReceive(response: response, data: data)
      }
      
      guard !data.isEmpty else {
        throw HTTPError.unknown
      }
      
      if let httpResponse = response as? HTTPURLResponse {
        // We send the response to interceptors for error handling
        for interceptor in interceptors {
          if let retriedResponse = try? await interceptor.onError(
            response: httpResponse,
            data: data,
            originalRequest: (path: path, method: method, parameters: parameters, headers: headers),
            client: self
          ) as? HTTPResponse<T> {
            return retriedResponse
          }
        }
        
        // Standard error handling if no interceptor has handled the error
        switch httpResponse.statusCode {
        case 300..<500:
          let clientErrorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
          throw HTTPError.clientError(httpResponse.statusCode, clientErrorResponse)
        case 500..<600:
          throw HTTPError.serverError(httpResponse.statusCode)
        default:
          break
        }
      }
      
      let decodedData = try JSONDecoder().decode(T.self, from: data)
      return HTTPResponse(data: decodedData, response: response)
      
    } catch {
      throw error
    }
  }
  
  // Helper method for sending a "pure" request without interceptors
  // Used in TokenRefreshInterceptor to prevent recursion
  public func performRawRequest<T: Decodable>(
    _ path: String,
    method: HTTPMethod = .get,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil
  ) async throws -> HTTPResponse<T> {
    var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
    urlRequest.httpMethod = method.rawValue
    headers?.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
    
    if let parameters = parameters {
      urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    let (data, response) = try await session.data(for: urlRequest)
    
    guard !data.isEmpty, let httpResponse = response as? HTTPURLResponse else {
      throw HTTPError.unknown
    }
    
    if (400..<600).contains(httpResponse.statusCode) {
      throw HTTPError.clientError(httpResponse.statusCode, nil)
    }
    
    let decodedData = try JSONDecoder().decode(T.self, from: data)
    return HTTPResponse(data: decodedData, response: response)
  }
}
