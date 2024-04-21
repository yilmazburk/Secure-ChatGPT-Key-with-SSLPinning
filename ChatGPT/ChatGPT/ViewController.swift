//
//  ViewController.swift
//  ChatGPT
//
//  Created by Burkan Yılmaz on 21.04.2024.
//

import UIKit
import Security

class ViewController: UIViewController {

    var pinnedCertificates: [Data]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if let certificateData = loadCertificate(filename: "api.openai.com") {
            pinnedCertificates = [certificateData]
        }
        
        getModels()
    }

    // Sertifikaları Bundle'dan okuyorum
    func loadCertificate(filename: String) -> Data? {
        guard let path = Bundle.main.path(forResource: filename, ofType: "cer") else {
            return nil
        }
        return try? Data(contentsOf: URL(fileURLWithPath: path))
    }
    
    private func getModels() {
        let url = URL(string: "https://api.openai.com/v1/models")!
        let token = "YOUR-API-KEY"
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"

        var urlSession = URLSession.shared
        if let pinnedCertificates = pinnedCertificates, !pinnedCertificates.isEmpty {
            urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
        urlSession.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            print(String(data: data, encoding: .utf8) ?? "Invalid JSON")
        }.resume()
    }
}

extension ViewController: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }

            var error: CFError?
            let status = SecTrustEvaluateWithError(serverTrust, &error)
            if status, error == nil {
                if let certificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] {
                    let serverCertificatesDataList = certificates.map { SecCertificateCopyData($0) as Data }
                    for serverCertificateData in serverCertificatesDataList {
                        if let pinnedCertificate = self.pinnedCertificates, pinnedCertificate.contains(serverCertificateData) {
                            print("Sertifika doğrulandı, bağlantı güvenli.")
                            let credential = URLCredential(trust: serverTrust)
                            completionHandler(.useCredential, credential)
                            return
                        }
                    }
                }
            }

            print("Sertifika doğrulanamadı, bağlantı reddedildi.")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
}


