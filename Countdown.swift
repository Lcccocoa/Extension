
import Foundation
import RxSwift

/// 倒计时管理模块
class Countdown {
    /// 倒计时标识符
    private var identifier: String
    /// 倒计时开始数值(默认60s)
    private var startValue: Int = 60
    /// 倒计时开始时间戳
    private var startTime:TimeInterval = 0
    /// 倒计时当前时间戳
    private var currentTime:TimeInterval = 0
    /// 计时器
    private var timer:Timer?
    
    private let disposeBag = DisposeBag()
    private var timeUpdateClosure: (Int) -> Void
    
    init(identifier: String, startValue: Int = 60, timeUpdate closure:@escaping (Int) -> Void) {
        self.identifier = identifier
        self.startValue = startValue
        self.timeUpdateClosure = closure
        
        // 磁盘是否存在倒计时信息
        let diskCache = PINCache.shared.diskCache
        if diskCache.containsObject(forKey: self.identifier) {
            // 读取开始时间
            let time:NSNumber = diskCache.object(forKey: self.identifier) as! NSNumber
            self.startTime = time.doubleValue
            currentTime = Date().timeIntervalSince1970
            let interval = startValue - ( Int(currentTime) - Int(startTime) )
            if 0 < interval && interval <= startValue {
                startCountdown()
            } else { // 无效
                diskCache.removeObject(forKeyAsync: self.identifier, completion: nil)
            }
        }
        
        cache()
    }

    /// 开始计时器
    func start() {
        // 记录倒计时时间
        startTime = Date().timeIntervalSince1970
        startCountdown()
    }
    
    func stop() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
            
            let dCache = PINCache.shared.diskCache
            dCache.setObjectAsync(NSNumber(value: self.startTime), forKey: self.identifier, completion: { (cache, key, value) in
                log.debug("缓存时间完成")
            })
        }
    }
    
    deinit {
        log.verbose("Countdown deinit")
        stop()
    }
    
    private func startCountdown() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        // 重启倒计时
        timer = Timer(timeInterval: 1, target: self, selector: #selector(timeUpdate(timer:)), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoopMode.defaultRunLoopMode)
        timer?.fire()
    }
    
    @objc private func timeUpdate(timer: Timer) {
        currentTime = Date().timeIntervalSince1970
        // 当前时间和开始时间的间隔
        let interval = startValue - ( Int(currentTime) - Int(startTime) )
        
        // 回调
        self.timeUpdateClosure(interval)

        if 0 < interval && interval <= startValue { // 时间间隔在0-60之间
            log.verbose("\(interval)")
        } else { // 停止倒计时
            log.verbose("timer 停止:\(interval)")
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    /// 倒计时缓存操作
    private func cache(){
        // 监听app退出,保存到磁盘缓存
        NotificationCenter.default.rx.notification(NSNotification.Name.UIApplicationWillTerminate)
            .subscribe { [weak self] notification in
                if self?.timer != nil {
                    let dCache = PINCache.shared.diskCache
                    dCache.setObjectAsync(NSNumber(value: (self?.startTime)!), forKey: (self?.identifier)!, completion: { (cache, key, value) in
                        log.debug("缓存时间完成")
                    })
                }
            }.disposed(by: disposeBag)
        
        // 切换到后台
        NotificationCenter.default.rx.notification(NSNotification.Name.UIApplicationDidEnterBackground)
            .subscribe { [weak self] notification in
                if self?.timer != nil {
                    let dCache = PINCache.shared.diskCache
                    dCache.setObjectAsync(NSNumber(value: (self?.startTime)!), forKey: (self?.identifier)!, completion: { (cache, key, value) in
                        log.debug("缓存时间完成")
                    })
                    
                    self?.timer?.fireDate = Date.distantFuture
                }
            }.disposed(by: disposeBag)
        
        // 进入前台
        NotificationCenter.default.rx.notification(NSNotification.Name.UIApplicationWillEnterForeground)
            .subscribe { [weak self] (notification) in
                if self?.timer != nil {
                    self?.timer?.fireDate = Date()
                }
            }.disposed(by: disposeBag)
    }
}
