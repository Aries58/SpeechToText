//
//  ViewController.swift
//  SpeechToText
//
//  Created by 王亮 on 2016/10/24.
//  Copyright © 2016年 wangliang. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController,SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var microphoneButton: UIButton!
    
    //en-US
//    private let speechRecognizer=SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    //zh_CN
     private let speechRecognizer=SFSpeechRecognizer(locale: Locale.init(identifier: "zh_CN"))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine=AVAudioEngine()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphoneButton.isEnabled=false
        
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled=false
            
            switch authStatus {
                
            case .authorized:
                isButtonEnabled=true
            case.denied:
                isButtonEnabled=false
                print("User denied access to speech recognizer")
            case.restricted:
                isButtonEnabled=false
                print("Speech recognition restricted")
            case.notDetermined:
                isButtonEnabled=false
                print("Speech recognition not yet authorizate")
            }
            
            OperationQueue.main.addOperation({
                
                self.microphoneButton.isEnabled=isButtonEnabled
            })
        }
        
  }
    
   
    @IBAction func microPhoneTap(_ sender: AnyObject) {
        
        print("microPhone---")
        
        if audioEngine.isRunning {
            
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled=false
            microphoneButton.setTitle("开始录音", for: .normal)
            
        }else {
        
            startRecording()
            microphoneButton.setTitle("停止录音", for: .normal)
        }
    }
    
    
  // SFSpeechRecognizerDelegate
 func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
        
        if available {
            
            print("available---")
            microphoneButton.isEnabled=true
        
        }else {
            
            print("not available---")
            microphoneButton.isEnabled=false
        }
    }
    
    
    //开始录音
    func startRecording() {
        
        if recognitionTask != nil {
        
            recognitionTask?.cancel()
            recognitionTask=nil
        }
        
        
        let audioSession=AVAudioSession.sharedInstance()
        
        do {
            //属性可能会抛出异常，故放入try catch里面
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true,with: .notifyOthersOnDeactivation)
            
        } catch  {
            
            print("audioSession properties were not set because of an error")
        }
        
        recognitionRequest=SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode=audioEngine.inputNode else {
            
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest=recognitionRequest else {
            
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults=true
        
        recognitionTask=speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal=false
            
            if result != nil {
                
                print("\(result)");
                
                self.textView.text = result?.bestTranscription.formattedString
                isFinal=(result?.isFinal)!
                
            }
            
            if error != nil || isFinal {
                
                print("\(error)");
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest=nil
                self.recognitionTask=nil
                
                self.microphoneButton.isEnabled=true
            }
            
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        
        } catch {
            
            print("audionEngine could not start because of an error")
        }
        
        textView.text="Say something, I am listening!"
        
    }
}

