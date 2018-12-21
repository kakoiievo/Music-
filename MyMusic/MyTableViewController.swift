//
//  MyTableViewController.swift
//  MyMusic
//
//  Created by Yung on 2018/12/21.
//  Copyright © 2018 perkinsung. All rights reserved.
//

import UIKit


/*
//參考資訊。https://medium.com/%E5%BD%BC%E5%BE%97%E6%BD%98%E7%9A%84-swift-ios-app-%E9%96%8B%E7%99%BC%E5%95%8F%E9%A1%8C%E8%A7%A3%E7%AD%94%E9%9B%86/%E5%88%A9%E7%94%A8-swift-4-%E7%9A%84-jsondecoder-%E5%92%8C-codable-%E8%A7%A3%E6%9E%90-json-%E5%92%8C%E7%94%9F%E6%88%90%E8%87%AA%E8%A8%82%E5%9E%8B%E5%88%A5%E8%B3%87%E6%96%99-ee793622629e
 
    https://itunes.apple.com/search?term=薛之謙&media=music
 */

//以自訂結構對應到JSON每一筆的key值(可以只要取得所關心的部分)
struct Song: Codable {
    var artistName: String
    var trackName: String
    var collectionName: String?
    var previewUrl: URL
    var artworkUrl100: URL
    var releaseDate: Date
    
    //var trackPrice: Double?
    //var isStreamable: Bool?
}

//經由JSON最外層的資料
struct SongResults: Codable {
    
    //API 下載後的ＪＳＯＮ 第一層的是resultCount
    var resultCount: Int
    
    //在下一層就是要查詢的項目 裡面包的就是 上面結構(Song)
    var results: [Song]
}


class MyTableViewController: UITableViewController
{
    //宣告由JSON資料曾接進來的 離線資料集
    var songList = [Song]()
    
    //目前點選的資料行 (觸發prepare)
    var currentRow = 0

    
    //MARK: - viewLife
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let urlStr = "https://itunes.apple.com/search?term=MCHOTDOG&media=music".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: urlStr)
        {
            let task = URLSession.shared.dataTask(with: url) { (jsondata, response , error) in
                
                //初始化JSON的解碼器(decoder)
                let decoder = JSONDecoder()
                
                //設定解碼器所使用的日期格式
                decoder.dateDecodingStrategy = .iso8601
                if let jdata = jsondata, let songResults = try?
                    
                    //幫當確認有拿到ＪＳＯＮ資料時。將資料解碼到自訂結構『SongResults常數』裡面
                    decoder.decode(SongResults.self, from: jdata)
                {
//                    for song in songResults.results
//                    {
//                        print(song)
//                    }
                    
                    //將解碼後的陣列(其中一個結構成員屬性的說值)抄錄到此類別的離線資料集(SongList)
                    self.songList = songResults.results
                    print("===============")
                    print(self.songList)
                    print("===============")
                    
                     //重整表格資料
                    DispatchQueue.main.async
                    {
                        
                        //重整表格資料
                        self.tableView.reloadData()
                    }
                    
                    
                } else {
                    print("error")
                }
            }
            task.resume()
        }
        

    }
    
    
    
   
    // MARK: - Table view data source

    //表格有幾段
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        
        return 1
    }

    //每一段表格有幾列資料
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
       
        return songList.count
    }
    
    //準備儲存格要存入的資料
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyTableViewCell", for: indexPath) as! MyTableViewCell
        
        cell.lblTrackName.text = songList[indexPath.row].trackName
        cell.lblArtisName.text = songList[indexPath.row].artistName
        cell.lblCollectionName.text = songList[indexPath.row].collectionName
        cell.lblReleaseDate.text = songList[indexPath.row].releaseDate.description
        
        
        //製作網路傳輸任務  拿取照片
        
        let task = URLSession.shared.dataTask(with: songList[indexPath.row].artworkUrl100) { (imagedata, reponse, error) in
            
            if error != nil
            {
                print("資料傳輸失敗")
                return
            }
            if let imgdata = imagedata
            {
                DispatchQueue.main.async {
                    cell.imagePhoto.image = UIImage(data: imgdata)
                }
                
            }
        }
        
        //開始執行網路任務 取得圖片
        task.resume()
        return cell
        
    }
    
    //MARK: - TableView delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        

        //記錄點選 儲存格位置
        currentRow = indexPath.row

    }
    
    //MARK: -  prepare segue
    //由連接線換頁時
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
        super.prepare(for: segue, sender: sender)
        
        //let musicVC = segue.description as! ViewController
        let musicVC = segue.destination as! ViewController
        
        musicVC.myTableViewController = self
        

        
    }

    

   

}
