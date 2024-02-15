import UIKit

class SecondVC: UIViewController {

    var qrCodeValue: String?

    @IBOutlet weak var lblTxtx: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.lblTxtx.text = qrCodeValue
        
    }
}
