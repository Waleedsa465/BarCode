import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var video = AVCaptureVideoPreviewLayer()
    var session: AVCaptureSession?
    var isProcessingQRCode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }

    func stopCamera() {
        session?.stopRunning()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCamera()
    }

    func startCamera() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let session = self?.session, !session.isRunning else {
                return
            }
            session.startRunning()
        }
    }

    
    func setupCamera() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session = AVCaptureSession()
            
            guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
                print("Failed to get the camera device")
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                self?.session?.addInput(input)
            } catch {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            let output = AVCaptureMetadataOutput()
            self?.session?.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            var barcodeTypes: [AVMetadataObject.ObjectType] = [.ean8, .ean13, .pdf417, .code39, .code128, .qr]
            if #available(iOS 15.4, *) {
                barcodeTypes.append(contentsOf: [.codabar, .microQR, .face,.ean8, .ean13, .pdf417, .code39, .code128, .qr])
            }

            output.metadataObjectTypes = barcodeTypes

            
            DispatchQueue.main.async { [weak self] in
                self?.video = AVCaptureVideoPreviewLayer(session: (self?.session!)!)
                self?.video.frame = self?.view.layer.bounds ?? CGRect.zero
                self?.video.videoGravity = .resizeAspectFill // Make sure the aspect ratio is maintained while filling the screen
                self?.view.layer.addSublayer(self?.video ?? CALayer())

                DispatchQueue.global(qos: .background).async {
                    self?.session?.startRunning()
                }
            }
        }
    }

    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
           guard !isProcessingQRCode else { return }
           
           for metadataObject in metadataObjects {
               guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { continue }
               guard let stringValue = readableObject.stringValue else { continue }
               isProcessingQRCode = true
               showQRCodeAlert(stringValue)
           }
       }

    
    func showQRCodeAlert(_ stringValue: String) {
        let alert = UIAlertController(title: "QR Code", message: stringValue, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retake", style: .default, handler: { _ in
            self.isProcessingQRCode = false
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.isProcessingQRCode = false
            self.navigateToSecondVC(stringValue)
            print("value : \(stringValue)")
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func navigateToSecondVC(_ stringValue: String) {
        let secondVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SecondVC") as! SecondVC
        self.isProcessingQRCode = false
        secondVC.qrCodeValue = stringValue
        navigationController?.pushViewController(secondVC, animated: true)
    }
}
