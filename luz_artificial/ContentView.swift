import SwiftUI
import AVFoundation

struct ContentView: View {
    
    struct CustomResponse: Decodable, Identifiable {
        var id: Int
        let success: Bool
        let transcription: String
        let place: String?
        let intensity: Int?
    }
    
    @State private var responses: [CustomResponse] = []
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var transcriptText: String = ""

    var body: some View {
            VStack {
                Button(action: {
                    if self.isRecording {
                        stopRecording()
                        isRecording = false
                    } else {
                        startRecording()
                        isRecording = true
                    }
                    
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 70, height: 70)
                        
                        if self.isRecording {
                            Circle()
                                .stroke(Color.white, lineWidth: 6)
                                .frame(width: 85, height: 86)                            
                        }
                    }
                    Text("Grabar")
                        .padding()
                }.padding()

                Button(action: {
                    uploadRecording()
                }) {
                    Text("Subir")
                        .padding()
                }
                VStack(alignment: .leading, content: {
                    if !transcriptText.isEmpty {
                        Text("Último comando enviado").bold();
                        Text(transcriptText).bold()
                    }
                })
                
                NavigationView {
                    List {
                        ForEach(responses) { response in
                            if response.success {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: "xmark")
                            }
                            Text(response.transcription)
                        }
                    }
                }.navigationBarTitle(
                    Text("Lista de Comandos")
                )
                

            }
        }

    func clearRecording() {
        let audioURL = getDocumentsDirectory().appendingPathComponent("recording.wav")
        
        do {
            try FileManager.default.removeItem(at: audioURL)
        } catch {
            print("Error clearing recording: \(error)")
        }
    }
    func uploadRecording() {
        let audioURL = getDocumentsDirectory().appendingPathComponent("recording.wav")
        let requestURL = URL(string: "https://luz-artificial.ue.r.appspot.com")!
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        
        let boundary = UUID().uuidString
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        let body = NSMutableData()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        
        do {
            let audioData = try Data(contentsOf: audioURL)
            body.append(audioData)
        } catch {
            print("Error reading audio file: \(error)")
            return
        }

        body.append("\r\n--\(boundary)--".data(using: .utf8)!)
        request.httpBody = body as Data
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error uploading recording: \(error)")
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("Upload successful with status code: \(httpResponse.statusCode)")

                if let data = data {
                    // Print the response body as a string
                    if let responseBody = String(data: data, encoding: .utf8) {
                        print("Response Body: \(responseBody)")
                    }

                    // Parse the response body as CustomResponse
                    do {
                        let customResponse = try JSONDecoder().decode(CustomResponse.self, from: data)
                        print("Parsed CustomResponse: \(customResponse)")
                        transcriptText = customResponse.transcription;
                        responses.append(customResponse)
                    } catch {
                        print("Failed to parse response: \(error)")
                        }
                    }
                }
        }
        task.resume()
    }

    func startRecording() {
        clearRecording()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            let settings = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false
            ] as [String : Any]
            let audioURL = getDocumentsDirectory().appendingPathComponent("recording.wav")
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.record()
        } catch {
            print("Error setting up audio recording: \(error)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
