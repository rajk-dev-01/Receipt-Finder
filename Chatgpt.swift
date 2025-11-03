//
//  Chatgpt.swift
//  Receipt Finder
//
//  Created by Rajahiresh Kalva on 10/2/25.
//

import Foundation
import SwiftUI

class ChatGPTService {
    let openAIKey = "YOUR_OPENAI_KEY_HERE"    
    func extractReceiptInfo(from text: String, completion: @escaping ([String: Any]?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let prompt = """
        You are a receipt parser. Extract the following fields from this text:
        - Store Name
        - Name(Customer Name only if not available mention NOT AVAILABLE)
        - Date
        - Total Amount
        - Address
        - Payment Method
        - Phone Number
        - Receipt Id
        - Tracking Numbers(numbers used to track packages available only for package receipts if not available mention NOT AVAILABLE)
        Return them strictly as JSON with keys: storeName, date, totalAmount, address, paymentMethod, name, phoneNumber, receiptId , tracking.
        No extra text, no explanation.

        Receipt text:
        \(text)
        """
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a helpful receipt parser."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                // ✅ Extract JSON only (between first { and last })
                if let start = content.firstIndex(of: "{"),
                   let end = content.lastIndex(of: "}") {
                    let jsonString = String(content[start...end])
                    
                    if let contentData = jsonString.data(using: .utf8),
                       let parsed = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any] {
                        completion(parsed)
                        return
                    }
                }
                
                completion(nil)
            }
        }.resume()
    }
}
