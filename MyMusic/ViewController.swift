import UIKit
import MediaPlayer  //匯入『媒體播』放框架（framework）
//import AVFoundation

class ViewController: UIViewController,AVAudioPlayerDelegate
{
    //宣告音樂播放器
    var audio: AVAudioPlayer!
    //播放與暫停按鈕
    @IBOutlet weak var btnPlayAndPause: UIButton!
    //音樂播放進度滑桿
    @IBOutlet weak var slider: UISlider!
    //宣告計時器
    var timer:Timer!
    //標示已播放時間
    @IBOutlet weak var lblPlayedTime: UILabel!
    //標示剩餘的播放時間
    @IBOutlet weak var lblLeftTime: UILabel!
    @IBOutlet weak var imagePhoto: UIImageView!
    
    
    //--<新增>--紀錄上一頁的表格控制器的實體
    weak var myTableViewController:MyTableViewController!
    
    
    
    
    
    //MARK: Target Action
    //播放或暫停按鈕
    @IBAction func btnPlayAndPause(_ sender: UIButton)
    {
        print("播放或暫停按鈕被按下！")
        //如果音樂播放器存在，而且狀態不是播放中
        if audio != nil && !audio.isPlaying
        {
            //更換為按鈕『暫停』圖示
            sender.setBackgroundImage(UIImage(named: "pause.png"), for: .normal)
            //音樂開始播放
            audio.play()
            //規劃一個每秒執行一次的計時器
            if timer == nil
            {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
                    //把目前的播放進度設定為滑桿目前所在位置
                    self.slider.value = Float(self.audio.currentTime)
                    //標示已播放時間和剩餘時間
                    self.countPlayTime()
                    print("timer執行中...")
                })
                print("timer引用計數：\(CFGetRetainCount(timer)-1)")
            }
        }
        else    //當音樂在播放中時
        {
            //更換為按鈕『播放』圖示
            sender.setBackgroundImage(UIImage(named: "play.png"), for: .normal)
            //音樂暫停播放
            audio.pause()
        }
    }
    //停止按鈕
    @IBAction func btnStop(_ sender: UIButton!)
    {
        print("停止按鈕被按下！")
        
        if audio != nil
        {
            //停止播放音樂
            audio.stop()
            audio.currentTime = 0   //注意：audio.stop()不會將目前播放時間還原
            //恢復按鈕為『播放』圖示
            btnPlayAndPause.setBackgroundImage(UIImage(named: "play.png"), for: .normal)
            
            if timer != nil
            {
                //停止計時器 PS.此指令會移除Timer.scheduledTimer()方法所產生的"所有"強引用（歸還引用計數為1）
                timer.invalidate()
                print("timer引用計數-invalidate：\(CFGetRetainCount(timer)-1)")
                timer = nil  //移除最後由var timer:Timer!所使用的強引用（引用計數降為0）
                //把滑桿位置拉回起始位置
                slider.value = 0
            }
            //確認已播放時間和剩餘時間
            countPlayTime()
        }
    }
    
    @IBAction func silderValueChanged(_ sender: UISlider)
    {
        print("音樂播放進度的滑桿被拖動")
        if audio != nil
        {
            //將主動拖曳的滑桿值設定給目前播放進度
            audio.currentTime = TimeInterval(sender.value)
            //重新標示拖曳後的已播放時間和剩餘時間
            countPlayTime()
        }
    }
    
    
    //MARK: View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        
        //一開始還沒完成音樂下載時 不允許按下播放按鈕
        btnPlayAndPause.isEnabled = false
        
        //取得iOS設備的通知中心
        let notificationCenter = NotificationCenter.default
        //在通知中心註冊觀察音樂播放"中斷"或"從中斷中恢復"的通知
        notificationCenter.addObserver(self, selector: #selector(audioInterrupted(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        
        do
        {
            //設定音樂串流的形式(此段必須配合音樂背景播放的設定25-1，背景播放才能正確運作！)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        }
        catch
        {
            print("音樂串流形式設定錯誤：\(error)")
            return
        }
        
        
        
        do
        {
         
            let preurl = myTableViewController.songList[myTableViewController.currentRow].previewUrl
            
            //準備取得試聽資料檔案
            var dataTask = URLSession.shared.dataTask(with: preurl)
            { (musicData, response, error) in
                
                self.audio = try? AVAudioPlayer(data: musicData!)
                
                //通知音樂播放器，由誰(目前的類別實體self)實作了相關的協定方法
                self.audio.delegate = self
                
                
                //讓音樂播放器準備播放
                if self.audio.prepareToPlay()
                {
                    //回到主執行緒
                    DispatchQueue.main.async
                        {
                        
                        //設定滑桿的起始秒數和最終秒數（總音訊長度）
                        self.slider.minimumValue = 0
                        self.slider.maximumValue = Float(self.audio.duration)
                        //把滑桿拉回最前面的位置
                        self.slider.value = 0
                        //標示音樂的可播放長度
                        self.countPlayTime()
                        self.btnPlayAndPause.isEnabled = true
                    }
                    
                
                }
                
            }
            
            //執行傳輸任務
            dataTask.resume()
            
            let artworkUrl = myTableViewController.songList[myTableViewController.currentRow].artworkUrl100
            dataTask = URLSession.shared.dataTask(with: artworkUrl) { (imagedata, reponse, error) in
                
                if error != nil
                {
                    print("資料傳輸失敗")
                    return
                }
                if let imgdata = imagedata
                {
                    DispatchQueue.main.async {
                        self.imagePhoto.image = UIImage(data: imgdata)
                    }
                    
                }
            }
            
            //開始執行網路任務 取得圖片
            dataTask.resume()
            
        }
        
        //畫面即將消失
        func viewDidDisappear(_ animated:Bool)
        {
            
            super.viewDidDisappear(animated)
            btnPlayAndPause.isEnabled = false
            btnStop(nil)
        }
        
        
       
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
       
    }
    
    //MARK: 自訂函式
    //由通知中心發現"音樂播放中斷時"呼叫
    @objc func audioInterrupted(_ notification:NSNotification)
    {
        print("音樂播放中斷或恢復：\(String(describing: notification.userInfo))")
        //<方法一>直接以通知的字典中，所查詢到的0或1的值，直接判斷運行的方式
        if let avAudioSessionInterruptionOptionKey = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
        {
            if avAudioSessionInterruptionOptionKey == 1
            {
                print("電話撥入：音樂播放中斷！")
                //暫停音樂播放
                if audio != nil
                {
                    audio.pause()
                }
            }
            else
            {
                print("電話掛斷：音樂播放從中斷中恢復！")
                //繼續播放
                if audio != nil
                {
                    audio.play()
                }
            }
        }
        //<方法二>以還原列舉的形式來檢測目前的中斷狀態
        //guard檢測audio是否不為nil，以及是否拿到通知的字典，如果都有則繼續執行，如果其中一項條件不成立，則離開函式
//        guard audio != nil, let userInfo = notification.userInfo
//        else
//        {
//            return
//        }
//        //從字典拿到中斷或恢復的UInt(1或0)
//        let type_tmp = userInfo[AVAudioSessionInterruptionTypeKey] as! UInt
//        //以取得的1或0當作列舉的原始值，初始化為中斷的列舉實體
//        let type = AVAudioSession.InterruptionType(rawValue: type_tmp)
//
//        switch type!
//        {
//            case .began:
//                 print("電話撥入：音樂播放中斷！")
//                //暫停音樂播放
//                 if audio != nil
//                 {
//                    audio.pause()
//                 }
//
//            case .ended:
//                print("電話掛斷：音樂播放從中斷中恢復！")
//                //繼續播放
//                if audio != nil
//                {
//                    audio.play()
//                }
//        }
    }
    
    //標示已播放和剩餘時間
    func countPlayTime()
    {
        //計算已播放時間
        lblPlayedTime.text = String(format: "%02i:%02i", Int(slider.value)/60 ,Int(slider.value)%60)
        //計算剩餘時間
        lblLeftTime.text = String(format: "%02i:%02i",(Int(audio.duration)-Int(slider.value))/60 ,(Int(audio.duration)-Int(slider.value))%60)
    }

    //MARK: AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        print("音樂播完了！！！")
//        //<方法一>停止播放
//        //按一下停止按鈕，讓所有狀態還原（包含停止計時器！）
//        btnStop(nil)
        
        //<方法二>繼續播放（循環播放）
        audio.play()
    }
    
}

