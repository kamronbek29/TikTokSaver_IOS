//
//  ViewController.swift
//  TikTokSaver
//
//  Created by Kamronbek on 8/3/20.
//  Copyright © 2020 Kamronbek. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var videoText: UILabel?
    @IBOutlet weak var actionText: UILabel?
    @IBOutlet weak var videoImage: UIImageView?
    
    @IBAction func clickedDownloadButton(_ sender: Any) {
        let user_text: String? = self.textField.text
        
        if user_text != nil {
            var url_to_download: String! = user_text

            if url_to_download.contains("tiktok") {
                self.actionText?.text = "Скачивание началось"
                url_to_download = url_to_download.replacingOccurrences(of: " ", with: "")
                let is_sucess: Bool = downloadVideo(tiktok_url: url_to_download)
                
                if is_sucess {
                    self.actionText?.text = "Скачивание завершено"
                } else {
                    self.actionText?.text = "Скачивание не удалось"
                }
            } else {
                return
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.hideKeyboardWhenTappedAround()
    }
    
    func getUrlContent(tiktok_url: String) -> String {
        let url = URL(string: tiktok_url)!
        let request = URLRequest(url: url)
        let session = URLSession.shared
        var response_data: String! = ""
        
        let sem = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request)
        {
            (data, response, error) in
            if let error = error {
                print(error , "error")
            } else if let data = data {
                let response_content = String(data: data, encoding: .utf8)!
                response_data = response_content
            } else {
                print("Something went wrong")
            }
            sem.signal()
        }
        task.resume()
        sem.wait()
        
        return response_data
    }


    func getVideoInfo(response_data: String) -> (String, String, String) {
        let page_json_part = response_data.components(separatedBy: "__INIT_PROPS__ = ")[1]
        let page_json_str = page_json_part.components(separatedBy: "</script>")[0]
        let video_data = page_json_str.components(separatedBy: "videoData")[1]

        let video_url: String = video_data.components(separatedBy: "urls")[1].components(separatedBy: "[\"")[1].components(separatedBy: "\"]")[0]
        let video_image: String = video_data.components(separatedBy: "coversOrigin")[1].components(separatedBy: "[\"")[1].components(separatedBy: "\"]")[0]
        let video_title: String = video_data.components(separatedBy: "\"text\":\"")[1].components(separatedBy: "\"")[0]
        
        return (video_url, video_image, video_title)
    }


    func downloadVideo(tiktok_url: String) -> Bool {
        let response_data = getUrlContent(tiktok_url: tiktok_url)
        
        if response_data != "" {
            let video_info = getVideoInfo(response_data: response_data)
            if video_info.1 != "" {
                DispatchQueue.main.async {
                    self.videoText?.text = video_info.2
                    if let url = URL(string: video_info.1) {
                        if let data = try? Data(contentsOf: url) {
                            print(video_info.1, "image url")
                            self.videoImage?.image = UIImage(data: data)
                        }
                    }
                }
                
                DispatchQueue.global(qos: .background).async {
                    if let url = URL(string: video_info.0),
                        let urlData = NSData(contentsOf: url) {
                        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
                        let filePath="\(documentsPath)/tempFile.mp4"
                        DispatchQueue.main.async {
                            urlData.write(toFile: filePath, atomically: true)
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                            })
                            { completed, error in
                                if completed {
                                    print("video saved!!")
                                }
                            }
                        }
                    }
                }
            }
            
            return true
        } else {
            print(response_data, "no response")
        }
        return false
    }

}


extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
