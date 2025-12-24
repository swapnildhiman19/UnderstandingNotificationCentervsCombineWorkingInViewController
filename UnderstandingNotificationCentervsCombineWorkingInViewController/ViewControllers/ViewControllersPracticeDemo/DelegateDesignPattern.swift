//
//  DelegateDesignPattern.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 14/12/25.
//
import UIKit

protocol PaymentDelegate : AnyObject {
    //structs won't be able to implement this delegate
    func paymentDidSucceed(amount: Double)
    func paymentDidFail(error: Error)
}

enum PaymentError : Error {
    case invalidAmount
}

//Processing Class
class PaymentProcessor {
    weak var delegate : PaymentDelegate?

    func processPayment(amount: Double) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            [weak self] in
            if amount > 0 {
                self?.delegate?.paymentDidSucceed(amount: amount)
            } else {
                self?.delegate?
                    .paymentDidFail(error: PaymentError.invalidAmount)
            }
        }
    }
}

//class confirming to this
class PaymentViewController : UIViewController, PaymentDelegate {

    let paymentProcessor = PaymentProcessor()

    override func viewDidLoad(){
        super.viewDidLoad()
        paymentProcessor.delegate = self
        checkout()
    }

    func checkout(){
        paymentProcessor.processPayment(amount: 200)
    }

    func paymentDidSucceed(amount: Double) {
        print("Payment of \(amount) has been successfully completed")
    }

    func paymentDidFail(error: any Error) {
        print("Payment failed: \(error.localizedDescription)")
    }
}

