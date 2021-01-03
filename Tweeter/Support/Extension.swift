//
//  Extension.swift
//  Tweeter
//
//  Created by Chien on 2019/11/6.
//  Copyright © 2019 Chien. All rights reserved.
//

import Foundation
import FirebaseDatabase

extension DataSnapshot {

    // Function for Decoding by Generic Type
    func decode<Type: Codable>() throws -> [Type] {

        var totalDecodeData: [Type] = []
        guard let totalValueDictionary = value as? [String: Any] else { throw RequestError.FetchObjectIsNotDictionary }
        
        for eachKey in totalValueDictionary.keys {
            guard let eachValueDictionary = totalValueDictionary[eachKey] as? [String: Any] else { throw RequestError.FetchObjectIsNotDictionary }
            
            do {

                let eachJSONData = try JSONSerialization.data(withJSONObject: eachValueDictionary)
                let eachDecodeData = try JSONDecoder().decode(Type.self, from: eachJSONData)
                totalDecodeData.append(eachDecodeData)
            } catch {
                throw RequestError.FetchDecodeFail
            }
        }

        return totalDecodeData
    }
}

extension UIColor {

    // Function for Setting Color Using Hex Code
    convenience init(hexCode: Int) {

        let redValue = (hexCode >> 16) & 0xFF
        let greenValue = (hexCode >> 8) & 0xFF
        let blueValue = hexCode & 0xFF
        
        assert(redValue >= 0 && redValue <= 255, "Invalid Red Value")
        assert(greenValue >= 0 && greenValue <= 255, "Invalid Green Value")
        assert(blueValue >= 0 && blueValue <= 255, "Invalid Blue Value")
        
        self.init(red: CGFloat(redValue) / 255, green: CGFloat(greenValue) / 255, blue: CGFloat(blueValue) / 255, alpha: 1)
    }
}

extension UIView {

    // Function for Rounding Corner Easily
    func roundedCorner(by radius: CGFloat) {

        self.layer.cornerRadius = radius
        self.clipsToBounds = true
    }
    
    // Function for Rendering Specific View's Shadow Color
    func usingShadowColor(withHexCode thisColor: Int = 0xA0A0A0) {
        
        self.clipsToBounds = false

        self.layer.shadowColor = UIColor(hexCode: thisColor).cgColor
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = .zero
    }
    
    // Function for Deleting Specific View's Shadow Color
    func removeShadowColor() {
        
        self.layer.shadowColor = nil
        self.layer.shadowRadius = 0
        self.layer.shadowOpacity = 0
    }
}

extension UIImageView {

    // Function for Helping Load Image
    func loadImage(from imageURL: URL?, completion: @escaping(_ error: FetchImageError?) -> Void) {
        
        if imageURL == nil { completion(FetchImageError.ObjectIsNil) }

        let imagePhotoFromCache = AppDelegate.myCache.object(forKey: imageURL!.absoluteString as NSString) as? UIImage
        
        if imagePhotoFromCache == nil {

            // Means there is no UIImage in cache
            URLSession.shared.dataTask(with: imageURL!) { (imageData, _, fetchError) in
                guard fetchError == nil else {
                    completion(FetchImageError.FetchURLFail(thisURL: imageURL!))
                    return
                }
                
                guard let imagePhoto = UIImage(data: imageData!) else {
                    completion(FetchImageError.ObjectIsNil)
                    return
                }

                // Store this UIImage into cache
                AppDelegate.myCache.setObject(imagePhoto, forKey: imageURL!.absoluteString as NSString)
                
                DispatchQueue.main.async {
                    
                    self.image = imagePhoto
                    self.contentMode = .scaleAspectFit
                    completion(nil)
                }
            }.resume()
        } else {
            
            // Means there is UIImage in cache
            self.image = imagePhotoFromCache!
            self.contentMode = .scaleAspectFit
            completion(nil)
        }
    }
}

extension UIViewController {

    // Function for Showing AlertController with Default "Okay"
    func ShowAlert(with title: String, message: String,
                   totalActions: [UIAlertAction] = [UIAlertAction(title: "Okay", style: .default, handler: nil)]) {

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for eachAction in totalActions {
            alertController.addAction(eachAction)
        }
        
        present(alertController, animated: true, completion: nil)
    }
}
