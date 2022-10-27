import SwiftUI

struct ContentView: View {
    @State private var pid: Int? = nil;
    @State private var pidText: String = "";
    @State private var pidValid: Bool = false;
    @State private var isRunning: Bool = false;
    @State private var senderTask: Task<(), Never>?;
    
    var body: some View {
        VStack {
            Text("Status: " + (isRunning ? "Running" : "Stopped")).font(.title2).foregroundColor(isRunning ? .green : .red)
            
            HStack {
                TextField(
                    "PID",
                    text: $pidText
                ).onChange(of: pidText, perform: { pidText in
                    if Int(pidText) != nil {
                        pidValid = true;
                    } else {
                        pidValid = false
                    }
                }).frame(width: 120)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .fixedSize(horizontal: true, vertical: false)
                
                Button("Set") {
                    pid = Int (pidText)
                    
                }.disabled(!pidValid)
            }
            
            Text("Current PID: " + ((pid != nil) ? String(pid!) : "-"))
            
            Button(!isRunning ? "Start" : "Stop", action: { Task {
                await executeSenderTask()
            }})
            .padding(.top)
            
            .disabled(pid == nil)
        }
        .padding()
    }
    
    func executeSenderTask() async {
        guard pid != nil else {
            return
        }
        
        if senderTask != nil {
            print("trying to kill task")
            senderTask!.cancel()
            
            return
        }
        
        senderTask = Task {
            isRunning = true
            
            let src = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
            
            let keyCode: CGKeyCode = 0x71; // F15
            //            let keyCode: CGKeyCode = 0x11; // T
            
            let keyDownEvent = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
            let keyUpEvent = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
            
            print("Sending keys to pid: ", pid!);
            
            while (!Task.isCancelled) {
                keyDownEvent?.postToPid( pid_t(pid!) );
                keyUpEvent?.postToPid( pid_t(pid!) );
                let sleepSeconds = Double.random(in: 2..<5) * 60;
                
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(sleepSeconds))
                } catch {
                    if Task.isCancelled {
                        print("calcellation error in sleep")
                        senderTask = nil
                        isRunning = false
                    }
                }
            }
            
            print("cancelled, after loop")
            senderTask = nil
            isRunning = false
            
            return
        }
        return
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/400.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/))
    }
}
